;;; -*- lexical-binding: t -*-
(defvar winkeys (if workman '("y" "n" "e" "o") '("h" "j" "k" "l")))

(evil-set-leader 'normal (kbd "SPC"))

;;; Magit section navigation: keep the configured layout (Workman or QWERTY).
(with-eval-after-load 'magit
  (evil-define-key 'normal magit-mode-map
    (kbd (nth 0 winkeys)) #'magit-section-up
    (kbd (nth 1 winkeys)) #'magit-section-forward
    (kbd (nth 2 winkeys)) #'magit-section-backward
    (kbd (nth 3 winkeys)) #'magit-visit-thing))

(defun my-pr-review-show-diff-line-numbers (&rest _)
  (let ((old-width 1)
        (new-width 1)
        lines)
    (remove-overlays (point-min) (point-max) 'my-pr-review-line-number t)
    (save-excursion
      (goto-char (or pr-review--diff-begin-point (point-min)))
      (beginning-of-line)
      (while (< (point) (point-max))
        (let ((old (alist-get 'line (get-text-property (point) 'pr-review-diff-line-left)))
              (new (alist-get 'line (get-text-property (point) 'pr-review-diff-line-right))))
          (when (or old new)
            (setq old (and old (number-to-string old))
                  new (and new (number-to-string new))
                  old-width (max old-width (length (or old "")))
                  new-width (max new-width (length (or new ""))))
            (push (list (point) old new) lines)))
        (forward-line 1)))
    (dolist (line lines)
      (pcase-let ((`(,pos ,old ,new) line))
        (let ((overlay (make-overlay pos pos nil t t)))
          (overlay-put overlay 'my-pr-review-line-number t)
          (overlay-put
           overlay 'before-string
           (concat
            (propertize (format (format "%%%ds " old-width) (or old ""))
                        'face (if old 'diff-removed 'line-number))
            (propertize (format (format "%%%ds " new-width) (or new ""))
                        'face (if new 'diff-added 'line-number))
            (propertize "| " 'face 'line-number))))))))

(with-eval-after-load 'pr-review
  (advice-add 'pr-review--refresh-internal :after #'my-pr-review-show-diff-line-numbers)
  (evil-define-key '(normal motion) pr-review-mode-map
    (kbd (nth 0 winkeys)) #'evil-backward-char
    (kbd (nth 1 winkeys)) #'next-line-dwim
    (kbd (nth 2 winkeys)) #'previous-line-dwim
    (kbd (nth 3 winkeys)) #'evil-forward-char))

;;; normal
;;; C-s save (old habits)
(evil-define-key 'normal 'global (kbd "C-s") #'save-buffer)
(evil-define-key 'normal 'global (kbd "<leader>s") #'save-buffer)

;;; quick dashboard
(evil-define-key 'normal 'global (kbd "<leader>d") #'dashboard-open)

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

;;; resize windows with C-S-<direction>
(evil-define-key 'normal 'global (kbd "C-S-<up>") (lambda () (interactive) (evil-window-decrease-height 2)))
(evil-define-key 'normal 'global (kbd "C-S-<down>") (lambda () (interactive) (evil-window-increase-height 2)))
(evil-define-key 'normal 'global (kbd "C-S-<right>") (lambda () (interactive) (evil-window-decrease-width 2)))
(evil-define-key 'normal 'global (kbd "C-S-<left>") (lambda () (interactive) (evil-window-increase-width 2)))

;; screen lines when wrapped, real lines with a count (matches relative numbers)
(evil-define-motion next-line-dwim (count)
  :type line
  (if count (evil-next-line count) (evil-next-visual-line 1)))

(evil-define-motion previous-line-dwim (count)
  :type line
  (if count (evil-previous-line count) (evil-previous-visual-line 1)))

(evil-define-key '(normal visual motion) 'global
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

(defun my/org-find-file-by-filetag ()
  (interactive)
  (let (tag-files)
    (dolist (file org-agenda-files)
      (with-temp-buffer
        (insert-file-contents file)
        (goto-char (point-min))
        (when (re-search-forward "^#[+]FILETAGS:[ \t]*\\(.*\\)$" nil t)
          (dolist (tag (split-string (match-string 1) ":" t "[ \t]+"))
            (push (cons (downcase tag) file) tag-files)))))
    (setq tag-files (nreverse tag-files))
    (unless tag-files
      (user-error "No file tags found in Org agenda files"))
    (let* ((tag (completing-read "File tag: "
                                 (delete-dups (mapcar #'car tag-files)) nil t))
           matches)
      (dolist (entry tag-files)
        (when (equal (car entry) tag)
          (push (cdr entry) matches)))
      (setq matches (delete-dups matches))
      (let* ((notes-dir (expand-file-name "~/notes"))
             (choices (mapcar (lambda (file)
                                (cons (file-relative-name file notes-dir) file))
                              matches))
             (choice (completing-read "Open note: " choices nil t)))
        (find-file (cdr (assoc choice choices)))))))

(evil-define-key 'normal 'global (kbd "<leader>t") #'my/org-find-file-by-filetag)

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

;;; org agenda
(evil-define-key 'normal 'global (kbd "<leader>a") #'org-agenda)

(with-eval-after-load 'org-agenda
  (require 'evil-org-agenda)
  (evil-org-agenda-set-keys)
  (evil-define-key 'motion org-agenda-mode-map
    (kbd (nth 1 winkeys)) #'org-agenda-next-line
    (kbd (nth 2 winkeys)) #'org-agenda-previous-line
    (kbd (concat "g" (nth 1 winkeys))) #'org-agenda-next-item
    (kbd (concat "g" (nth 2 winkeys))) #'org-agenda-previous-item
    (kbd (concat "C-" (nth 1 winkeys))) #'org-agenda-next-item
    (kbd (concat "C-" (nth 2 winkeys))) #'org-agenda-previous-item))

;;; fuzzy find project files and open Magit
(evil-define-key 'normal 'global (kbd "<leader>f") #'project-find-file)
(evil-define-key 'normal 'global (kbd "<leader>g") #'magit-status)

;;; create new org note
(defcustom my/org-note-templates
  '(("hiring" . "#+TITLE: {{title}}\n#+DATE: {{date}}\n#+FILETAGS:\n#+REPO:\n#+SITE:\n#+CATEGORY: hiring\n#+BEGIN: clocktable :scope file\n#+END\n#+COLUMNS: %50ITEM(Task) %10Effort(Effort){:} %10CLOCKSUM\n\n* SPA\n** Pros\n** Cons\n\n* Repo\n** Pros\n** Cons\n\n* Decision\n")
    ("standup" . "#+TITLE: {{tmrw date}}\n#+DATE: {{date}}\n#+FILETAGS:\n#+CATEGORY: standup\n\n* TODO Yesterday\nDEADLINE: <{{date}}>\n** Dev\n** Review\n\n* TODO Today\nDEADLINE: <{{tmrw date}} 10:00>\n** Dev\n** Review\n\n* Push\n")
    ("dev" . "#+TITLE: {{title}}\n#+DATE: {{date}}\n#+FILETAGS:\n#+PR:\n#+CATEGORY: dev\n#+BEGIN: clocktable :scope file\n#+END\n#+COLUMNS: %50ITEM(Task) %10Effort(Effort){:} %10CLOCKSUM\n\n* TODO Issue\n* TODO Functional Requirements [/]\n* TODO Fix\n* TODO Review\n")
    ("review" . "#+TITLE: {{title}}\n#+DATE: {{date}}\n#+FILETAGS:\n#+PR:\n#+CATEGORY: review\n#+BEGIN: clocktable :scope file\n#+END\n#+COLUMNS: %50ITEM(Task) %10Effort(Effort){:} %10CLOCKSUM\n\n* TODO Issue\n* TODO Review\n")
    ("generic" . "#+TITLE: {{title}}\n#+DATE: {{date}}\n#+FILETAGS:\n#+PR:\n#+CATEGORY: generic\n#+BEGIN: clocktable :scope file\n#+END\n#+COLUMNS: %50ITEM(Task) %10Effort(Effort){:} %10CLOCKSUM\n\n"))
  "Org note templates. Use {{title}}, {{date}}, and {{tmrw date}} placeholders."
  :type '(alist :key-type (string :tag "Template name")
                :value-type (string :tag "Template"))
  :group 'org)

(defun my/org-create-note-from-template (template-name title date tomorrow-date filepath)
  (let ((content (cdr (assoc template-name my/org-note-templates))))
    (dolist (replacement `(("{{title}}" . ,title)
                           ("{{date}}" . ,date)
                           ("{{tmrw date}}" . ,tomorrow-date)))
      (setq content (replace-regexp-in-string (regexp-quote (car replacement))
                                              (cdr replacement) content t t)))
    (with-temp-file filepath
      (insert content))
    (set-file-modes filepath #o755)
    (find-file filepath)
    (setq buffer-read-only nil)
    (goto-char (point-min))
    (search-forward "\n\n" nil t)
    (evil-insert-state)))

(defun create-org-note ()
  (interactive)
  (let* ((template-name (completing-read "Note template: "
                                         (mapcar #'car my/org-note-templates)
                                         nil t nil nil "generic"))
         (now (current-time))
         (date (format-time-string "%Y-%m-%d" now))
         (tomorrow-date (format-time-string "%Y-%m-%d"
                                            (time-add now (days-to-time 1))))
         (title (if (equal template-name "standup")
                    tomorrow-date
                  (read-string "Note title: ")))
         (filename (concat title ".org"))
         (filepath (expand-file-name filename
                                     (file-name-directory (or buffer-file-name default-directory)))))
    (my/org-create-note-from-template template-name title date tomorrow-date filepath)))

(defun my/open-standup-note ()
  (interactive)
  (let* ((now (current-time))
         (target-offset (cond
                         ((< (string-to-number (format-time-string "%H" now)) 10) 0)
                         ((= (nth 6 (decode-time now)) 5) 3)
                         (t 1)))
         (target-time (time-add now (days-to-time target-offset)))
         (target-date (format-time-string "%Y-%m-%d" target-time))
         (previous-date (format-time-string
                         "%Y-%m-%d"
                         (time-add now (days-to-time (if (= target-offset 0) -1 0)))))
         (month-directory (downcase (format-time-string "%b-%y" target-time)))
         (filepath (expand-file-name
                    (format "standup/%s/%s.org" month-directory target-date)
                    "~/notes")))
    (if (file-exists-p filepath)
        (find-file filepath)
      (make-directory (file-name-directory filepath) t)
      (my/org-create-note-from-template "standup" target-date previous-date
                                         target-date filepath))))

(evil-define-key 'normal 'global (kbd "<leader>+") #'create-org-note)


;;; quick buffers
(evil-define-key 'normal 'global (kbd "<leader>b") #'switch-to-buffer)

;;; completes thru completion-at-point
(evil-define-key '(normal insert) 'global (kbd "C-<down>") #'completion-at-point)

(provide 'keymaps)
