;;; acm.el --- Competitive programming made easy -*- lexical-binding: t; -*-

;; Copyright (C) 2018 ksqsf

;; Author: ksqsf <i@ksqsf.moe>
;; Version: 0.1
;; URL: https://github.com/ksqsf/acm.el

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package features acm-mode, a minor mode to help competitive programmers
;; quickly build, test, and submit solutions.
;;
;; With acm-mode enabled, you can switch to a buffer for program input,
;; build your program, and instantly run your program with the provided input.
;; The running time and the ouput are provided as well.

;;; Code:

(defvar-local acm--source-buffer nil)
(defvar-local acm--input-buffer nil)
(defvar-local acm--output-buffer nil)
(defvar-local acm--window-configuration nil)

(defun acm--base-name ()
  (with-current-buffer acm--source-buffer
    (file-name-base (buffer-file-name))))

(defun acm--command ()
  "Get the command.  Buffers must be associated before calling this function."
  (with-current-buffer acm--source-buffer
    (format "./%s" (acm--base-name))))

(defun acm--try-fill-input ()
  "Try filling in the input buffer with an input file whose name is like EXE.in.

Note this function does NOT mean visting that input file."
  (let ((input-file-name (format "%s.in" (acm--base-name))))
    (when (file-exists-p input-file-name)
      (with-current-buffer acm--input-buffer
	(insert-file-contents input-file-name)))))

(defun acm-compile ()
  "Compile the current file to an executable with the same name."
  (interactive)
  (with-current-buffer acm--source-buffer
    (let* ((src-file (buffer-file-name))
	 (exe-file (file-name-base src-file)))
    (compile (format "g++ -o %s -Wall -ggdb -std=c++14 %s" exe-file src-file)))))

(defun acm-run ()
  "Execute the executable, using input from the input buffer, writing output to the output buffer."
  (interactive)
  (with-current-buffer acm--source-buffer
    (let ((command (acm--command))
	  (output-buffer acm--output-buffer))
      (with-current-buffer acm--input-buffer
	(shell-command-on-region (point-min) (point-max) command output-buffer)))))

(defun acm-input ()
  "Switch to the input buffer."
  (interactive)
  (with-current-buffer acm--source-buffer
    (switch-to-buffer-other-window acm--input-buffer)))

(defun acm-output ()
  "Switch to the input buffer."
  (interactive)
  (with-current-buffer acm--source-buffer
    (switch-to-buffer-other-window acm--output-buffer)))

(defun acm-restore-window-configuration ()
  "Restore the window configuration."
  (interactive)
  (with-current-buffer acm--source-buffer
    (if (null acm--window-configuration)
      (error "Input buffers and output buffers are not associated.  Try re-enabling ACM mode?")
    (set-window-configuration acm--window-configuration))))

(defvar acm-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-c") 'acm-compile)
    (define-key map (kbd "C-c c") 'acm-compile)
    (define-key map (kbd "C-c r") 'acm-run)
    (define-key map (kbd "C-c i") 'acm-input)
    (define-key map (kbd "C-c o") 'acm-output)
    (define-key map (kbd "C-c w") 'acm-restore-window-configuration)
    map))

(define-minor-mode acm-mode
  "Minor mode to assist in competitive programming.

\\{acm-mode-map}"
  :lighter " ACM"

  (if acm-mode
      (save-excursion
	(delete-other-windows)

	;; Create window configuration.
	(let* ((name (file-name-base (buffer-file-name)))
	       (input-buffer-name (format "*ACM Input for %s*" name))
	       (output-buffer-name (format "*ACM Output for %s*" name))
	       (source-buffer (current-buffer))
	       (input-buffer (get-buffer-create input-buffer-name))
	       (output-buffer (get-buffer-create output-buffer-name))
	       (up (split-window-right)))

	  ;; Associate buffers.
	  (setq acm--input-buffer input-buffer)
	  (setq acm--output-buffer output-buffer)
	  (setq acm--source-buffer source-buffer)
	  (with-current-buffer acm--input-buffer
	    (acm-io-mode)
	    (setq acm--source-buffer source-buffer)
	    (setq acm--input-buffer input-buffer)
	    (setq acm--output-buffer output-buffer))
	  (with-current-buffer acm--output-buffer
	    (acm-io-mode)
	    (setq acm--source-buffer source-buffer)
	    (setq acm--input-buffer input-buffer)
	    (setq acm--output-buffer output-buffer))

	  ;; Initialize buffers.
	  (acm--try-fill-input)

	  ;; Switch to buffers. Associate the source buffer.
	  (with-selected-window up
	    (switch-to-buffer acm--input-buffer)
	    (let ((down (split-window-below)))
	      (with-selected-window down
		(switch-to-buffer acm--output-buffer)))))

	;; Save window configuration.
	(setq acm--window-configuration (current-window-configuration)))

    (save-excursion
      (setq acm--input-buffer nil)
      (setq acm--output-buffer nil)
      (setq acm--window-configuration nil))))

(defun acm-source ()
  "Go to source buffer."
  (interactive)
  (switch-to-buffer-other-window acm--source-buffer))

(defvar acm-io-mode-map
  (let ((map (copy-keymap acm-mode-map)))
    (define-key map (kbd "C-c s") 'acm-source)
    map))

(define-derived-mode acm-io-mode fundamental-mode
  "ACM-IO"
  "Special modes for ACM Input/Output.

\\{acm-io-mode-map}")

(provide 'acm)
;;; acm.el ends here
