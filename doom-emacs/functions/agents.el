;;; functions/agents.el -*- lexical-binding: t; -*-
;;
;; Agent workflow for Doom Emacs + ai-code + Magit.
;;
;;   One task = one branch + one worktree + one Doom workspace + one agent.
;;
;; Works with whichever ai-code backend is selected (Claude Code now, Pi later).
;; Worktrees live inside each repo at .worktrees/BRANCH (ignored via
;; .git/info/exclude) and task files live in the main repo's .ai.code.files/
;; (linked into each worktree), so task notes survive restarts and backend
;; switches.
;;
;; Keys (SPC j = "jobs"):
;;   SPC j n  new task          SPC j f  finish task (after merging)
;;   SPC j g  Magit for this task's worktree
;;   SPC j e  file tree for this task's worktree
;;   SPC j l  restore the layout (agent, tree, dashboard)
;;   SPC j z  zoom the current window, again to restore
;;   SPC j r  resume agent here SPC j R  resume agents in all task workspaces
;;   SPC j h  repo home (main checkout, for questions)
;;   SPC j s  scratch agent     SPC j a  one-off question, no session
;;   SPC j d  sessions dashboard  SPC j j  jump to a workspace

(require 'cl-lib)
(require 'seq)

(defvar my/agent-scratch-dir (expand-file-name "~/scratch/")
  "Folder used by the throwaway scratch agent.")

(defvar my/ask-program '("claude" "-p")
  "Command used by `my/ask'. The question is appended as the last argument.
For Pi, use \\='(\"pi\" \"-p\").")

;;; Helpers

(defun my/agent--repo-root ()
  "Return the main checkout of the current repository (never a worktree)."
  (require 'magit)
  (let ((common (magit-git-string "rev-parse" "--path-format=absolute"
                                  "--git-common-dir")))
    (unless common
      (user-error "Not inside a Git repository"))
    (file-name-as-directory
     (file-name-directory (directory-file-name common)))))

(defun my/agent--repo-name (root)
  "Return the repository name for ROOT, the way ai-code names it."
  (let ((name (file-name-nondirectory (directory-file-name root))))
    (if (string-suffix-p ".git" name) (substring name 0 -4) name)))

(defvar my/agent-worktrees-dir ".worktrees"
  "Folder inside each repo's main checkout that holds its task worktrees.")

(defun my/agent--worktree-path (root branch)
  "Return the worktree path for BRANCH inside the main checkout ROOT."
  (expand-file-name branch (expand-file-name my/agent-worktrees-dir root)))

(defun my/agent--exclude-worktrees (root)
  "Make Git ignore the worktrees folder in ROOT, via .git/info/exclude.
This is a local ignore list: it isn't committed, so teammates are unaffected."
  (let* ((exclude (expand-file-name ".git/info/exclude" root))
         (entry (concat "/" my/agent-worktrees-dir "/")))
    (make-directory (file-name-directory exclude) t)
    (unless (and (file-exists-p exclude)
                 (with-temp-buffer
                   (insert-file-contents exclude)
                   (re-search-forward (concat "^" (regexp-quote entry) "$") nil t)))
      (with-temp-buffer
        (when (file-exists-p exclude)
          (insert-file-contents exclude)
          (goto-char (point-max))
          (unless (bolp) (insert "\n")))
        (insert entry "\n")
        (write-region (point-min) (point-max) exclude nil 'silent)))))

(defun my/agent--create-worktree (root branch start-point)
  "Create BRANCH from START-POINT in a worktree under ROOT/.worktrees/.
Reuse BRANCH if it already exists. Return the worktree path."
  (let ((default-directory root)
        (path (my/agent--worktree-path root branch)))
    (when (file-exists-p path)
      (user-error "%s already exists" path))
    (my/agent--exclude-worktrees root)
    (make-directory (file-name-directory (directory-file-name path)) t)
    (unless (zerop (if (magit-branch-p branch)
                       (magit-call-git "worktree" "add" path branch)
                     (magit-call-git "worktree" "add" "-b" branch path start-point)))
      (user-error "git worktree add failed; see the *magit-process* buffer"))
    path))

(defun my/agent--create-task-file (root path branch)
  "Offer to create an ai-code task file for BRANCH, linked into PATH.
The real file lives in ROOT/.ai.code.files/ so it outlives the worktree."
  (when (and (fboundp 'ai-code--worktree-create-and-link-task-file)
             (y-or-n-p "Create a task file for this task? "))
    (ai-code--worktree-create-and-link-task-file root path branch)))

(defun my/agent--read-branch (start-point)
  "Read a valid new branch name, starting at START-POINT."
  (let (name)
    (while (not name)
      (let ((input (read-string (format "Task branch (from %s): " start-point))))
        (if (magit-git-success "check-ref-format" "--branch" input)
            (setq name input)
          (message "Invalid branch name: %s" input)
          (sit-for 1))))
    name))

(defun my/agent--session-buffers (dir)
  "Return live ai-code agent buffers whose session is rooted at DIR."
  (let ((target (file-name-as-directory (file-truename dir))))
    (cl-remove-if-not
     (lambda (buf)
       (when-let* ((proc (get-buffer-process buf))
                   ((process-live-p proc))
                   (owner (ignore-errors
                            (ai-code-backends-infra-session-directory buf))))
         (string= (file-name-as-directory (file-truename owner)) target)))
     (buffer-list))))

(defvar my/agent-continue-switches
  '((claude-code ai-code-claude-code-program-switches "--continue")
    (pi ai-code-pi-program-switches "--continue"))
  "Per backend: its switches variable and the flag that continues the most
recent conversation in a directory, without showing a picker.")

(defun my/agent--start-in (dir &optional resume)
  "Start an agent rooted at DIR.
With RESUME, continue the most recent conversation in DIR; for a backend
missing from `my/agent-continue-switches', show its resume picker instead."
  (with-current-buffer (dired-noselect dir)
    (pcase (and resume
                (alist-get ai-code-selected-backend my/agent-continue-switches))
      ((and `(,var ,flag) (guard (boundp var)))
       (cl-progv (list var) (list (append (symbol-value var) (list flag)))
         (ai-code-cli-start)))
      (_ (if resume (ai-code-cli-resume) (ai-code-cli-start))))))

(defun my/agent-dashboard-show ()
  "Show and refresh the sessions dashboard here, without selecting it."
  (require 'ai-code-session)
  (if (get-buffer-window ai-code-session-dashboard-buffer-name)
      (with-current-buffer ai-code-session-dashboard-buffer-name
        (ai-code-session-dashboard-refresh))
    (save-selected-window (ai-code-session-dashboard))))

(defun my/agent--task-file (dir)
  "Return the task file linked into worktree DIR, or nil."
  (seq-find #'file-symlink-p (directory-files dir t "\\.org\\'")))

;; ai-code ties a task file to its worktree with a buffer-local setting made
;; when the file is created. It's lost when the file is reopened (e.g. after a
;; session restore), and prompts sent from the file would then go to the main
;; checkout. Re-tie it whenever a task file is opened.
(defun my/agent-bind-task-file-h ()
  "Tie a task file to the worktree it is linked into, if any."
  (when (and buffer-file-name
             (string-match-p "/\\.ai\\.code\\.files/[^/]+\\.org\\'"
                             buffer-file-name))
    (ignore-errors
      (require 'magit)
      (require 'ai-code)
      (let ((name (file-name-nondirectory buffer-file-name)))
        (when-let* ((dir (seq-find
                          (lambda (dir)
                            (let ((link (expand-file-name name dir)))
                              (and (file-symlink-p link)
                                   (file-equal-p link buffer-file-name))))
                          (mapcar #'car (cdr (magit-list-worktrees))))))
          (ai-code--set-session-project-root dir))))))

(add-hook 'find-file-hook #'my/agent-bind-task-file-h)

;; ai-code never refreshes the dashboard by itself, so do it on a timer while
;; it's visible.
(defvar my/agent-dashboard-refresh-seconds 10
  "How often the visible sessions dashboard is refreshed.")

(defvar my/agent-dashboard-timer nil)

(defun my/agent-dashboard-refresh-visible ()
  "Refresh the sessions dashboard if a window shows it."
  (when-let* ((buf (get-buffer "*AI Code Sessions*"))
              ((get-buffer-window buf t)))
    (with-current-buffer buf
      (with-demoted-errors "Dashboard refresh: %S"
        (ai-code-session-dashboard-refresh)))))

(when (timerp my/agent-dashboard-timer)
  (cancel-timer my/agent-dashboard-timer))
(setq my/agent-dashboard-timer
      (run-with-timer my/agent-dashboard-refresh-seconds
                      my/agent-dashboard-refresh-seconds
                      #'my/agent-dashboard-refresh-visible))

;; Doom opens symlinks as their real file, so a task file linked into a
;; worktree looks like it belongs to the main checkout. Each workspace
;; therefore records its checkout as a workspace parameter, which is saved
;; and restored with the session.

(defun my/agent--main-root-of (dir)
  "Return the main checkout of the repository containing DIR, or nil."
  (when (and dir (not (file-remote-p dir)) (file-directory-p dir))
    (let ((default-directory dir))
      (ignore-errors (my/agent--repo-root)))))

(defun my/agent--workspace-dir (&optional name)
  "Return the checkout recorded for workspace NAME (default: current), or nil."
  (when-let* ((persp (if name (persp-get-by-name name) (get-current-persp)))
              ((perspective-p persp))
              (dir (persp-parameter 'my/agent-dir persp)))
    (file-name-as-directory dir)))

(defun my/agent--set-workspace-dir (dir)
  "Record DIR as the current workspace's checkout."
  (set-persp-parameter 'my/agent-dir (expand-file-name dir)))

(defun my/agent--current-dir ()
  "Return the Git checkout the current workspace is about.
Use the workspace's recorded checkout; fall back to the selected window's
buffer."
  (require 'magit)
  (or (my/agent--workspace-dir)
      (with-current-buffer (window-buffer (selected-window))
        (magit-toplevel))
      (user-error "Can't tell which Git checkout this workspace is for")))

(defun my/agent--main-checkout-p (dir)
  "Return non-nil when DIR is a repository's main checkout, not a worktree."
  (when-let ((main (my/agent--main-root-of dir)))
    (file-equal-p dir main)))

;;; Commands

(defun my/agent-task ()
  "Start a new task: branch + worktree + workspace + agent.
The worktree goes in the repo's .worktrees/ folder. You're offered an
ai-code task file; describe the task there. The agent opens on the right."
  (interactive)
  (require 'magit)
  (require 'ai-code)
  (require 'ai-code-git)
  (let* ((root (my/agent--repo-root))
         (default-directory root)
         (repo (my/agent--repo-name root))
         (start (magit-read-starting-point "Start task from"))
         (branch (my/agent--read-branch start))
         (workspace (format "%s:%s" repo branch))
         (path nil))
    (when (+workspace-exists-p workspace)
      (user-error "Workspace %s already exists; jump to it with SPC j j" workspace))
    (setq path (my/agent--create-worktree root branch start))
    (+workspace-switch workspace t)
    (my/agent--set-workspace-dir path)
    (delete-other-windows)
    (dired path)
    (my/agent--create-task-file root path branch)
    (delete-other-windows)
    (if-let ((task (my/agent--task-file path)))
        (find-file task)
      (dired path))
    (my/agent--start-in path)
    (my/agent--show-panels)))

(defun my/agent-resume (&optional fresh)
  "Resume the agent for the current workspace's checkout.
With prefix FRESH (\\[universal-argument]), start a new conversation instead."
  (interactive "P")
  (require 'ai-code)
  (let ((dir (my/agent--current-dir)))
    (if (my/agent--session-buffers dir)
        (message "An agent is already running in %s" dir)
      (my/agent--start-in dir (not fresh)))))

(defun my/agent-magit ()
  "Open Magit for the current workspace's checkout.
Unlike SPC g g, this is right even when the task file is focused."
  (interactive)
  (magit-status-setup-buffer (my/agent--current-dir)))

(defun my/agent-tree ()
  "Show the file tree for the current workspace's checkout only.
Unlike SPC o p, this never falls back to the main checkout."
  (interactive)
  (require 'treemacs)
  (with-current-buffer (dired-noselect (my/agent--current-dir))
    (treemacs-add-and-display-current-project-exclusively)))

(defun my/agent--show-panels ()
  "Show the task's agent, file tree and sessions dashboard, keeping focus."
  (save-selected-window
    (with-demoted-errors "Agent panels: %S"
      (when-let* ((dir (my/agent--workspace-dir))
                  (agent (car (my/agent--session-buffers dir)))
                  ((not (get-buffer-window agent))))
        (ai-code-backends-infra--display-buffer-in-side-window agent))
      (my/agent-tree)))
  (my/agent-dashboard-show))

(defun my/agent-layout ()
  "Bring back this workspace's agent, file tree and dashboard windows."
  (interactive)
  (my/agent--show-panels))

(defvar my/zoom--saved nil
  "Alist of ((FRAME . WORKSPACE) . WINDOW-CONFIGURATION) for `my/zoom-toggle'.")

(defun my/zoom-toggle ()
  "Show only the current window, full frame; run again to restore the layout.
Unlike SPC w m m, this also works from side windows such as the agent."
  (interactive)
  (let* ((key (cons (selected-frame) (+workspace-current-name)))
         (saved (assoc key my/zoom--saved)))
    (if saved
        (progn
          (setq my/zoom--saved (delq saved my/zoom--saved))
          (set-window-configuration (cdr saved)))
      (push (cons key (current-window-configuration)) my/zoom--saved)
      (let ((ignore-window-parameters t))
        (delete-other-windows)))))

(defun my/agent--workspace-for (dir)
  "Return the name of the workspace whose checkout is DIR, or nil."
  (seq-find (lambda (name)
              (when-let* ((d (my/agent--workspace-dir name)))
                (file-equal-p d dir)))
            (+workspace-list-names)))

(defun my/agent-dashboard-visit-a (fn &rest args)
  "Jump to the session's workspace instead of showing its buffer here."
  (if-let* ((session (ai-code-session-dashboard--session-at-point))
            (root (ai-code-session-repo-root session))
            (name (my/agent--workspace-for root)))
      (progn
        (+workspace-switch name)
        (my/agent--show-panels)
        (when-let* ((win (get-buffer-window (ai-code-session-buffer session))))
          (select-window win)))
    (apply fn args)))

(advice-add 'ai-code-session-dashboard-visit :around #'my/agent-dashboard-visit-a)

;; Evil's normal state hides the dashboard's own keys (RET, r, g, k, D), so
;; bind evil-friendly ones. j/k keep moving the cursor.
(map! :after ai-code-session
      :map ai-code-session-dashboard-mode-map
      :n "RET" #'ai-code-session-dashboard-visit
      :n "gr"  #'ai-code-session-dashboard-refresh
      :n "x"   #'ai-code-session-dashboard-kill-session
      :n "D"   #'ai-code-session-dashboard-open-diff
      :n "q"   #'quit-window)

(defun my/agent-resume-all ()
  "Continue the agent in every task workspace and show the dashboard there.
Runs after a session restore. Repo home and scratch workspaces are skipped."
  (interactive)
  (require 'ai-code)
  (let ((origin (+workspace-current-name))
        (count 0))
    (dolist (name (+workspace-list-names))
      (when-let* ((dir (my/agent--workspace-dir name))
                  ((file-directory-p dir))
                  ((not (my/agent--main-checkout-p dir))))
        (+workspace-switch name)
        (condition-case err
            (progn
              (unless (my/agent--session-buffers dir)
                (my/agent--start-in dir t)
                (cl-incf count))
              (my/agent--show-panels))
          (error (message "Skipped %s: %s" name (error-message-string err))))))
    (+workspace-switch origin)
    (message "Resumed %d agent(s)" count)))

(defun my/agent-home ()
  "Open the repo's home workspace (main checkout) with an agent for questions.
Ask with `q' in the ai-code menu, or use plan mode, so it doesn't edit main."
  (interactive)
  (require 'magit)
  (require 'ai-code)
  (let* ((root (my/agent--repo-root))
         (default-directory root)
         (workspace (format "%s:%s" (my/agent--repo-name root)
                            (or (magit-get-current-branch) "home"))))
    (+workspace-switch workspace t)
    (my/agent--set-workspace-dir root)
    (unless (my/agent--session-buffers root)
      (delete-other-windows)
      (dired root)
      (my/agent--start-in root))))

(defun my/agent-scratch ()
  "Jump to the scratch workspace, starting its agent if needed."
  (interactive)
  (require 'ai-code)
  (make-directory my/agent-scratch-dir t)
  (+workspace-switch "scratch" t)
  (unless (my/agent--session-buffers my/agent-scratch-dir)
    (delete-other-windows)
    (find-file (expand-file-name "notes.org" my/agent-scratch-dir))
    (my/agent--start-in my/agent-scratch-dir)))

(defun my/agent-finish ()
  "Finish the current task after merging it.
Stops its agent, removes the worktree and closes the workspace.
The task file stays in the main repo's .ai.code.files/."
  (interactive)
  (require 'magit)
  (let* ((dir (my/agent--current-dir))
         (default-directory dir)
         (main (my/agent--repo-root))
         (branch (magit-get-current-branch))
         (workspace (+workspace-current-name)))
    (when (file-equal-p dir main)
      (user-error "This is the main checkout, not a task worktree"))
    ;; The linked task file is just a symlink; the real file stays in main.
    (let ((untracked (cl-remove-if
                      (lambda (f) (file-symlink-p (expand-file-name f dir)))
                      (magit-untracked-files))))
      (when (or (magit-anything-modified-p) untracked)
        (user-error "Worktree has uncommitted or untracked changes; commit or discard them in Magit first")))
    (let ((main-head (let ((default-directory main)) (magit-rev-parse "HEAD"))))
      (unless (magit-git-success "merge-base" "--is-ancestor" "HEAD" main-head)
        (unless (y-or-n-p (format "%s is not merged into the main checkout. Remove anyway? "
                                  branch))
          (user-error "Cancelled"))))
    (unless (y-or-n-p (format "Stop the agent and remove worktree %s? " dir))
      (user-error "Cancelled"))
    (let ((kill-buffer-query-functions nil))
      (mapc #'kill-buffer (my/agent--session-buffers dir)))
    (dolist (link (directory-files dir t "\\.org\\'"))
      (when (file-symlink-p link) (delete-file link)))
    (let ((default-directory main))
      (unless (zerop (magit-call-git "worktree" "remove" dir))
        (user-error "git worktree remove failed; see the *magit-process* buffer"))
      (when (and branch (y-or-n-p (format "Also delete branch %s? " branch)))
        (unless (zerop (magit-call-git "branch" "-d" branch))
          (message "Branch %s not deleted (not fully merged?); use Magit b x" branch))))
    (+workspace/kill workspace)
    (message "Task %s finished" workspace)))

(defun my/ask (question)
  "Ask QUESTION once, without a session. The answer shows in *ask*.
Runs in the current project, so the agent can read its files."
  (interactive "sAsk: ")
  (let ((dir (or (doom-project-root) default-directory))
        (buf (get-buffer-create "*ask*")))
    (with-current-buffer buf
      (special-mode)
      (setq default-directory dir)
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert "Q: " question "\n\n"))
      (when (fboundp 'evil-local-set-key)
        (evil-local-set-key 'normal (kbd "q") #'quit-window)
        (evil-local-set-key 'motion (kbd "q") #'quit-window)))
    (let ((default-directory dir))
      (make-process
       :name "ask"
       :buffer buf
       :command (append my/ask-program (list question))
       :filter (lambda (proc text)
                 (when (buffer-live-p (process-buffer proc))
                   (with-current-buffer (process-buffer proc)
                     (let ((inhibit-read-only t))
                       (goto-char (point-max))
                       (insert text)))))
       :sentinel #'ignore))
    (pop-to-buffer buf)))

;;; Keys

(map! :leader
      (:prefix-map ("j" . "agents")
       :desc "New task"                  "n" #'my/agent-task
       :desc "Finish task"               "f" #'my/agent-finish
       :desc "Magit for this task"       "g" #'my/agent-magit
       :desc "File tree for this task"   "e" #'my/agent-tree
       :desc "Restore task layout"       "l" #'my/agent-layout
       :desc "Zoom window (toggle)"      "z" #'my/zoom-toggle
       :desc "Resume agent here"         "r" #'my/agent-resume
       :desc "Resume all agents"         "R" #'my/agent-resume-all
       :desc "Repo home (questions)"     "h" #'my/agent-home
       :desc "Scratch agent"             "s" #'my/agent-scratch
       :desc "Ask once"                  "a" #'my/ask
       :desc "Sessions dashboard"        "d" #'ai-code-session-dashboard
       :desc "Jump to workspace"         "j" #'+workspace/switch-to))
