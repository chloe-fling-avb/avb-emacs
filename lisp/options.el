;;; -*- lexical-binding: t -*-
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(require 'use-package)
(setq use-package-always-ensure t
      custom-file (locate-user-emacs-file "custom.el")
      inhibit-startup-screen t
      make-backup-files nil
      create-lockfiles nil
      native-comp-async-report-warnings-errors 'silent
      org-startup-truncated nil)
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

;;; evil
(use-package evil
  :init
  (setq evil-want-C-i-jump nil ; frees TAB for org in terminals
        evil-want-C-u-scroll t
        evil-want-Y-yank-to-eol t
        evil-undo-system 'undo-redo)
  :config
  (evil-mode 1))

;;; clipboard/mouse
(xterm-mouse-mode 1)

(defvar wl-copied nil)
(unless (display-graphic-p)
  (setq interprogram-cut-function
        (lambda (text)
          (setq wl-copied text)
          (let ((proc (make-process :name "wl-copy" :command '("wl-copy")
                                    :connection-type 'pipe :noquery t)))
            (process-send-string proc text)
            (process-send-eof proc)))
        interprogram-paste-function
        (lambda ()
          (let ((text (shell-command-to-string "wl-paste -n 2>/dev/null")))
            (unless (or (string-empty-p text) (equal text wl-copied)) text)))))

;;; tab
(setq-default tab-width 4
              indent-tabs-mode nil
              c-basic-offset 4)

;;; ui
(setq display-line-numbers-type 'relative)
(global-display-line-numbers-mode 1)
(global-hl-line-mode 1)
(fido-vertical-mode 1)
(use-package ef-themes :config (load-theme 'ef-winter t))

;;; statusline
(defun stl-filepath ()
  (when buffer-file-name
    (let* ((dir (file-name-directory buffer-file-name))
           (path (if (file-in-directory-p dir command-line-default-directory)
                     (file-relative-name dir command-line-default-directory)
                   (abbreviate-file-name dir))))
      (unless (equal path "./") path))))

(defvar-local stl-git-counts nil)

;; hooks diff-hl's hunk list: (line inserts deletes type)
(defun stl-git-count (changes &rest _)
  (setq stl-git-counts
        (cl-loop for (_line ins del _type) in changes
                 sum (max 0 (- ins del)) into added
                 sum (min ins del) into changed
                 sum (max 0 (- del ins)) into removed
                 finally return (list added changed removed)))
  (force-mode-line-update))
(advice-add 'diff-hl--update-overlays :before #'stl-git-count)
(advice-add 'diff-hl-remove-overlays :after (lambda (&rest _) (setq stl-git-counts nil)))

(defun stl-git ()
  (when (and vc-mode (string-match "Git.\\(.+\\)" vc-mode))
    (let ((head (match-string-no-properties 1 vc-mode)))
      (pcase-let ((`(,added ,changed ,removed) stl-git-counts))
        (concat "[\ue725 " ; branch icon
                head
                (and added (> added 0) (format " +%d" added))
                (and changed (> changed 0) (format " ~%d" changed))
                (and removed (> removed 0) (format " -%d" removed))
                "]")))))

(setq-default mode-line-format
              '((:eval (if (mode-line-window-selected-p)
                           `("[" ,(stl-filepath) "%b] " ,(stl-git))
                         " %b"))
                mode-line-format-right-align
                (:eval (when (mode-line-window-selected-p)
                         `("[" mode-name "] [%p %l:%C] " ,(format-time-string "%H:%M"))))))

;; refresh clock once a minute
(run-at-time t 60 #'force-mode-line-update t)

;;; flash
(use-package evil-snipe
  :custom (evil-snipe-scope 'visible)
  :config (evil-snipe-override-mode 1))

;;; git
(use-package diff-hl
  :config
  (global-diff-hl-mode 1)
  (diff-hl-flydiff-mode 1)
  (unless (display-graphic-p) (diff-hl-margin-mode 1)))

;;; langs
(use-package nix-mode)
(use-package svelte-mode)
(use-package typescript-mode)
(use-package rust-mode)
(use-package lua-mode :custom (lua-indent-level 4))
(use-package markdown-mode :custom (markdown-header-scaling t))

;;; lsp
(use-package corfu
  :custom (corfu-preselect 'prompt)
  :config
  (global-corfu-mode 1)
  (add-hook 'evil-insert-state-exit-hook #'corfu-quit))

(use-package corfu-terminal
  :unless (display-graphic-p)
  :config (corfu-terminal-mode 1))

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs '(svelte-mode "svelteserver" "--stdio")))

(dolist (hook '(js-mode-hook typescript-mode-hook lua-mode-hook c-mode-hook c++-mode-hook
                python-mode-hook rust-mode-hook nix-mode-hook svelte-mode-hook))
  (add-hook hook #'eglot-ensure))

;; autotrigger completion only in lsp buffers
(add-hook 'eglot-managed-mode-hook
          (lambda ()
            (when (eglot-managed-p)
              (setq-local corfu-auto t)
              (corfu-mode 1))))

(setq flymake-show-diagnostics-at-end-of-line t)

(add-hook 'before-save-hook
          (lambda ()
            (when (and (fboundp 'eglot-managed-p) (eglot-managed-p)
                       (eglot-server-capable :documentFormattingProvider))
              (eglot-format-buffer))))

;;; colorizer
(use-package rainbow-mode :hook (prog-mode text-mode))

(provide 'options)
