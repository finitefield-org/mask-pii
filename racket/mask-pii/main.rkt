#lang racket

(provide
 masker?
 make-masker
 mask-emails
 mask-phones
 with-mask-char
 process)

;; Predicate and data structure for masker configuration values.
(struct masker (email-enabled phone-enabled mask-char) #:transparent)

;; Create a new masker with all masks disabled.
(define (make-masker)
  (masker #f #f #\*))

;; Enable email address masking.
(define (mask-emails m)
  (struct-copy masker m [email-enabled #t]))

;; Enable phone number masking.
(define (mask-phones m)
  (struct-copy masker m [phone-enabled #t]))

;; Set the character used for masking. A null character resets to '*'.
(define (with-mask-char c m)
  (struct-copy masker m [mask-char (normalize-mask-char c)]))

;; Process input text and mask enabled PII patterns.
(define (process m input)
  (cond
    [(and (not (masker-email-enabled m)) (not (masker-phone-enabled m))) input]
    [else
     (define mask-char (normalize-mask-char (masker-mask-char m)))
     (define after-emails
       (if (masker-email-enabled m)
           (mask-emails-in-text input mask-char)
           input))
     (if (masker-phone-enabled m)
         (mask-phones-in-text after-emails mask-char)
         after-emails)]))

(define (normalize-mask-char c)
  (if (char=? c #\nul) #\* c))

(define (mask-emails-in-text input mask-char)
  (define n (string-length input))
  (define arr (string->vector input))
  (define (finalize last acc)
    (define pieces (if (< last n) (cons (substring input last n) acc) acc))
    (apply string-append (reverse pieces)))
  (define (loop i last acc)
    (cond
      [(>= i n) (finalize last acc)]
      [(char=? (vector-ref arr i) #\@)
       (define local-start (scan-left-local arr (sub1 i)))
       (define local-end i)
       (define domain-start (add1 i))
       (define domain-end (scan-right-domain arr n domain-start))
       (if (and (< local-start local-end) (< domain-start domain-end))
           (let ([matched-end (find-valid-domain input domain-start domain-end)])
             (if matched-end
                 (let* ([local-part (substring input local-start local-end)]
                        [domain-part (substring input domain-start matched-end)]
                        [prefix (substring input last local-start)]
                        [masked (string-append prefix
                                               (mask-local local-part mask-char)
                                               "@"
                                               domain-part)])
                   (loop matched-end matched-end (cons masked acc)))
                 (loop (add1 i) last acc)))
           (loop (add1 i) last acc))]
      [else (loop (add1 i) last acc)]))
  (loop 0 0 '()))

(define (mask-phones-in-text input mask-char)
  (define n (string-length input))
  (define arr (string->vector input))
  (define (finalize last acc)
    (define pieces (if (< last n) (cons (substring input last n) acc) acc))
    (apply string-append (reverse pieces)))
  (define (loop i last acc)
    (cond
      [(>= i n) (finalize last acc)]
      [(is-phone-start (vector-ref arr i))
       (define end-index (scan-right-phone arr n i))
       (define-values (digit-count last-digit-index)
         (scan-phone-digits arr i end-index))
       (cond
         [(= last-digit-index -1) (loop end-index last acc)]
         [(>= digit-count 5)
          (define candidate-end (add1 last-digit-index))
          (define candidate (substring input i candidate-end))
          (define prefix (substring input last i))
          (define masked (string-append prefix
                                        (mask-phone-candidate candidate mask-char)))
          (loop candidate-end candidate-end (cons masked acc))]
         [else (loop end-index last acc)])]
      [else (loop (add1 i) last acc)]))
  (loop 0 0 '()))

(define (scan-left-local arr idx)
  (cond
    [(< idx 0) 0]
    [(is-local-char (vector-ref arr idx)) (scan-left-local arr (sub1 idx))]
    [else (add1 idx)]))

(define (scan-right-domain arr n idx)
  (cond
    [(>= idx n) n]
    [(is-domain-char (vector-ref arr idx)) (scan-right-domain arr n (add1 idx))]
    [else idx]))

(define (scan-right-phone arr n idx)
  (cond
    [(>= idx n) n]
    [(is-phone-char (vector-ref arr idx)) (scan-right-phone arr n (add1 idx))]
    [else idx]))

(define (scan-phone-digits arr start end)
  (let loop ([idx start] [count 0] [last-idx -1])
    (cond
      [(>= idx end) (values count last-idx)]
      [(is-digit (vector-ref arr idx))
       (loop (add1 idx) (add1 count) idx)]
      [else (loop (add1 idx) count last-idx)])))

(define (find-valid-domain input start end)
  (let loop ([candidate-end end])
    (cond
      [(<= candidate-end start) #f]
      [(is-valid-domain (substring input start candidate-end)) candidate-end]
      [else (loop (sub1 candidate-end))])))

(define (mask-local local mask-char)
  (define len (string-length local))
  (if (> len 1)
      (string-append (string (string-ref local 0))
                     (make-string (sub1 len) mask-char))
      (string mask-char)))

(define (mask-phone-candidate candidate mask-char)
  (define digit-count
    (for/sum ([c (in-string candidate)] #:when (is-digit c)) 1))
  (if (<= digit-count 4)
      candidate
      (let loop ([chars (string->list candidate)]
                 [digit-index 0]
                 [acc '()])
        (cond
          [(null? chars) (list->string (reverse acc))]
          [(is-digit (car chars))
           (define next-index (add1 digit-index))
           (define masked? (<= next-index (- digit-count 4)))
           (loop (cdr chars)
                 next-index
                 (cons (if masked? mask-char (car chars)) acc))]
          [else (loop (cdr chars) digit-index (cons (car chars) acc))]))))

(define (is-local-char c)
  (or (char<=? #\a c #\z)
      (char<=? #\A c #\Z)
      (char<=? #\0 c #\9)
      (char=? c #\.)
      (char=? c #\_)
      (char=? c #\%)
      (char=? c #\+)
      (char=? c #\-)))

(define (is-domain-char c)
  (or (char<=? #\a c #\z)
      (char<=? #\A c #\Z)
      (char<=? #\0 c #\9)
      (char=? c #\-)
      (char=? c #\.)))

(define (is-valid-domain domain)
  (define parts (split-on-char domain #\.))
  (define (valid-label? label)
    (and (not (string=? label ""))
         (not (char=? (string-ref label 0) #\-))
         (not (char=? (string-ref label (sub1 (string-length label))) #\-))
         (for/and ([c (in-string label)])
           (or (is-alpha-numeric c) (char=? c #\-)))))
  (define (valid-tld? tld)
    (and (>= (string-length tld) 2)
         (for/and ([c (in-string tld)]) (is-alpha c))))
  (cond
    [(string=? domain "") #f]
    [(char=? (string-ref domain 0) #\.) #f]
    [(char=? (string-ref domain (sub1 (string-length domain))) #\.) #f]
    [(< (length parts) 2) #f]
    [else (and (for/and ([label (in-list parts)]) (valid-label? label))
               (valid-tld? (last parts)))]))

(define (split-on-char s ch)
  (define n (string-length s))
  (let loop ([i 0] [start 0] [parts '()])
    (cond
      [(>= i n) (reverse (cons (substring s start n) parts))]
      [(char=? (string-ref s i) ch)
       (loop (add1 i) (add1 i) (cons (substring s start i) parts))]
      [else (loop (add1 i) start parts)])))

(define (is-phone-start c)
  (or (is-digit c) (char=? c #\+) (char=? c #\()))

(define (is-phone-char c)
  (or (is-digit c)
      (char=? c #\ )
      (char=? c #\-)
      (char=? c #\()
      (char=? c #\))
      (char=? c #\+)))

(define (is-digit c)
  (char<=? #\0 c #\9))

(define (is-alpha c)
  (or (char<=? #\a c #\z) (char<=? #\A c #\Z)))

(define (is-alpha-numeric c)
  (or (is-alpha c) (is-digit c)))
