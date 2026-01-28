# mask-pii Cross-language Test Cases

This file defines a detailed, language-agnostic test matrix to keep behavior consistent across all implementations.

## General Notes

- **Email masking rule:** keep the first character of the local part, mask the rest with the mask character, preserve the domain.
- **Short email local part:** if the local part length is 1, mask it fully (e.g., `a@b.com` -> `*@b.com`).
- **Email matching rule (no regex):** scan for `@`, accept local part with ASCII `[A-Za-z0-9._%+-]`, accept domain with ASCII `[A-Za-z0-9.-]`, require at least one dot, a TLD of letters only with length >= 2, and no empty or hyphen-delimited labels.
- **Phone masking rule:** preserve formatting (spaces, hyphens, parentheses) and the **last 4 digits**. All other digits are replaced.
- **Phone matching rule (no regex):** scan contiguous runs of `[0-9 +()-]` that start with a digit, `+`, or `(` and contain **at least 5 digits**; the match ends at the last digit in the run.
- **Very short phone numbers:** if the total digit count is **4 or fewer**, keep all digits as-is.
- **Mask character:** defaults to `*`, configurable via builder method.

---

## Email Masking (default mask char `*`)

### Basic cases

| Input | Expected Output |
| --- | --- |
| `alice@example.com` | `a****@example.com` |
| `a@b.com` | `*@b.com` |
| `ab@example.com` | `a*@example.com` |
| `a.b+c_d@example.co.jp` | `a******@example.co.jp` |

### Mixed text

| Input | Expected Output |
| --- | --- |
| `Contact: alice@example.com.` | `Contact: a****@example.com.` |
| `alice@example.com and bob@example.org` | `a****@example.com and b**@example.org` |

### Edge/ambiguous cases

| Input | Expected Output |
| --- | --- |
| `alice@example` | unchanged (no match) |
| `alice@localhost` | unchanged (no match) |
| `alice@@example.com` | unchanged (no match) |
| `first.last+tag@sub.domain.com` | `f*************@sub.domain.com` |

---

## Phone Masking (default mask char `*`)

### Basic international formats

| Input | Expected Output |
| --- | --- |
| `090-1234-5678` | `***-****-5678` |
| `Call (555) 123-4567` | `Call (***) ***-4567` |
| `Intl: +81 3 1234 5678` | `Intl: +** * **** 5678` |
| `+1 (800) 123-4567` | `+* (***) ***-4567` |

### Short numbers and boundary lengths

| Input | Expected Output |
| --- | --- |
| `1234` | `1234` |
| `12345` | `*2345` |
| `12-3456` | `**-3456` |

### Mixed text

| Input | Expected Output |
| --- | --- |
| `Tel: 090-1234-5678 ext. 99` | `Tel: ***-****-5678 ext. 99` |
| `Numbers: 111-2222 and 333-4444` | `Numbers: ***-2222 and ***-4444` |

### Edge/ambiguous cases

| Input | Expected Output |
| --- | --- |
| `abcdef` | unchanged (no match) |
| `+` | unchanged (no match) |
| `(12) 345 678` | `(**) **5 678` |

---

## Combined Masking (emails + phones)

| Input | Expected Output |
| --- | --- |
| `Contact: alice@example.com or 090-1234-5678.` | `Contact: a****@example.com or ***-****-5678.` |
| `Email bob@example.org, phone +1 (800) 123-4567` | `Email b**@example.org, phone +* (***) ***-4567` |

---

## Custom Mask Character (e.g., `#`)

| Input | Configuration | Expected Output |
| --- | --- | --- |
| `alice@example.com` | `mask_emails, with_mask_char('#')` | `a####@example.com` |
| `090-1234-5678` | `mask_phones, with_mask_char('#')` | `###-####-5678` |
| `Contact: alice@example.com or 090-1234-5678.` | `mask_emails + mask_phones + with_mask_char('#')` | `Contact: a####@example.com or ###-####-5678.` |

---

## Masker Configuration Behavior

| Scenario | Expected Output |
| --- | --- |
| `Masker.new` (no masks enabled) | input unchanged |
| `mask_emails` only | only emails masked |
| `mask_phones` only | only phones masked |
| `mask_emails + mask_phones` | both masked |

---

## Stability and Regression Checks

- Ensure **order of masking** does not corrupt previously masked output.
- Ensure **non-ASCII text** is preserved around masked content.
- Ensure **multiple matches** are all masked within a single input string.
