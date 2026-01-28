# mask-pii (Nushell)

mask-pii is a lightweight, customizable library for masking Personally Identifiable Information (PII) such as email addresses and phone numbers.

- Homepage: https://finitefield.org/en/oss/mask-pii
- Repository: https://github.com/finitefield-org/mask-pii
- Issues: https://github.com/finitefield-org/mask-pii/issues
- License: MIT
- Developed by: [Finite Field, K.K.](https://finitefield.org/en/)

## Installation

Copy `nushell/src/mask_pii.nu` into your Nushell module path, or load it directly from a checkout.

## Usage

```nu
use mask_pii.nu *

let masker = (masker new | mask_emails | mask_phones)
let result = ($masker | process "Contact: alice@example.com or 090-1234-5678.")
$result
```

## Configuration

- `masker new` creates a masker with no masks enabled.
- `mask_emails` enables email masking.
- `mask_phones` enables phone masking.
- `with_mask_char "#"` sets the mask character (defaults to `*`).

## Development

```sh
nu nushell/tests/test_mask_pii.nu
```
