;;; -*- lexical-binding: t -*-
(use-package dired-preview
  :ensure t
  :demand t
  :config
  (setq dired-preview-delay 0.7)
  (dolist (command (if use-meow '(meow-next meow-prev)
                    '(evil-next-line evil-previous-line)))
    (add-to-list 'dired-preview-trigger-commands command))
  (setq dired-preview-max-size (expt 2 20))
  (setq dired-preview-ignored-extensions
        '("mkv" "webm" "mp4"
          "mp3" "ogg" "m4a" "flac" "wav"
          "gz" "zst" "tar" "xz" "rar" "zip" "iso"
          ".DS_Store"))
  (dired-preview-global-mode 1))

;;; file browser, opens on current file
(my/leader "e" #'dired-jump)

;; yazi-style: left = parent, right = open
(with-eval-after-load 'dired
  (unless use-meow
    (evil-define-key 'normal dired-mode-map
      (kbd (nth 0 winkeys)) #'dired-up-directory
      (kbd (nth 1 winkeys)) #'dired-next-line
      (kbd (nth 2 winkeys)) #'dired-previous-line
      (kbd (nth 3 winkeys)) #'dired-find-file
      (kbd "RET") #'dired-find-file
      (kbd "+") #'dired-create-directory
      (kbd "C") #'dired-do-copy
      (kbd "R") #'dired-do-rename)))

;;; fuzzy find project files
(my/leader "f" #'project-find-file)

(provide 'config-dired)
