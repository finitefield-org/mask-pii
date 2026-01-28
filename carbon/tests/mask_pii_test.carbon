package MaskPII;

/// Asserts that two strings are equal.
fn AssertEqual(expected: String, actual: String) {
  Assert(expected == actual);
}

/// Runs the mask-pii cross-language test suite.
fn Main() {
  // Email masking
  var masker: Masker = New().MaskEmails();
  AssertEqual("a****@example.com", masker.Process("alice@example.com"));
  AssertEqual("*@b.com", masker.Process("a@b.com"));
  AssertEqual("a*@example.com", masker.Process("ab@example.com"));
  AssertEqual("a******@example.co.jp", masker.Process("a.b+c_d@example.co.jp"));
  AssertEqual("Contact: a****@example.com.", masker.Process("Contact: alice@example.com."));
  AssertEqual(
    "a****@example.com and b**@example.org",
    masker.Process("alice@example.com and bob@example.org")
  );
  AssertEqual("alice@example", masker.Process("alice@example"));
  AssertEqual("alice@localhost", masker.Process("alice@localhost"));
  AssertEqual("alice@@example.com", masker.Process("alice@@example.com"));
  AssertEqual(
    "f*************@sub.domain.com",
    masker.Process("first.last+tag@sub.domain.com")
  );

  // Phone masking
  masker = New().MaskPhones();
  AssertEqual("***-****-5678", masker.Process("090-1234-5678"));
  AssertEqual("Call (***) ***-4567", masker.Process("Call (555) 123-4567"));
  AssertEqual("Intl: +** * **** 5678", masker.Process("Intl: +81 3 1234 5678"));
  AssertEqual("+* (***) ***-4567", masker.Process("+1 (800) 123-4567"));
  AssertEqual("1234", masker.Process("1234"));
  AssertEqual("*2345", masker.Process("12345"));
  AssertEqual("**-3456", masker.Process("12-3456"));
  AssertEqual("Tel: ***-****-5678 ext. 99", masker.Process("Tel: 090-1234-5678 ext. 99"));
  AssertEqual(
    "Numbers: ***-2222 and ***-4444",
    masker.Process("Numbers: 111-2222 and 333-4444")
  );
  AssertEqual("abcdef", masker.Process("abcdef"));
  AssertEqual("+", masker.Process("+"));
  AssertEqual("(**) **5 678", masker.Process("(12) 345 678"));

  // Combined masking
  masker = New().MaskEmails().MaskPhones();
  AssertEqual(
    "Contact: a****@example.com or ***-****-5678.",
    masker.Process("Contact: alice@example.com or 090-1234-5678.")
  );
  AssertEqual(
    "Email b**@example.org, phone +* (***) ***-4567",
    masker.Process("Email bob@example.org, phone +1 (800) 123-4567")
  );

  // Custom mask character
  masker = New().MaskEmails().WithMaskChar('#');
  AssertEqual("a####@example.com", masker.Process("alice@example.com"));
  masker = New().MaskPhones().WithMaskChar('#');
  AssertEqual("###-####-5678", masker.Process("090-1234-5678"));
  masker = New().MaskEmails().MaskPhones().WithMaskChar('#');
  AssertEqual(
    "Contact: a####@example.com or ###-####-5678.",
    masker.Process("Contact: alice@example.com or 090-1234-5678.")
  );

  // Configuration behavior
  AssertEqual("no changes", New().Process("no changes"));
  AssertEqual("a****@example.com", New().MaskEmails().Process("alice@example.com"));
  AssertEqual("***-****-5678", New().MaskPhones().Process("090-1234-5678"));
  AssertEqual(
    "a****@example.com and ***-****-5678",
    New().MaskEmails().MaskPhones().Process("alice@example.com and 090-1234-5678")
  );
}
