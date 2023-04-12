;;; ob-blockdiag.el --- org-babel functions for blockdiag evaluation

;; Copyright (C) 2017 Dmitry Moskowski

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;; Author: Dmitry Moskowski
;; Keywords: tools, convenience
;; Package-Version: 20170501.112
;; Homepage: https://github.com/corpix/ob-blockdiag.el

;; This file is NOT part of GNU Emacs.

;;; Commentary:

;; Org-Babel support for evaluating blockdiag source code.

;;; Requirements:

;; - blockdiag :: http://blockdiag.com/en/

;;; Code:
(require 'ob)

;; (add-to-list 'org-src-lang-modes '("blockdiag" . blockdiag))

(defun org-babel-execute:_blockdiag (body params)
  (let ((file (cdr (assoc :file params)))
        (tool (cdr (assoc :tool params)))
        (transparency (cdr (assoc :transparency params)))
        (antialias (cdr (assoc :antialias params)))
        (font (cdr (assoc :font params)))
        (size (cdr (assoc :size params)))
        (type (cdr (assoc :type params)))

        (buffer-name "*ob-blockdiag*")
        (error-template "Subprocess '%s' exited with code '%d', see output in '%s' buffer"))
    (unless file (error "no :file specified"))
    (save-window-excursion
      (let ((buffer (get-buffer buffer-name)))(if buffer (kill-buffer buffer-name) nil))
      (let ((data-file (org-babel-temp-file "blockdiag-input"))
            (args (append (list "-o" file)
                          (if transparency (list) (list "--no-transparency"))
                          (if antialias (list "--antialias") (list))
                          (if size (list "--size" size) (list))
                          (if font (list "--font" font) (list))
                          (if type (list "-T" type) (list))))
            (buffer (get-buffer-create buffer-name)))
        (with-temp-file data-file (insert body))
        (let
            ((exit-code (apply 'call-process tool nil buffer nil (append args (list data-file)))))
          (if (= 0 exit-code) nil (error (format error-template tool exit-code buffer-name))))))))

(defun org-babel-blockdiag-initialize ()
  "Define execution functions associated to blockdiag commands.
This function has to be called whenever `org-babel-blockdiag-commands'
is modified outside the Customize interface."
  (interactive)
  (dolist (name org-babel-blockdiag-commands)
    (let ((fname (intern (concat "org-babel-execute:" name)))
          (exe (or (executable-find name)
                   (executable-find (concat name "3"))
                   name)))
      ;; org-babel-execute:?
      (defalias fname
        (lambda (body params)
          ;; (:documentation
          ;;  (format "Execute a block of %s command with Babel." name))
          (org-babel-execute:_blockdiag body params)))
      (put fname 'definition-name 'org-babel-blockdiag-initialize)
      ;; org-babel-default-header-args:?
      (funcall (if (fboundp 'defvar-1) #'defvar-1 #'set) ;Emacs-29
               (intern (concat "org-babel-default-header-args:" name))
               `(
                 (:results . "file")
                 (:exports . "results")
                 (:tool    . ,exe)
                 (:transparency . nil)
                 (:antialias . nil)
                 (:font    . nil)
                 (:size    . nil)
                 (:type    . nil))
               nil))))

(defcustom org-babel-blockdiag-commands
  '("blockdiag" "actdiag" "seqdiag" "nwdiag" "rackdiag" "packetdiag")
  "List of names of blockdiag commands supported by babel blockdiag code blocks.
Call `org-babel-blockdiag-initialize' when modifying this variable
outside the Customize interface."
  :group 'org-babel
  :type '(repeat (string :tag "Blockdiag command: "))
  :set (lambda (symbol value)
         (set-default-toplevel-value symbol value)
         (org-babel-blockdiag-initialize)))

(provide 'ob-blockdiag)
;;; ob-blockdiag.el ends here
