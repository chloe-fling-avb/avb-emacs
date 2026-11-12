;;; -*- lexical-binding: t -*-
(use-package dired-preview
  :ensure t
  :demand t
  :config
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

;;; file browser, opens on current file
(evil-define-key 'normal 'global (kbd "<leader>e") #'dired-jump)

;; yazi-style: left = parent, right = open
(with-eval-after-load 'dired
  (evil-define-key 'normal dired-mode-map
    (kbd (nth 0 winkeys)) #'dired-up-directory
    (kbd (nth 1 winkeys)) #'dired-next-line
    (kbd (nth 2 winkeys)) #'dired-previous-line
    (kbd (nth 3 winkeys)) #'dired-find-file
    (kbd "RET") #'dired-find-file
    (kbd "+") #'dired-create-directory
    (kbd "C") #'dired-do-copy
    (kbd "R") #'dired-do-rename))

;;; fuzzy find project files
(evil-define-key 'normal 'global (kbd "<leader>f") #'project-find-file)

(provide 'config-dired)
