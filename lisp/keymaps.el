;;; -*- lexical-binding: t -*-
(defun my/leader (key command)
  (if use-meow
      (meow-leader-define-key (cons (mapconcat #'string key " ") command))
    (evil-define-key 'normal 'global (kbd (concat "<leader>" key)) command)))

(when use-meow
  (global-set-key (kbd "C-<down>") #'completion-at-point))

(my/leader "i" #'set-input-method)

;;; windmove
(windmove-default-keybindings)
(add-hook 'org-shiftup-final-hook #'windmove-up)
(add-hook 'org-shiftleft-final-hook #'windmove-left)
(add-hook 'org-shiftdown-final-hook #'windmove-down)
(add-hook 'org-shiftright-final-hook #'windmove-right)

(provide 'keymaps)
