alias MaskPII.Masker

masker =
  Masker.new()
  |> Masker.mask_emails()
  |> Masker.mask_phones()
  |> Masker.with_mask_char("#")

input_text = "Contact: alice@example.com or 090-1234-5678."
output = Masker.process(masker, input_text)

IO.puts(output)
