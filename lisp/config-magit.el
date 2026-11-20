;;; -*- lexical-binding: t -*-
(use-package magit
  :ensure t)

(use-package diff-hl
  :demand t
  :config
  (global-diff-hl-mode 1)
  (diff-hl-flydiff-mode 1)
  (unless (display-graphic-p) (diff-hl-margin-mode 1)))

(provide 'config-magit)
