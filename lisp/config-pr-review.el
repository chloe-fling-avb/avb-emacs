;;; -*- lexical-binding: t -*-
(use-package pr-review
  :demand t
  :config
  (add-to-list 'browse-url-default-handlers
               '(pr-review-url-parse . pr-review-open-url))
  (unless use-meow
    (evil-ex-define-cmd "prr" #'pr-review)
    (evil-ex-define-cmd "prs" #'pr-review-search)
    (evil-ex-define-cmd "prn" #'pr-review-notification)))

(unless use-meow
  ;; screen lines when wrapped, real lines with a count (matches relative numbers)
  (evil-define-motion next-line-dwim (count)
    :type line
    (if count (evil-next-line count) (evil-next-visual-line 1)))

  (evil-define-motion previous-line-dwim (count)
    :type line
    (if count (evil-previous-line count) (evil-previous-visual-line 1))))

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
  (if use-meow
      (progn
        (define-key pr-review-mode-map (kbd (nth 0 winkeys)) #'backward-char)
        (define-key pr-review-mode-map (kbd (nth 3 winkeys)) #'forward-char))
    (evil-define-key '(normal motion) pr-review-mode-map
      (kbd (nth 0 winkeys)) #'evil-backward-char
      (kbd (nth 1 winkeys)) #'next-line-dwim
      (kbd (nth 2 winkeys)) #'previous-line-dwim
      (kbd (nth 3 winkeys)) #'evil-forward-char)))

(provide 'config-pr-review)
