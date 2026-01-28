# mask-pii (Hare)

Version: 0.2.0

A lightweight, customizable Hare library for masking Personally Identifiable Information (PII) such as **email addresses** and **phone numbers**.

Homepage: https://finitefield.org/en/oss/mask-pii
Repository: https://github.com/finitefield-org/mask-pii
Issues: https://github.com/finitefield-org/mask-pii/issues
License: MIT
Keywords: pii, masking, email, phone, privacy

Developed by: [Finite Field, K.K.](https://finitefield.org/en/)

## Features

- Email masking: masks the local part while preserving the domain (e.g., `a****@example.com`).
- Phone masking: detects international phone formats and masks all digits except the last 4 (e.g., `090-****-5678`, `+1 (***) ***-4567`).
- Customizable: change the masking character (default is `*`).
- Pure Hare implementation.

## Installation

Until the package is published to harepm, clone this repository and add the `hare` directory to your `HAREPATH`.

```bash
git clone https://github.com/finitefield-org/mask-pii.git
export HAREPATH=$PWD/mask-pii/hare
```

## Usage

```hare
use fmt;
use maskpii;

export fn main() void = {
	let m = maskpii::new();
	maskpii::mask_emails(&m);
	maskpii::mask_phones(&m);
	maskpii::with_mask_char(&m, '#');

	let input = "Contact: alice@example.com or 090-1234-5678.";
	let output = maskpii::process(&m, input)!;
	defer free(output);

	fmt::println(output);
	// Output: "Contact: a####@example.com or ###-####-5678."
};
```

## Configuration

The `masker` type uses a builder-style API. By default, `new()` performs no masking (pass-through).

| Function | Description | Default |
| --- | --- | --- |
| `mask_emails(&masker)` | Enables detection and masking of email addresses. | Disabled |
| `mask_phones(&masker)` | Enables detection and masking of phone numbers. | Disabled |
| `with_mask_char(&masker, rune)` | Sets the character used for masking (e.g., `'*'`, `'#'`, `'x'`). | `'*'` |
| `process(&masker, str)` | Masks the input and returns a newly allocated string. | N/A |

## Memory

`process` returns a newly allocated string; the caller must free it with `free`.
