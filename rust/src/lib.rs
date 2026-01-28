/// A configurable masker for common PII such as emails and phone numbers.
pub struct Masker {
    mask_email: bool,
    mask_phone: bool,
    mask_char: char,
}

impl Default for Masker {
    fn default() -> Self {
        Self::new()
    }
}

impl Masker {
    /// Create a new masker with all masks disabled by default.
    pub fn new() -> Self {
        Self {
            mask_email: false,
            mask_phone: false,
            mask_char: '*',
        }
    }

    /// Enable email address masking.
    pub fn mask_emails(mut self) -> Self {
        self.mask_email = true;
        self
    }

    /// Enable phone number masking.
    pub fn mask_phones(mut self) -> Self {
        self.mask_phone = true;
        self
    }

    /// Set the character used for masking.
    pub fn with_mask_char(mut self, c: char) -> Self {
        self.mask_char = c;
        self
    }

    /// Process input text and mask enabled PII patterns.
    pub fn process(&self, input: &str) -> String {
        let mut result = input.to_string();

        if self.mask_email {
            result = mask_emails_in_text(&result, self.mask_char);
        }

        if self.mask_phone {
            result = mask_phones_in_text(&result, self.mask_char);
        }

        result
    }
}

fn mask_emails_in_text(input: &str, mask_char: char) -> String {
    let bytes = input.as_bytes();
    let len = bytes.len();
    let mut output = String::with_capacity(input.len());
    let mut last = 0;
    let mut i = 0;

    while i < len {
        if bytes[i] == b'@' {
            let mut local_start = i;
            while local_start > 0 && is_local_byte(bytes[local_start - 1]) {
                local_start -= 1;
            }
            let local_end = i;

            let domain_start = i + 1;
            let mut domain_end = domain_start;
            while domain_end < len && is_domain_byte(bytes[domain_end]) {
                domain_end += 1;
            }

            if local_start < local_end && domain_start < domain_end {
                let mut candidate_end = domain_end;
                let mut matched_domain_end = None;
                while candidate_end > domain_start {
                    let domain = &input[domain_start..candidate_end];
                    if is_valid_domain(domain) {
                        matched_domain_end = Some(candidate_end);
                        break;
                    }
                    candidate_end -= 1;
                }

                if let Some(valid_end) = matched_domain_end {
                    let local = &input[local_start..local_end];
                    let domain = &input[domain_start..valid_end];
                    output.push_str(&input[last..local_start]);
                    output.push_str(&mask_local(local, mask_char));
                    output.push('@');
                    output.push_str(domain);
                    last = valid_end;
                    i = valid_end;
                    continue;
                }
            }
        }

        i += 1;
    }

    output.push_str(&input[last..]);
    output
}

fn mask_phones_in_text(input: &str, mask_char: char) -> String {
    let bytes = input.as_bytes();
    let len = bytes.len();
    let mut output = String::with_capacity(input.len());
    let mut last = 0;
    let mut i = 0;

    while i < len {
        if is_phone_start(bytes[i]) {
            let mut end = i;
            while end < len && is_phone_char(bytes[end]) {
                end += 1;
            }

            let mut digit_count = 0;
            let mut last_digit_index = None;
            for idx in i..end {
                if bytes[idx].is_ascii_digit() {
                    digit_count += 1;
                    last_digit_index = Some(idx);
                }
            }

            if let Some(last_digit) = last_digit_index {
                let candidate_end = last_digit + 1;
                if digit_count >= 5 {
                    let candidate = &input[i..candidate_end];
                    output.push_str(&input[last..i]);
                    output.push_str(&mask_phone_candidate(candidate, mask_char));
                    last = candidate_end;
                    i = candidate_end;
                    continue;
                }
            }

            i = end;
            continue;
        }

        i += 1;
    }

    output.push_str(&input[last..]);
    output
}

fn mask_local(local: &str, mask_char: char) -> String {
    let len = local.len();
    if len > 1 {
        let mut result = String::with_capacity(len);
        let first = local.as_bytes()[0] as char;
        result.push(first);
        for _ in 1..len {
            result.push(mask_char);
        }
        result
    } else {
        mask_char.to_string()
    }
}

fn mask_phone_candidate(candidate: &str, mask_char: char) -> String {
    let bytes = candidate.as_bytes();
    let digit_count = bytes.iter().filter(|b| b.is_ascii_digit()).count();
    let mut current_index = 0;
    let mut result = String::with_capacity(candidate.len());

    for &b in bytes {
        if b.is_ascii_digit() {
            current_index += 1;
            if digit_count > 4 && current_index <= digit_count - 4 {
                result.push(mask_char);
            } else {
                result.push(b as char);
            }
        } else {
            result.push(b as char);
        }
    }

    result
}

fn is_local_byte(byte: u8) -> bool {
    matches!(
        byte,
        b'a'..=b'z'
            | b'A'..=b'Z'
            | b'0'..=b'9'
            | b'.'
            | b'_'
            | b'%'
            | b'+'
            | b'-'
    )
}

fn is_domain_byte(byte: u8) -> bool {
    matches!(
        byte,
        b'a'..=b'z' | b'A'..=b'Z' | b'0'..=b'9' | b'-' | b'.'
    )
}

