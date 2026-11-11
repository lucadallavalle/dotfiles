;;; functions/functions.el -*- lexical-binding: t; -*-
;;
;; Org helpers.

(defun my/org-reformat-buffer ()
  "Rewrite the current Org buffer in Org's canonical formatting.
Parses the buffer and re-emits it, after asking for confirmation."
  (interactive)
  (when (y-or-n-p "Really format current buffer? ")
    (let ((document (org-element-interpret-data (org-element-parse-buffer))))
      (erase-buffer)
      (insert document)
      (goto-char (point-min)))))

(defun my/org-add-ids-to-headlines-in-file (&optional all)
  "Add an ID property to each top-level headline that lacks one.
With prefix argument ALL, do it for every headline in the file."
  (interactive "P")
  (org-map-entries #'org-id-get-create (unless all "LEVEL=1")))
