# mask-pii (AWK)

mask-pii is a lightweight, customizable library for masking PII such as email addresses and phone numbers.

## Requirements

- POSIX awk (tested with `awk` on macOS and `gawk`)

## Usage

Load the library with `-f` and call the public API functions.

```sh
awk -f awk/src/mask_pii.awk -f your_script.awk
```

Example script:

```awk
BEGIN {
  mask_pii_new(masker)
  mask_pii_mask_emails(masker)
  mask_pii_mask_phones(masker)
  mask_pii_with_mask_char(masker, "#")
  print mask_pii_process(masker, "Contact: alice@example.com or 090-1234-5678.")
}
```

Output:

```
Contact: a####@example.com or ###-####-5678.
```

## Public API

- `mask_pii_new(masker)`
- `mask_pii_mask_emails(masker)`
- `mask_pii_mask_phones(masker)`
- `mask_pii_with_mask_char(masker, char)`
- `mask_pii_process(masker, input_text)`
- `mask_pii_version()`

## Tests

```sh
awk -f awk/src/mask_pii.awk -f awk/tests/test_mask_pii.awk
```

## Package metadata

- homepage: `https://finitefield.org/en/oss/mask-pii`
- repository: `https://github.com/finitefield-org/mask-pii`
- issues: `https://github.com/finitefield-org/mask-pii/issues`
- license: `MIT`
- keywords: `pii`, `masking`, `email`, `phone`, `privacy`
