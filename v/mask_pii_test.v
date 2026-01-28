module mask_pii

struct TestCase {
	input    string
	expected string
}

fn assert_cases(masker Masker, cases []TestCase) {
	for tc in cases {
		got := masker.process(tc.input)
		assert got == tc.expected
	}
}

fn test_email_basic_cases() {
	masker := new().mask_emails()
	assert_cases(masker, [
		TestCase{input: 'alice@example.com', expected: 'a****@example.com'},
		TestCase{input: 'a@b.com', expected: '*@b.com'},
		TestCase{input: 'ab@example.com', expected: 'a*@example.com'},
		TestCase{input: 'a.b+c_d@example.co.jp', expected: 'a******@example.co.jp'},
	])
}

fn test_email_mixed_text() {
	masker := new().mask_emails()
	assert_cases(masker, [
		TestCase{input: 'Contact: alice@example.com.', expected: 'Contact: a****@example.com.'},
		TestCase{input: 'alice@example.com and bob@example.org', expected: 'a****@example.com and b**@example.org'},
	])
}

fn test_email_edge_cases() {
	masker := new().mask_emails()
	assert_cases(masker, [
		TestCase{input: 'alice@example', expected: 'alice@example'},
		TestCase{input: 'alice@localhost', expected: 'alice@localhost'},
		TestCase{input: 'alice@@example.com', expected: 'alice@@example.com'},
		TestCase{input: 'first.last+tag@sub.domain.com', expected: 'f*************@sub.domain.com'},
	])
}

fn test_phone_basic_formats() {
	masker := new().mask_phones()
	assert_cases(masker, [
		TestCase{input: '090-1234-5678', expected: '***-****-5678'},
		TestCase{input: 'Call (555) 123-4567', expected: 'Call (***) ***-4567'},
		TestCase{input: 'Intl: +81 3 1234 5678', expected: 'Intl: +** * **** 5678'},
		TestCase{input: '+1 (800) 123-4567', expected: '+* (***) ***-4567'},
	])
}

fn test_phone_short_and_boundary_lengths() {
	masker := new().mask_phones()
	assert_cases(masker, [
		TestCase{input: '1234', expected: '1234'},
		TestCase{input: '12345', expected: '*2345'},
		TestCase{input: '12-3456', expected: '**-3456'},
	])
}

fn test_phone_mixed_text() {
	masker := new().mask_phones()
	assert_cases(masker, [
		TestCase{input: 'Tel: 090-1234-5678 ext. 99', expected: 'Tel: ***-****-5678 ext. 99'},
		TestCase{input: 'Numbers: 111-2222 and 333-4444', expected: 'Numbers: ***-2222 and ***-4444'},
	])
}

fn test_phone_edge_cases() {
	masker := new().mask_phones()
	assert_cases(masker, [
		TestCase{input: 'abcdef', expected: 'abcdef'},
		TestCase{input: '+', expected: '+'},
		TestCase{input: '(12) 345 678', expected: '(**) **5 678'},
	])
}

fn test_combined_masking() {
	masker := new().mask_emails().mask_phones()
	assert_cases(masker, [
		TestCase{input: 'Contact: alice@example.com or 090-1234-5678.', expected: 'Contact: a****@example.com or ***-****-5678.'},
		TestCase{input: 'Email bob@example.org, phone +1 (800) 123-4567', expected: 'Email b**@example.org, phone +* (***) ***-4567'},
	])
}

fn test_custom_mask_character() {
	email_masker := new().mask_emails().with_mask_char(`#`)
	phone_masker := new().mask_phones().with_mask_char(`#`)
	combined := new().mask_emails().mask_phones().with_mask_char(`#`)

	assert_cases(email_masker, [TestCase{input: 'alice@example.com', expected: 'a####@example.com'}])
	assert_cases(phone_masker, [TestCase{input: '090-1234-5678', expected: '###-####-5678'}])

	got := combined.process('Contact: alice@example.com or 090-1234-5678.')
	want := 'Contact: a####@example.com or ###-####-5678.'
	assert got == want
}

fn test_masker_configuration() {
	input := 'alice@example.com 090-1234-5678'

	passthrough := new()
	assert passthrough.process(input) == input

	email_only := new().mask_emails()
	assert email_only.process(input) == 'a****@example.com 090-1234-5678'

	phone_only := new().mask_phones()
	assert phone_only.process(input) == 'alice@example.com ***-****-5678'

	both := new().mask_emails().mask_phones()
	assert both.process(input) == 'a****@example.com ***-****-5678'
}

fn test_non_ascii_text_is_preserved() {
	masker := new().mask_emails().mask_phones()
	input := '連絡先: alice@example.com と 090-1234-5678'
	expected := '連絡先: a****@example.com と ***-****-5678'
	assert masker.process(input) == expected
}
