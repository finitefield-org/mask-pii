(asdf:defsystem "mask-pii"
  :description "Mask email addresses and phone numbers in text."
  :author "Finite Field, K.K."
  :license "MIT"
  :version "0.2.0"
  :homepage "https://finitefield.org/en/oss/mask-pii"
  :bug-tracker "https://github.com/finitefield-org/mask-pii/issues"
  :source-control (:git "https://github.com/finitefield-org/mask-pii")
  :components ((:module "src"
                :components ((:file "mask-pii"))))
  :in-order-to ((test-op (test-op "mask-pii/tests"))))

(asdf:defsystem "mask-pii/tests"
  :description "Tests for mask-pii."
  :author "Finite Field, K.K."
  :license "MIT"
  :version "0.2.0"
  :depends-on ("mask-pii" "fiveam")
  :components ((:module "tests"
                :components ((:file "mask-pii-tests"))))
  :perform (test-op (op c)
             (symbol-call :fiveam :run! 'mask-pii-tests)))
