# mask-pii (PHP)

mask-pii is a lightweight, customizable library for masking emails and phone numbers in text.

- Homepage: https://finitefield.org/en/oss/mask-pii
- Repository: https://github.com/finitefield-org/mask-pii
- Issues: https://github.com/finitefield-org/mask-pii/issues
- License: MIT
- Developed by: [Finite Field, K.K.](https://finitefield.org/en/)

## Installation

```bash
composer require finitefield-org/mask-pii
```

## Usage

```php
<?php

use MaskPII\Masker;

$masker = (new Masker())
    ->maskEmails()
    ->maskPhones()
    ->withMaskChar("*");

echo $masker->process("Contact: alice@example.com or 090-1234-5678.");
// Contact: a****@example.com or ***-****-5678.
```

## Examples

See `example/basic.php` for a runnable example.
```
