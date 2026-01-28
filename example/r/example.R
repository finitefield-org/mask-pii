library(maskpii)

masker <- Masker()
output <- masker$mask_emails()$mask_phones()$with_mask_char("#")$process(
  "Contact: alice@example.com or 090-1234-5678."
)

cat(output, "\n")
