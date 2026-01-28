using MaskPII

masker = Masker()
mask_emails(masker)
mask_phones(masker)
with_mask_char(masker, '#')

input_text = "Contact: alice@example.com or 090-1234-5678."
output = process(masker, input_text)

println(output)
