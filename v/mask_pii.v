module mask_pii

// Version is the current library version.
pub const version = '0.2.0'

// Masker is a configurable masker for common PII such as emails and phone numbers.
pub struct Masker {
	mask_email bool
	mask_phone bool
	mask_char  byte
}

// new creates a new masker with all masks disabled by default.
pub fn new() Masker {
	return Masker{
		mask_email: false
		mask_phone: false
		mask_char: `*`
	}
}

// mask_emails enables email address masking.
pub fn (m Masker) mask_emails() Masker {
	mut next := m
	next.mask_email = true
	return next
}

// mask_phones enables phone number masking.
pub fn (m Masker) mask_phones() Masker {
	mut next := m
	next.mask_phone = true
	return next
}

// with_mask_char sets the character used for masking.
pub fn (m Masker) with_mask_char(ch byte) Masker {
	mut next := m
	if ch == 0 {
		next.mask_char = `*`
	} else {
		next.mask_char = ch
	}
	return next
}

// process scans input text and masks enabled PII patterns.
pub fn (m Masker) process(input string) string {
	if !m.mask_email && !m.mask_phone {
		return input
	}
	mut result := input
	mask_char := if m.mask_char == 0 { `*` } else { m.mask_char }
	if m.mask_email {
		result = mask_emails_in_text(result, mask_char)
	}
	if m.mask_phone {
		result = mask_phones_in_text(result, mask_char)
	}
	return result
}

fn mask_emails_in_text(input string, mask_char byte) string {
	bytes := input.bytes()
	length := bytes.len
	mut output := []u8{cap: length}
	mut last := 0
	mut i := 0
	for i < length {
		if bytes[i] == `@` {
			mut local_start := i
			for local_start > 0 && is_local_byte(bytes[local_start - 1]) {
				local_start--
			}
			local_end := i

			domain_start := i + 1
			mut domain_end := domain_start
			for domain_end < length && is_domain_byte(bytes[domain_end]) {
				domain_end++
			}

			if local_start < local_end && domain_start < domain_end {
				mut candidate_end := domain_end
				mut matched_end := -1
				for candidate_end > domain_start {
					domain := input[domain_start..candidate_end]
					if is_valid_domain(domain) {
						matched_end = candidate_end
						break
					}
					candidate_end--
				}

				if matched_end != -1 {
					local := input[local_start..local_end]
					output << bytes[last..local_start]
					output << mask_local(local, mask_char).bytes()
					output << [u8(`@`)]
					output << bytes[domain_start..matched_end]
					last = matched_end
					i = matched_end
					continue
				}
			}
		}
		i++
	}

	output << bytes[last..]
	return output.bytestr()
}

fn mask_phones_in_text(input string, mask_char byte) string {
	bytes := input.bytes()
	length := bytes.len
	mut output := []u8{cap: length}
	mut last := 0
	mut i := 0
	for i < length {
		if is_phone_start(bytes[i]) {
			mut end := i
			for end < length && is_phone_char(bytes[end]) {
				end++
			}

			mut digit_count := 0
			mut last_digit_index := -1
			for idx := i; idx < end; idx++ {
				if is_digit(bytes[idx]) {
					digit_count++
					last_digit_index = idx
				}
			}

			if last_digit_index != -1 {
				candidate_end := last_digit_index + 1
				if digit_count >= 5 {
					output << bytes[last..i]
					output << mask_phone_candidate(input[i..candidate_end], mask_char).bytes()
					last = candidate_end
					i = candidate_end
					continue
				}
			}

			i = end
			continue
		}
		i++
	}

	output << bytes[last..]
	return output.bytestr()
}

fn mask_local(local string, mask_char byte) string {
	if local.len > 1 {
		mut out := []u8{len: local.len}
		out[0] = local[0]
		for i := 1; i < local.len; i++ {
			out[i] = mask_char
		}
		return out.bytestr()
	}
	return [u8(mask_char)].bytestr()
}

fn mask_phone_candidate(candidate string, mask_char byte) string {
	bytes := candidate.bytes()
	mut digit_count := 0
	for b in bytes {
		if is_digit(b) {
			digit_count++
		}
	}

	mut current_index := 0
	mut out := []u8{len: bytes.len}
	for i, b in bytes {
		if is_digit(b) {
			current_index++
			if digit_count > 4 && current_index <= digit_count - 4 {
				out[i] = mask_char
			} else {
				out[i] = b
			}
		} else {
			out[i] = b
		}
	}
	return out.bytestr()
}

fn is_local_byte(b byte) bool {
	return (b >= `a` && b <= `z`)
		|| (b >= `A` && b <= `Z`)
		|| (b >= `0` && b <= `9`)
		|| b == `.` || b == `_` || b == `%` || b == `+` || b == `-`
}

fn is_domain_byte(b byte) bool {
	return (b >= `a` && b <= `z`)
		|| (b >= `A` && b <= `Z`)
		|| (b >= `0` && b <= `9`)
		|| b == `-` || b == `.`
}

fn is_valid_domain(domain string) bool {
	if domain.len == 0 || domain[0] == `.` || domain[domain.len - 1] == `.` {
		return false
	}

	parts := domain.split('.')
	if parts.len < 2 {
		return false
	}

	for part in parts {
		if part.len == 0 {
			return false
		}
		if part[0] == `-` || part[part.len - 1] == `-` {
			return false
		}
		for i := 0; i < part.len; i++ {
			b := part[i]
			if !(is_alnum(b) || b == `-`) {
				return false
			}
		}
	}

	tld := parts[parts.len - 1]
	if tld.len < 2 {
		return false
	}
	for i := 0; i < tld.len; i++ {
		if !is_alpha(tld[i]) {
			return false
		}
	}

	return true
}

fn is_phone_start(b byte) bool {
	return is_digit(b) || b == `+` || b == `(`
}

fn is_phone_char(b byte) bool {
	return is_digit(b) || b == ` ` || b == `-` || b == `(` || b == `)` || b == `+`
}

fn is_digit(b byte) bool {
	return b >= `0` && b <= `9`
}

fn is_alpha(b byte) bool {
	return (b >= `a` && b <= `z`) || (b >= `A` && b <= `Z`)
}

fn is_alnum(b byte) bool {
	return is_alpha(b) || is_digit(b)
}
