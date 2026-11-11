;;; functions/sessions.el -*- lexical-binding: t; -*-
;;
;; Restore the last session when the first frame of the daemon opens.
;; Agents are not restored (they're live processes): run SPC j R afterwards.

(defun my/restore-session-once (&rest _)
  "Restore the last Doom session once, shortly after the first frame opens.
The delay lets the dashboard draw first, so it doesn't cover the session."
  (remove-hook 'server-after-make-frame-hook #'my/restore-session-once)
  (run-with-timer
   0.5 nil
   (lambda ()
     (doom-load-session)
     (message "Session restored. Resume agents with SPC j R"))))

(add-hook 'server-after-make-frame-hook #'my/restore-session-once)
