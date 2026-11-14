;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")
(setq user-full-name "Luca Dalla Valle"
      user-mail-address "luca.dallavalle@outlook.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;; (setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
(setq doom-font (font-spec :family "Fira Code" :size 16 :weight 'regular)
      doom-variable-pitch-font (font-spec :family "IBM Plex Sans" :size 16))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'catppuccin)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type 'relative)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

;; Where projectile looks for projects
(setq projectile-project-search-path '("~/dev"))

;; Org: refiling, TODO keywords, logging
;; `my/org-todo-keywords' is in functions/org-format.el, loaded here because
;; this block can run before the loop at the end of this file.
(load (expand-file-name "functions/org-format.el" doom-user-dir) nil t)
(after! org
  (setq org-refile-targets '((org-agenda-files :maxlevel . 3)))
  (setq org-refile-use-outline-path 'file)
  (setq org-refile-allow-creating-parent-nodes 'confirm)
  (setq org-log-done 'time)
  (setq org-todo-keywords my/org-todo-keywords)
  (setq org-todo-keywords-for-agenda my/org-todo-keywords)
  (setq org-log-into-drawer 't)
  (setq org-id-link-to-org-use-id 'use-existing)
  (setq org-todo-repeat-to-state 'REPEAT)
  (setq calendar-week-start-day 1))

;; Word count in the modeline for text buffers
(setq doom-modeline-enable-word-count 't)

;; Agenda views: SPC o A, then n (everything) or h (home only)
(setq org-agenda-custom-commands
      '(("n" "What's Next?"
         ((agenda "" ((org-agenda-span 7)))
          (todo "PROJ|STRT|WAIT|NEXT")))
        ("h" "What's Next? (home)"
         ((agenda "" ((org-agenda-span 7)))
          (todo "PROJ|STRT|WAIT|NEXT"))
         ((org-agenda-files '("~/org/todo.org"))))))

;; Import other document formats into Org through pandoc
(use-package! org-pandoc-import :after org)

;; Coding agents (see README.md and functions/agents.el)
(use-package! ai-code
  :demand t
  :config
  (ai-code-set-backend 'claude-code)      ; later: 'pi
  ;; Task worktrees go in each repo's .worktrees/ folder (see functions/agents.el).
  ;; This only affects ai-code's own worktree command, if you use it directly.
  (setq ai-code-git-worktree-root (expand-file-name "~/worktrees"))
  ;; Agent window on the right, as in the layout
  (setq ai-code-backends-infra-window-side 'right
        ai-code-backends-infra-window-width 90)
  ;; (setq ai-code-backends-infra-terminal-backend 'eat)
  (map! :leader :desc "AI code" "o c" #'ai-code-menu)
  (global-auto-revert-mode 1)
  (setq auto-revert-interval 1)
  (after! magit
    (ai-code-magit-setup-transients)))

;; List the repo's worktrees in every Magit status buffer
(after! magit
  (add-hook 'magit-status-sections-hook #'magit-insert-worktrees t))

;; Save file buffers by themselves after 5 idle seconds, so nothing is lost
;; and agents and Magit always see what's on screen.
(setq auto-save-visited-interval 5)
(auto-save-visited-mode 1)

;; Keep Emacs' own Lisp indentation: an .editorconfig indent_size would
;; otherwise force a fixed offset and misalign Lisp code.
(setq editorconfig-lisp-use-default-indent t)

;; Custom functions.
;; Load everything in functions/ (agents.el, sessions.el, ...)
(dolist (file (directory-files (expand-file-name "functions" doom-user-dir)
                               t "\\.el\\'"))
  (load file nil t))
