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
