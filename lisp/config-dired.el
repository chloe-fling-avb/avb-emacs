;;; -*- lexical-binding: t -*-
(use-package dired-preview
  :ensure t
  :demand t
  :config
  (setq dired-preview-delay 0.7)
  (dolist (command '(meow-next meow-prev))
    (add-to-list 'dired-preview-trigger-commands command))
  (setq dired-preview-max-size (expt 2 20))
  (setq dired-preview-ignored-extensions
        '("mkv" "webm" "mp4"
          "mp3" "ogg" "m4a" "flac" "wav"
          "gz" "zst" "tar" "xz" "rar" "zip" "iso"
          ".DS_Store"))
  (dired-preview-global-mode 1))

;; yazi-style: left = parent, right = open
(with-eval-after-load 'dired
  (define-key dired-mode-map (kbd "RET") #'dired-find-file)
  (define-key dired-mode-map (kbd "+") #'dired-create-directory)
  (define-key dired-mode-map (kbd "C") #'dired-do-copy)
  (define-key dired-mode-map (kbd "R") #'dired-do-rename))

;;; fuzzy find project files
(my/leader "f" #'project-find-file)

(provide 'config-dired)
