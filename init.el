;;; -*- lexical-binding: t -*-
(defvar workman t)

(add-to-list 'load-path (expand-file-name "lisp" (file-name-directory load-file-name)))

(add-hook 'org-mode-hook
          (lambda ()
            (flyspell-mode 1)
            (flyspell-buffer)
            (org-hide-drawer-all)))

(require 'options)
(require 'keymaps)
