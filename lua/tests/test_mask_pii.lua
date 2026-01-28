local function script_dir()
  local info = debug.getinfo(1, "S")
  local source = info.source
  if source:sub(1, 1) == "@" then
    source = source:sub(2)
  end
  return source:match("(.*/)") or "./"
end

local root = script_dir() .. "../"
package.path = root .. "src/?.lua;" .. root .. "src/?/init.lua;" .. package.path

local mask_pii = require("mask_pii")
local Masker = mask_pii.Masker

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    local prefix = message or "assertion failed"
    error(prefix .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
  end
end

local function assert_cases(masker, cases)
  for _, case in ipairs(cases) do
    local input_text = case[1]
    local expected = case[2]
    local got = masker:process(input_text)
    assert_equal(got, expected, "case failed for input: " .. input_text)
  end
end

local function run()
  local masker

  masker = Masker.new():mask_emails()
  assert_cases(masker, {
    { "alice@example.com", "a****@example.com" },
    { "a@b.com", "*@b.com" },
    { "ab@example.com", "a*@example.com" },
    { "a.b+c_d@example.co.jp", "a******@example.co.jp" },
  })

  masker = Masker.new():mask_emails()
  assert_cases(masker, {
    { "Contact: alice@example.com.", "Contact: a****@example.com." },
    { "alice@example.com and bob@example.org", "a****@example.com and b**@example.org" },
  })

  masker = Masker.new():mask_emails()
  assert_cases(masker, {
    { "alice@example", "alice@example" },
    { "alice@localhost", "alice@localhost" },
    { "alice@@example.com", "alice@@example.com" },
    { "first.last+tag@sub.domain.com", "f*************@sub.domain.com" },
  })

  masker = Masker.new():mask_phones()
  assert_cases(masker, {
    { "090-1234-5678", "***-****-5678" },
    { "Call (555) 123-4567", "Call (***) ***-4567" },
    { "Intl: +81 3 1234 5678", "Intl: +** * **** 5678" },
    { "+1 (800) 123-4567", "+* (***) ***-4567" },
  })

  masker = Masker.new():mask_phones()
  assert_cases(masker, {
    { "1234", "1234" },
    { "12345", "*2345" },
    { "12-3456", "**-3456" },
  })

  masker = Masker.new():mask_phones()
  assert_cases(masker, {
    { "Tel: 090-1234-5678 ext. 99", "Tel: ***-****-5678 ext. 99" },
    { "Numbers: 111-2222 and 333-4444", "Numbers: ***-2222 and ***-4444" },
  })

  masker = Masker.new():mask_phones()
  assert_cases(masker, {
    { "abcdef", "abcdef" },
    { "+", "+" },
    { "(12) 345 678", "(**) **5 678" },
  })

  masker = Masker.new():mask_emails():mask_phones()
  assert_cases(masker, {
    { "Contact: alice@example.com or 090-1234-5678.", "Contact: a****@example.com or ***-****-5678." },
    { "Email bob@example.org, phone +1 (800) 123-4567", "Email b**@example.org, phone +* (***) ***-4567" },
  })

  local email_masker = Masker.new():mask_emails():with_mask_char("#")
  local phone_masker = Masker.new():mask_phones():with_mask_char("#")
  local combined = Masker.new():mask_emails():mask_phones():with_mask_char("#")

  assert_cases(email_masker, { { "alice@example.com", "a####@example.com" } })
  assert_cases(phone_masker, { { "090-1234-5678", "###-####-5678" } })

  assert_equal(
    combined:process("Contact: alice@example.com or 090-1234-5678."),
    "Contact: a####@example.com or ###-####-5678.",
    "combined mask char"
  )

  local input_text = "alice@example.com 090-1234-5678"
  local passthrough = Masker.new()
  assert_equal(passthrough:process(input_text), input_text, "masker default config")

  local email_only = Masker.new():mask_emails()
  assert_equal(email_only:process(input_text), "a****@example.com 090-1234-5678", "email only")

  local phone_only = Masker.new():mask_phones()
  assert_equal(phone_only:process(input_text), "alice@example.com ***-****-5678", "phone only")

  local both = Masker.new():mask_emails():mask_phones()
  assert_equal(both:process(input_text), "a****@example.com ***-****-5678", "both")

  local non_ascii = "連絡先: alice@example.com と 090-1234-5678"
  local expected = "連絡先: a****@example.com と ***-****-5678"
  assert_equal(both:process(non_ascii), expected, "non-ascii")
end

run()
print("All tests passed.")
