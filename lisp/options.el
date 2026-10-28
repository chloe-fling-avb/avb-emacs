;;; -*- lexical-binding: t -*-
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(require 'use-package)
(setq use-package-always-ensure nil
      custom-file (locate-user-emacs-file "custom.el")
      inhibit-startup-screen t
      make-backup-files nil
      create-lockfiles nil
      native-comp-async-report-warnings-errors 'silent
      org-startup-truncated nil
      org-log-done 'time
      org-todo-keywords '((sequence "TODO" "IN PROGRESS" "|" "DONE"))
      org-agenda-files (directory-files-recursively
                        (expand-file-name "~/notes") "\\.org\\'"))
(menu-bar-mode -1)
(when (fboundp 'tool-bar-mode)
  (tool-bar-mode -1))
(when (fboundp 'scroll-bar-mode)
  (scroll-bar-mode -1))

;;; evil
(use-package evil
  :init
  (setq evil-want-keybinding nil
        evil-want-C-i-jump nil ; frees TAB for org in terminals
        evil-want-C-u-scroll t
        evil-want-Y-yank-to-eol t
        evil-undo-system 'undo-redo)
(add-to-list 'browse-url-default-handlers
             '(pr-review-url-parse . pr-review-open-url))
  :config
  (evil-mode 1)
  (evil-ex-define-cmd "prr" #'pr-review)
  (evil-ex-define-cmd "prs" #'pr-review-search)
  (evil-ex-define-cmd "prn" #'pr-review-notification)
  (evil-ex-define-cmd "pi" #'pilish)
  (evil-ex-define-cmd "term" #'ghostel))

;; Give Magit Evil-aware maps, including its transient menus.
(use-package evil-collection
  :ensure t
  :after evil
  :config
  (evil-collection-init '(magit)))

(use-package evil-org
  :after evil org
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

(with-eval-after-load 'org-colview
  (setq org-columns-default-format
        "%50ITEM(Task) %10Effort(Effort){:} %10CLOCKSUM"))

;;; zoom mode
(use-package zoom)
(custom-set-variables
 '(zoom-mode nil))

;;; ghostel
(use-package ghostel
  :ensure t)

;;; pilish
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(add-to-list 'package-archives '("gnu" . "https://elpa.gnu.org/packages/") t)
(package-refresh-contents)
(use-package pilish)
(setq pilish-evil-integration nil)

;;; dired preview
(use-package dired-preview
  :ensure t
  :config
  ;; Default values for demo purposes
  (setq dired-preview-delay 0.7)
  (add-to-list 'dired-preview-trigger-commands 'evil-next-line)
  (add-to-list 'dired-preview-trigger-commands 'evil-previous-line)
  (setq dired-preview-max-size (expt 2 20))
  (setq dired-preview-ignored-extensions
        '("mkv" "webm" "mp4"
          "mp3" "ogg" "m4a" "flac" "wav"
          "gz" "zst" "tar" "xz" "rar" "zip" "iso"
          ".DS_Store"))
  (dired-preview-global-mode 1))

;;; clipboard/mouse
(xterm-mouse-mode 1)
(mouse-wheel-mode 1)

(defvar terminal-copied nil)
(unless (display-graphic-p)
  (pcase system-type
    ('darwin
     (setq interprogram-cut-function
           (lambda (text)
             (setq terminal-copied text)
             (let ((proc (make-process :name "pbcopy" :command '("pbcopy")
                                       :connection-type 'pipe :noquery t)))
               (process-send-string proc text)
               (process-send-eof proc)))
           interprogram-paste-function
           (lambda ()
             (let ((text (shell-command-to-string "pbpaste 2>/dev/null")))
               (unless (or (string-empty-p text) (equal text terminal-copied)) text)))))
    ('gnu/linux
     (setq interprogram-cut-function
           (lambda (text)
             (setq terminal-copied text)
             (let ((proc (make-process :name "wl-copy" :command '("wl-copy")
                                       :connection-type 'pipe :noquery t)))
               (process-send-string proc text)
               (process-send-eof proc)))
           interprogram-paste-function
           (lambda ()
             (let ((text (shell-command-to-string "wl-paste -n 2>/dev/null")))
               (unless (or (string-empty-p text) (equal text terminal-copied)) text)))))))

;;; tab
(setq-default tab-width 4
              indent-tabs-mode nil
              c-basic-offset 4)

;;; ui
(add-to-list 'display-buffer-alist
             '(".*" (display-buffer-same-window)))
(setq pop-up-windows nil
      switch-to-buffer-obey-display-actions t)
(defun config-switch-to-buffer-other-window (_original buffer &optional norecord)
  (switch-to-buffer buffer norecord))
(advice-add 'switch-to-buffer-other-window :around
            #'config-switch-to-buffer-other-window)
(set-face-attribute 'default nil :family "Aporetic Serif Mono" :height 180)
(setq display-line-numbers-type 'relative)
(global-display-line-numbers-mode 1)
(global-hl-line-mode 1)
(fido-vertical-mode 1)
(use-package ef-themes :config (load-theme 'ef-dream t))

;;; statusline
(defun stl-filepath ()
  (when buffer-file-name
    (let* ((dir (file-name-directory buffer-file-name))
           (path (if (file-in-directory-p dir command-line-default-directory)
                     (file-relative-name dir command-line-default-directory)
                   (abbreviate-file-name dir))))
      (unless (equal path "./") path))))

(defvar-local stl-git-counts nil)

;; magit
(require 'package)
(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/") t)

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

;; approximate phase from the mean synodic month, relative to the 2000-01-06 new moon
(defun stl-moon ()
  (let* ((synodic 29.530588853)
         (days (/ (float-time (time-subtract nil (date-to-time "2000-01-06T18:14:00Z")))
                  86400.0))
         (idx (mod (round (* 8 (/ (mod days synodic) synodic))) 8)))
    (aref ["○" "◔+" "◑+" "◕+" "●" "◕-" "◐-" "◔-"] idx)))

(setq-default mode-line-format
              '((:eval (if (mode-line-window-selected-p)
                           `("[" ,(stl-filepath) "%b] " ,(stl-git))
                         " %b"))
                mode-line-format-right-align
                (:eval (when (mode-line-window-selected-p)
                         `("[" mode-name "] [%p %l:%C] " ,(stl-moon) " " ,(format-time-string "%H:%M"))))))

;; org mode options
;;; prettiness
(setq org-hide-emphasis-markers t)
  (font-lock-add-keywords 'org-mode
                          '(("^ *\\([-]\\) "
                             (0 (prog1 () (compose-region (match-beginning 1) (match-end 1) "•"))))))
;;; diary in a sensible location
(setq diary-file "~/notes/diary"
      org-agenda-include-diary t)

;;; appt reminders
(require 'appt)
(setq appt-message-warning-time 5
      appt-display-interval 1)
(appt-activate 1)

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
  :unless (or (display-graphic-p)
              (>= emacs-major-version 31))
  :config (corfu-terminal-mode 1))

(use-package eglot
  :config
  ;; Pyright asks Eglot to make one native file watch per workspace directory.
  ;; Large macOS projects exhaust the file-descriptor limit.  Tell Pyright we
  ;; do not support dynamic file-watch registration before it initializes.
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

;;; colorizer
(use-package rainbow-mode :hook (prog-mode text-mode))

(provide 'options)

;;; change cursor in insert mode (terminal frames only)
(add-hook 'evil-insert-state-entry-hook
          (lambda ()
            (unless (display-graphic-p)
              (send-string-to-terminal "\033[5 q"))))
(add-hook 'evil-insert-state-exit-hook
          (lambda ()
            (unless (display-graphic-p)
              (send-string-to-terminal "\033[2 q"))))
