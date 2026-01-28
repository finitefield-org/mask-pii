# mask-pii (JavaScript)

mask-pii is a lightweight, customizable library for masking Personally Identifiable Information (PII) such as email addresses and phone numbers.

## Installation

```bash
npm install mask-pii
```

## Usage

```js
const { Masker } = require("mask-pii");

const masker = new Masker()
  .maskEmails()
  .maskPhones()
  .withMaskChar("#");

const input = "Contact: alice@example.com or 090-1234-5678.";
const output = masker.process(input);
console.log(output);
```

## API

### `Masker`

- `maskEmails()` enables email masking.
- `maskPhones()` enables phone masking.
- `withMaskChar(char)` sets the mask character (defaults to `*`).
- `process(text)` returns the masked text.

## Development

```bash
npm test
```

## License

MIT

Developed by: [Finite Field, K.K.](https://finitefield.org/en/)
