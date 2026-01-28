# mask-pii (Fish)

mask-pii is a lightweight, customizable library for masking Personally Identifiable Information (PII) such as email addresses and phone numbers.

- Version: 0.2.0
- Homepage: https://finitefield.org/en/oss/mask-pii
- Repository: https://github.com/finitefield-org/mask-pii
- Issues: https://github.com/finitefield-org/mask-pii/issues
- License: MIT
- Keywords: pii, masking, email, phone, privacy

## Installation (Fisher)

```fish
fisher install finitefield-org/mask-pii
```

## Usage

```fish
mask_pii --emails --phones --mask-char '#' "Contact: alice@example.com or 090-1234-5678."
```

Using stdin:

```fish
echo "Call (555) 123-4567" | mask_pii --phones
```

## API

- `mask_pii [--emails] [--phones] [--mask-char CHAR] [TEXT]`
- `mask_pii_version`

## Notes

- Pass `TEXT` as a single argument (quote it if it contains spaces), or pipe input via stdin.
- If no masking targets are enabled, the input is returned unchanged.
