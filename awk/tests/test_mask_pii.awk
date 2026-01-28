# Test suite for mask_pii.awk

function assert_equal(label, actual, expected) {
  if (actual != expected) {
    print "FAIL: " label
    print "  expected: " expected
    print "  actual  : " actual
    failures++
  }
}

BEGIN {
  failures = 0

  # Email masking basic cases
  mask_pii_new(masker)
  mask_pii_mask_emails(masker)
  assert_equal("email alice@example.com", mask_pii_process(masker, "alice@example.com"), "a****@example.com")
  assert_equal("email a@b.com", mask_pii_process(masker, "a@b.com"), "*@b.com")
  assert_equal("email ab@example.com", mask_pii_process(masker, "ab@example.com"), "a*@example.com")
  assert_equal("email a.b+c_d@example.co.jp", mask_pii_process(masker, "a.b+c_d@example.co.jp"), "a******@example.co.jp")

  # Email masking mixed text
  mask_pii_new(masker)
  mask_pii_mask_emails(masker)
  assert_equal("email mixed punctuation", mask_pii_process(masker, "Contact: alice@example.com."), "Contact: a****@example.com.")
  assert_equal("email mixed multiple", mask_pii_process(masker, "alice@example.com and bob@example.org"), "a****@example.com and b**@example.org")

  # Email masking edge cases
  mask_pii_new(masker)
  mask_pii_mask_emails(masker)
  assert_equal("email no tld", mask_pii_process(masker, "alice@example"), "alice@example")
  assert_equal("email localhost", mask_pii_process(masker, "alice@localhost"), "alice@localhost")
  assert_equal("email double at", mask_pii_process(masker, "alice@@example.com"), "alice@@example.com")
  assert_equal("email long tag", mask_pii_process(masker, "first.last+tag@sub.domain.com"), "f*************@sub.domain.com")

  # Phone masking basic cases
  mask_pii_new(masker)
  mask_pii_mask_phones(masker)
  assert_equal("phone 090", mask_pii_process(masker, "090-1234-5678"), "***-****-5678")
  assert_equal("phone parens", mask_pii_process(masker, "Call (555) 123-4567"), "Call (***) ***-4567")
  assert_equal("phone intl", mask_pii_process(masker, "Intl: +81 3 1234 5678"), "Intl: +** * **** 5678")
  assert_equal("phone +1", mask_pii_process(masker, "+1 (800) 123-4567"), "+* (***) ***-4567")

  # Phone masking short numbers
  mask_pii_new(masker)
  mask_pii_mask_phones(masker)
  assert_equal("phone 1234", mask_pii_process(masker, "1234"), "1234")
  assert_equal("phone 12345", mask_pii_process(masker, "12345"), "*2345")
  assert_equal("phone 12-3456", mask_pii_process(masker, "12-3456"), "**-3456")

  # Phone masking mixed text
  mask_pii_new(masker)
  mask_pii_mask_phones(masker)
  assert_equal("phone ext", mask_pii_process(masker, "Tel: 090-1234-5678 ext. 99"), "Tel: ***-****-5678 ext. 99")
  assert_equal("phone multiple", mask_pii_process(masker, "Numbers: 111-2222 and 333-4444"), "Numbers: ***-2222 and ***-4444")

  # Phone masking edge cases
  mask_pii_new(masker)
  mask_pii_mask_phones(masker)
  assert_equal("phone no match", mask_pii_process(masker, "abcdef"), "abcdef")
  assert_equal("phone plus", mask_pii_process(masker, "+"), "+")
  assert_equal("phone parentheses", mask_pii_process(masker, "(12) 345 678"), "(**) **5 678")

  # Combined masking
  mask_pii_new(masker)
  mask_pii_mask_emails(masker)
  mask_pii_mask_phones(masker)
  assert_equal("combined", mask_pii_process(masker, "Contact: alice@example.com or 090-1234-5678."), "Contact: a****@example.com or ***-****-5678.")
  assert_equal("combined order", mask_pii_process(masker, "Email bob@example.org, phone +1 (800) 123-4567"), "Email b**@example.org, phone +* (***) ***-4567")

  # Custom mask character
  mask_pii_new(masker)
  mask_pii_mask_emails(masker)
  mask_pii_with_mask_char(masker, "#")
  assert_equal("custom email", mask_pii_process(masker, "alice@example.com"), "a####@example.com")

  mask_pii_new(masker)
  mask_pii_mask_phones(masker)
  mask_pii_with_mask_char(masker, "#")
  assert_equal("custom phone", mask_pii_process(masker, "090-1234-5678"), "###-####-5678")

  mask_pii_new(masker)
  mask_pii_mask_emails(masker)
  mask_pii_mask_phones(masker)
  mask_pii_with_mask_char(masker, "#")
  assert_equal("custom combined", mask_pii_process(masker, "Contact: alice@example.com or 090-1234-5678."), "Contact: a####@example.com or ###-####-5678.")

  # Masker configuration behavior
  mask_pii_new(masker)
  assert_equal("no masks", mask_pii_process(masker, "alice@example.com"), "alice@example.com")

  mask_pii_new(masker)
  mask_pii_mask_emails(masker)
  assert_equal("emails only", mask_pii_process(masker, "alice@example.com or 090-1234-5678"), "a****@example.com or 090-1234-5678")

  mask_pii_new(masker)
  mask_pii_mask_phones(masker)
  assert_equal("phones only", mask_pii_process(masker, "alice@example.com or 090-1234-5678"), "alice@example.com or ***-****-5678")

  mask_pii_new(masker)
  mask_pii_mask_emails(masker)
  mask_pii_mask_phones(masker)
  assert_equal("emails + phones", mask_pii_process(masker, "alice@example.com or 090-1234-5678"), "a****@example.com or ***-****-5678")

  # Non-ASCII preservation
  mask_pii_new(masker)
  mask_pii_mask_emails(masker)
  assert_equal("non-ascii", mask_pii_process(masker, "こんにちは alice@example.com"), "こんにちは a****@example.com")

  if (failures > 0) {
    print failures " tests failed."
    exit 1
  }
  print "All tests passed."
}
