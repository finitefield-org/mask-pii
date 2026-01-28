# mask-pii (OCaml)

Version: 0.2.0

A lightweight, customizable OCaml library for masking Personally Identifiable Information (PII) such as **email addresses** and **phone numbers**.

It is designed to be safe, fast, and easy to integrate into logging or data processing pipelines.

Official website: https://finitefield.org/en/oss/mask-pii
Developed by: [Finite Field, K.K.](https://finitefield.org/en/)

## Features

- **Email Masking:** Masks the local part while preserving the domain (e.g., `a****@example.com`).
- **Global Phone Masking:** Detects international phone formats and masks all digits except the last 4.
- **Customizable:** Change the masking character (default is `*`).
- **No regex:** Scans using a predictable ASCII-only matcher.

## Installation

From opam:

```bash
opam install mask-pii
```

From a local checkout:

```bash
opam install .
```

## Usage

```ocaml
open Mask_pii

let () =
  let masker =
    new_masker
    |> mask_emails
    |> mask_phones
    |> with_mask_char '#'
  in
  let result = process masker "Contact: alice@example.com or 090-1234-5678." in
  print_endline result
  (* => "Contact: a####@example.com or ###-####-5678." *)
```

## Configuration

The `masker` value uses a builder-style API. By default, `new_masker` performs **no masking** (pass-through).

### Builder Functions

| Function | Description | Default |
| --- | --- | --- |
| `mask_emails` | Enables detection and masking of email addresses. | Disabled |
| `mask_phones` | Enables detection and masking of phone numbers. | Disabled |
| `with_mask_char` | Sets the character used for masking (e.g., `'*'`, `'#'`, `'x'`). | `'*'` |

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
