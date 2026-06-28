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
;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
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

(after! org
  (setq org-refile-targets '((org-agenda-files :maxlevel . 3)))
  (setq org-refile-use-outline-path 'file)
  (setq org-refile-allow-creating-parent-nodes 'confirm)
  (setq org-log-done 'time)
  (setq org-todo-keywords '((sequence "TODO(t)" "NEXT(n)" "PROJ(p)" "REPEAT(r)" "STRT(s)" "WAIT(w)" "IDEA(i)" "|" "DONE(d)" "KILL(k)")))
  (setq org-todo-keywords-for-agenda '((sequence "TODO(t)" "NEXT(n)" "PROJ(p)" "REPEAT(r)" "STRT(s)" "WAIT(w)" "IDEA(i)" "|" "DONE(d)" "KILL(k)")))
  (setq org-log-into-drawer 't)
  (setq org-id-link-to-org-use-id 'use-existing)
  (setq org-todo-repeat-to-state 'REPEAT)
  (setq calendar-week-start-day 1))
  (setq doom-modeline-enable-word-count 't)

  (setq org-agenda-custom-commands
        '(("n" "What's Next?"
           ((agenda "" ((org-agenda-span 7)))
            (todo "PROJ|STRT|WAIT|NEXT")))
          ("h" "What's Next? (home)"
           ((agenda "" ((org-agenda-span 7)))
            (todo "PROJ|STRT|WAIT|NEXT"))
           ((org-agenda-files '("~/org/todo.org"))))
          ("w" "What's Next? (work)"
           ((agenda "" ((org-agenda-span 7)))
            (todo "PROJ|STRT|WAIT|NEXT"))
           ((org-agenda-files '("~/org/todo_work.org"))))))

(use-package! org-pandoc-import :after org)

;; Custom functions.
(defun my/org-reformat-buffer ()
  (interactive)
  (when (y-or-n-p "Really format current buffer? ")
    (let ((document (org-element-interpret-data (org-element-parse-buffer))))
      (erase-buffer)
      (insert document)
      (goto-char (point-min)))))

(defun my/org-add-ids-to-headlines-in-file ()
  "Add ID properties to all headlines in the current file
which do not already have one."
  (interactive)
  (org-map-entries 'org-id-get-create))
