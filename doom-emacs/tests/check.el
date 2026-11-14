;;; tests/check.el -*- lexical-binding: t; -*-
;;
;; Elisp checks for this config, run by pre-commit:
;;
;;   emacs --batch -Q -l doom-emacs/tests/check.el
;;
;; 1. Every .el file reads cleanly (balanced parentheses, valid syntax).
;; 2. functions/*.el byte-compile without a single warning, against the
;;    installed Doom and packages. A call to a function that no longer exists
;;    (a typo, or an ai-code internal removed by an upgrade) is such a warning.
;;
;; 3. functions/*.el, tests/*.el and config.el are indented the way Emacs
;;    indents them; a file that isn't is re-indented in place and the check
;;    fails, so the fix gets staged.
;;
;; Steps 2 and 3 are skipped, with a notice, on a machine without Doom.

(require 'cl-lib)
(require 'bytecomp)

(defvar check-root
  (expand-file-name ".." (file-name-directory load-file-name))
  "The doom-emacs/ folder.")

(defvar check-emacs-dir
  (file-name-as-directory
   (let ((dir (getenv "EMACSDIR")))
     (if (member dir '(nil "")) (expand-file-name "~/.config/emacs") dir)))
  "Where Doom is installed.")

(defvar check-failures 0)

(defvar check--form-start 1)

(defun check-fail (format-string &rest args)
  "Report a failure."
  (cl-incf check-failures)
  (message "FAIL %s" (apply #'format format-string args)))

(defun check-read (file)
  "Fail unless every form in FILE can be read."
  (with-temp-buffer
    (insert-file-contents file)
    (set-syntax-table emacs-lisp-mode-syntax-table)
    (condition-case err
        (while (progn (forward-comment (point-max)) (not (eobp)))
          (setq check--form-start (point))
          (read (current-buffer)))
      (error (check-fail "%s:%d: %s" file
                         (line-number-at-pos check--form-start)
                         (if (eq (car err) 'end-of-file)
                             "unbalanced parentheses in this form"
                           (error-message-string err)))))))

(defun check-load-doom ()
  "Load Doom's macros and the packages the config calls; nil without Doom."
  (let ((build (seq-find #'file-directory-p
                         (file-expand-wildcards
                          (expand-file-name ".local/straight/build-*"
                                            check-emacs-dir)))))
    (when build
      (setq user-emacs-directory check-emacs-dir)
      (add-to-list 'load-path (expand-file-name "lisp" check-emacs-dir))
      (dolist (dir (directory-files build t "\\`[^.]"))
        (when (file-directory-p dir)
          (add-to-list 'load-path dir)))
      (require 'doom)
      (require 'doom-lib)
      (dolist (file '("modules/doom/compat/+keybinds.el"
                      "modules/doom/compat/+use-package.el"
                      "lisp/lib/sessions.el"
                      "lisp/lib/projects.el"
                      "sources/doom+/modules/ui/workspaces/autoload/workspaces.el"
                      "sources/doom+/modules/lang/emacs-lisp/autoload/emacs-lisp.el"))
        (load (expand-file-name file check-emacs-dir) nil t))
      ;; Indent as the running Doom does (its emacs-lisp module sets this).
      (advice-add #'calculate-lisp-indent :override
                  #'+emacs-lisp--calculate-lisp-indent-a)
      (dolist (feature '(magit treemacs persp-mode org org-element org-id evil
                         ai-code ai-code-git ai-code-session
                         ai-code-backends-infra))
        (require feature))
      t)))

(defun check-compile (files)
  "Fail on any byte-compiler warning or error in FILES."
  (let ((byte-compile-dest-file-function
         (lambda (_) (make-temp-file "check" nil ".elc")))
        (warnings 0))
    (add-function :before byte-compile-log-warning-function
                  (lambda (&rest _) (cl-incf warnings)))
    (dolist (file files)
      (if (byte-compile-file file)
          ;; Later files call functions defined in earlier ones.
          (load file nil t)
        (check-fail "%s: does not compile" file)))
    (unless (zerop warnings)
      (check-fail "%d byte-compiler warning(s), listed above" warnings))))

(defun check-indent (files)
  "Re-indent FILES the way Emacs does; fail for each file that changed."
  (dolist (file files)
    (with-temp-buffer
      (insert-file-contents file)
      (let ((before (buffer-string))
            (indent-tabs-mode nil)
            (inhibit-message t))
        (delay-mode-hooks (emacs-lisp-mode))
        (indent-region (point-min) (point-max))
        (unless (string= before (buffer-string))
          (write-region (point-min) (point-max) file nil 'silent)
          (let ((inhibit-message nil))
            (check-fail "%s: re-indented, stage it again" file)))))))

(let* ((functions (directory-files (expand-file-name "functions" check-root)
                                   t "\\.el\\'"))
       (top (directory-files check-root t "\\.el\\'"))
       (tests (directory-files (expand-file-name "tests" check-root)
                               t "\\.el\\'")))
  (dolist (file (append top functions tests))
    (check-read file))
  (when (zerop check-failures)
    (if (not (check-load-doom))
        (message "Doom not found in %s: compile and indent checks skipped"
                 check-emacs-dir)
      (check-compile functions)
      (check-indent (append functions tests
                            (list (expand-file-name "config.el" check-root))))))
  (if (zerop check-failures)
      (message "Elisp checks passed")
    (kill-emacs 1)))
