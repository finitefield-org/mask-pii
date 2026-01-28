package mask_pii

import "core:testing"

TestCase :: struct {
	input:    string,
	expected: string,
}

assert_cases :: proc(t: ^testing.T, masker: Masker, cases: []TestCase) {
	for c in cases {
		got := process(masker, c.input)
		testing.expect(t, got == c.expected)
	}
}

test_email_basic_cases :: proc(t: ^testing.T) {
	masker := mask_emails(new())
	cases := []TestCase{
		{input = "alice@example.com", expected = "a****@example.com"},
		{input = "a@b.com", expected = "*@b.com"},
		{input = "ab@example.com", expected = "a*@example.com"},
		{input = "a.b+c_d@example.co.jp", expected = "a******@example.co.jp"},
	}
	assert_cases(t, masker, cases)
}

test_email_mixed_text :: proc(t: ^testing.T) {
	masker := mask_emails(new())
	cases := []TestCase{
		{input = "Contact: alice@example.com.", expected = "Contact: a****@example.com."},
		{input = "alice@example.com and bob@example.org", expected = "a****@example.com and b**@example.org"},
	}
	assert_cases(t, masker, cases)
}

test_email_edge_cases :: proc(t: ^testing.T) {
	masker := mask_emails(new())
	cases := []TestCase{
		{input = "alice@example", expected = "alice@example"},
		{input = "alice@localhost", expected = "alice@localhost"},
		{input = "alice@@example.com", expected = "alice@@example.com"},
		{input = "first.last+tag@sub.domain.com", expected = "f*************@sub.domain.com"},
	}
	assert_cases(t, masker, cases)
}

test_phone_basic_formats :: proc(t: ^testing.T) {
	masker := mask_phones(new())
	cases := []TestCase{
		{input = "090-1234-5678", expected = "***-****-5678"},
		{input = "Call (555) 123-4567", expected = "Call (***) ***-4567"},
		{input = "Intl: +81 3 1234 5678", expected = "Intl: +** * **** 5678"},
		{input = "+1 (800) 123-4567", expected = "+* (***) ***-4567"},
	}
	assert_cases(t, masker, cases)
}

test_phone_short_and_boundary_lengths :: proc(t: ^testing.T) {
	masker := mask_phones(new())
	cases := []TestCase{
		{input = "1234", expected = "1234"},
		{input = "12345", expected = "*2345"},
		{input = "12-3456", expected = "**-3456"},
	}
	assert_cases(t, masker, cases)
}

test_phone_mixed_text :: proc(t: ^testing.T) {
	masker := mask_phones(new())
	cases := []TestCase{
		{input = "Tel: 090-1234-5678 ext. 99", expected = "Tel: ***-****-5678 ext. 99"},
		{input = "Numbers: 111-2222 and 333-4444", expected = "Numbers: ***-2222 and ***-4444"},
	}
	assert_cases(t, masker, cases)
}

test_phone_edge_cases :: proc(t: ^testing.T) {
	masker := mask_phones(new())
	cases := []TestCase{
		{input = "abcdef", expected = "abcdef"},
		{input = "+", expected = "+"},
		{input = "(12) 345 678", expected = "(**) **5 678"},
	}
	assert_cases(t, masker, cases)
}

test_combined_masking :: proc(t: ^testing.T) {
	masker := mask_phones(mask_emails(new()))
	cases := []TestCase{
		{input = "Contact: alice@example.com or 090-1234-5678.", expected = "Contact: a****@example.com or ***-****-5678."},
		{input = "Email bob@example.org, phone +1 (800) 123-4567", expected = "Email b**@example.org, phone +* (***) ***-4567"},
	}
	assert_cases(t, masker, cases)
}

test_custom_mask_character :: proc(t: ^testing.T) {
	email_masker := with_mask_char(mask_emails(new()), '#')
	phone_masker := with_mask_char(mask_phones(new()), '#')
	combined := with_mask_char(mask_phones(mask_emails(new())), '#')

	assert_cases(t, email_masker, []TestCase{TestCase{input = "alice@example.com", expected = "a####@example.com"}})
	assert_cases(t, phone_masker, []TestCase{TestCase{input = "090-1234-5678", expected = "###-####-5678"}})

	got := process(combined, "Contact: alice@example.com or 090-1234-5678.")
	want := "Contact: a####@example.com or ###-####-5678."
	testing.expect(t, got == want)
}

test_masker_configuration :: proc(t: ^testing.T) {
	input_text := "alice@example.com 090-1234-5678"

	passthrough := new()
	testing.expect(t, process(passthrough, input_text) == input_text)

	email_only := mask_emails(new())
	testing.expect(t, process(email_only, input_text) == "a****@example.com 090-1234-5678")

	phone_only := mask_phones(new())
	testing.expect(t, process(phone_only, input_text) == "alice@example.com ***-****-5678")

	both := mask_phones(mask_emails(new()))
	testing.expect(t, process(both, input_text) == "a****@example.com ***-****-5678")
}

test_non_ascii_text_is_preserved :: proc(t: ^testing.T) {
	masker := mask_phones(mask_emails(new()))
	input_text := "連絡先: alice@example.com と 090-1234-5678"
	expected := "連絡先: a****@example.com と ***-****-5678"
	testing.expect(t, process(masker, input_text) == expected)
}
