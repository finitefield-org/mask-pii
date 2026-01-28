# mask-pii (Zig)

Version: 0.2.0

A lightweight, customizable Zig library for masking Personally Identifiable Information (PII) such as **email addresses** and **phone numbers**.

🌐 Official website: https://finitefield.org/en/oss/mask-pii  
🏢 Developed by: Finite Field, K.K.  

## Features

- 📧 **Email Masking:** Masks the local part while preserving the domain (e.g., `a****@example.com`).
- 📞 **Global Phone Masking:** Detects international phone formats and masks all digits except the last 4 (e.g., `090-****-5678`, `+1 (***) ***-4567`).
- 🛠 **Customizable:** Change the masking character (default is `*`).
- 🚀 **Zero Unnecessary Dependencies:** Pure Zig implementation.

## Installation

```bash
zig fetch --save https://github.com/finitefield-org/mask-pii/archive/refs/tags/zig/v0.2.0.tar.gz
```

## Usage

```zig
const std = @import("std");
const MaskPII = @import("mask-pii");

pub fn main() !void {
    var masker = MaskPII.Masker.init();
    _ = masker.maskEmails().maskPhones().withMaskChar('#');

    const allocator = std.heap.page_allocator;
    const input = "Contact: alice@example.com or 090-1234-5678.";
    const output = try masker.process(allocator, input);
    defer allocator.free(output);

    try std.io.getStdOut().writer().print("{s}\n", .{output});
    // Output: "Contact: a####@example.com or ###-####-5678."
}
```

## Configuration

The `Masker` type uses a builder-style API. By default, `init()` performs **no masking** (pass-through). Enable the filters you need.

| Method | Description | Default |
| --- | --- | --- |
| `maskEmails()` | Enables detection and masking of email addresses. | Disabled |
| `maskPhones()` | Enables detection and masking of phone numbers. | Disabled |
| `withMaskChar(u8)` | Sets the character used for masking (e.g., `'*'`, `'#'`, `'x'`). | `'*'` |

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
