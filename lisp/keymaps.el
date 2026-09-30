;;; -*- lexical-binding: t -*-
(defvar winkeys (if workman '("y" "n" "e" "o") '("h" "j" "k" "l")))

(evil-set-leader 'normal (kbd "SPC"))

;;; normal
;;; C-s save (old habits)
(evil-define-key 'normal 'global (kbd "C-s") #'save-buffer)
(evil-define-key 'normal 'global (kbd "<leader>s") #'save-buffer)

;;; easy window creation/killing
(evil-define-key 'normal 'global (kbd "<leader>-") #'evil-window-split)
(evil-define-key 'normal 'global (kbd "<leader>|") #'evil-window-vsplit)
(evil-define-key 'normal 'global (kbd "<leader>wx") #'evil-window-delete)

(evil-define-key 'normal 'global (kbd "<leader>x") (lambda () (interactive) (evil-delete-buffer nil t)))

;;; ctrl + movement across emacs windows / tmux panes
(defun tmux-nav (move flag)
  (lambda ()
    (interactive)
    (condition-case nil
        (funcall move)
      (user-error (when (getenv "TMUX")
                    (call-process "tmux" nil nil nil "select-pane" flag))))))

(cl-loop for key in winkeys
         for move in '(windmove-left windmove-down windmove-up windmove-right)
         for flag in '("-L" "-D" "-U" "-R")
         do (evil-define-key 'normal 'global (kbd (concat "C-" key)) (tmux-nav move flag)))

;;; resize windows with C-<direction>
(evil-define-key 'normal 'global (kbd "C-<up>") (lambda () (interactive) (evil-window-decrease-height 2)))
(evil-define-key 'normal 'global (kbd "C-<down>") (lambda () (interactive) (evil-window-increase-height 2)))
(evil-define-key 'normal 'global (kbd "C-<right>") (lambda () (interactive) (evil-window-decrease-width 2)))
(evil-define-key 'normal 'global (kbd "C-<left>") (lambda () (interactive) (evil-window-increase-width 2)))

;; screen lines when wrapped, real lines with a count (matches relative numbers)
(evil-define-motion next-line-dwim (count)
  :type line
  (if count (evil-next-line count) (evil-next-visual-line 1)))

(evil-define-motion previous-line-dwim (count)
  :type line
  (if count (evil-previous-line count) (evil-previous-visual-line 1)))

(evil-define-key '(normal visual) 'global
  (kbd (nth 0 winkeys)) #'evil-backward-char
  (kbd (nth 1 winkeys)) #'next-line-dwim
  (kbd (nth 2 winkeys)) #'previous-line-dwim
  (kbd (nth 3 winkeys)) #'evil-forward-char)

(when workman
  (evil-define-key '(normal visual) 'global (kbd "M-y") #'evil-yank)
  (evil-define-key 'normal 'global
    (kbd "M-n") #'evil-search-next
    (kbd "M-e") #'evil-forward-word-end
    (kbd "M-o") #'evil-open-below))

;;; easy terminal
(evil-define-key 'normal 'global (kbd "<leader>t") (lambda () (interactive) (ansi-term (getenv "SHELL"))))

;;; file browser, opens on current file
(evil-define-key 'normal 'global (kbd "<leader>e") #'dired-jump)

;; yazi-style: left = parent, right = open
(with-eval-after-load 'dired
  (evil-define-key 'normal dired-mode-map
    (kbd (nth 0 winkeys)) #'dired-up-directory
    (kbd (nth 1 winkeys)) #'dired-next-line
    (kbd (nth 2 winkeys)) #'dired-previous-line
    (kbd (nth 3 winkeys)) #'dired-find-file))

;;; fuzzy find project files
(evil-define-key 'normal 'global (kbd "<leader>f") #'project-find-file)

;;; create new org note
(defun create-org-note ()
  (interactive)
  (let* ((title (read-string "Note title: "))
         (filename (concat title ".org"))
         (filepath (expand-file-name filename (file-name-directory (or buffer-file-name default-directory))))
         (date (format-time-string "%Y-%m-%d")))
    (with-temp-file filepath
      (insert (format "#+TITLE: %s\n" title))
      (insert (format "#+DATE: %s\n" date))
      (insert "#+FILETAGS: \n\n"))
    (find-file filepath)
    (end-of-line 3)
    (evil-insert-state)))

(evil-define-key 'normal 'global (kbd "<leader>+") #'create-org-note)


;;; quick buffers
(evil-define-key 'normal 'global (kbd "<leader>b") #'switch-to-buffer)

;;; completes thru completion-at-point
(evil-define-key '(normal insert) 'global (kbd "C-<down>") #'completion-at-point)

(provide 'keymaps)
