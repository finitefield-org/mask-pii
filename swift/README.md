# mask-pii (Swift)

Version: 0.2.0

A lightweight, customizable Swift library for masking Personally Identifiable Information (PII) such as **email addresses** and **phone numbers**.

🌐 Official website: https://finitefield.org/en/oss/mask-pii  
🏢 Developed by: [Finite Field, K.K.](https://finitefield.org/en/)  

## Features

- 📧 **Email Masking:** Masks the local part while preserving the domain (e.g., `a****@example.com`).
- 📞 **Global Phone Masking:** Detects international phone formats and masks all digits except the last 4 (e.g., `090-****-5678`, `+1 (***) ***-4567`).
- 🛠 **Customizable:** Change the masking character (default is `*`).
- 🚀 **Zero Unnecessary Dependencies:** Pure Swift implementation.

## Installation (SwiftPM)

Add this package to your `Package.swift` dependencies:

```swift
.package(url: "https://github.com/finitefield-org/mask-pii", from: "0.2.0")
```

Then add `MaskPII` to your target dependencies.

## Usage

```swift
import MaskPII

let masker = Masker()
    .maskEmails()
    .maskPhones()
    .withMaskChar("#")

let input = "Contact: alice@example.com or 090-1234-5678."
let output = masker.process(input)

print(output)
// Output: "Contact: a####@example.com or ###-####-5678."
```

## Configuration

The `Masker` class uses a builder-style API. By default, `Masker()` performs **no masking** (pass-through). Enable the filters you need.

| Method | Description | Default |
| --- | --- | --- |
| `maskEmails()` | Enables detection and masking of email addresses. | Disabled |
| `maskPhones()` | Enables detection and masking of phone numbers. | Disabled |
| `withMaskChar(Character)` | Sets the character used for masking (e.g., `'*'`, `'#'`, `'x'`). | `'*'` |

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

- Homepage: https://finitefield.org/en/oss/mask-pii
- Repository: https://github.com/finitefield-org/mask-pii
- Issues: https://github.com/finitefield-org/mask-pii/issues
- License: MIT
- Keywords: pii, masking, email, phone, privacy
