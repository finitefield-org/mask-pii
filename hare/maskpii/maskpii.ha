use ascii;
use io;
use memio;
use strings;

// Version of the mask-pii Hare module.
export const version: str = "0.2.0";

// masker is a configurable PII masker for emails and phone numbers.
export type masker = struct {
	mask_email: bool,
	mask_phone: bool,
	mask_char: rune,
};

// new creates a new masker with all masks disabled by default.
export fn new() masker = {
	return masker {
		mask_email = false,
		mask_phone = false,
		mask_char = '*',
	};
};

// mask_emails enables email address masking.
export fn mask_emails(m: *masker) *masker = {
	m.mask_email = true;
	return m;
};

// mask_phones enables phone number masking.
export fn mask_phones(m: *masker) *masker = {
	m.mask_phone = true;
	return m;
};

// with_mask_char sets the character used for masking.
export fn with_mask_char(m: *masker, c: rune) *masker = {
	if (c == '\0') {
		c = '*';
	}
	m.mask_char = c;
	return m;
};

// process scans input text and masks enabled PII patterns.
// The returned string is newly allocated and must be freed by the caller.
export fn process(m: *masker, input: str) (str | nomem) = {
	let mask_char = m.mask_char;
	if (mask_char == '\0') {
		mask_char = '*';
	}

	let result = strings::dup(input)?;

	if (m.mask_email) {
		let masked = mask_emails_in_text(result, mask_char)?;
		free(result);
		result = masked;
	}

	if (m.mask_phone) {
		let masked = mask_phones_in_text(result, mask_char)?;
		free(result);
		result = masked;
	}

	return result;
};

fn mask_emails_in_text(input: str, mask_char: rune) (str | nomem) = {
	let bytes = strings::toutf8(input);
	let length = len(bytes);
	let stream = memio::dynamic();
	defer io::close(&stream)!;
	let out: *io::handle = &stream;

	let last: size = 0z;

	for (let i = 0z; i < length; i += 1) {
		if (rune(bytes[i]) == '@') {
			let local_start = find_local_start(bytes, i);
			let local_end = i;
			let domain_start = i + 1;
			let domain_end = find_domain_end(bytes, domain_start);

			if (local_start < local_end && domain_start < domain_end) {
				let matched_end = find_valid_domain_end(input, domain_start, domain_end);
				if (matched_end > 0z) {
					write_sub(out, input, last, local_start);
					write_masked_local(out, input, local_start, local_end, mask_char);
					memio::appendrune(out, '@')!;
					write_sub(out, input, domain_start, matched_end);
					last = matched_end;
					i = matched_end - 1;
					continue;
				}
			}
		}
	}

	write_sub(out, input, last, length);

	let out = memio::string(&stream)!;
	return strings::dup(out)?;
};

fn mask_phones_in_text(input: str, mask_char: rune) (str | nomem) = {
	let bytes = strings::toutf8(input);
	let length = len(bytes);
	let stream = memio::dynamic();
	defer io::close(&stream)!;
	let out: *io::handle = &stream;

	let last: size = 0z;

	for (let i = 0z; i < length; i += 1) {
		if (is_phone_start(bytes[i])) {
			let end = find_phone_end(bytes, i, length);
			let digit_info = count_digits(bytes, i, end);

			if (digit_info.has_digit && digit_info.digit_count >= 5) {
				let candidate_end = digit_info.last_digit + 1;
				let candidate = strings::bytesub(input, i, candidate_end)!;
				write_sub(out, input, last, i);
				write_masked_phone(out, candidate, mask_char);
				last = candidate_end;
				i = candidate_end - 1;
				continue;
			}

			i = end - 1;
			continue;
		}
	}

	write_sub(out, input, last, length);

	let out = memio::string(&stream)!;
	return strings::dup(out)?;
};

fn find_local_start(bytes: []u8, at: size) size = {
	let start = at;
	for (start > 0z && is_local_byte(bytes[start - 1])) {
		start -= 1;
	}
	return start;
};

fn find_domain_end(bytes: []u8, start: size) size = {
	let end = start;
	let length = len(bytes);
	for (end < length && is_domain_byte(bytes[end])) {
		end += 1;
	}
	return end;
};

fn find_valid_domain_end(input: str, start: size, end: size) size = {
	let candidate_end = end;
	for (candidate_end > start) {
		let domain = strings::bytesub(input, start, candidate_end)!;
		if (is_valid_domain(domain)) {
			return candidate_end;
		}
		candidate_end -= 1;
	}
	return 0z;
};

