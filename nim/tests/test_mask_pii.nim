import unittest
import mask_pii

proc applyMask(inputText: string; maskEmails = false; maskPhones = false; maskChar: char = '*'): string =
  var masker = newMasker()
  if maskEmails:
    discard masker.maskEmails()
  if maskPhones:
    discard masker.maskPhones()
  discard masker.withMaskChar(maskChar)
  masker.process(inputText)

suite "Masker configuration behavior":
  test "no masks enabled returns input unchanged":
    check newMasker().process("Contact: alice@example.com") == "Contact: alice@example.com"

  test "mask emails only":
    check applyMask("alice@example.com", maskEmails = true) == "a****@example.com"

  test "mask phones only":
    check applyMask("090-1234-5678", maskPhones = true) == "***-****-5678"

  test "mask emails and phones":
    let inputText = "Contact: alice@example.com or 090-1234-5678."
    let expected = "Contact: a****@example.com or ***-****-5678."
    check applyMask(inputText, maskEmails = true, maskPhones = true) == expected

suite "Email masking":
  test "basic cases":
    check applyMask("alice@example.com", maskEmails = true) == "a****@example.com"
    check applyMask("a@b.com", maskEmails = true) == "*@b.com"
    check applyMask("ab@example.com", maskEmails = true) == "a*@example.com"
    check applyMask("a.b+c_d@example.co.jp", maskEmails = true) == "a******@example.co.jp"

  test "mixed text":
    check applyMask("Contact: alice@example.com.", maskEmails = true) == "Contact: a****@example.com."
    check applyMask("alice@example.com and bob@example.org", maskEmails = true) == "a****@example.com and b**@example.org"

  test "edge cases":
    check applyMask("alice@example", maskEmails = true) == "alice@example"
    check applyMask("alice@localhost", maskEmails = true) == "alice@localhost"
    check applyMask("alice@@example.com", maskEmails = true) == "alice@@example.com"
    check applyMask("first.last+tag@sub.domain.com", maskEmails = true) == "f*************@sub.domain.com"

suite "Phone masking":
  test "basic international formats":
    check applyMask("090-1234-5678", maskPhones = true) == "***-****-5678"
    check applyMask("Call (555) 123-4567", maskPhones = true) == "Call (***) ***-4567"
    check applyMask("Intl: +81 3 1234 5678", maskPhones = true) == "Intl: +** * **** 5678"
    check applyMask("+1 (800) 123-4567", maskPhones = true) == "+* (***) ***-4567"

  test "short numbers and boundary lengths":
    check applyMask("1234", maskPhones = true) == "1234"
    check applyMask("12345", maskPhones = true) == "*2345"
    check applyMask("12-3456", maskPhones = true) == "**-3456"

  test "mixed text":
    check applyMask("Tel: 090-1234-5678 ext. 99", maskPhones = true) == "Tel: ***-****-5678 ext. 99"
    check applyMask("Numbers: 111-2222 and 333-4444", maskPhones = true) == "Numbers: ***-2222 and ***-4444"

  test "edge cases":
    check applyMask("abcdef", maskPhones = true) == "abcdef"
    check applyMask("+", maskPhones = true) == "+"
    check applyMask("(12) 345 678", maskPhones = true) == "(**) **5 678"

suite "Custom mask character":
  test "custom char for emails":
    check applyMask("alice@example.com", maskEmails = true, maskChar = '#') == "a####@example.com"

  test "custom char for phones":
    check applyMask("090-1234-5678", maskPhones = true, maskChar = '#') == "###-####-5678"

  test "custom char for both":
    let inputText = "Contact: alice@example.com or 090-1234-5678."
    let expected = "Contact: a####@example.com or ###-####-5678."
    check applyMask(inputText, maskEmails = true, maskPhones = true, maskChar = '#') == expected
