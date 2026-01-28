# mask-pii

mask-pii is a lightweight, customizable library for masking Personally Identifiable Information (PII) such as email addresses and phone numbers.

The project provides consistent masking behavior across multiple language implementations, with an emphasis on safety, speed, and easy integration into logging or data processing pipelines.

- 🌐 Official website: https://finitefield.org/en/oss/mask-pii
- 🏢 Developed by: [Finite Field, K.K.](https://finitefield.org/en/)

## Language-specific implementations

- Go: see `go/README.md`
- D: see `d/README.md`
- Bash: see `bash/README.md`
- Carbon: see `carbon/README.md`
- AWK: see `awk/README.md`
- Deno: see `deno/README.md`
- Crystal: see `crystal/README.md`
- JavaScript: see `javascript/README.md`
- Elixir: see `elixir/README.md`
- Groovy: see `groovy/README.md`
- Haskell: see `haskell/README.md`
- Hare: see `hare/README.md`
- Julia: see `julia/README.md`
- OCaml: see `ocaml/README.md`
- Lua: see `lua/README.md`
- Nushell: see `nushell/README.md`
- PHP: see `php/README.md`
- PowerShell: see `powershell/README.md`
- Pony: see `pony/README.md`
- Python: see `python/README.md`
- R: see `r/README.md`
- Red: see `red/README.md`
- Rust: see `rust/README.md`
- Ruby: see `ruby/README.md`
- Swift: see `swift/README.md`
- Odin: see `odin/README.md`
- V: see `v/README.md`
- Fish: see `fish/README.md`
- Zsh: see `zsh/README.md`
- Zig: see `zig/README.md`
- Racket: see `racket/README.md`
- Common Lisp: see `common-lisp/README.md`

## Core concepts

- **Email masking:** masks the local part while preserving the domain.
- **Phone masking:** detects common international formats and masks all digits except the last 4 while keeping separators.
- **Customizable:** configurable mask character and masking targets.

## Notes

Each language implementation documents its own installation and usage details in its respective README.
