# mask-pii (Red)

Version: 0.2.0

A lightweight, customizable Red library for masking Personally Identifiable Information (PII) such as **email addresses** and **phone numbers**.

🌐 Official website: https://finitefield.org/en/oss/mask-pii  
🏢 Developed by: Finite Field, K.K.  

## Features

- 📧 **Email Masking:** Masks the local part while preserving the domain (e.g., `a****@example.com`).
- 📞 **Global Phone Masking:** Detects international phone formats and masks all digits except the last 4.
- 🛠 **Customizable:** Change the masking character (default is `*`).
- 🚀 **Zero Dependencies:** Pure Red implementation.

## Installation

Red uses a file-based package system. Add `red/mask-pii.red` to your project and load it with `do`.

## Usage

```red
Red [
    Title: "mask-pii example"
]

do %mask-pii.red

masker: make-masker
masker/mask-emails
masker/mask-phones
masker/with-mask-char #"#"

input: "Contact: alice@example.com or 090-1234-5678."
output: masker/process input

print output
; Output: Contact: a####@example.com or ###-####-5678.
```

## Configuration

The `Masker` uses a builder-style API. By default, `make-masker` performs **no masking** (pass-through). Enable the filters you need.

| Method | Description | Default |
| --- | --- | --- |
| `mask-emails` | Enables detection and masking of email addresses. | Disabled |
| `mask-phones` | Enables detection and masking of phone numbers. | Disabled |
| `with-mask-char` | Sets the character used for masking (e.g., `'*'`, `'#'`, `'x'`). | `'*'` |
| `process` | Runs the masking pipeline over input text. | N/A |

## Masking Logic Details

### Emails

- Keeps the **first character** of the local part and the domain.
- Masks the rest of the local part.
- If the local part length is 1, it is fully masked.

### Phones

- Preserves formatting (hyphens, spaces, parentheses).
- Masks all digits except the **last 4**.
- If the total digit count is **4 or fewer**, digits are preserved as-is.
