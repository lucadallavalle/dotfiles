(defun my/org-reformat-buffer ()
  (interactive)
  (when (y-or-n-p "Really format current buffer? ")
    (let ((document (org-element-interpret-data (org-element-parse-buffer))))
      (erase-buffer)
      (insert document)
      (goto-char (point-min)))))

(defun my/org-add-ids-to-headlines-in-file (&optional all)
  "Add ID properties to top-level headlines in the current file
which do not already have one. With prefix argument ALL, to every headline."
  (interactive "P")
  (org-map-entries 'org-id-get-create (unless all "LEVEL=1")))
