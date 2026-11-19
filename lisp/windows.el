;;; -*- lexical-binding: t -*-
(require 'keymaps)
(require 'workman)

;;; resize windows with C-S-<direction>
(if use-meow
    (meow-normal-define-key
     (cons "C-S-<up>" (lambda () (interactive) (shrink-window 2)))
     (cons "C-S-<down>" (lambda () (interactive) (enlarge-window 2)))
     (cons "C-S-<right>" (lambda () (interactive) (shrink-window-horizontally 2)))
     (cons "C-S-<left>" (lambda () (interactive) (enlarge-window-horizontally 2))))
  (evil-define-key 'normal 'global (kbd "C-S-<up>") (lambda () (interactive) (evil-window-decrease-height 2)))
  (evil-define-key 'normal 'global (kbd "C-S-<down>") (lambda () (interactive) (evil-window-increase-height 2)))
  (evil-define-key 'normal 'global (kbd "C-S-<right>") (lambda () (interactive) (evil-window-decrease-width 2)))
  (evil-define-key 'normal 'global (kbd "C-S-<left>") (lambda () (interactive) (evil-window-increase-width 2))))

(defun config-dired-preview-buffer-p (buffer &rest _)
  (and (boundp 'dired-preview--buffers)
       (memq (get-buffer buffer) dired-preview--buffers)))

(defun config-magit-buffer-p (buffer)
  (let ((buffer (get-buffer buffer)))
    (and buffer
         (with-current-buffer buffer
           (derived-mode-p 'magit-mode)))))

(defun config-dired-current-buffer-p (&rest _)
  (derived-mode-p 'dired-mode))

(add-to-list 'display-buffer-alist
             '((not (or (derived-mode . magit-mode)
                        config-dired-preview-buffer-p
                        config-dired-current-buffer-p))
               (display-buffer-same-window)))

(defun config-switch-to-buffer-other-window (original buffer &optional norecord)
  (if (or (derived-mode-p 'magit-mode)
          (config-magit-buffer-p buffer))
      (funcall original buffer norecord)
    (switch-to-buffer buffer norecord)))
(advice-add 'switch-to-buffer-other-window :around
            #'config-switch-to-buffer-other-window)

(provide 'windows)
