# mask-pii (Groovy)

Version: 0.2.0

A lightweight, customizable Groovy library for masking Personally Identifiable Information (PII) such as **email addresses** and **phone numbers**.

Official website: https://finitefield.org/en/oss/mask-pii
Developed by: [Finite Field, K.K.](https://finitefield.org/en/)

## Features

- **Email Masking:** Masks the local part while preserving the domain (e.g., `a****@example.com`).
- **Global Phone Masking:** Detects international phone formats and masks all digits except the last 4.
- **Customizable:** Change the masking character (default is `*`).
- **Zero Unnecessary Dependencies:** Pure Groovy implementation.

## Installation

### Gradle

```groovy
dependencies {
    implementation 'org.finitefield:mask-pii:0.2.0'
}
```

### Maven

```xml
<dependency>
  <groupId>org.finitefield</groupId>
  <artifactId>mask-pii</artifactId>
  <version>0.2.0</version>
</dependency>
```

## Usage

```groovy
import org.finitefield.maskpii.Masker

def masker = new Masker()
    .maskEmails()
    .maskPhones()
    .withMaskChar('#')

def inputText = 'Contact: alice@example.com or 090-1234-5678.'
def output = masker.process(inputText)

println(output)
// => Contact: a####@example.com or ###-####-5678.
```

## Configuration

The `Masker` class uses a builder-style API. By default, `new Masker()` performs **no masking** (pass-through).

### Builder Methods

| Method | Description | Default |
| --- | --- | --- |
| `maskEmails()` | Enables detection and masking of email addresses. | Disabled |
| `maskPhones()` | Enables detection and masking of global phone numbers. | Disabled |
| `withMaskChar(char)` | Sets the character used for masking (e.g., `"*"`, `"#"`, `"x"`). | `"*"` |

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
