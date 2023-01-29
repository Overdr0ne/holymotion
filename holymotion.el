;;; holymotion.el --- evil-easymotion, purified of evil

;; Author: Overdr0ne <scmorris.dev@gmail.com>
;; Keywords: convenience
;; Version: 20160228
;; Package-Requires: ((emacs "24") (avy "0.3.0") (cl-lib "0.5"))

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; This is a clone of the popular holymotion package for vim, which
;; describes itself in these terms:

;; > EasyMotion provides a much simpler way to use some motions in vim.
;; > It takes the <number> out of <number>w or <number>f{char} by
;; > highlighting all possible choices and allowing you to press one key
;; > to jump directly to the target.

;; If you're having trouble picturing this, please visit the github repo
;; for a screencast.

;; Usage/status
;; ============

;; This code was shamelessly forked from https://github.com/PythonNut/evil-easymotion

;; Currently most motions are supported, and it's easy to define your own holymotions.

;;   (evilem-define (kbd "SPC w") 'evil-forward-word-begin)

;; To define holymotions for all motions that evil defines by default, add

;;   (evilem-default-keybindings "SPC")

;; This binds all motions under the prefix `SPC` in `holymotion-state-map`.  This is not done by default for motions defined manually.  You will need to supply the prefix.

;; More advanced use-cases are detailed in the github README.

;;; Code:
(require 'cl-lib)
(require 'avy)

(defgroup holymotion nil
  "Emulate vim-easymotion."
  :group 'convenience
  :prefix "holymotion-")

(defcustom holymotion-keys nil
  "Value of `avy-keys' to set during motions.  Set to nil to leave unchanged."
  :type '(repeat :tag "Keys" character))

(defcustom holymotion-style nil
  "Value of `avy-style' to set during motions.  Set to nil to leave unchanged."
  :type '(choice
          (const :tag "Pre" pre)
          (const :tag "At" at)
          (const :tag "At Full" at-full)
          (const :tag "Post" post)
          (const :tag "De Bruijn" de-bruijn)
          (const :tag "Default" nil)))

(defvar holymotion-map (make-sparse-keymap)
  "Keymap used for the default bindings.")

(eval-and-compile
  (defun holymotion--unquote (exp)
    "Return EXP unquoted."
    (while (member (car-safe exp) '(quote function))
      (setq exp (cadr exp)))
    exp)

  (defun holymotion--make-name (func)
    (format "holymotion--motion-%s"
            (if (functionp func)
                (symbol-name (holymotion--unquote func))
              (mapconcat (lambda (f)
                           (symbol-name (holymotion--unquote f)))
                         func
                         "-")))))

(defun holymotion--jump (points)
  "Avy-jump to the set of POINTS generated by collector."
  (require 'avy)
  (let* ((avy-style (or holymotion-style avy-style))
         (avy-keys (or holymotion-keys avy-keys)))
    (avy-process points
                 (avy--style-fn avy-style))))

(defun holymotion--default-collect-postprocess (points)
  "Collect default postprocess using jump POINTS."
  (cl-stable-sort
   points
   #'<
   :key (lambda (pt)
          (if (equal (selected-window) (cdr pt))
              (abs (- (point) (car pt)))
            most-positive-fixnum))))

;;;###autoload
(defun holymotion--collect (func &optional
                                 scope
                                 all-windows
                                 initial-point
                                 collect-postprocess
                                 include-invisible)
  "Repeatedly execute FUNC and collect the cursor positions into a list.

Optionally:

Operate within SCOPE, see `bounds-of-thing-at-point’.

ALL-WINDOWS to consider in search of candidates.

INITIAL-POINT position to start search.

Use COLLECT-POSTPROCESS to apply any filtering after collection.

INCLUDE-INVISIBLE results with invisible overlay."
  (cl-letf ((points nil)
            (point nil)
            (avy-all-windows all-windows)
            ;; make sure the motion doesn't move the window
            (scroll-conservatively 101)
            (smooth-scrolling-mode nil)
            (scroll-margin 0))
    (if (functionp func)
        (avy-dowindows current-prefix-arg
          (save-excursion
            (save-restriction
              (when initial-point
                (goto-char (funcall initial-point)))
              (cl-destructuring-bind (beg . end)
                  (if scope
                      (bounds-of-thing-at-point scope)
                    (cons (point-min)
                          (point-max)))

                ;; trim trailing newline
                (when (= (char-before end) 10)
                  (cl-decf end))

                (narrow-to-region (max beg (window-start))
                                  (min end (window-end))))
              (while (and (ignore-errors
                            (setq this-command func
                                  last-command func)
                            (call-interactively func)
                            (unless include-invisible
                              (let ((ov (car (overlays-at (point)))))
                                (while (and ov (member
                                                'invisible
                                                (overlay-properties ov)))
                                  (goto-char (overlay-end ov))
                                  ;; This is a bit of a hack, since we
                                  ;; can't guarantee that we will end
                                  ;; up at the same point if we start
                                  ;; at the end of the invisible
                                  ;; region vs. looping through it.
                                  (call-interactively func)
                                  (setq ov (car (overlays-at (point)))))))
                            t)
                          (setq point (cons (point) (get-buffer-window)))
                          (not (member point points))
                          (push point points))))))
      (setq points (cl-remove-duplicates
                    (cl-mapcan (lambda (f)
                                 (holymotion--collect f scope all-windows))
                               func))))
    (funcall (or collect-postprocess
                 #'holymotion--default-collect-postprocess)
             points)))

(cl-defmacro holymotion-make-motion (name
                                     funcs
                                     &key
                                     pre-hook
                                     post-hook
                                     bind
                                     scope
                                     all-windows
                                     initial-point
                                     collect-postprocess
                                     include-invisible)
  "Automatically define an holymotion for FUNCS, naming it NAME.

Keywords:

Add PRE-HOOK or POST-HOOK to further customize your motion command.

BIND variables before jumping.

Operate within SCOPE, see `bounds-of-thing-at-point’.

ALL-WINDOWS to consider in search of candidates.

INITIAL-POINT position to start search.

Use COLLECT-POSTPROCESS to apply any filtering after collection.

INCLUDE-INVISIBLE results with invisible overlay."
  `(defun ,name ()
     (interactive)
     (require 'avy)
     (avy-with ,name
       (cl-letf* ,bind
         ,(when pre-hook `(funcall ,(if (functionp pre-hook)
                                        pre-hook
                                      `(lambda () ,pre-hook))))
         (holymotion--jump (holymotion--collect ,funcs
                                                ,scope
                                                ,all-windows
                                                ,initial-point
                                                ,collect-postprocess
                                                ,include-invisible))
         ,(when post-hook `(funcall ,(if (functionp post-hook)
                                         post-hook
                                       `(lambda () ,post-hook))))))))

(cl-defmacro holymotion-create (motion
                                &key
                                name
                                pre-hook
                                post-hook
                                bind
                                scope
                                all-windows
                                initial-point
                                collect-postprocess
                                include-invisible)
  "Convenience macro to create MOTION.

Keywords:

NAME for motion is autogenerated if not provided.

Add PRE-HOOK or POST-HOOK to further customize your motion command.

BIND variables before jumping.

Operate within SCOPE, see `bounds-of-thing-at-point’.

ALL-WINDOWS to consider in search of candidates.

INITIAL-POINT position to start search.

Use COLLECT-POSTPROCESS to apply any filtering after collection.

INCLUDE-INVISIBLE results with invisible overlay."
  `(holymotion-make-motion
    ,(or (holymotion--unquote name)
         (intern (holymotion--make-name motion)))
    ,motion
    :pre-hook ,pre-hook
    :post-hook ,post-hook
    :bind ,bind
    :scope ,scope
    :all-windows ,all-windows
    :initial-point ,initial-point
    :collect-postprocess ,collect-postprocess
    :include-invisible ,include-invisible))

(defmacro holymotion-derive-cmd (cmd)
  "Create and name a holymotion from CMD."
  `(progn
     (holymotion-make-motion ,(intern (concat "holymotion-" (symbol-name cmd)))
                             #',cmd
                             :scope 'line)))

;; (defun holymotion-derive-cmd (cmd)
;;   "Create and name a holymotion from CMD."
;;   (holymotion-make-motion (intern (concat "holymotion-" (symbol-name cmd)))
;;                           (cmd)))

;;;###autoload
(holymotion-make-motion
 holymotion-forward-to-word #'forward-to-word
 :scope 'line)

;;;###autoload
(holymotion-make-motion
 holymotion-forward-whitespace #'forward-whitespace
 :scope 'line)

;;;###autoload
(holymotion-make-motion
 holymotion-forward-word #'forward-word
 :scope 'line)

;;;###autoload
(holymotion-make-motion
 holymotion-backward-to-word #'backward-to-word
 :scope 'line)

;;;###autoload
(holymotion-make-motion
 holymotion-backward-word #'backward-word
 :scope 'line)

;;;###autoload
(holymotion-make-motion
 holymotion-next-line #'next-line
 :bind ((temporary-goal-column (current-column))
        (line-move-visual nil)))

;;;###autoload
(holymotion-make-motion
 holymotion-previous-line #'previous-line
 :bind ((temporary-goal-column (current-column))
        (line-move-visual nil)))

;;;###autoload
(holymotion-make-motion
 holymotion-next-visual-line #'next-line
 :bind ((temporary-goal-column (current-column))
        (line-move-visual t)))

;;;###autoload
(holymotion-make-motion
 holymotion-previous-visual-line #'previous-line
 :bind ((temporary-goal-column (current-column))
        (line-move-visual t)))

;;;###autoload
(holymotion-make-motion
 holymotion-backward-beginning-of-defun #'beginning-of-defun
 )

;;;###autoload
(holymotion-make-motion
 holymotion-backward-sentence #'backward-sentence)

;;;###autoload
(holymotion-make-motion
 holymotion-forward-sentence #'forward-sentence)

;;;###autoload
;; (holymotion-make-motion
;;  holymotion-search-next #'evil-search-next
;;  :bind (((symbol-function #'isearch-lazy-highlight-update)
;;          #'ignore)
;;         (search-highlight nil)))

;;;###autoload
;; (holymotion-make-motion
;;  holymotion-search-previous #'evil-search-previous
;;  :bind (((symbol-function #'isearch-lazy-highlight-update)
;;          #'ignore)
;;         (search-highlight nil)))

;;;###autoload
;; (holymotion-make-motion
;;  holymotion-search-word-forward #'evil-search-word-forward
;;  :bind (((symbol-function #'isearch-lazy-highlight-update)
;;          #'ignore)
;;         (search-highlight nil)))

;;;###autoload
;; (holymotion-make-motion
;;  holymotion-search-word-backward #'evil-search-word-backward
;;  :bind (((symbol-function #'isearch-lazy-highlight-update)
;;          #'ignore)
;;         (search-highlight nil)))

(provide 'holymotion)
;;; holymotion.el ends here
