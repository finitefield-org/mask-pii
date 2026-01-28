# mask-pii (Crystal)

Version: 0.2.0

A lightweight, customizable Crystal library for masking Personally Identifiable Information (PII) such as **email addresses** and **phone numbers**.

Official website: https://finitefield.org/en/oss/mask-pii  
Developed by: Finite Field, K.K.  

## Features

- **Email Masking:** Masks the local part while preserving the domain (e.g., `a****@example.com`).
- **Global Phone Masking:** Detects international phone formats and masks all digits except the last 4 (e.g., `090-****-5678`, `+1 (***) ***-4567`).
- **Customizable:** Change the masking character (default is `*`).
- **Zero Unnecessary Dependencies:** Pure Crystal implementation.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  mask_pii:
    github: finitefield-org/mask-pii
    version: "~> 0.2.0"
    subdir: crystal
```

Then run:

```bash
shards install
```

## Usage

```crystal
require "mask_pii"

masker = MaskPII::Masker.new
  .mask_emails
  .mask_phones
  .with_mask_char('#')

input = "Contact: alice@example.com or 090-1234-5678."
output = masker.process(input)

puts output
# Output: "Contact: a####@example.com or ###-####-5678."
```

## Configuration

The `Masker` type uses a builder-style API. By default, `Masker.new` performs **no masking** (pass-through). Enable the filters you need.

| Method | Description | Default |
| --- | --- | --- |
| `mask_emails` | Enables detection and masking of email addresses. | Disabled |
| `mask_phones` | Enables detection and masking of phone numbers. | Disabled |
| `with_mask_char(Char | String | Nil)` | Sets the character used for masking (e.g., `'*'`, `'#'`, `'x'`). | `'*'` |

## Masking Logic Details

### Emails

- Keeps the **first character** of the local part and the domain.
- Masks the rest of the local part.
- If the local part length is 1, it is fully masked.

### Phones

- Preserves formatting (hyphens, spaces, parentheses).
- Masks all digits except the **last 4**.
- If the total digit count is **4 or fewer**, digits are preserved as-is.

## Links

- Repository: https://github.com/finitefield-org/mask-pii
- Issues: https://github.com/finitefield-org/mask-pii/issues

## Keywords

pii, masking, email, phone, privacy
