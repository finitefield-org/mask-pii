# mask-pii (Racket)

mask-pii is a lightweight library for masking PII such as email addresses and phone numbers.

- Developed by: [Finite Field, K.K.](https://finitefield.org/en/)
- Homepage: https://finitefield.org/en/oss/mask-pii
- Repository: https://github.com/finitefield-org/mask-pii
- Issues: https://github.com/finitefield-org/mask-pii/issues
- License: MIT

## Installation

```bash
raco pkg install mask-pii
```

## Usage

```racket
#lang racket

(require mask-pii)

(define masker
  (with-mask-char #\#
    (mask-phones
      (mask-emails (make-masker)))))

(displayln
  (process masker "Contact: alice@example.com or 090-1234-5678."))
```

## API

- `make-masker` creates a new masker with all masks disabled.
- `mask-emails` enables email masking.
- `mask-phones` enables phone masking.
- `with-mask-char` sets the mask character.
- `process` masks enabled PII patterns in the input string.
