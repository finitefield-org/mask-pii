# mask-pii (Tcl)

Version: 0.2.0

A lightweight Tcl package for masking Personally Identifiable Information (PII) such as **email addresses** and **phone numbers**.

Official website: https://finitefield.org/en/oss/mask-pii
Developed by: [Finite Field, K.K.](https://finitefield.org/en/)

## Features

- **Email Masking:** Keeps the first character of the local part and preserves the domain.
- **Phone Masking:** Preserves formatting and the last 4 digits.
- **Customizable:** Choose a custom mask character (default `*`).
- **No Regex Dependency:** Scans text deterministically for consistent cross-language behavior.

## Installation

Add the `tcl` directory to your `auto_path`, or install with a Tcl package manager that supports `pkgIndex.tcl`.

```tcl
lappend auto_path /path/to/mask-pii/tcl
package require mask_pii 0.2.0
```

## Usage

```tcl
package require mask_pii 0.2.0

set masker [::mask_pii::Masker new]
$masker mask_emails
$masker mask_phones
$masker with_mask_char "#"

set input "Contact: alice@example.com or 090-1234-5678."
set output [$masker process $input]
puts $output

$masker destroy
```

## API

- `::mask_pii::Masker new` creates a new masker.
- `mask_emails` enables email masking.
- `mask_phones` enables phone masking.
- `with_mask_char CHAR` sets the mask character (uses the first character of the string).
- `process INPUT` returns the masked string.

## Testing

From the repository root:

```bash
tclsh tcl/tests/mask_pii.test
```

## License

MIT
