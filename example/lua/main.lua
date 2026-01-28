local mask_pii = require("mask_pii")
local Masker = mask_pii.Masker

local masker = Masker.new():mask_emails():mask_phones():with_mask_char("#")
local input_text = "Contact: alice@example.com or 090-1234-5678."
print(masker:process(input_text))
