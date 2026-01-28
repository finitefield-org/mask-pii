# mask-pii (D)

Version: 0.2.0

A lightweight, configurable D library for masking Personally Identifiable Information (PII) such as email addresses and phone numbers.

- 🌐 Homepage: https://finitefield.org/en/oss/mask-pii
- 📦 Repository: https://github.com/finitefield-org/mask-pii
- 🐛 Issues: https://github.com/finitefield-org/mask-pii/issues
- 🏢 Developed by: [Finite Field, K.K.](https://finitefield.org/en/)
- 📄 License: MIT
- 🔎 Keywords: pii, masking, email, phone, privacy

## Installation

Add the dependency using dub:

```bash
dub add mask-pii
```

## Usage

```d
import std.stdio : writeln;
import mask_pii : Masker;

void main() {
    auto masker = Masker()
        .maskEmails()
        .maskPhones()
        .withMaskChar('#');

    auto inputText = "Contact: alice@example.com or 090-1234-5678.";
    auto outputText = masker.process(inputText);

    writeln(outputText);
    // Contact: a####@example.com or ###-####-5678.
}
```

## Configuration

`Masker` follows a builder-style API. By default, it performs no masking until you enable it.

| Method | Description | Default |
| --- | --- | --- |
| `maskEmails()` | Enable email masking. | Disabled |
| `maskPhones()` | Enable phone masking. | Disabled |
| `withMaskChar(char)` | Set the masking character. | `'*'` |
| `process(string)` | Mask enabled PII patterns. | - |

## Examples

See `example/d/main.d` for a runnable example.
