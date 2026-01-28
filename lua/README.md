# mask-pii (Lua)

mask-pii is a lightweight, customizable library for masking Personally Identifiable Information (PII) such as email addresses and phone numbers.

- Homepage: https://finitefield.org/en/oss/mask-pii
- Repository: https://github.com/finitefield-org/mask-pii
- Issues: https://github.com/finitefield-org/mask-pii/issues
- License: MIT
- Developed by: [Finite Field, K.K.](https://finitefield.org/en/)

## Installation

```sh
luarocks install mask-pii
```

## Usage

```lua
local mask_pii = require("mask_pii")
local Masker = mask_pii.Masker

local masker = Masker.new():mask_emails():mask_phones()
local result = masker:process("Contact: alice@example.com or 090-1234-5678.")
print(result)
```

## Configuration

- `Masker.new()` creates a masker with no masks enabled.
- `mask_emails()` enables email masking.
- `mask_phones()` enables phone masking.
- `with_mask_char("#")` sets the mask character (defaults to `*`).

## Development

```sh
lua tests/test_mask_pii.lua
```
