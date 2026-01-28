#lang racket

(require mask-pii)

(define masker
  (with-mask-char #\#
    (mask-phones
      (mask-emails (make-masker)))))

(displayln (process masker "Contact: alice@example.com or 090-1234-5678."))
