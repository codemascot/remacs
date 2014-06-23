;;; tildify-test.el --- ERT tests for teldify.el

;; Copyright (C) 2014 Free Software Foundation, Inc.

;; Author:     Michal Nazarewicz <mina86@mina86.com>
;; Version:    4.5
;; Keywords:   text, TeX, SGML, wp

;; This file is part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package defines regression tests for the tildify package.

;;; Code:

(require 'ert)
(require 'tildify)

(defun tildify-test--example-sentence (space)
  "Return an example sentence with SPACE where hard space is required."
  (concat "Lorem ipsum v" space "dolor sit amet, a" space
          "consectetur adipiscing elit."))


(defun tildify-test--example-html (sentence &optional with-nbsp is-xml)
  "Return an example HTML code.
SENTENCE is placed where spaces should not be replaced with hard spaces, and
WITH-NBSP is placed where spaces should be replaced with hard spaces.  If the
latter is missing, SENTENCE will be used in all placeholder positions.
If IS-XML is non-nil, <pre> tag is not treated specially."
  (let ((with-nbsp (or with-nbsp sentence)))
    (concat "<p>" with-nbsp "</p>\n"
            "<pre>" (if is-xml with-nbsp sentence) "</pre>\n"
            "<! -- " sentence " -- >\n"
            "<p>" with-nbsp "</p>\n"
            "<" sentence ">\n")))


(defun tildify-test--test (modes input expected)
  "Test tildify running in MODES.
INPUT is the initial content of the buffer and EXPECTED is expected result
after `tildify-buffer' is run."
  (with-temp-buffer
    (dolist (mode modes)
      (erase-buffer)
      (funcall mode)
      (let ((header (concat "Testing `tildify-buffer' in "
                            (symbol-name mode) "\n")))
        (insert header input)
        (tildify-buffer t)
        (should (string-equal (concat header expected) (buffer-string))))
      (erase-buffer)
      (let ((header (concat "Testing `tildify-region' in "
                            (symbol-name mode) "\n")))
        (insert header input)
        (tildify-region (point-min) (point-max) t)
        (should (string-equal (concat header expected) (buffer-string)))))))

(ert-deftest tildify-test-html ()
  "Tests tildification in an HTML document"
  (let* ((sentence (tildify-test--example-sentence " "))
         (with-nbsp (tildify-test--example-sentence "&nbsp;")))
    (tildify-test--test '(html-mode sgml-mode)
                        (tildify-test--example-html sentence sentence)
                        (tildify-test--example-html sentence with-nbsp))))

(ert-deftest tildify-test-xml ()
  "Tests tildification in an XML document"
  (let* ((sentence (tildify-test--example-sentence " "))
         (with-nbsp (tildify-test--example-sentence "&#160;")))
    (tildify-test--test '(nxml-mode)
                        (tildify-test--example-html sentence sentence t)
                        (tildify-test--example-html sentence with-nbsp t))))


(defun tildify-test--example-tex (sentence &optional with-nbsp)
  "Return an example (La)Tex code.
SENTENCE is placed where spaces should not be replaced with hard spaces, and
WITH-NBSP is placed where spaces should be replaced with hard spaces.  If the
latter is missing, SENTENCE will be used in all placeholder positions."
  (let ((with-nbsp (or with-nbsp sentence)))
    (concat with-nbsp "\n"
            "\\begin{verbatim}\n" sentence "\n\\end{verbatim}\n"
            "\\verb#" sentence "#\n"
            "$$" sentence "$$\n"
            "$" sentence "$\n"
            "\\[" sentence "\\]\n"
            "\\v A % " sentence "\n"
            with-nbsp "\n")))

(ert-deftest tildify-test-tex ()
  "Tests tildification in a (La)TeX document"
  (let* ((sentence (tildify-test--example-sentence " "))
         (with-nbsp (tildify-test--example-sentence "~")))
    (tildify-test--test '(tex-mode latex-mode plain-tex-mode)
                        (tildify-test--example-tex sentence sentence)
                        (tildify-test--example-tex sentence with-nbsp))))


(ert-deftest tildify-test-find-env-end-re-bug ()
    "Tests generation of end-regex using mix of indexes and strings"
  (with-temp-buffer
    (insert "foo whatever end-foo")
    (goto-char (point-min))
    (should (string-equal "end-foo"
                          (tildify-find-env "foo\\|bar"
                                            '(("foo\\|bar" . ("end-" 0))))))))


(ert-deftest tildify-test-find-env-group-index-bug ()
    "Tests generation of match-string indexes"
  (with-temp-buffer
    (let ((pairs '(("start-\\(foo\\|bar\\)" . ("end-" 1))
                   ("open-\\(foo\\|bar\\)" . ("close-" 1))))
          (beg-re "start-\\(foo\\|bar\\)\\|open-\\(foo\\|bar\\)"))
      (insert "open-foo whatever close-foo")
      (goto-char (point-min))
      (should (string-equal "close-foo" (tildify-find-env beg-re pairs))))))


(provide 'tildify-tests)

;;; tildify-tests.el ends here
