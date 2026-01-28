use ../src/mask_pii.nu *

# Assert equality for test cases.
def assert_eq [label: string, expected: string, actual: string] {
  if $expected != $actual {
    error make {
      msg: $"($label) expected=($expected) actual=($actual)"
    }
  }
}

let base = (masker new)
let email_masker = ($base | mask_emails)
let phone_masker = ($base | mask_phones)
let both_masker = ($base | mask_emails | mask_phones)
let custom_masker = ($base | mask_emails | mask_phones | with_mask_char "#")

let email_cases = [
  { input: "alice@example.com" expected: "a****@example.com" }
  { input: "a@b.com" expected: "*@b.com" }
  { input: "ab@example.com" expected: "a*@example.com" }
  { input: "a.b+c_d@example.co.jp" expected: "a******@example.co.jp" }
  { input: "Contact: alice@example.com." expected: "Contact: a****@example.com." }
  { input: "alice@example.com and bob@example.org" expected: "a****@example.com and b**@example.org" }
  { input: "alice@example" expected: "alice@example" }
  { input: "alice@localhost" expected: "alice@localhost" }
  { input: "alice@@example.com" expected: "alice@@example.com" }
  { input: "first.last+tag@sub.domain.com" expected: "f*************@sub.domain.com" }
]

for case in $email_cases {
  let actual = ($email_masker | process $case.input)
  assert_eq "email" $case.expected $actual
}

let phone_cases = [
  { input: "090-1234-5678" expected: "***-****-5678" }
  { input: "Call (555) 123-4567" expected: "Call (***) ***-4567" }
  { input: "Intl: +81 3 1234 5678" expected: "Intl: +** * **** 5678" }
  { input: "+1 (800) 123-4567" expected: "+* (***) ***-4567" }
  { input: "1234" expected: "1234" }
  { input: "12345" expected: "*2345" }
  { input: "12-3456" expected: "**-3456" }
  { input: "Tel: 090-1234-5678 ext. 99" expected: "Tel: ***-****-5678 ext. 99" }
  { input: "Numbers: 111-2222 and 333-4444" expected: "Numbers: ***-2222 and ***-4444" }
  { input: "abcdef" expected: "abcdef" }
  { input: "+" expected: "+" }
  { input: "(12) 345 678" expected: "(**) **5 678" }
]

for case in $phone_cases {
  let actual = ($phone_masker | process $case.input)
  assert_eq "phone" $case.expected $actual
}

let combined_cases = [
  { input: "Contact: alice@example.com or 090-1234-5678." expected: "Contact: a****@example.com or ***-****-5678." }
  { input: "Email bob@example.org, phone +1 (800) 123-4567" expected: "Email b**@example.org, phone +* (***) ***-4567" }
]

for case in $combined_cases {
  let actual = ($both_masker | process $case.input)
  assert_eq "combined" $case.expected $actual
}

let custom_cases = [
  { input: "alice@example.com" expected: "a####@example.com" }
  { input: "090-1234-5678" expected: "###-####-5678" }
  { input: "Contact: alice@example.com or 090-1234-5678." expected: "Contact: a####@example.com or ###-####-5678." }
]

for case in $custom_cases {
  let actual = ($custom_masker | process $case.input)
  assert_eq "custom" $case.expected $actual
}

let no_mask = ($base | process "alice@example.com")
assert_eq "no-mask" "alice@example.com" $no_mask
