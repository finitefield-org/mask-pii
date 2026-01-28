#lang racket

(require rackunit
         mask-pii)

(define (run input masker)
  (process masker input))

(define mask-default
  (mask-phones (mask-emails (make-masker))))

(define mask-default-emails
  (mask-emails (make-masker)))

(define mask-default-phones
  (mask-phones (make-masker)))

(define mask-hash
  (with-mask-char #\# (mask-phones (mask-emails (make-masker)))))

(module+ test
  (test-case "email basic cases"
    (check-equal? (run "alice@example.com" mask-default-emails)
                  "a****@example.com")
    (check-equal? (run "a@b.com" mask-default-emails)
                  "*@b.com")
    (check-equal? (run "ab@example.com" mask-default-emails)
                  "a*@example.com")
    (check-equal? (run "a.b+c_d@example.co.jp" mask-default-emails)
                  "a******@example.co.jp"))

  (test-case "email mixed text"
    (check-equal? (run "Contact: alice@example.com." mask-default-emails)
                  "Contact: a****@example.com.")
    (check-equal? (run "alice@example.com and bob@example.org" mask-default-emails)
                  "a****@example.com and b**@example.org"))

  (test-case "email edge cases"
    (check-equal? (run "alice@example" mask-default-emails)
                  "alice@example")
    (check-equal? (run "alice@localhost" mask-default-emails)
                  "alice@localhost")
    (check-equal? (run "alice@@example.com" mask-default-emails)
                  "alice@@example.com")
    (check-equal? (run "first.last+tag@sub.domain.com" mask-default-emails)
                  "f*************@sub.domain.com"))

  (test-case "phone basic cases"
    (check-equal? (run "090-1234-5678" mask-default-phones)
                  "***-****-5678")
    (check-equal? (run "Call (555) 123-4567" mask-default-phones)
                  "Call (***) ***-4567")
    (check-equal? (run "Intl: +81 3 1234 5678" mask-default-phones)
                  "Intl: +** * **** 5678")
    (check-equal? (run "+1 (800) 123-4567" mask-default-phones)
                  "+* (***) ***-4567"))

  (test-case "phone short numbers"
    (check-equal? (run "1234" mask-default-phones)
                  "1234")
    (check-equal? (run "12345" mask-default-phones)
                  "*2345")
    (check-equal? (run "12-3456" mask-default-phones)
                  "**-3456"))

  (test-case "phone mixed text"
    (check-equal? (run "Tel: 090-1234-5678 ext. 99" mask-default-phones)
                  "Tel: ***-****-5678 ext. 99")
    (check-equal? (run "Numbers: 111-2222 and 333-4444" mask-default-phones)
                  "Numbers: ***-2222 and ***-4444"))

  (test-case "phone edge cases"
    (check-equal? (run "abcdef" mask-default-phones)
                  "abcdef")
    (check-equal? (run "+" mask-default-phones)
                  "+")
    (check-equal? (run "(12) 345 678" mask-default-phones)
                  "(**) **5 678"))

  (test-case "combined masking"
    (check-equal? (run "Contact: alice@example.com or 090-1234-5678."
                       mask-default)
                  "Contact: a****@example.com or ***-****-5678.")
    (check-equal? (run "Email bob@example.org, phone +1 (800) 123-4567"
                       mask-default)
                  "Email b**@example.org, phone +* (***) ***-4567"))

  (test-case "custom mask character"
    (check-equal? (run "alice@example.com" mask-hash)
                  "a####@example.com")
    (check-equal? (run "090-1234-5678" (with-mask-char #\# mask-default-phones))
                  "###-####-5678")
    (check-equal? (run "Contact: alice@example.com or 090-1234-5678."
                       mask-hash)
                  "Contact: a####@example.com or ###-####-5678."))

  (test-case "masker configuration behavior"
    (check-equal? (run "alice@example.com" (make-masker))
                  "alice@example.com")
    (check-equal? (run "alice@example.com" mask-default-emails)
                  "a****@example.com")
    (check-equal? (run "090-1234-5678" mask-default-phones)
                  "***-****-5678")
    (check-equal? (run "alice@example.com 090-1234-5678" mask-default)
                  "a****@example.com ***-****-5678"))

  (test-case "stability checks"
    (check-equal? (run "メール: alice@example.com" mask-default)
                  "メール: a****@example.com")
    (check-equal? (run "alice@example.com alice@example.com" mask-default-emails)
                  "a****@example.com a****@example.com")))
