;;; -*- lexical-binding: t -*-
(use-package pr-review
  :demand t
  :config
  (add-to-list 'browse-url-default-handlers
               '(pr-review-url-parse . pr-review-open-url)))

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
  (advice-add 'pr-review--refresh-internal :after #'my-pr-review-show-diff-line-numbers))

(provide 'config-pr-review)
