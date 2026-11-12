;;; -*- lexical-binding: t -*-
(use-package evil
  :demand t
  :init
  (setq evil-want-keybinding nil
        evil-want-C-i-jump nil ; frees TAB for org in terminals
        evil-want-C-u-scroll t
        evil-want-Y-yank-to-eol t
        evil-undo-system 'undo-redo)
  :config
  (evil-mode 1)
  (evil-ex-define-cmd "pi" #'pilish)
  (evil-ex-define-cmd "term" #'ghostel))

(use-package evil-org
  :demand t
  :after (evil org)
  :config
  (setq evil-org-movement-bindings
        `((up . ,(if workman "e" "k"))
          (down . ,(if workman "n" "j"))
          (left . ,(if workman "y" "h"))
          (right . ,(if workman "o" "l"))))
  (dolist (hook '(org-mode-hook org-capture-mode-hook org-src-mode-hook))
    (add-hook hook #'evil-org-mode))
  (evil-org-set-key-theme '(navigation insert textobjects additional))
  (evil-define-key 'normal 'evil-org-mode
    (kbd "RET") #'org-open-at-point
    (kbd "o") #'evil-forward-char))

(use-package evil-collection
  :ensure t
  :demand t
  :after (evil magit)
  :config
  (evil-collection-init '(magit)))

(provide 'config-evil)
