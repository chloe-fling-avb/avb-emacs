;;; -*- lexical-binding: t -*-
(defun my/leader (key command)
  (if use-meow
      (meow-leader-define-key (cons (mapconcat #'string key " ") command))
    (evil-define-key 'normal 'global (kbd (concat "<leader>" key)) command)))

(if use-meow
    (meow-normal-define-key '("C-s" . save-buffer))
  (evil-set-leader 'normal (kbd "SPC"))
  (evil-define-key 'normal 'global (kbd "C-s") #'save-buffer)
  (evil-define-key '(normal insert) 'global (kbd "C-<down>") #'completion-at-point))

(when use-meow
  (global-set-key (kbd "C-<down>") #'completion-at-point))

(my/leader "s" #'save-buffer)
(my/leader "i" #'set-input-method)

(provide 'keymaps)
