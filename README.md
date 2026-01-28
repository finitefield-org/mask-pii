# mask-pii

mask-pii is a lightweight, customizable library for masking Personally Identifiable Information (PII) such as email addresses and phone numbers.

The project provides consistent masking behavior across multiple language implementations, with an emphasis on safety, speed, and easy integration into logging or data processing pipelines.

- 🌐 Official website: https://finitefield.org/en/oss/mask-pii
- 🏢 Developed by [Finite Field, K.K.](https://finitefield.org/en/)

## Language-specific implementations

- Go: see `go/README.md`
- Elixir: see `elixir/README.md`
- Julia: see `julia/README.md`
- PHP: see `php/README.md`
- Python: see `python/README.md`
- Rust: see `rust/README.md`
- Ruby: see `ruby/README.md`
- Swift: see `swift/README.md`

## Core concepts

- **Email masking:** masks the local part while preserving the domain.
- **Phone masking:** detects common international formats and masks all digits except the last 4 while keeping separators.
- **Customizable:** configurable mask character and masking targets.

## Notes

Each language implementation documents its own installation and usage details in its respective README.
