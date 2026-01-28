package main

import (
	"core:fmt"
	"mask_pii"
)

main :: proc() {
	masker := mask_pii.new()
	masker = mask_pii.mask_emails(masker)
	masker = mask_pii.mask_phones(masker)
	masker = mask_pii.with_mask_char(masker, '#')

	input := "Contact: alice@example.com or 090-1234-5678."
	output := mask_pii.process(masker, input)

	fmt.println(output)
}
