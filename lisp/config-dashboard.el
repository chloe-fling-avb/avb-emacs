;;; -*- lexical-binding: t -*-
(use-package dashboard
  :ensure t
  :demand t
  :config
  (setq dashboard-banner-logo-title "イーマクス"
        dashboard-items '((recents . 10) (agenda . 7))
        dashboard-week-agenda t
        dashboard-agenda-show-all t
        dashboard-footer-messages
        '("一天到晚忙来忙去，屁点钱都没挣到 \n Whole Day I'm Fucking Busy Only Get Few Money"
          "ＢＯＲＮ ＴＯ ＤＩＥ \nWORLD IS A FUCK \n鬼神 Merge Em All 1989 \nI am slop man \n410,757,864,530 AI PRs"
          "眠いで忙しい。。。"
          "ἔοικα γοῦν τούτου γε σμικρῷ τινι αὐτῷ τούτῳ σοφώτερος εἶναι, ὅτι ἃ μὴ οἶδα οὐδὲ οἴομαι εἰδέναι")
        dashboard-startup-banner "~/Downloads/emacs.tiff"
        dashboard-navigator-buttons
        '(((nil "Projects" "Open ~/projects"
             (lambda (&rest _) (dired "~/projects")))
           (nil "Notes" "Open ~/notes"
            (lambda (&rest _) (dired "~/notes")))
           (nil "Standup" "Open the current standup note"
            (lambda (&rest _) (my/open-standup-note)))
           (nil "PRs" "Open PRs assigned to me"
            (lambda (&rest _)
              (pr-review-search "is:pr archived:false assignee:@me is:open")))))
        dashboard-startupify-list
        '(dashboard-insert-banner
          dashboard-insert-newline
          dashboard-insert-banner-title
          dashboard-insert-newline
          dashboard-insert-navigator
          dashboard-insert-init-info
          dashboard-insert-items
          dashboard-insert-newline
          dashboard-insert-footer))
  (dashboard-setup-startup-hook)
  (defun config-dashboard-diary-agenda ()
    (require 'diary-lib)
    (when (file-exists-p diary-file)
      (mapcar
       (lambda (entry)
         (let* ((date (car entry))
                (time (encode-time 0 0 0 (nth 1 date) (car date) (nth 2 date)))
                (item (format "%s %s"
                              (format-time-string dashboard-agenda-time-string-format time)
                              (cadr entry))))
           (propertize item
                       'dashboard-agenda-file diary-file
                       'dashboard-agenda-loc 1)))
       (diary-list-entries (calendar-current-date)
                           (if dashboard-week-agenda 8 1)
                           t))))
  (defun config-dashboard-agenda-with-diary (original &rest args)
    (append (config-dashboard-diary-agenda) (apply original args)))
  (advice-add 'dashboard-get-agenda :around
              #'config-dashboard-agenda-with-diary))

(my/leader "d" #'dashboard-open)

(provide 'config-dashboard)