fn write_sub(out: *io::handle, input: str, start: size, end: size) void = {
	if (start >= end) {
		return;
	}
	let segment = strings::bytesub(input, start, end)!;
	memio::concat(out, segment)!;
};

fn write_masked_local(out: *io::handle, input: str, start: size, end: size, mask_char: rune) void = {
	let local_len = end - start;
	if (local_len == 0z) {
		return;
	}
	if (local_len > 1) {
		let first = strings::bytesub(input, start, start + 1)!;
		memio::concat(out, first)!;
		for (let i = 1z; i < local_len; i += 1) {
			memio::appendrune(out, mask_char)!;
		}
		return;
	}
	memio::appendrune(out, mask_char)!;
};

type digit_info = struct {
	has_digit: bool,
	digit_count: size,
	last_digit: size,
};

fn count_digits(bytes: []u8, start: size, end: size) digit_info = {
	let info = digit_info {
		has_digit = false,
		digit_count = 0z,
		last_digit = 0z,
	};
	for (let i = start; i < end; i += 1) {
		if (is_digit(bytes[i])) {
			info.has_digit = true;
			info.digit_count += 1;
			info.last_digit = i;
		}
	}
	return info;
};

fn find_phone_end(bytes: []u8, start: size, length: size) size = {
	let end = start;
	for (end < length && is_phone_char(bytes[end])) {
		end += 1;
	}
	return end;
};

fn write_masked_phone(out: *io::handle, candidate: str, mask_char: rune) void = {
	let bytes = strings::toutf8(candidate);
	let digit_count = count_digits_only(bytes);
	let current_index: size = 0z;

	for (let i = 0z; i < len(bytes); i += 1) {
		if (is_digit(bytes[i])) {
			current_index += 1;
			if (digit_count > 4 && current_index <= digit_count - 4) {
				memio::appendrune(out, mask_char)!;
			} else {
				memio::appendrune(out, rune(bytes[i]))!;
			}
		} else {
			memio::appendrune(out, rune(bytes[i]))!;
		}
	}
};

fn count_digits_only(bytes: []u8) size = {
	let count: size = 0z;
	for (let i = 0z; i < len(bytes); i += 1) {
		if (is_digit(bytes[i])) {
			count += 1;
		}
	}
	return count;
};

fn is_valid_domain(domain: str) bool = {
	let bytes = strings::toutf8(domain);
	let length = len(bytes);
	if (length == 0z) {
		return false;
	}
	if (rune(bytes[0]) == '.' || rune(bytes[length - 1]) == '.') {
		return false;
	}

	let part_count: size = 0z;
	let part_start: size = 0z;
	let last_part_start: size = 0z;
	let last_part_len: size = 0z;

	for (let i = 0z; i <= length; i += 1) {
		if (i == length || rune(bytes[i]) == '.') {
			let part_len = i - part_start;
			if (part_len == 0z) {
				return false;
			}
			if (rune(bytes[part_start]) == '-' || rune(bytes[i - 1]) == '-') {
				return false;
			}
			for (let j = part_start; j < i; j += 1) {
				let r = rune(bytes[j]);
				if (!(ascii::isalnum(r) || r == '-')) {
					return false;
				}
			}
			part_count += 1;
			last_part_start = part_start;
			last_part_len = part_len;
			part_start = i + 1;
		}
	}

	if (part_count < 2) {
		return false;
	}
	if (last_part_len < 2) {
		return false;
	}

	for (let j = last_part_start; j < last_part_start + last_part_len; j += 1) {
		if (!ascii::isalpha(rune(bytes[j]))) {
			return false;
		}
	}

	return true;
};

fn is_local_byte(b: u8) bool = {
	let r = rune(b);
	return ascii::isalnum(r)
		|| r == '.'
		|| r == '_'
		|| r == '%'
		|| r == '+'
		|| r == '-';
};

fn is_domain_byte(b: u8) bool = {
	let r = rune(b);
	return ascii::isalnum(r)
		|| r == '-'
		|| r == '.';
};

fn is_phone_start(b: u8) bool = {
	let r = rune(b);
	return ascii::isdigit(r) || r == '+' || r == '(';
};

fn is_phone_char(b: u8) bool = {
	let r = rune(b);
	return ascii::isdigit(r) || r == ' ' || r == '-' || r == '(' || r == ')' || r == '+';
};

fn is_digit(b: u8) bool = {
	return ascii::isdigit(rune(b));
};
