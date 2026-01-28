# mask-pii

Version: 0.2.0

A lightweight, customizable Rust library for masking Personally Identifiable Information (PII) such as **email addresses** and **phone numbers** (supporting global formats).

It is designed to be safe, fast, and easy to integrate into logging or data processing pipelines.

🌐 Official website: [https://finitefield.org/en/oss/mask-pii](https://finitefield.org/en/oss/mask-pii)  
🏢 Developed by: [Finite Field, K.K.](https://finitefield.org)  

## Features

- 📧 **Email Masking:** Masks the local part while preserving the domain (e.g., `a****@example.com`).
- 📞 **Global Phone Masking:** Detects international phone formats and masks all digits except the last 4 (e.g., `090-****-5678`, `+1 (***) ***-1234`).
- 🛠 **Customizable:** Change the masking character (default is `*`).
- 🚀 **Zero Unnecessary Dependencies:** Pure Rust implementation.

## Installation

Add this to your `Cargo.toml`:

```toml
[dependencies]
mask-pii = "0.1.0"
```

## Usage
```rust
use mask_pii::Masker;

fn main() {
    // Configure the masker
    let masker = Masker::new()
        .mask_emails()
        .mask_phones()
        .with_mask_char('#'); // Optional: Use '#' instead of '*'

    let input = "Contact: alice@example.com or 090-1234-5678.";
    
    // Process the text
    let output = masker.process(input);

    println!("{}", output);
    // Output: "Contact: a####@example.com or 090-####-5678."
}
```

## Configuration

The `Masker` struct uses the **Builder Pattern**. You can chain methods to configure which PII types to detect and how to mask them.

By default, `Masker::new()` performs **no masking** (pass-through). You must explicitly enable the filters you need.

### Builder Methods

| Method | Description | Default |
| --- | --- | --- |
| `mask_emails()` | Enables detection and masking of email addresses. | `Disabled` |
| `mask_phones()` | Enables detection and masking of global phone numbers. | `Disabled` |
| `with_mask_char(char)` | Sets the character used for masking (e.g., `'*'`, `'#'`, `'x'`). | `'*'` |

### Masking Logic Details

Understanding how data is masked is crucial for security and usability.

* **📧 Emails**
* **Pattern:** Detects standard email formats.
* **Behavior:** Keeps the **first character** of the local part and the domain. Masks the rest of the local part.
* **Example:** `alice@example.com` -> `a****@example.com`
* **Short Emails:** If the local part is 1 character, it is fully masked (e.g., `a@b.com` -> `*@b.com`).


* **📞 Phones (Global Support)**
* **Pattern:** Detects sequences of digits that look like phone numbers (supports International `+81...`, US `(555)...`, and Hyphenated `090-...`).
* **Behavior:** Preserves formatting (hyphens, spaces, parentheses) and the **last 4 digits**. All other digits are replaced.
* **Example:**
* `090-1234-5678` -> `090-****-5678`
* `+1 (800) 123-4567` -> `+1 (***) ***-4567`
* `12345` -> `*2345` (Short numbers)
