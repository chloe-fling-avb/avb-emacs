;;; -*- lexical-binding: t -*-
(setq org-startup-truncated nil
      org-log-done 'time
      org-todo-keywords '((sequence "TODO" "IN PROGRESS" "|" "DONE")))

(when (file-directory-p "~/notes")
  (setq org-agenda-files (directory-files-recursively
                          (expand-file-name "~/notes") "\\.org\\'")))

;; agenda opens every file in the background; only spellcheck if a buffer is actually shown
(defun config-org-setup-view (&rest _)
  (remove-hook 'window-buffer-change-functions #'config-org-setup-view t)
  (flyspell-mode 1)
  (flyspell-buffer)
  (org-hide-drawer-all))

(add-hook 'org-mode-hook
          (lambda ()
            (if (get-buffer-window (current-buffer))
                (config-org-setup-view)
              (add-hook 'window-buffer-change-functions #'config-org-setup-view nil t))))

(with-eval-after-load 'org-colview
  (setq org-columns-default-format
        "%50ITEM(Task) %10Effort(Effort){:} %10CLOCKSUM"))

;;; org-transclusion
(use-package org-transclusion
  :commands (org-transclusion-add org-transclusion-remove
             org-transclusion-transient-menu org-transclusion-mode))

(defun my/org-transclusion-default-keyword-values (string)
  (append
   (unless (org-transclusion-keyword-value-level string) '(:level 4))
   (unless (org-transclusion-keyword-value-exclude-elements string)
     '(:exclude-elements "drawer keyword"))))

(with-eval-after-load 'org-transclusion
  (add-to-list 'org-transclusion-keyword-value-functions
               #'my/org-transclusion-default-keyword-values)
  (add-to-list 'org-transclusion-extensions 'org-transclusion-http)
  (require 'org-transclusion-http))

(defun my/org-transclusion-insert-keyword ()
  (interactive)
  (insert "#+transclude: ")
  (call-interactively #'org-insert-link))

(my/leader "Ti" #'my/org-transclusion-insert-keyword)
(my/leader "Ta" #'org-transclusion-add)
(my/leader "Td" #'org-transclusion-remove)
(my/leader "Tm" #'org-transclusion-transient-menu)
(my/leader "Tt" #'org-transclusion-mode)

;;; quick tag search
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

(my/leader "t" #'my/org-find-file-by-filetag)

;;; org agenda
(my/leader "a" #'org-agenda)

(with-eval-after-load 'org-agenda
  (unless use-meow
    (require 'evil-org-agenda)
    (evil-org-agenda-set-keys)
    (evil-define-key 'motion org-agenda-mode-map
      (kbd (nth 1 winkeys)) #'org-agenda-next-line
      (kbd (nth 2 winkeys)) #'org-agenda-previous-line
      (kbd (concat "g" (nth 1 winkeys))) #'org-agenda-next-item
      (kbd (concat "g" (nth 2 winkeys))) #'org-agenda-previous-item
      (kbd (concat "C-" (nth 1 winkeys))) #'org-agenda-next-item
      (kbd (concat "C-" (nth 2 winkeys))) #'org-agenda-previous-item)))

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

(provide 'config-org)
