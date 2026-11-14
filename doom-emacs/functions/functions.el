;;; functions/functions.el -*- lexical-binding: t; -*-
;;
;; Org helpers. Formatting is in org-format.el.

(defun my/org-add-ids-to-headlines-in-file (&optional all)
  "Add an ID property to each top-level headline that lacks one.
With prefix argument ALL, do it for every headline in the file."
  (interactive "P")
  (org-map-entries #'org-id-get-create (unless all "LEVEL=1")))
