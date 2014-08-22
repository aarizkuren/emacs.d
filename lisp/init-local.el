;;; Package --- Summary
;;;; init-local
;;; Commentary:
;;;; My local configurations for Emacs

;;; Code:
; Change default font to Source Code Pro
(set-face-attribute 'default nil :font "Source Code Pro Medium")
(set-frame-font "Source Code Pro Medium" nil t)

; Disable auto-save and backups
(setq backup-inhibited t)
(setq auto-save-default nil)

;; ORG Configurations
(setq org-agenda-files (list "~/.org/burlata.org"
                             "~/.org/lana.org"
                             "~/.org/proiektuak.org"
                             ))

(provide 'init-local)
;;; init-local.el ends here
