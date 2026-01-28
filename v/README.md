# mask-pii (V)

Version: 0.2.0

A lightweight, customizable V library for masking Personally Identifiable Information (PII) such as email addresses and phone numbers.

- Official website: https://finitefield.org/en/oss/mask-pii
- Developed by: [Finite Field, K.K.](https://finitefield.org/en/)

## Metadata

- homepage: https://finitefield.org/en/oss/mask-pii
- repository: https://github.com/finitefield-org/mask-pii
- Issues: https://github.com/finitefield-org/mask-pii/issues
- license: MIT
- keywords: pii, masking, email, phone, privacy

## Features

- Email masking: Masks the local part while preserving the domain (e.g., a****@example.com).
- Phone masking: Detects common international formats and masks all digits except the last 4.
- Customizable: Change the masking character (default is *).
- Zero dependencies: Pure V implementation.

## Installation

```bash
v install mask_pii
```

## Usage

```v
module main

import mask_pii

fn main() {
	masker := mask_pii.new()
		.mask_emails()
		.mask_phones()
		.with_mask_char(`#`)

	input := 'Contact: alice@example.com or 090-1234-5678.'
	output := masker.process(input)

	println(output)
	// Output: Contact: a####@example.com or ###-####-5678.
}
```

## Configuration

The `Masker` type uses a builder-style API. By default, `new()` performs no masking (pass-through). Enable the filters you need.

| Method | Description | Default |
| --- | --- | --- |
| `mask_emails()` | Enables detection and masking of email addresses. | Disabled |
| `mask_phones()` | Enables detection and masking of phone numbers. | Disabled |
| `with_mask_char(byte)` | Sets the character used for masking. | `*` |

## Masking Logic Details

### Emails

- Keeps the first character of the local part and the domain.
- Masks the rest of the local part.
- If the local part length is 1, it is fully masked.

### Phones

- Preserves formatting (hyphens, spaces, parentheses).
- Masks all digits except the last 4.
- If the total digit count is 4 or fewer, digits are preserved as-is.
