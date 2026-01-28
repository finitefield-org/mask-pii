# maskpii (R)

Version: 0.2.0

maskpii is an R implementation of the mask-pii library for masking email addresses and
phone numbers while preserving formatting.

🌐 Official website: https://finitefield.org/en/oss/mask-pii  
🏢 Developed by: Finite Field, K.K.  

## Installation

```r
# Install from source (example)
# install.packages("path/to/maskpii_0.2.0.tar.gz", repos = NULL, type = "source")
```

## Usage

```r
library(maskpii)

masker <- Masker()
result <- masker$mask_emails()$mask_phones()$with_mask_char("#")$process(
  "Contact: alice@example.com or 090-1234-5678."
)
print(result)
```

## Notes

- Email masking preserves the domain and masks the local part.
- Phone masking preserves separators and the last four digits.
