package maskpii

import "testing"

type testCase struct {
	input    string
	expected string
}

func assertCases(t *testing.T, masker *Masker, cases []testCase) {
	t.Helper()
	for _, tc := range cases {
		if got := masker.Process(tc.input); got != tc.expected {
			t.Fatalf("input %q: expected %q, got %q", tc.input, tc.expected, got)
		}
	}
}

func TestEmailBasicCases(t *testing.T) {
	masker := New().MaskEmails()
	assertCases(t, masker, []testCase{
		{input: "alice@example.com", expected: "a****@example.com"},
		{input: "a@b.com", expected: "*@b.com"},
		{input: "ab@example.com", expected: "a*@example.com"},
		{input: "a.b+c_d@example.co.jp", expected: "a******@example.co.jp"},
	})
}

func TestEmailMixedText(t *testing.T) {
	masker := New().MaskEmails()
	assertCases(t, masker, []testCase{
		{input: "Contact: alice@example.com.", expected: "Contact: a****@example.com."},
		{input: "alice@example.com and bob@example.org", expected: "a****@example.com and b**@example.org"},
	})
}

func TestEmailEdgeCases(t *testing.T) {
	masker := New().MaskEmails()
	assertCases(t, masker, []testCase{
		{input: "alice@example", expected: "alice@example"},
		{input: "alice@localhost", expected: "alice@localhost"},
		{input: "alice@@example.com", expected: "alice@@example.com"},
		{input: "first.last+tag@sub.domain.com", expected: "f*************@sub.domain.com"},
	})
}

func TestPhoneBasicFormats(t *testing.T) {
	masker := New().MaskPhones()
	assertCases(t, masker, []testCase{
		{input: "090-1234-5678", expected: "***-****-5678"},
		{input: "Call (555) 123-4567", expected: "Call (***) ***-4567"},
		{input: "Intl: +81 3 1234 5678", expected: "Intl: +** * **** 5678"},
		{input: "+1 (800) 123-4567", expected: "+* (***) ***-4567"},
	})
}

func TestPhoneShortAndBoundaryLengths(t *testing.T) {
	masker := New().MaskPhones()
	assertCases(t, masker, []testCase{
		{input: "1234", expected: "1234"},
		{input: "12345", expected: "*2345"},
		{input: "12-3456", expected: "**-3456"},
	})
}

func TestPhoneMixedText(t *testing.T) {
	masker := New().MaskPhones()
	assertCases(t, masker, []testCase{
		{input: "Tel: 090-1234-5678 ext. 99", expected: "Tel: ***-****-5678 ext. 99"},
		{input: "Numbers: 111-2222 and 333-4444", expected: "Numbers: ***-2222 and ***-4444"},
	})
}

func TestPhoneEdgeCases(t *testing.T) {
	masker := New().MaskPhones()
	assertCases(t, masker, []testCase{
		{input: "abcdef", expected: "abcdef"},
		{input: "+", expected: "+"},
		{input: "(12) 345 678", expected: "(**) **5 678"},
	})
}

func TestCombinedMasking(t *testing.T) {
	masker := New().MaskEmails().MaskPhones()
	assertCases(t, masker, []testCase{
		{input: "Contact: alice@example.com or 090-1234-5678.", expected: "Contact: a****@example.com or ***-****-5678."},
		{input: "Email bob@example.org, phone +1 (800) 123-4567", expected: "Email b**@example.org, phone +* (***) ***-4567"},
	})
}

func TestCustomMaskCharacter(t *testing.T) {
	emailMasker := New().MaskEmails().WithMaskChar('#')
	phoneMasker := New().MaskPhones().WithMaskChar('#')
	combined := New().MaskEmails().MaskPhones().WithMaskChar('#')

	assertCases(t, emailMasker, []testCase{{input: "alice@example.com", expected: "a####@example.com"}})
	assertCases(t, phoneMasker, []testCase{{input: "090-1234-5678", expected: "###-####-5678"}})

	got := combined.Process("Contact: alice@example.com or 090-1234-5678.")
	want := "Contact: a####@example.com or ###-####-5678."
	if got != want {
		t.Fatalf("expected %q, got %q", want, got)
	}
}

func TestMaskerConfiguration(t *testing.T) {
	input := "alice@example.com 090-1234-5678"

	passthrough := New()
	if got := passthrough.Process(input); got != input {
		t.Fatalf("expected %q, got %q", input, got)
	}

	emailOnly := New().MaskEmails()
	if got := emailOnly.Process(input); got != "a****@example.com 090-1234-5678" {
		t.Fatalf("expected %q, got %q", "a****@example.com 090-1234-5678", got)
	}

	phoneOnly := New().MaskPhones()
	if got := phoneOnly.Process(input); got != "alice@example.com ***-****-5678" {
		t.Fatalf("expected %q, got %q", "alice@example.com ***-****-5678", got)
	}

	both := New().MaskEmails().MaskPhones()
	if got := both.Process(input); got != "a****@example.com ***-****-5678" {
		t.Fatalf("expected %q, got %q", "a****@example.com ***-****-5678", got)
	}
}

func TestNonASCIITextIsPreserved(t *testing.T) {
	masker := New().MaskEmails().MaskPhones()
	input := "連絡先: alice@example.com と 090-1234-5678"
	expected := "連絡先: a****@example.com と ***-****-5678"
	if got := masker.Process(input); got != expected {
		t.Fatalf("expected %q, got %q", expected, got)
	}
}
