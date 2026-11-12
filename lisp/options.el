;;; -*- lexical-binding: t -*-
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(require 'use-package)
(setq use-package-always-ensure t
      use-package-always-defer t
      use-package-expand-minimally t
      custom-file (locate-user-emacs-file "custom.el")
      inhibit-startup-screen t
      make-backup-files nil
      create-lockfiles nil
      native-comp-async-report-warnings-errors 'silent)
(menu-bar-mode -1)
(when (fboundp 'tool-bar-mode)
  (tool-bar-mode -1))
(when (fboundp 'scroll-bar-mode)
  (scroll-bar-mode -1))

;;; zoom mode
(use-package zoom)
(custom-set-variables
 '(zoom-mode nil))

;;; NOTE: i am keenly aware both of these packages violate my personal AI policy.

;;; ghostel
(use-package ghostel :commands ghostel)

;;; pilish
(use-package pilish
  :commands pilish
  :init (setq pilish-evil-integration nil))

;;; clipboard/mouse
(xterm-mouse-mode 1)
(mouse-wheel-mode 1)

(defvar terminal-copied nil)

(defun clipboard-setup (copy-cmd paste-cmd)
  "Route the kill ring through COPY-CMD and PASTE-CMD (shell command strings)."
  (setq interprogram-cut-function
        (lambda (text)
          (setq terminal-copied text)
          (let ((proc (make-process :name copy-cmd :command (list copy-cmd)
                                    :connection-type 'pipe :noquery t)))
            (process-send-string proc text)
            (process-send-eof proc)))
        interprogram-paste-function
        (lambda ()
          (let ((text (shell-command-to-string (concat paste-cmd " 2>/dev/null"))))
            (unless (or (string-empty-p text) (equal text terminal-copied)) text)))))

(unless (display-graphic-p)
  (pcase system-type
    ('darwin (clipboard-setup "pbcopy" "pbpaste"))
    ('gnu/linux (clipboard-setup "wl-copy" "wl-paste -n"))))

;;; tab
(setq-default tab-width 4
              indent-tabs-mode nil
              c-basic-offset 4)

;;; ui
(setq zone-when-idle 300)
(set-face-attribute 'default nil :family "Aporetic Serif Mono" :height 180)
(setq display-line-numbers-type 'relative)
(global-display-line-numbers-mode 1)
(global-hl-line-mode 1)
(fido-vertical-mode 1)
(define-key icomplete-minibuffer-map (kbd "M-RET") #'icomplete-fido-exit)
(use-package doric-themes :demand t :config (load-theme 'doric-obsidian t))

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

;; refresh clock once a minute
(run-at-time t 60 #'force-mode-line-update t)

;;; flash
(use-package evil-snipe
  :demand t
  :after evil
  :custom (evil-snipe-scope 'visible)
  :config (evil-snipe-override-mode 1))

;;; colorizer
(use-package rainbow-mode :hook (prog-mode text-mode))

;;; change cursor in insert mode (terminal frames only)
(add-hook 'evil-insert-state-entry-hook
          (lambda ()
            (unless (display-graphic-p)
              (send-string-to-terminal "\033[5 q"))))
(add-hook 'evil-insert-state-exit-hook
          (lambda ()
            (unless (display-graphic-p)
              (send-string-to-terminal "\033[2 q"))))

(provide 'options)
