;;; holymotion-lib.el --- a library of holymotions   -*- lexical-binding: t; -*-

;; Copyright (C) 2023  Sam

;; Author: Sam <scmorris.dev@gmail.com>
;; Keywords: lisp, tools

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This is just a separable library of holymotions, so users of holymotion can
;; have a collection of predefines.

;;; Code:

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
 holymotion-forward-list #'forward-list)

;;;###autoload
(holymotion-make-motion
 holymotion-backward-list #'backward-list)

;;;###autoload
(holymotion-make-motion
 holymotion-forward-sexp #'forward-sexp)

;;;###autoload
(holymotion-make-motion
 holymotion-backward-sexp #'backward-sexp)

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
 holymotion-backward-beginning-of-defun #'beginning-of-defun)

;;;###autoload
(holymotion-make-motion
 holymotion-beginning-of-line #'beginning-of-line)

;;;###autoload
(holymotion-make-motion
 holymotion-end-of-line #'beginning-of-line)

;;;###autoload
(holymotion-make-motion
 holymotion-backward-sentence #'backward-sentence)

;;;###autoload
(holymotion-make-motion
 holymotion-forward-sentence #'forward-sentence)

(provide 'holymotion-lib)
;;; holymotion-lib.el ends here
