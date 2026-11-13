;;; -*- lexical-binding: t -*-
;;; langs
(use-package nix-mode)
(use-package svelte-mode)
(use-package typescript-mode)
(use-package rust-mode)
(use-package lua-mode :custom (lua-indent-level 4))
(use-package markdown-mode :custom (markdown-header-scaling t))

;;; lsp
(use-package corfu
  :demand t
  :custom (corfu-preselect 'prompt)
  :config
  (global-corfu-mode 1)
  (add-hook (if use-meow 'meow-insert-exit-hook 'evil-insert-state-exit-hook)
            #'corfu-quit))

(use-package corfu-terminal
  :demand t
  :unless (or (display-graphic-p)
              (>= emacs-major-version 31))
  :config (corfu-terminal-mode 1))

(with-eval-after-load 'eglot
  ;; Pyright's per-directory watches exhaust macOS file descriptors on large projects.
  (defun config-eglot-client-capabilities (original server)
    (let ((capabilities (funcall original server)))
      (when (memq 'python-mode (eglot--major-modes server))
        (let* ((workspace (plist-get capabilities :workspace))
               (file-watches (plist-get workspace :didChangeWatchedFiles)))
          (plist-put file-watches :dynamicRegistration :json-false)
          (plist-put workspace :didChangeWatchedFiles file-watches)
          (plist-put capabilities :workspace workspace)))
      capabilities))
  (advice-add 'eglot-client-capabilities :around
              #'config-eglot-client-capabilities)
  (add-to-list 'eglot-server-programs '(svelte-mode "svelteserver" "--stdio"))
  (add-to-list 'eglot-server-programs '((nxml-mode xml-mode) "lemminx"))
  (add-to-list 'eglot-server-programs
               '((python-mode python-ts-mode) "pyright-langserver" "--stdio")))

(dolist (hook '(js-mode-hook typescript-mode-hook nxml-mode-hook xml-mode-hook
                lua-mode-hook c-mode-hook c++-mode-hook python-mode-hook rust-mode-hook
                nix-mode-hook svelte-mode-hook))
  (add-hook hook #'eglot-ensure))

;; autotrigger completion only in lsp buffers
(add-hook 'eglot-managed-mode-hook
          (lambda ()
            (when (eglot-managed-p)
              (setq-local corfu-auto t)
              (corfu-mode 1))))

(add-hook 'before-save-hook
          (lambda ()
            (when (and (not (derived-mode-p 'typescript-mode 'typescript-ts-mode
                                            'tsx-ts-mode))
                       (fboundp 'eglot-managed-p) (eglot-managed-p)
                       (eglot-server-capable :documentFormattingProvider))
              (eglot-format-buffer))))

(provide 'config-lsp)
