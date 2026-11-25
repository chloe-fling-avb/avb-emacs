;;; -*- lexical-binding: t -*-
(defvar my/enable-meow nil)
(defvar workman t)

(add-to-list 'load-path (expand-file-name "lisp" (file-name-directory load-file-name)))

(require 'options)
(require 'workman)
(when my/enable-meow
  (require 'config-meow)
  (config-meow-enable))
(require 'keymaps)
(require 'windows)
(require 'config-dired)
(require 'config-magit)
(require 'config-lsp)
(require 'config-org)
(require 'config-org-notes)
(require 'config-pr-review)
(require 'config-dashboard)
(require 'snowglobe)

;; this is my normal window setup (yes it looks that insane)
(defalias 'cf-windows
  (kmacro
   "C-c d C-SPC 3 C-x 3 C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x } C-x o <tab> <tab> <tab> <return> C-x 5 2"))