fn is_valid_domain(domain: &str) -> bool {
    if domain.starts_with('.') || domain.ends_with('.') {
        return false;
    }

    let parts: Vec<&str> = domain.split('.').collect();
    if parts.len() < 2 {
        return false;
    }

    for part in &parts {
        if part.is_empty() {
            return false;
        }
        if part.starts_with('-') || part.ends_with('-') {
            return false;
        }
        if !part
            .as_bytes()
            .iter()
            .all(|b| b.is_ascii_alphanumeric() || *b == b'-')
        {
            return false;
        }
    }

    let tld = parts.last().unwrap();
    if tld.len() < 2 || !tld.as_bytes().iter().all(|b| b.is_ascii_alphabetic()) {
        return false;
    }

    true
}

fn is_phone_start(byte: u8) -> bool {
    byte.is_ascii_digit() || byte == b'+' || byte == b'('
}

fn is_phone_char(byte: u8) -> bool {
    byte.is_ascii_digit() || matches!(byte, b' ' | b'-' | b'(' | b')' | b'+')
}

#[cfg(test)]
mod tests {
    use super::*;

    fn assert_cases(masker: &Masker, cases: &[(&str, &str)]) {
        for (input, expected) in cases {
            assert_eq!(masker.process(input), *expected);
        }
    }

    #[test]
    fn test_email_basic_cases() {
        let masker = Masker::new().mask_emails();
        assert_cases(
            &masker,
            &[
                ("alice@example.com", "a****@example.com"),
                ("a@b.com", "*@b.com"),
                ("ab@example.com", "a*@example.com"),
                ("a.b+c_d@example.co.jp", "a******@example.co.jp"),
            ],
        );
    }

    #[test]
    fn test_email_mixed_text() {
        let masker = Masker::new().mask_emails();
        assert_cases(
            &masker,
            &[
                ("Contact: alice@example.com.", "Contact: a****@example.com."),
                (
                    "alice@example.com and bob@example.org",
                    "a****@example.com and b**@example.org",
                ),
            ],
        );
    }

    #[test]
    fn test_email_edge_cases() {
        let masker = Masker::new().mask_emails();
        assert_cases(
            &masker,
            &[
                ("alice@example", "alice@example"),
                ("alice@localhost", "alice@localhost"),
                ("alice@@example.com", "alice@@example.com"),
                (
                    "first.last+tag@sub.domain.com",
                    "f*************@sub.domain.com",
                ),
            ],
        );
    }

    #[test]
    fn test_phone_basic_formats() {
        let masker = Masker::new().mask_phones();
        assert_cases(
            &masker,
            &[
                ("090-1234-5678", "***-****-5678"),
                ("Call (555) 123-4567", "Call (***) ***-4567"),
                ("Intl: +81 3 1234 5678", "Intl: +** * **** 5678"),
                ("+1 (800) 123-4567", "+* (***) ***-4567"),
            ],
        );
    }

    #[test]
    fn test_phone_short_and_boundary_lengths() {
        let masker = Masker::new().mask_phones();
        assert_cases(
            &masker,
            &[("1234", "1234"), ("12345", "*2345"), ("12-3456", "**-3456")],
        );
    }

    #[test]
    fn test_phone_mixed_text() {
        let masker = Masker::new().mask_phones();
        assert_cases(
            &masker,
            &[
                (
                    "Tel: 090-1234-5678 ext. 99",
                    "Tel: ***-****-5678 ext. 99",
                ),
                (
                    "Numbers: 111-2222 and 333-4444",
                    "Numbers: ***-2222 and ***-4444",
                ),
            ],
        );
    }

    #[test]
    fn test_phone_edge_cases() {
        let masker = Masker::new().mask_phones();
        assert_cases(
            &masker,
            &[("abcdef", "abcdef"), ("+", "+"), ("(12) 345 678", "(**) **5 678")],
        );
    }

    #[test]
    fn test_combined_masking() {
        let masker = Masker::new().mask_emails().mask_phones();
        assert_cases(
            &masker,
            &[
                (
                    "Contact: alice@example.com or 090-1234-5678.",
                    "Contact: a****@example.com or ***-****-5678.",
                ),
                (
                    "Email bob@example.org, phone +1 (800) 123-4567",
                    "Email b**@example.org, phone +* (***) ***-4567",
                ),
            ],
        );
    }

    #[test]
    fn test_custom_mask_character() {
        let email_masker = Masker::new().mask_emails().with_mask_char('#');
        let phone_masker = Masker::new().mask_phones().with_mask_char('#');
        let combined = Masker::new().mask_emails().mask_phones().with_mask_char('#');

        assert_cases(&email_masker, &[("alice@example.com", "a####@example.com")]);
        assert_cases(&phone_masker, &[("090-1234-5678", "###-####-5678")]);
        assert_eq!(
            combined.process("Contact: alice@example.com or 090-1234-5678."),
            "Contact: a####@example.com or ###-####-5678."
        );
    }

    #[test]
    fn test_masker_configuration() {
        let input = "alice@example.com 090-1234-5678";

        let passthrough = Masker::new();
        assert_eq!(passthrough.process(input), input);

        let email_only = Masker::new().mask_emails();
        assert_eq!(
            email_only.process(input),
            "a****@example.com 090-1234-5678"
        );

        let phone_only = Masker::new().mask_phones();
        assert_eq!(
            phone_only.process(input),
            "alice@example.com ***-****-5678"
        );

        let both = Masker::new().mask_emails().mask_phones();
        assert_eq!(both.process(input), "a****@example.com ***-****-5678");
    }

    #[test]
    fn test_non_ascii_text_is_preserved() {
        let masker = Masker::new().mask_emails().mask_phones();
        let input = "連絡先: alice@example.com と 090-1234-5678";
        let expected = "連絡先: a****@example.com と ***-****-5678";
        assert_eq!(masker.process(input), expected);
    }
}
