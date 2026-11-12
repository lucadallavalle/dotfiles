;;; functions/sessions.el -*- lexical-binding: t; -*-
;;
;; Restore the last session when the first frame of the daemon opens, then
;; continue the agents of all task workspaces (see agents.el).

(defun my/restore-session-once (&rest _)
  "Restore the last Doom session once, shortly after the first frame opens.
The delay lets the dashboard draw first, so it doesn't cover the session."
  (remove-hook 'server-after-make-frame-hook #'my/restore-session-once)
  (run-with-timer
   0.5 nil
   #'doom-load-session))

(add-hook 'server-after-make-frame-hook #'my/restore-session-once)

;; Every session load (also SPC q l) brings back the agents and their panels;
;; the saved window layouts can't restore them, their buffers are gone.
(defun my/session-resume-agents-a (&rest _)
  "Resume the agents of the restored workspaces."
  (my/agent-resume-all))

(advice-add 'doom-load-session :after #'my/session-resume-agents-a)

;; Workspace layouts are saved without side windows (agent, file tree,
;; dashboard, popups): putting those back fails once their buffers are gone,
;; and the whole layout is lost. agents.el redraws the panels instead.
(defun my/session-window-state-get (&optional frame rwin)
  "Window state of FRAME's main area, side windows left out."
  (let ((window-persistent-parameters
         (seq-remove (lambda (p) (memq (car p) '(window-side window-slot)))
                     window-persistent-parameters)))
    (window-state-get (or rwin (window-main-window (or frame (selected-frame)))) t)))

(defun my/session--side-window-in-state-p (state)
  "Non-nil if window STATE contains a side window (layouts saved before)."
  (cond ((not (consp state)) nil)
        ((eq (car state) 'window-side) t)
        (t (or (my/session--side-window-in-state-p (car state))
               (my/session--side-window-in-state-p (cdr state))))))

(defun my/session-window-state-put (state &optional frame rwin)
  "Restore window STATE in FRAME; refuse layouts that still hold side windows.
persp-mode then shows one of the workspace's buffers instead."
  (when (my/session--side-window-in-state-p state)
    (error "Layout saved with side windows, not restored"))
  (window-state-put state (or rwin (frame-root-window (or frame (selected-frame)))) t))

(after! persp-mode
  (setq persp-window-state-get-function #'my/session-window-state-get
        persp-window-state-put-function #'my/session-window-state-put))

;; SPC TAB x kills every workspace and buffer, agents included, in one key
;; press. Unbound; SPC TAB d still kills a single workspace.
(map! :leader "TAB x" nil)

;; Save the session without being asked: whenever Emacs has been idle for two
;; minutes, on top of persp-mode's own save on exit. A crash or a forgotten
;; SPC q s then loses at most the last few minutes of layout changes.

(defvar my/session-save-idle-seconds 120
  "Idle time after which the session is saved.")

(defvar my/session-save-timer nil)

(defun my/session-save-quietly ()
  "Save the session if a client frame is open, without echoing anything."
  (when (and (bound-and-true-p persp-mode)
             (seq-some (lambda (frame) (frame-parameter frame 'client))
                       (frame-list)))
    (let ((inhibit-message t))
      (with-demoted-errors "Session save: %S"
        (persp-save-state-to-file (doom-session-file))))))

(when (timerp my/session-save-timer)
  (cancel-timer my/session-save-timer))
(setq my/session-save-timer
      (run-with-idle-timer my/session-save-idle-seconds t
                           #'my/session-save-quietly))

;; `doom-save-session' (SPC q s) switches off persp-mode's save on exit for
;; the rest of the session; switch it back on.
(defun my/session-keep-autosave-a (&rest _)
  "Keep persp-mode saving the session when Emacs exits."
  (setq persp-auto-save-opt 1))

(advice-add 'doom-save-session :after #'my/session-keep-autosave-a)
