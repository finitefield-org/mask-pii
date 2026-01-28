package mask_pii

// Version is the current release version of the mask-pii Odin package.
Version :: "0.2.0"

// Masker is a configurable masker for common PII such as emails and phone numbers.
Masker :: struct {
	mask_email: bool,
	mask_phone: bool,
	mask_char:  rune,
}

// new creates a new masker with all masks disabled by default.
new :: proc() -> Masker {
	return Masker{
		mask_email = false,
		mask_phone = false,
		mask_char = '*',
	}
}

// mask_emails enables email address masking.
mask_emails :: proc(masker: Masker) -> Masker {
	masker.mask_email = true
	return masker
}

// mask_phones enables phone number masking.
mask_phones :: proc(masker: Masker) -> Masker {
	masker.mask_phone = true
	return masker
}

// with_mask_char sets the character used for masking.
with_mask_char :: proc(masker: Masker, mask_char: rune) -> Masker {
	if mask_char == 0 {
		mask_char = '*'
	}
	masker.mask_char = mask_char
	return masker
}

// process scans input text and masks enabled PII patterns.
process :: proc(masker: Masker, input: string) -> string {
	if !masker.mask_email && !masker.mask_phone {
		return input
	}

	mask_char := masker.mask_char
	if mask_char == 0 {
		mask_char = '*'
	}

	result := input
	if masker.mask_email {
		result = mask_emails_in_text(result, mask_char)
	}
	if masker.mask_phone {
		result = mask_phones_in_text(result, mask_char)
	}

	return result
}

// mask_emails_in_text masks email addresses within the input string.
mask_emails_in_text :: proc(input: string, mask_char: rune) -> string {
	input_bytes := []u8(input)
	length := len(input_bytes)
	output := make([]u8, 0, length)
	last := 0

	for i := 0; i < length; i += 1 {
		if input_bytes[i] == u8('@') {
			local_start := i
			for local_start > 0 && is_local_byte(input_bytes[local_start - 1]) {
				local_start -= 1
			}
			local_end := i

			domain_start := i + 1
			domain_end := domain_start
			for domain_end < length && is_domain_byte(input_bytes[domain_end]) {
				domain_end += 1
			}

			if local_start < local_end && domain_start < domain_end {
				candidate_end := domain_end
				matched_end := -1
				for candidate_end > domain_start {
					domain := input[domain_start:candidate_end]
					if is_valid_domain(domain) {
						matched_end = candidate_end
						break
					}
					candidate_end -= 1
				}

				if matched_end != -1 {
					local := input[local_start:local_end]
					domain := input[domain_start:matched_end]
					append_bytes(&output, input_bytes[last:local_start])
					append_masked_local(&output, local, mask_char)
					append_byte(&output, u8('@'))
					append_bytes(&output, []u8(domain))
					last = matched_end
					i = matched_end - 1
					continue
				}
			}
		}
	}

	append_bytes(&output, input_bytes[last:])
	return string(output)
}

// mask_phones_in_text masks phone numbers within the input string.
mask_phones_in_text :: proc(input: string, mask_char: rune) -> string {
	input_bytes := []u8(input)
	length := len(input_bytes)
	output := make([]u8, 0, length)
	last := 0

	for i := 0; i < length; i += 1 {
		if is_phone_start(input_bytes[i]) {
			end := i
			for end < length && is_phone_char(input_bytes[end]) {
				end += 1
			}

			digit_count := 0
			last_digit_index := -1
			for idx := i; idx < end; idx += 1 {
				if is_digit(input_bytes[idx]) {
					digit_count += 1
					last_digit_index = idx
				}
			}

			if last_digit_index != -1 {
				candidate_end := last_digit_index + 1
				if digit_count >= 5 {
					append_bytes(&output, input_bytes[last:i])
					append_masked_phone_candidate(&output, input_bytes[i:candidate_end], mask_char)
					last = candidate_end
					i = candidate_end - 1
					continue
				}
			}

			i = end - 1
			continue
		}
	}

	append_bytes(&output, input_bytes[last:])
	return string(output)
}

// append_masked_local appends a masked email local part to the output buffer.
append_masked_local :: proc(output: ^[]u8, local: string, mask_char: rune) {
	local_bytes := []u8(local)
	local_len := len(local_bytes)
	if local_len > 0 {
		append_byte(output, local_bytes[0])
		for i := 1; i < local_len; i += 1 {
			append_rune(output, mask_char)
		}
	} else {
		append_rune(output, mask_char)
	}
}

