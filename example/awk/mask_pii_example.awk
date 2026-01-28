BEGIN {
  mask_pii_new(masker)
  mask_pii_mask_emails(masker)
  mask_pii_mask_phones(masker)
  mask_pii_with_mask_char(masker, "#")
  print mask_pii_process(masker, "Contact: alice@example.com or 090-1234-5678.")
}
