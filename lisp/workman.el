;;; -*- lexical-binding: t -*-
(require 'keymaps)

(defvar winkeys (if workman '("y" "n" "e" "o") '("h" "j" "k" "l")))

(when workman
  (evil-define-key '(normal visual) 'global (kbd "M-y") #'evil-yank)
  (evil-define-key 'normal 'global
    (kbd "M-n") #'evil-search-next
    (kbd "M-e") #'evil-forward-word-end
    (kbd "M-o") #'evil-open-below))

(provide 'workman)
