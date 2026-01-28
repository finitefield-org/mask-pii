#!/usr/bin/env fish

set -l script_dir (dirname (status --current-filename))
set -l root_dir (cd "$script_dir/.."; pwd)
set -l functions_dir "$root_dir/functions"

set -g fish_function_path $functions_dir $fish_function_path
source "$functions_dir/mask_pii.fish"

function assert_equal
    set -l expected $argv[1]
    set -l actual $argv[2]
    set -l label $argv[3]
    if test "$expected" != "$actual"
        echo "FAIL: $label"
        echo "  expected: $expected"
        echo "  actual  : $actual"
        exit 1
    end
end

# Email masking
assert_equal "a****@example.com" (mask_pii --emails "alice@example.com") "email basic"
assert_equal "*@b.com" (mask_pii --emails "a@b.com") "email short local"
assert_equal "a*@example.com" (mask_pii --emails "ab@example.com") "email two chars"
assert_equal "a******@example.co.jp" (mask_pii --emails "a.b+c_d@example.co.jp") "email symbols"

assert_equal "Contact: a****@example.com." (mask_pii --emails "Contact: alice@example.com.") "email mixed text"
assert_equal "a****@example.com and b**@example.org" (mask_pii --emails "alice@example.com and bob@example.org") "email multiple"

assert_equal "alice@example" (mask_pii --emails "alice@example") "email invalid domain"
assert_equal "alice@localhost" (mask_pii --emails "alice@localhost") "email localhost"
assert_equal "alice@@example.com" (mask_pii --emails "alice@@example.com") "email double at"
assert_equal "f*************@sub.domain.com" (mask_pii --emails "first.last+tag@sub.domain.com") "email subdomain"

# Phone masking
assert_equal "***-****-5678" (mask_pii --phones "090-1234-5678") "phone basic"
assert_equal "Call (***) ***-4567" (mask_pii --phones "Call (555) 123-4567") "phone parentheses"
assert_equal "Intl: +** * **** 5678" (mask_pii --phones "Intl: +81 3 1234 5678") "phone intl"
assert_equal "+* (***) ***-4567" (mask_pii --phones "+1 (800) 123-4567") "phone intl 2"

assert_equal "1234" (mask_pii --phones "1234") "phone short"
assert_equal "*2345" (mask_pii --phones "12345") "phone 5 digits"
assert_equal "**-3456" (mask_pii --phones "12-3456") "phone hyphen"

assert_equal "Tel: ***-****-5678 ext. 99" (mask_pii --phones "Tel: 090-1234-5678 ext. 99") "phone mixed text"
assert_equal "Numbers: ***-2222 and ***-4444" (mask_pii --phones "Numbers: 111-2222 and 333-4444") "phone multiple"

assert_equal "abcdef" (mask_pii --phones "abcdef") "phone no match"
assert_equal "+" (mask_pii --phones "+") "phone plus only"
assert_equal "(**) **5 678" (mask_pii --phones "(12) 345 678") "phone edge"

# Combined masking
assert_equal "Contact: a****@example.com or ***-****-5678." (mask_pii --emails --phones "Contact: alice@example.com or 090-1234-5678.") "combined"
assert_equal "Email b**@example.org, phone +* (***) ***-4567" (mask_pii --emails --phones "Email bob@example.org, phone +1 (800) 123-4567") "combined 2"

# Custom mask character
assert_equal "a####@example.com" (mask_pii --emails --mask-char '#' "alice@example.com") "mask char email"
assert_equal "###-####-5678" (mask_pii --phones --mask-char '#' "090-1234-5678") "mask char phone"
assert_equal "Contact: a####@example.com or ###-####-5678." (mask_pii --emails --phones --mask-char '#' "Contact: alice@example.com or 090-1234-5678.") "mask char combined"

# Configuration behavior
assert_equal "alice@example.com" (mask_pii "alice@example.com") "no mask"
assert_equal "a****@example.com" (mask_pii --emails "alice@example.com") "emails only"
assert_equal "***-****-5678" (mask_pii --phones "090-1234-5678") "phones only"

# Non-ASCII preservation
assert_equal "こんにちは a****@example.com" (mask_pii --emails "こんにちは alice@example.com") "unicode preserved"

echo "OK"
