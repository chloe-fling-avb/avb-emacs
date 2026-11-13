;;; -*- lexical-binding: t -*-
(use-package magit
  :ensure t)

(my/leader "g" #'magit-status)

(when (and workman (not use-meow))
  (with-eval-after-load 'magit
    (evil-define-key 'normal magit-mode-map
      (kbd (nth 0 winkeys)) #'magit-section-up
      (kbd (nth 1 winkeys)) #'magit-section-forward
      (kbd (nth 2 winkeys)) #'magit-section-backward
      (kbd (nth 3 winkeys)) #'magit-visit-thing)))

(use-package diff-hl
  :demand t
  :config
  (global-diff-hl-mode 1)
  (diff-hl-flydiff-mode 1)
  (unless (display-graphic-p) (diff-hl-margin-mode 1)))

(provide 'config-magit)
