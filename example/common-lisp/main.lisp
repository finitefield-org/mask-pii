(ql:quickload :mask-pii)

(defparameter *masker*
  (with-mask-char
   (mask-phones
    (mask-emails (new-masker)))
   #\#))

(format t "~A~%"
        (process *masker* "Contact: alice@example.com or 090-1234-5678."))