// append_masked_phone_candidate appends a masked phone candidate to the output buffer.
append_masked_phone_candidate :: proc(output: ^[]u8, candidate: []u8, mask_char: rune) {
	digit_count := 0
	for b in candidate {
		if is_digit(b) {
			digit_count += 1
		}
	}

	current_index := 0
	for b in candidate {
		if is_digit(b) {
			current_index += 1
			if digit_count > 4 && current_index <= digit_count - 4 {
				append_rune(output, mask_char)
			} else {
				append_byte(output, b)
			}
		} else {
			append_byte(output, b)
		}
	}
}

// append_bytes copies raw bytes into the output buffer.
append_bytes :: proc(output: ^[]u8, data: []u8) {
	for b in data {
		append_byte(output, b)
	}
}

// append_byte appends a single byte to the output buffer.
append_byte :: proc(output: ^[]u8, b: u8) {
	output^ = append(output^, b)
}

// append_rune appends a rune encoded as UTF-8 into the output buffer.
append_rune :: proc(output: ^[]u8, r: rune) {
	if r < 0 {
		append_byte(output, u8('?'))
		return
	}

	u := u32(r)
	if u <= 0x7F {
		append_byte(output, u8(u))
		return
	}
	if u <= 0x7FF {
		append_byte(output, u8(0xC0 | (u >> 6)))
		append_byte(output, u8(0x80 | (u & 0x3F)))
		return
	}
	if u <= 0xFFFF {
		append_byte(output, u8(0xE0 | (u >> 12)))
		append_byte(output, u8(0x80 | ((u >> 6) & 0x3F)))
		append_byte(output, u8(0x80 | (u & 0x3F)))
		return
	}
	if u <= 0x10FFFF {
		append_byte(output, u8(0xF0 | (u >> 18)))
		append_byte(output, u8(0x80 | ((u >> 12) & 0x3F)))
		append_byte(output, u8(0x80 | ((u >> 6) & 0x3F)))
		append_byte(output, u8(0x80 | (u & 0x3F)))
		return
	}

	append_byte(output, u8('?'))
}

// is_local_byte reports whether the byte is valid in an email local part.
is_local_byte :: proc(b: u8) -> bool {
	return (b >= u8('a') && b <= u8('z')) ||
		(b >= u8('A') && b <= u8('Z')) ||
		(b >= u8('0') && b <= u8('9')) ||
		b == u8('.') ||
		b == u8('_') ||
		b == u8('%') ||
		b == u8('+') ||
		b == u8('-')
}

// is_domain_byte reports whether the byte is valid in an email domain candidate.
is_domain_byte :: proc(b: u8) -> bool {
	return (b >= u8('a') && b <= u8('z')) ||
		(b >= u8('A') && b <= u8('Z')) ||
		(b >= u8('0') && b <= u8('9')) ||
		b == u8('-') ||
		b == u8('.')
}

// is_valid_domain checks whether the domain meets the masking rules.
is_valid_domain :: proc(domain: string) -> bool {
	domain_bytes := []u8(domain)
	length := len(domain_bytes)
	if length == 0 {
		return false
	}
	if domain_bytes[0] == u8('.') || domain_bytes[length - 1] == u8('.') {
		return false
	}

	dot_count := 0
	label_start := 0
	for i := 0; i <= length; i += 1 {
		if i == length || domain_bytes[i] == u8('.') {
			label_len := i - label_start
			if label_len == 0 {
				return false
			}

			label_first := domain_bytes[label_start]
			label_last := domain_bytes[i - 1]
			if label_first == u8('-') || label_last == u8('-') {
				return false
			}

			for j := label_start; j < i; j += 1 {
				b := domain_bytes[j]
				if !(is_alpha(b) || is_digit(b) || b == u8('-')) {
					return false
				}
			}

			if i < length {
				dot_count += 1
			} else {
				if label_len < 2 {
					return false
				}
				for j := label_start; j < i; j += 1 {
					if !is_alpha(domain_bytes[j]) {
						return false
					}
				}
			}

			label_start = i + 1
		}
	}

	return dot_count >= 1
}

// is_phone_start reports whether the byte can start a phone candidate run.
is_phone_start :: proc(b: u8) -> bool {
	return is_digit(b) || b == u8('+') || b == u8('(')
}

// is_phone_char reports whether the byte is allowed in a phone candidate run.
is_phone_char :: proc(b: u8) -> bool {
	return is_digit(b) || b == u8(' ') || b == u8('-') || b == u8('(') || b == u8(')') || b == u8('+')
}

// is_digit reports whether the byte is an ASCII digit.
is_digit :: proc(b: u8) -> bool {
	return b >= u8('0') && b <= u8('9')
}

// is_alpha reports whether the byte is an ASCII letter.
is_alpha :: proc(b: u8) -> bool {
	return (b >= u8('a') && b <= u8('z')) || (b >= u8('A') && b <= u8('Z'))
}
