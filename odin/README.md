# mask-pii (Odin)

Version: 0.2.0

A lightweight, customizable Odin package for masking Personally Identifiable Information (PII) such as **email addresses** and **phone numbers**.

🌐 Official website: https://finitefield.org/en/oss/mask-pii  
🏢 Developed by: [Finite Field, K.K.](https://finitefield.org/en/)  

## Features

- 📧 **Email Masking:** Masks the local part while preserving the domain (e.g., `a****@example.com`).
- 📞 **Global Phone Masking:** Detects international phone formats and masks all digits except the last 4 (e.g., `090-****-5678`, `+1 (***) ***-4567`).
- 🛠 **Customizable:** Change the masking character (default is `*`).
- 🚀 **No External Dependencies:** Pure Odin implementation.

## Installation

Clone the repository and add the Odin package collection path:

```bash
git clone https://github.com/finitefield-org/mask-pii.git
```

Then reference the package by collection alias when building or running:

```bash
odin test odin/mask_pii -collection:mask_pii=./odin/mask_pii
odin run example/odin -collection:mask_pii=./odin/mask_pii
```

## Usage

```odin
package main

import (
    "core:fmt"
    "mask_pii"
)

main :: proc() {
    masker := mask_pii.new()
    masker = mask_pii.mask_emails(masker)
    masker = mask_pii.mask_phones(masker)
    masker = mask_pii.with_mask_char(masker, '#')

    input := "Contact: alice@example.com or 090-1234-5678."
    output := mask_pii.process(masker, input)

    fmt.println(output)
    // Output: "Contact: a####@example.com or ###-####-5678."
}
```

## Configuration

The `Masker` type uses a builder-style API. By default, `new()` performs **no masking** (pass-through). Enable the filters you need.

| Function | Description | Default |
| --- | --- | --- |
| `new()` | Creates a new masker with all masks disabled. | N/A |
| `mask_emails(masker)` | Enables detection and masking of email addresses. | Disabled |
| `mask_phones(masker)` | Enables detection and masking of phone numbers. | Disabled |
| `with_mask_char(masker, char)` | Sets the character used for masking (e.g., `'*'`, `'#'`, `'x'`). | `'*'` |
| `process(masker, input)` | Masks enabled PII patterns in the input string. | N/A |

## Masking Logic Details

### Emails

- Keeps the **first character** of the local part and the domain.
- Masks the rest of the local part.
- If the local part length is 1, it is fully masked.

### Phones

- Preserves formatting (hyphens, spaces, parentheses).
- Masks all digits except the **last 4**.
- If the total digit count is **4 or fewer**, digits are preserved as-is.

## Package Metadata

- homepage: https://finitefield.org/en/oss/mask-pii
- repository: https://github.com/finitefield-org/mask-pii
- Issues: https://github.com/finitefield-org/mask-pii/issues
- license: MIT
- keywords: pii, masking, email, phone, privacy
