;;; -*- lexical-binding: t -*-
(defun my/c-c-key (key command)
  (define-key mode-specific-map (kbd key) command))

(global-set-key (kbd "C-<down>") #'completion-at-point)

(my/c-c-key "i" #'set-input-method)

;;; windmove
(windmove-default-keybindings)
(add-hook 'org-shiftup-final-hook #'windmove-up)
(add-hook 'org-shiftleft-final-hook #'windmove-left)
(add-hook 'org-shiftdown-final-hook #'windmove-down)
(add-hook 'org-shiftright-final-hook #'windmove-right)

(provide 'keymaps)
