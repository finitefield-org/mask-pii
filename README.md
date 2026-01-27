# mask-pii

A lightweight, customizable Rust library for masking Personally Identifiable Information (PII) such as **email addresses** and **phone numbers** (supporting global formats).

It is designed to be safe, fast, and easy to integrate into logging or data processing pipelines.

## Features

- 📧 **Email Masking:** Masks the local part while preserving the domain (e.g., `a****@example.com`).
- 📞 **Global Phone Masking:** Detects international phone formats and masks all digits except the last 4 (e.g., `090-****-5678`, `+1 (***) ***-1234`).
- 🛠 **Customizable:** Change the masking character (default is `*`).
- 🚀 **Zero Unnecessary Dependencies:** Only depends on `regex`.

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

## Developer
This library is developed by [Finite Field, K.K.](https://finitefield.org).
