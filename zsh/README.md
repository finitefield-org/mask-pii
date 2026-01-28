# mask-pii (Zsh)

Version: 0.2.0

A lightweight, customizable Zsh library for masking Personally Identifiable Information (PII) such as **email addresses** and **phone numbers**.

It is designed to be safe, fast, and easy to integrate into shell pipelines or log processing.

Official website: https://finitefield.org/en/oss/mask-pii
Developed by: [Finite Field, K.K.](https://finitefield.org/en/)

## Features

- **Email Masking:** Masks the local part while preserving the domain (e.g., `a****@example.com`).
- **Global Phone Masking:** Detects international phone formats and masks all digits except the last 4.
- **Customizable:** Change the masking character (default is `*`).
- **Pure Zsh:** No external dependencies.

## Installation

### Antigen

Add to your `.zshrc`:

```zsh
antigen bundle finitefield-org/mask-pii@main zsh
```

### Local checkout

```zsh
source /path/to/mask-pii/zsh/mask-pii.plugin.zsh
```

## Usage

```zsh
mask_pii_new masker
mask_pii_mask_emails masker
mask_pii_mask_phones masker
mask_pii_with_mask_char masker "#"

input_text="Contact: alice@example.com or 090-1234-5678."
output=$(mask_pii_process masker "$input_text")

print -r -- "$output"
# => "Contact: a####@example.com or ###-####-5678."
```

## Configuration

The masker is represented by a named associative array. By default, masking is disabled.

### Builder Functions

| Function | Description | Default |
| --- | --- | --- |
| `mask_pii_new name` | Creates a new masker configuration. | Masking disabled |
| `mask_pii_mask_emails name` | Enables email masking. | Disabled |
| `mask_pii_mask_phones name` | Enables phone masking. | Disabled |
| `mask_pii_with_mask_char name char` | Sets the masking character. | `*` |
| `mask_pii_process name input` | Returns masked output for the input text. | N/A |

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
  - `090-1234-5678` -> `***-****-5678`
  - `+1 (800) 123-4567` -> `+* (***) ***-4567`
  - `12345` -> `*2345`

## Testing

```zsh
zsh zsh/tests/test_mask_pii.zsh
```
