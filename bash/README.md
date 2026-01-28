# mask-pii (Bash)

Version: 0.2.0

A lightweight, configurable Bash library for masking Personally Identifiable Information (PII) such as **email addresses** and **phone numbers**.

Official website: https://finitefield.org/en/oss/mask-pii  
Developed by: Finite Field, K.K.  

## Features

- **Email Masking:** Masks the local part while preserving the domain (e.g., `a****@example.com`).
- **Phone Masking:** Detects common formats and masks all digits except the last 4 while keeping separators.
- **Customizable:** Change the masking character (default is `*`).
- **Reusable Configuration:** Create named maskers for separate pipelines.

## Requirements

- Bash 3.2 or later.

## Installation (bpkg)

```bash
bpkg install finitefield-org/mask-pii/bash
```

## Usage

```bash
#!/usr/bin/env bash

source "$(bpkg prefix)/mask-pii/mask_pii.sh"

mask_pii_new masker
mask_pii_mask_emails masker
mask_pii_mask_phones masker
mask_pii_with_mask_char masker '#'

input='Contact: alice@example.com or 090-1234-5678.'
output=$(mask_pii_process masker "$input")

echo "$output"
# Contact: a####@example.com or ###-####-5678.
```

## Configuration

The Bash API uses a named masker configuration stored in shell variables.

| Function | Description | Default |
| --- | --- | --- |
| `mask_pii_new name` | Create a new masker configuration. | Disabled masks |
| `mask_pii_mask_emails name` | Enable email masking. | Disabled |
| `mask_pii_mask_phones name` | Enable phone masking. | Disabled |
| `mask_pii_with_mask_char name char` | Set the mask character (first char is used). | `*` |
| `mask_pii_process name text` | Mask the input text and print the result. | N/A |

## Masking Logic Details

### Emails

- Keeps the **first character** of the local part and the domain.
- Masks the rest of the local part.
- If the local part length is 1, it is fully masked.

### Phones

- Preserves formatting (hyphens, spaces, parentheses).
- Masks all digits except the **last 4**.
- If the total digit count is **4 or fewer**, digits are preserved as-is.
