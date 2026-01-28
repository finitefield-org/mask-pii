library(testthat)

new_masker <- function() {
  Masker()
}

test_that("email masking basic cases", {
  masker <- new_masker()$mask_emails()

  expect_equal(masker$process("alice@example.com"), "a****@example.com")
  expect_equal(masker$process("a@b.com"), "*@b.com")
  expect_equal(masker$process("ab@example.com"), "a*@example.com")
  expect_equal(masker$process("a.b+c_d@example.co.jp"), "a******@example.co.jp")
})

test_that("email masking mixed text", {
  masker <- new_masker()$mask_emails()

  expect_equal(masker$process("Contact: alice@example.com."), "Contact: a****@example.com.")
  expect_equal(
    masker$process("alice@example.com and bob@example.org"),
    "a****@example.com and b**@example.org"
  )
})

test_that("email masking edge cases", {
  masker <- new_masker()$mask_emails()

  expect_equal(masker$process("alice@example"), "alice@example")
  expect_equal(masker$process("alice@localhost"), "alice@localhost")
  expect_equal(masker$process("alice@@example.com"), "alice@@example.com")
  expect_equal(
    masker$process("first.last+tag@sub.domain.com"),
    "f*************@sub.domain.com"
  )
})

test_that("phone masking basic cases", {
  masker <- new_masker()$mask_phones()

  expect_equal(masker$process("090-1234-5678"), "***-****-5678")
  expect_equal(masker$process("Call (555) 123-4567"), "Call (***) ***-4567")
  expect_equal(masker$process("Intl: +81 3 1234 5678"), "Intl: +** * **** 5678")
  expect_equal(masker$process("+1 (800) 123-4567"), "+* (***) ***-4567")
})

test_that("phone masking short and boundary cases", {
  masker <- new_masker()$mask_phones()

  expect_equal(masker$process("1234"), "1234")
  expect_equal(masker$process("12345"), "*2345")
  expect_equal(masker$process("12-3456"), "**-3456")
})

test_that("phone masking mixed text", {
  masker <- new_masker()$mask_phones()

  expect_equal(
    masker$process("Tel: 090-1234-5678 ext. 99"),
    "Tel: ***-****-5678 ext. 99"
  )
  expect_equal(
    masker$process("Numbers: 111-2222 and 333-4444"),
    "Numbers: ***-2222 and ***-4444"
  )
})

test_that("phone masking edge cases", {
  masker <- new_masker()$mask_phones()

  expect_equal(masker$process("abcdef"), "abcdef")
  expect_equal(masker$process("+"), "+")
  expect_equal(masker$process("(12) 345 678"), "(**) **5 678")
})

test_that("combined masking", {
  masker <- new_masker()$mask_emails()$mask_phones()

  expect_equal(
    masker$process("Contact: alice@example.com or 090-1234-5678."),
    "Contact: a****@example.com or ***-****-5678."
  )
  expect_equal(
    masker$process("Email bob@example.org, phone +1 (800) 123-4567"),
    "Email b**@example.org, phone +* (***) ***-4567"
  )
})

test_that("custom mask character", {
  masker <- new_masker()$mask_emails()$with_mask_char("#")
  expect_equal(masker$process("alice@example.com"), "a####@example.com")

  masker <- new_masker()$mask_phones()$with_mask_char("#")
  expect_equal(masker$process("090-1234-5678"), "###-####-5678")

  masker <- new_masker()$mask_emails()$mask_phones()$with_mask_char("#")
  expect_equal(
    masker$process("Contact: alice@example.com or 090-1234-5678."),
    "Contact: a####@example.com or ###-####-5678."
  )
})

test_that("masker configuration behavior", {
  input_text <- "Contact: alice@example.com or 090-1234-5678."

  masker <- new_masker()
  expect_equal(masker$process(input_text), input_text)

  expect_equal(
    new_masker()$mask_emails()$process(input_text),
    "Contact: a****@example.com or 090-1234-5678."
  )

  expect_equal(
    new_masker()$mask_phones()$process(input_text),
    "Contact: alice@example.com or ***-****-5678."
  )
})
