# mask-pii (Pony)

Version: 0.2.0

A lightweight, customizable Pony library for masking Personally Identifiable Information (PII) such as **email addresses** and **phone numbers**.

It is designed to be safe, fast, and easy to integrate into logging or data processing pipelines.

Official website: https://finitefield.org/en/oss/mask-pii
Developed by: https://finitefield.org/en/

## Installation

Add this repository as a dependency and point your package path to `pony/mask_pii`.

## Usage

```pony
use "mask_pii"

actor Main
  new create(env: Env) =>
    let masker = Masker
    masker.mask_emails()
    masker.mask_phones()
    masker.with_mask_char('#')

    let input = "Contact: alice@example.com or 090-1234-5678."
    let output = masker.process(input)

    env.out.print(output)
    // Output: "Contact: a####@example.com or ###-####-5678."
```

## Configuration

The `Masker` class uses a builder-style API. You can chain methods to configure which PII types to detect and how to mask them.

By default, `Masker` performs **no masking** (pass-through). You must explicitly enable the filters you need.

### Builder Methods

| Method | Description | Default |
| --- | --- | --- |
| `mask_emails()` | Enables detection and masking of email addresses. | Disabled |
| `mask_phones()` | Enables detection and masking of phone numbers. | Disabled |
| `with_mask_char(char)` | Sets the character used for masking (e.g., `'*'`, `'#'`, `'x'`). | `'*'` |

## Masking Logic Details

- Emails: Keep the first character of the local part and preserve the domain. Short local parts are fully masked.
- Phones: Preserve separators and the last 4 digits, mask all other digits.

## License

MIT

## Metadata

Homepage: https://finitefield.org/en/oss/mask-pii
Repository: https://github.com/finitefield-org/mask-pii
Issues: https://github.com/finitefield-org/mask-pii/issues
License: MIT
Keywords: pii, masking, email, phone, privacy
