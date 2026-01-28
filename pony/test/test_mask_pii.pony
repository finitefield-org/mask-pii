use "ponytest"
use "path:../mask_pii"

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  fun tag tests(test: PonyTest) =>
    test(_EmailMasking)
    test(_PhoneMasking)
    test(_CombinedMasking)
    test(_CustomMaskChar)
    test(_ConfigurationBehavior)

class iso _EmailMasking is UnitTest
  fun name(): String => "email/masking"

  fun apply(h: TestHelper) =>
    let masker = Masker
    masker.mask_emails()

    h.assert_eq[String]("a****@example.com", masker.process("alice@example.com"))
    h.assert_eq[String]("*@b.com", masker.process("a@b.com"))
    h.assert_eq[String]("a*@example.com", masker.process("ab@example.com"))
    h.assert_eq[String]("a******@example.co.jp", masker.process("a.b+c_d@example.co.jp"))

    h.assert_eq[String]("Contact: a****@example.com.", masker.process("Contact: alice@example.com."))
    h.assert_eq[String]("a****@example.com and b**@example.org",
      masker.process("alice@example.com and bob@example.org"))

    h.assert_eq[String]("alice@example", masker.process("alice@example"))
    h.assert_eq[String]("alice@localhost", masker.process("alice@localhost"))
    h.assert_eq[String]("alice@@example.com", masker.process("alice@@example.com"))
    h.assert_eq[String]("f*************@sub.domain.com",
      masker.process("first.last+tag@sub.domain.com"))

class iso _PhoneMasking is UnitTest
  fun name(): String => "phone/masking"

  fun apply(h: TestHelper) =>
    let masker = Masker
    masker.mask_phones()

    h.assert_eq[String]("***-****-5678", masker.process("090-1234-5678"))
    h.assert_eq[String]("Call (***) ***-4567", masker.process("Call (555) 123-4567"))
    h.assert_eq[String]("Intl: +** * **** 5678", masker.process("Intl: +81 3 1234 5678"))
    h.assert_eq[String]("+* (***) ***-4567", masker.process("+1 (800) 123-4567"))

    h.assert_eq[String]("1234", masker.process("1234"))
    h.assert_eq[String]("*2345", masker.process("12345"))
    h.assert_eq[String]("**-3456", masker.process("12-3456"))

    h.assert_eq[String]("Tel: ***-****-5678 ext. 99",
      masker.process("Tel: 090-1234-5678 ext. 99"))
    h.assert_eq[String]("Numbers: ***-2222 and ***-4444",
      masker.process("Numbers: 111-2222 and 333-4444"))

    h.assert_eq[String]("abcdef", masker.process("abcdef"))
    h.assert_eq[String]("+", masker.process("+"))
    h.assert_eq[String]("(**) **5 678", masker.process("(12) 345 678"))

class iso _CombinedMasking is UnitTest
  fun name(): String => "combined/masking"

  fun apply(h: TestHelper) =>
    let masker = Masker
    masker.mask_emails()
    masker.mask_phones()

    h.assert_eq[String](
      "Contact: a****@example.com or ***-****-5678.",
      masker.process("Contact: alice@example.com or 090-1234-5678.")
    )
    h.assert_eq[String](
      "Email b**@example.org, phone +* (***) ***-4567",
      masker.process("Email bob@example.org, phone +1 (800) 123-4567")
    )

class iso _CustomMaskChar is UnitTest
  fun name(): String => "custom/mask_char"

  fun apply(h: TestHelper) =>
    let email_masker = Masker
    email_masker.mask_emails()
    email_masker.with_mask_char('#')

    let phone_masker = Masker
    phone_masker.mask_phones()
    phone_masker.with_mask_char('#')

    let combined = Masker
    combined.mask_emails()
    combined.mask_phones()
    combined.with_mask_char('#')

    h.assert_eq[String]("a####@example.com", email_masker.process("alice@example.com"))
    h.assert_eq[String]("###-####-5678", phone_masker.process("090-1234-5678"))
    h.assert_eq[String](
      "Contact: a####@example.com or ###-####-5678.",
      combined.process("Contact: alice@example.com or 090-1234-5678.")
    )

class iso _ConfigurationBehavior is UnitTest
  fun name(): String => "configuration/behavior"

  fun apply(h: TestHelper) =>
    let input = "Contact: alice@example.com or 090-1234-5678."

    let none = Masker
    h.assert_eq[String](input, none.process(input))

    let emails_only = Masker
    emails_only.mask_emails()
    h.assert_eq[String]("Contact: a****@example.com or 090-1234-5678.", emails_only.process(input))

    let phones_only = Masker
    phones_only.mask_phones()
    h.assert_eq[String]("Contact: alice@example.com or ***-****-5678.", phones_only.process(input))

    let both = Masker
    both.mask_emails()
    both.mask_phones()
    h.assert_eq[String]("Contact: a****@example.com or ***-****-5678.", both.process(input))
