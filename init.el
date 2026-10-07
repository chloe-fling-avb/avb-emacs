;;; -*- lexical-binding: t -*-
(defvar workman nil)

(add-to-list 'load-path (expand-file-name "lisp" (file-name-directory load-file-name)))

(add-hook 'org-mode-hook
          (lambda ()
            (flyspell-mode 1)
            (flyspell-buffer)))

(require 'options)
(require 'keymaps)
