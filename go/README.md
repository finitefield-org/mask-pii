# mask-pii (Go)

Version: 0.2.0

A lightweight, customizable Go library for masking Personally Identifiable Information (PII) such as **email addresses** and **phone numbers**.

🌐 Official website: https://finitefield.org/en/oss/mask-pii  
🏢 Developed by: Finite Field, K.K.  

## Features

- 📧 **Email Masking:** Masks the local part while preserving the domain (e.g., `a****@example.com`).
- 📞 **Global Phone Masking:** Detects international phone formats and masks all digits except the last 4 (e.g., `090-****-5678`, `+1 (***) ***-4567`).
- 🛠 **Customizable:** Change the masking character (default is `*`).
- 🚀 **Zero Unnecessary Dependencies:** Pure Go implementation.

## Installation

```bash
go get github.com/finitefield-org/mask-pii/go@v0.2.0
```

## Usage

```go
package main

import (
	"fmt"

	"github.com/finitefield-org/mask-pii/go"
)

func main() {
	masker := maskpii.New()
		.MaskEmails()
		.MaskPhones()
		.WithMaskChar('#')

	input := "Contact: alice@example.com or 090-1234-5678."
	output := masker.Process(input)

	fmt.Println(output)
	// Output: "Contact: a####@example.com or ###-####-5678."
}
```

## Configuration

The `Masker` type uses a builder-style API. By default, `New()` performs **no masking** (pass-through). Enable the filters you need.

| Method | Description | Default |
| --- | --- | --- |
| `MaskEmails()` | Enables detection and masking of email addresses. | Disabled |
| `MaskPhones()` | Enables detection and masking of phone numbers. | Disabled |
| `WithMaskChar(rune)` | Sets the character used for masking (e.g., `'*'`, `'#'`, `'x'`). | `'*'` |

## Masking Logic Details

### Emails

- Keeps the **first character** of the local part and the domain.
- Masks the rest of the local part.
- If the local part length is 1, it is fully masked.

### Phones

- Preserves formatting (hyphens, spaces, parentheses).
- Masks all digits except the **last 4**.
- If the total digit count is **4 or fewer**, digits are preserved as-is.
