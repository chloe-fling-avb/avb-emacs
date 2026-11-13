;;; -*- lexical-binding: t -*-
(require 'keymaps)
(require 'workman)

;;; easy window creation/killing
(my/leader "-" (if use-meow #'split-window-below #'evil-window-split))
(my/leader "|" (if use-meow #'split-window-right #'evil-window-vsplit))
(my/leader "wx" (if use-meow #'delete-window #'evil-window-delete))
(my/leader "x" (if use-meow #'kill-current-buffer
                 (lambda () (interactive) (evil-delete-buffer nil t))))

;;; ctrl + movement across emacs windows / tmux panes
(defun tmux-nav (move flag)
  (lambda ()
    (interactive)
    (condition-case nil
        (funcall move)
      (user-error (when (getenv "TMUX")
                    (call-process "tmux" nil nil nil "select-pane" flag))))))

(unless use-meow
  (cl-loop for key in winkeys
           for move in '(windmove-left windmove-down windmove-up windmove-right)
           for flag in '("-L" "-D" "-U" "-R")
           do (evil-define-key 'normal 'global (kbd (concat "C-" key)) (tmux-nav move flag)))

  (evil-define-key '(normal visual) 'global
    (kbd (nth 0 winkeys)) #'evil-backward-char
    (kbd (nth 1 winkeys)) #'evil-next-visual-line
    (kbd (nth 2 winkeys)) #'evil-previous-visual-line
    (kbd (nth 3 winkeys)) #'evil-forward-char))

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

;;; quick buffers
(my/leader "b" #'switch-to-buffer)

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
