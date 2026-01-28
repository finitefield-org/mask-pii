module main

import mask_pii

fn main() {
	masker := mask_pii.new()
		.mask_emails()
		.mask_phones()
		.with_mask_char(`#`)

	input := 'Contact: alice@example.com or 090-1234-5678.'
	output := masker.process(input)

	println(output)
}
