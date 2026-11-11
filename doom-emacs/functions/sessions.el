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
   (lambda ()
     (doom-load-session)
     (my/agent-resume-all))))

(add-hook 'server-after-make-frame-hook #'my/restore-session-once)
