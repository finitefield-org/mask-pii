# mask-pii (Perl)

Version: 0.2.0

A lightweight, configurable Perl library for masking Personally Identifiable Information (PII) such as **email addresses** and **phone numbers**.

Official website: https://finitefield.org/en/oss/mask-pii
Developed by: [Finite Field, K.K.](https://finitefield.org/en/)

## Features

- **Email masking:** Keeps the first local-part character and preserves the domain.
- **Phone masking:** Preserves formatting and the last 4 digits.
- **Customizable:** Choose your masking character (default: `*`).
- **No regex dependency:** Deterministic byte-level scanning.

## Installation

From a local checkout:

```bash
cd perl
perl Makefile.PL
make
make test
make install
```

From CPAN (once published):

```bash
cpanm Mask::PII
```

## Usage

```perl
use Mask::PII;

my $masker = Mask::PII::Masker->new
    ->mask_emails
    ->mask_phones
    ->with_mask_char('#');

my $input = 'Contact: alice@example.com or 090-1234-5678.';
my $output = $masker->process($input);

print "$output\n";
# Contact: a####@example.com or ###-####-5678.
```

## Configuration

The `Mask::PII::Masker` class uses a builder-style API. By default, `new` performs no masking.

| Method | Description | Default |
| --- | --- | --- |
| `mask_emails` | Enables email masking. | Disabled |
| `mask_phones` | Enables phone masking. | Disabled |
| `with_mask_char($char)` | Sets the masking character. | `*` |

## Testing

```bash
cd perl
prove -l t
```

## License

MIT
