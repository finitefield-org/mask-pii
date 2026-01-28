# Bash Example

```bash
#!/usr/bin/env bash

source "../../bash/mask_pii.sh"

mask_pii_new masker
mask_pii_mask_emails masker
mask_pii_mask_phones masker

input='Contact: alice@example.com or 090-1234-5678.'
output=$(mask_pii_process masker "$input")

echo "$output"
# Contact: a****@example.com or ***-****-5678.
```
