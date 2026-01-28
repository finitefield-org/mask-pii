require "mask_pii"

masker = MaskPII::Masker.new
  .mask_emails
  .mask_phones
  .with_mask_char('#')

puts masker.process("Contact: alice@example.com or 090-1234-5678.")
# Output: "Contact: a####@example.com or ###-####-5678."
