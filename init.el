;;; -*- lexical-binding: t -*-
(defvar workman t)

(add-to-list 'load-path (expand-file-name "lisp" (file-name-directory load-file-name)))

(require 'options)
(require 'config-evil)
(require 'keymaps)
(require 'workman)
(require 'windows)
(require 'config-dired)
(require 'config-magit)
(require 'config-lsp)
(require 'config-org)
(require 'config-org-notes)
(require 'config-pr-review)
(require 'config-dashboard)
(require 'snowglobe)
