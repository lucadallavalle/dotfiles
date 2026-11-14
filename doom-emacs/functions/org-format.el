;;; functions/org-format.el -*- lexical-binding: t; -*-
;;
;; Canonical Org formatting, shared with the pre-commit hook of the notes
;; repo. Must load in a bare `emacs --batch -Q' with only Org on the
;; load-path: no Doom macros, no other packages.

(defvar org-todo-keywords)
(defvar org-src-preserve-indentation)
(defvar org-tags-column)
(defvar org-list-allow-alphabetical)

(declare-function org-element-parse-buffer "org-element")
(declare-function org-element-interpret-data "org-element")
(declare-function org-element-map "org-element")
(declare-function org-element-property "org-element-ast")
(declare-function org-element-put-property "org-element-ast")

(defconst my/org-todo-keywords
  '((sequence "TODO(t)" "NEXT(n)" "PROJ(p)" "REPEAT(r)" "STRT(s)" "WAIT(w)"
     "IDEA(i)" "|" "DONE(d)" "KILL(k)"))
  "TODO keywords, for `org-todo-keywords' and the agenda.")

(defun my/org-format-batch-settings ()
  "Set what a bare Emacs lacks to format Org like the Doom config does.
Call it before visiting the Org file. The running Emacs never calls it."
  (setq org-todo-keywords my/org-todo-keywords
        ;; The values Doom's org module sets.
        org-src-preserve-indentation t
        org-tags-column 0
        org-list-allow-alphabetical t))

(defun my/org-format--unindent-verbatim (tree)
  "Strip each indented verbatim element in TREE of its own indentation.
The interpreters of these elements emit their contents verbatim (src and
example blocks because `org-src-preserve-indentation' is t), and the list
item around them indents every line again: without this the contents move
right on every run."
  (org-element-map tree '(src-block example-block export-block
                          latex-environment)
    (lambda (element)
      (let ((column (save-excursion
                      (goto-char (org-element-property :post-affiliated
                                                       element))
                      (current-indentation))))
        (unless (zerop column)
          (org-element-put-property
           element :value
           (replace-regexp-in-string
            (format "^ \\{1,%d\\}" column) ""
            (org-element-property :value element))))))))

(defun my/org-format-buffer ()
  "Rewrite the current Org buffer in Org's canonical formatting.
Parses the buffer and re-emits it, without asking. Return non-nil if the
text changed."
  (unless (derived-mode-p 'org-mode)
    (user-error "Not an Org buffer"))
  (require 'org-element)
  (let ((tree (org-element-parse-buffer)))
    (my/org-format--unindent-verbatim tree)
    (let ((document (org-element-interpret-data tree)))
      (unless (string= document (buffer-string))
        (delete-region (point-min) (point-max))
        (insert document)
        t))))

(defun my/org-reformat-buffer ()
  "Rewrite the current Org buffer in Org's canonical formatting.
Asks for confirmation first."
  (interactive)
  (when (y-or-n-p "Really format current buffer? ")
    (my/org-format-buffer)
    (goto-char (point-min))))
