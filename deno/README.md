# mask-pii (Deno)

Version: 0.2.0

A lightweight, customizable Deno module for masking Personally Identifiable Information (PII) such as **email addresses** and **phone numbers**.

Official website: https://finitefield.org/en/oss/mask-pii
Developed by: [Finite Field, K.K.](https://finitefield.org/en/)

## Installation

From deno.land/x:

```ts
import { Masker } from "https://deno.land/x/mask_pii@v0.2.0/mod.ts";
```

From a local checkout:

```ts
import { Masker } from "../deno/mod.ts";
```

## Usage

```ts
import { Masker } from "https://deno.land/x/mask_pii@v0.2.0/mod.ts";

const masker = new Masker()
  .maskEmails()
  .maskPhones()
  .withMaskChar("#");

const input = "Contact: alice@example.com or 090-1234-5678.";
const output = masker.process(input);

console.log(output);
// => "Contact: a####@example.com or ###-####-5678."
```

## Configuration

The `Masker` class uses a builder-style API. By default, `new Masker()` performs **no masking** (pass-through).

### Builder Methods

| Method | Description | Default |
| --- | --- | --- |
| `maskEmails()` | Enables detection and masking of email addresses. | Disabled |
| `maskPhones()` | Enables detection and masking of phone numbers. | Disabled |
| `withMaskChar(char)` | Sets the character used for masking. | `"*"` |

## Development

```bash
deno task test
```

## License

MIT
