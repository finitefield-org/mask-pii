# mask-pii (Ruby)

Version: 0.2.0

A lightweight, customizable Ruby library for masking Personally Identifiable Information (PII) such as **email addresses** and **phone numbers**.

It is designed to be safe, fast, and easy to integrate into logging or data processing pipelines.

Official website: [https://finitefield.org/en/oss/mask-pii](https://finitefield.org/en/oss/mask-pii)
Developed by: [Finite Field, K.K.](https://finitefield.org)

## Features

- **Email Masking:** Masks the local part while preserving the domain (e.g., `a****@example.com`).
- **Global Phone Masking:** Detects international phone formats and masks all digits except the last 4.
- **Customizable:** Change the masking character (default is `*`).
- **Zero Unnecessary Dependencies:** Pure Ruby implementation.

## Installation

Add this to your `Gemfile`:

```ruby
gem "mask-pii", path: "../mask-pii/ruby"
```

Or install from a packaged gem:

```bash
gem install mask-pii
```

## Publishing

From the `ruby` directory:

```bash
gem build mask-pii.gemspec
gem push mask-pii-0.1.0.gem
```

## Usage

```ruby
require "mask_pii"

masker = MaskPII::Masker.new
  .mask_emails
  .mask_phones
  .with_mask_char("#")

input = "Contact: alice@example.com or 090-1234-5678."
output = masker.process(input)

puts output
# => "Contact: a####@example.com or 090-####-5678."
```

## Configuration

The `Masker` class uses a builder-style API. By default, `Masker.new` performs **no masking** (pass-through).

### Builder Methods

| Method | Description | Default |
| --- | --- | --- |
| `mask_emails` | Enables detection and masking of email addresses. | Disabled |
| `mask_phones` | Enables detection and masking of global phone numbers. | Disabled |
| `with_mask_char(char)` | Sets the character used for masking (e.g., `"*"`, `"#"`, `"x"`). | `"*"` |

### Masking Logic Details

**Emails**
- **Pattern:** Detects standard email formats.
- **Behavior:** Keeps the first character of the local part and the domain. Masks the rest of the local part.
- **Example:** `alice@example.com` -> `a****@example.com`
- **Short Emails:** If the local part is 1 character, it is fully masked (e.g., `a@b.com` -> `*@b.com`).

**Phones (Global Support)**
- **Pattern:** Detects sequences of digits that look like phone numbers (supports international `+81...`, US `(555)...`, and hyphenated `090-...`).
- **Behavior:** Preserves formatting (hyphens, spaces, parentheses) and the **last 4 digits**. All other digits are replaced.
- **Examples:**
  - `090-1234-5678` -> `090-****-5678`
  - `+1 (800) 123-4567` -> `+1 (***) ***-4567`
  - `12345` -> `*2345`
