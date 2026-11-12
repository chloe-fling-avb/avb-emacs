;;; -*- lexical-binding: t -*-
(require 'config-org)

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

(provide 'config-org-notes)
