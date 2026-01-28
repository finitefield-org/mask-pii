(defpackage :mask-pii-tests
  (:use :cl :fiveam :mask-pii))

(in-package :mask-pii-tests)

(def-suite mask-pii-tests)
(in-suite mask-pii-tests)

(defun run-mask (configure input)
  (process (funcall configure (new-masker)) input))

(deftest email-basic-cases
  (is (string= (run-mask #'mask-emails "alice@example.com") "a****@example.com"))
  (is (string= (run-mask #'mask-emails "a@b.com") "*@b.com"))
  (is (string= (run-mask #'mask-emails "ab@example.com") "a*@example.com"))
  (is (string= (run-mask #'mask-emails "a.b+c_d@example.co.jp")
               "a******@example.co.jp")))

(deftest email-mixed-text
  (is (string= (run-mask #'mask-emails "Contact: alice@example.com.")
               "Contact: a****@example.com."))
  (is (string= (run-mask #'mask-emails "alice@example.com and bob@example.org")
               "a****@example.com and b**@example.org")))

(deftest email-edge-cases
  (is (string= (run-mask #'mask-emails "alice@example") "alice@example"))
  (is (string= (run-mask #'mask-emails "alice@localhost") "alice@localhost"))
  (is (string= (run-mask #'mask-emails "alice@@example.com") "alice@@example.com"))
  (is (string= (run-mask #'mask-emails "first.last+tag@sub.domain.com")
               "f*************@sub.domain.com")))

(deftest phone-basic-cases
  (is (string= (run-mask #'mask-phones "090-1234-5678") "***-****-5678"))
  (is (string= (run-mask #'mask-phones "Call (555) 123-4567")
               "Call (***) ***-4567"))
  (is (string= (run-mask #'mask-phones "Intl: +81 3 1234 5678")
               "Intl: +** * **** 5678"))
  (is (string= (run-mask #'mask-phones "+1 (800) 123-4567")
               "+* (***) ***-4567")))

(deftest phone-short-cases
  (is (string= (run-mask #'mask-phones "1234") "1234"))
  (is (string= (run-mask #'mask-phones "12345") "*2345"))
  (is (string= (run-mask #'mask-phones "12-3456") "**-3456")))

(deftest phone-mixed-text
  (is (string= (run-mask #'mask-phones "Tel: 090-1234-5678 ext. 99")
               "Tel: ***-****-5678 ext. 99"))
  (is (string= (run-mask #'mask-phones "Numbers: 111-2222 and 333-4444")
               "Numbers: ***-2222 and ***-4444")))

(deftest phone-edge-cases
  (is (string= (run-mask #'mask-phones "abcdef") "abcdef"))
  (is (string= (run-mask #'mask-phones "+") "+"))
  (is (string= (run-mask #'mask-phones "(12) 345 678") "(**) **5 678")))

(deftest combined-masking
  (let ((masker (mask-phones (mask-emails (new-masker)))))
    (is (string= (process masker "Contact: alice@example.com or 090-1234-5678.")
                 "Contact: a****@example.com or ***-****-5678."))
    (is (string= (process masker "Email bob@example.org, phone +1 (800) 123-4567")
                 "Email b**@example.org, phone +* (***) ***-4567"))))

(deftest custom-mask-character
  (let ((masker (with-mask-char (mask-phones (mask-emails (new-masker))) #\#)))
    (is (string= (process masker "alice@example.com") "a####@example.com"))
    (is (string= (process masker "090-1234-5678") "###-####-5678"))
    (is (string= (process masker "Contact: alice@example.com or 090-1234-5678.")
                 "Contact: a####@example.com or ###-####-5678."))))

(deftest configuration-behavior
  (let ((plain (new-masker))
        (email-only (mask-emails (new-masker)))
        (phone-only (mask-phones (new-masker)))
        (both (mask-phones (mask-emails (new-masker)))))
    (is (string= (process plain "alice@example.com") "alice@example.com"))
    (is (string= (process email-only "alice@example.com") "a****@example.com"))
    (is (string= (process phone-only "090-1234-5678") "***-****-5678"))
    (is (string= (process both "alice@example.com 090-1234-5678")
                 "a****@example.com ***-****-5678"))))
