#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$ROOT_DIR/mask_pii.sh"

fail_count=0

assert_eq() {
  local name="$1"
  local expected="$2"
  local actual="$3"

  if [[ "$expected" != "$actual" ]]; then
    printf 'FAIL: %s\nExpected: %s\nActual:   %s\n\n' "$name" "$expected" "$actual" >&2
    ((fail_count++))
  fi
}

run_email_tests() {
  mask_pii_new email_masker
  mask_pii_mask_emails email_masker

  assert_eq "email_basic_1" "a****@example.com" "$(mask_pii_process email_masker "alice@example.com")"
  assert_eq "email_basic_2" "*@b.com" "$(mask_pii_process email_masker "a@b.com")"
  assert_eq "email_basic_3" "a*@example.com" "$(mask_pii_process email_masker "ab@example.com")"
  assert_eq "email_basic_4" "a******@example.co.jp" "$(mask_pii_process email_masker "a.b+c_d@example.co.jp")"

  assert_eq "email_mixed_1" "Contact: a****@example.com." "$(mask_pii_process email_masker "Contact: alice@example.com.")"
  assert_eq "email_mixed_2" "a****@example.com and b**@example.org" "$(mask_pii_process email_masker "alice@example.com and bob@example.org")"

  assert_eq "email_edge_1" "alice@example" "$(mask_pii_process email_masker "alice@example")"
  assert_eq "email_edge_2" "alice@localhost" "$(mask_pii_process email_masker "alice@localhost")"
  assert_eq "email_edge_3" "alice@@example.com" "$(mask_pii_process email_masker "alice@@example.com")"
  assert_eq "email_edge_4" "f*************@sub.domain.com" "$(mask_pii_process email_masker "first.last+tag@sub.domain.com")"
}

run_phone_tests() {
  mask_pii_new phone_masker
  mask_pii_mask_phones phone_masker

  assert_eq "phone_basic_1" "***-****-5678" "$(mask_pii_process phone_masker "090-1234-5678")"
  assert_eq "phone_basic_2" "Call (***) ***-4567" "$(mask_pii_process phone_masker "Call (555) 123-4567")"
  assert_eq "phone_basic_3" "Intl: +** * **** 5678" "$(mask_pii_process phone_masker "Intl: +81 3 1234 5678")"
  assert_eq "phone_basic_4" "+* (***) ***-4567" "$(mask_pii_process phone_masker "+1 (800) 123-4567")"

  assert_eq "phone_short_1" "1234" "$(mask_pii_process phone_masker "1234")"
  assert_eq "phone_short_2" "*2345" "$(mask_pii_process phone_masker "12345")"
  assert_eq "phone_short_3" "**-3456" "$(mask_pii_process phone_masker "12-3456")"

  assert_eq "phone_mixed_1" "Tel: ***-****-5678 ext. 99" "$(mask_pii_process phone_masker "Tel: 090-1234-5678 ext. 99")"
  assert_eq "phone_mixed_2" "Numbers: ***-2222 and ***-4444" "$(mask_pii_process phone_masker "Numbers: 111-2222 and 333-4444")"

  assert_eq "phone_edge_1" "abcdef" "$(mask_pii_process phone_masker "abcdef")"
  assert_eq "phone_edge_2" "+" "$(mask_pii_process phone_masker "+")"
  assert_eq "phone_edge_3" "(**) **5 678" "$(mask_pii_process phone_masker "(12) 345 678")"
}

run_combined_tests() {
  mask_pii_new combined_masker
  mask_pii_mask_emails combined_masker
  mask_pii_mask_phones combined_masker

  assert_eq "combined_1" "Contact: a****@example.com or ***-****-5678." "$(mask_pii_process combined_masker "Contact: alice@example.com or 090-1234-5678.")"
  assert_eq "combined_2" "Email b**@example.org, phone +* (***) ***-4567" "$(mask_pii_process combined_masker "Email bob@example.org, phone +1 (800) 123-4567")"
}

run_custom_mask_tests() {
  mask_pii_new custom_email
  mask_pii_mask_emails custom_email
  mask_pii_with_mask_char custom_email '#'
  assert_eq "custom_email" "a####@example.com" "$(mask_pii_process custom_email "alice@example.com")"

  mask_pii_new custom_phone
  mask_pii_mask_phones custom_phone
  mask_pii_with_mask_char custom_phone '#'
  assert_eq "custom_phone" "###-####-5678" "$(mask_pii_process custom_phone "090-1234-5678")"

  mask_pii_new custom_combined
  mask_pii_mask_emails custom_combined
  mask_pii_mask_phones custom_combined
  mask_pii_with_mask_char custom_combined '#'
  assert_eq "custom_combined" "Contact: a####@example.com or ###-####-5678." "$(mask_pii_process custom_combined "Contact: alice@example.com or 090-1234-5678.")"
}

run_configuration_tests() {
  mask_pii_new empty_masker
  assert_eq "config_none" "Contact: alice@example.com or 090-1234-5678." "$(mask_pii_process empty_masker "Contact: alice@example.com or 090-1234-5678.")"

  mask_pii_new email_only
  mask_pii_mask_emails email_only
  assert_eq "config_email_only" "Contact: a****@example.com or 090-1234-5678." "$(mask_pii_process email_only "Contact: alice@example.com or 090-1234-5678.")"

  mask_pii_new phone_only
  mask_pii_mask_phones phone_only
  assert_eq "config_phone_only" "Contact: alice@example.com or ***-****-5678." "$(mask_pii_process phone_only "Contact: alice@example.com or 090-1234-5678.")"

  mask_pii_new both
  mask_pii_mask_emails both
  mask_pii_mask_phones both
  assert_eq "config_both" "Contact: a****@example.com or ***-****-5678." "$(mask_pii_process both "Contact: alice@example.com or 090-1234-5678.")"
}

run_email_tests
run_phone_tests
run_combined_tests
run_custom_mask_tests
run_configuration_tests

if (( fail_count > 0 )); then
  printf '%d test(s) failed.\n' "$fail_count" >&2
  exit 1
fi

echo "All tests passed."
