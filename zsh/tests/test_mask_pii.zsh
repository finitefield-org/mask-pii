#!/usr/bin/env zsh

set -euo pipefail
set +v
set +x

SCRIPT_DIR=${0:A:h}
source "$SCRIPT_DIR/../mask-pii.plugin.zsh"

assert_equal() {
  local expected=$1
  local actual=$2
  local message=$3
  if [[ $expected != $actual ]]; then
    print -r -- "FAIL: $message" >&2
    print -r -- "  expected: $expected" >&2
    print -r -- "  actual:   $actual" >&2
    return 1
  fi
}

assert_cases() {
  local name=$1
  shift
  local -a cases
  cases=($@)
  local i=1
  while (( i <= ${#cases} )); do
    local input=${cases[i]}
    local expected=${cases[i+1]}
    local actual
    actual=$(mask_pii_process "$name" "$input")
    assert_equal "$expected" "$actual" "case: $input"
    ((i+=2))
  done
}

masker_email=()
mask_pii_new masker_email
mask_pii_mask_emails masker_email

assert_cases masker_email \
  "alice@example.com" "a****@example.com" \
  "a@b.com" "*@b.com" \
  "ab@example.com" "a*@example.com" \
  "a.b+c_d@example.co.jp" "a******@example.co.jp"

assert_cases masker_email \
  "Contact: alice@example.com." "Contact: a****@example.com." \
  "alice@example.com and bob@example.org" "a****@example.com and b**@example.org"

assert_cases masker_email \
  "alice@example" "alice@example" \
  "alice@localhost" "alice@localhost" \
  "alice@@example.com" "alice@@example.com" \
  "first.last+tag@sub.domain.com" "f*************@sub.domain.com"

masker_phone=()
mask_pii_new masker_phone
mask_pii_mask_phones masker_phone

assert_cases masker_phone \
  "090-1234-5678" "***-****-5678" \
  "Call (555) 123-4567" "Call (***) ***-4567" \
  "Intl: +81 3 1234 5678" "Intl: +** * **** 5678" \
  "+1 (800) 123-4567" "+* (***) ***-4567"

assert_cases masker_phone \
  "1234" "1234" \
  "12345" "*2345" \
  "12-3456" "**-3456"

assert_cases masker_phone \
  "Tel: 090-1234-5678 ext. 99" "Tel: ***-****-5678 ext. 99" \
  "Numbers: 111-2222 and 333-4444" "Numbers: ***-2222 and ***-4444"

assert_cases masker_phone \
  "abcdef" "abcdef" \
  "+" "+" \
  "(12) 345 678" "(**) **5 678"

masker_both=()
mask_pii_new masker_both
mask_pii_mask_emails masker_both
mask_pii_mask_phones masker_both

assert_cases masker_both \
  "Contact: alice@example.com or 090-1234-5678." "Contact: a****@example.com or ***-****-5678." \
  "Email bob@example.org, phone +1 (800) 123-4567" "Email b**@example.org, phone +* (***) ***-4567"

masker_email_hash=()
mask_pii_new masker_email_hash
mask_pii_mask_emails masker_email_hash
mask_pii_with_mask_char masker_email_hash "#"

masker_phone_hash=()
mask_pii_new masker_phone_hash
mask_pii_mask_phones masker_phone_hash
mask_pii_with_mask_char masker_phone_hash "#"

masker_combined_hash=()
mask_pii_new masker_combined_hash
mask_pii_mask_emails masker_combined_hash
mask_pii_mask_phones masker_combined_hash
mask_pii_with_mask_char masker_combined_hash "#"

assert_cases masker_email_hash \
  "alice@example.com" "a####@example.com"

assert_cases masker_phone_hash \
  "090-1234-5678" "###-####-5678"

assert_equal \
  "Contact: a####@example.com or ###-####-5678." \
  "$(mask_pii_process masker_combined_hash "Contact: alice@example.com or 090-1234-5678.")" \
  "custom mask character combined"

masker_none=()
mask_pii_new masker_none
input="alice@example.com 090-1234-5678"
assert_equal "$input" "$(mask_pii_process masker_none "$input")" "no masks enabled"

masker_email_only=()
mask_pii_new masker_email_only
mask_pii_mask_emails masker_email_only
assert_equal "a****@example.com 090-1234-5678" "$(mask_pii_process masker_email_only "$input")" "email only"

masker_phone_only=()
mask_pii_new masker_phone_only
mask_pii_mask_phones masker_phone_only
assert_equal "alice@example.com ***-****-5678" "$(mask_pii_process masker_phone_only "$input")" "phone only"

masker_both_again=()
mask_pii_new masker_both_again
mask_pii_mask_emails masker_both_again
mask_pii_mask_phones masker_both_again
assert_equal "a****@example.com ***-****-5678" "$(mask_pii_process masker_both_again "$input")" "both"

masker_unicode=()
mask_pii_new masker_unicode
mask_pii_mask_emails masker_unicode
mask_pii_mask_phones masker_unicode
assert_equal \
  "連絡先: a****@example.com と ***-****-5678" \
  "$(mask_pii_process masker_unicode "連絡先: alice@example.com と 090-1234-5678")" \
  "non-ascii preservation"

print -r -- "All Zsh tests passed."
