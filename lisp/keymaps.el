;;; -*- lexical-binding: t -*-
(evil-set-leader 'normal (kbd "SPC"))

;;; C-s save (old habits)
(evil-define-key 'normal 'global (kbd "C-s") #'save-buffer)
(evil-define-key 'normal 'global (kbd "<leader>s") #'save-buffer)

;;; language swaps
(evil-define-key 'normal 'global (kbd "<leader>i") #'set-input-method)

;;; completes thru completion-at-point
(evil-define-key '(normal insert) 'global (kbd "C-<down>") #'completion-at-point)

(provide 'keymaps)
