;;; snowglobe.el --- adds snow behind the emacs dashboard -*- lexical-binding: t; -*-
;;; original white-christmas.el by Clemens Radermach

(defvar dashboard-buffer-name)
(defvar dashboard-mode-hook)

(defface dashboard-snow-face
  '((t (:foreground "white")))
  "Face used for snowflakes on the dashboard.")

(defvar dashboard-snow-char ?❄)

(defvar dashboard-snow-speed 0.1)

(defvar dashboard-snow-spawn-per-frame 1)

(defvar dashboard-snow--timer nil)
(defvar dashboard-snow--flakes nil)
(defvar dashboard-snow--size nil)

(defun dashboard-snow--flake-string ()
  (propertize (char-to-string dashboard-snow-char)
              'face 'dashboard-snow-face))

(defun dashboard-snow--advance (width height)
  (unless (equal dashboard-snow--size (cons width height))
    (setq dashboard-snow--size (cons width height)
          dashboard-snow--flakes nil))
  (setq dashboard-snow--flakes
        (delq nil
              (mapcar (lambda (f)
                        (when (< (cdr f) height)
                          (cons (car f) (1+ (cdr f)))))
                      dashboard-snow--flakes)))
  (dotimes (_ dashboard-snow-spawn-per-frame)
    (let ((col (random width)))
      (unless (assq col dashboard-snow--flakes)
        (push (cons col 1) dashboard-snow--flakes)))))

(defun dashboard-snow--row-columns (row)
  (sort (delq nil (mapcar (lambda (f) (and (= (cdr f) row) (car f)))
                          dashboard-snow--flakes))
        #'<))

(defun dashboard-snow--clear ()
  (let ((pos (point-min)))
    (while (setq pos (text-property-any pos (point-max) 'dashboard-snow t))
      (remove-text-properties pos (1+ pos) '(display nil dashboard-snow nil))
      (setq pos (1+ pos)))))

(defun dashboard-snow--prepare (width height)
  (goto-char (point-min))
  (dotimes (i height)
    (end-of-line)
    (let ((bol (line-beginning-position)))
      ;; Leave lines with images alone, padding would make them wrap.
      (unless (text-property-not-all bol (point) 'display nil)
        (let ((w (string-width (buffer-substring bol (point)))))
          (when (< w width)
            (insert (make-string (- width w) ?\s))))))
    (when (< i (1- height))
      (if (eobp) (insert "\n") (forward-char 1)))))

(defun dashboard-snow--draw (col row)
  (goto-char (point-min))
  (forward-line (1- row))
  (let ((eol (line-end-position)))
    (move-to-column col)
    (when (and (= (current-column) col)
               (< (point) eol)
               (eq (char-after) ?\s)
               (not (get-text-property (point) 'display)))
      (add-text-properties (point) (1+ (point))
                           `(display ,(dashboard-snow--flake-string)
                                     dashboard-snow t)))))

(defun dashboard-snow--render (width height)
  (let ((inhibit-read-only t)
        (buffer-undo-list t))
    (with-silent-modifications
      (save-excursion
        (dashboard-snow--clear)
        (dashboard-snow--prepare width height)
        (dolist (f dashboard-snow--flakes)
          (dashboard-snow--draw (car f) (cdr f)))))))

(defun dashboard-snow--tick ()
  (let* ((buf (get-buffer dashboard-buffer-name))
         (win (and buf (get-buffer-window buf))))
    (cond
     ((not (buffer-live-p buf)) (dashboard-snow-stop))
     (win
      (with-current-buffer buf
        (let ((width (1- (window-body-width win)))
              (height (window-body-height win)))
          (dashboard-snow--advance width height)
          (dashboard-snow--render width height)))))))

(defun dashboard-snow-start ()
  (unless dashboard-snow--timer
    (setq dashboard-snow--timer
          (run-with-timer 0 dashboard-snow-speed #'dashboard-snow--tick))))

(defun dashboard-snow-stop ()
  (interactive)
  (when dashboard-snow--timer
    (cancel-timer dashboard-snow--timer)
    (setq dashboard-snow--timer nil))
  (when-let* ((buf (get-buffer dashboard-buffer-name)))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (with-silent-modifications (dashboard-snow--clear))))))

(with-eval-after-load 'dashboard
  (add-hook 'dashboard-mode-hook #'dashboard-snow-start))

(provide 'snowglobe)
