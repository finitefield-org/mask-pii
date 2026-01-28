Red [
    Title: "mask-pii Red tests"
]

do %../mask-pii.red

failures: copy []

assert-equal: func [label [string!] actual [string!] expected [string!]][
    if actual <> expected [
        append failures rejoin [label " expected=" mold expected " actual=" mold actual]
    ]
]

; Email masking
masker: make-masker
masker/mask-emails
assert-equal "email basic" masker/process "alice@example.com" "a****@example.com"
assert-equal "email short local" masker/process "a@b.com" "*@b.com"
assert-equal "email two local" masker/process "ab@example.com" "a*@example.com"
assert-equal "email complex" masker/process "a.b+c_d@example.co.jp" "a******@example.co.jp"

assert-equal "email mixed 1" masker/process "Contact: alice@example.com." "Contact: a****@example.com."
assert-equal "email mixed 2" masker/process "alice@example.com and bob@example.org" "a****@example.com and b**@example.org"

assert-equal "email invalid 1" masker/process "alice@example" "alice@example"
assert-equal "email invalid 2" masker/process "alice@localhost" "alice@localhost"
assert-equal "email invalid 3" masker/process "alice@@example.com" "alice@@example.com"
assert-equal "email subdomain" masker/process "first.last+tag@sub.domain.com" "f*************@sub.domain.com"

; Phone masking
masker: make-masker
masker/mask-phones
assert-equal "phone jp" masker/process "090-1234-5678" "***-****-5678"
assert-equal "phone parens" masker/process "Call (555) 123-4567" "Call (***) ***-4567"
assert-equal "phone intl" masker/process "Intl: +81 3 1234 5678" "Intl: +** * **** 5678"
assert-equal "phone us" masker/process "+1 (800) 123-4567" "+* (***) ***-4567"

assert-equal "phone short 4" masker/process "1234" "1234"
assert-equal "phone short 5" masker/process "12345" "*2345"
assert-equal "phone mixed short" masker/process "12-3456" "**-3456"

assert-equal "phone mixed text" masker/process "Tel: 090-1234-5678 ext. 99" "Tel: ***-****-5678 ext. 99"
assert-equal "phone multiple" masker/process "Numbers: 111-2222 and 333-4444" "Numbers: ***-2222 and ***-4444"

assert-equal "phone invalid" masker/process "abcdef" "abcdef"
assert-equal "phone plus only" masker/process "+" "+"
assert-equal "phone edge" masker/process "(12) 345 678" "(**) **5 678"

; Combined masking
masker: make-masker
masker/mask-emails
masker/mask-phones
assert-equal "combined 1" masker/process "Contact: alice@example.com or 090-1234-5678." "Contact: a****@example.com or ***-****-5678."
assert-equal "combined 2" masker/process "Email bob@example.org, phone +1 (800) 123-4567" "Email b**@example.org, phone +* (***) ***-4567"

; Custom mask character
masker: make-masker
masker/mask-emails
masker/with-mask-char #"#"
assert-equal "custom email" masker/process "alice@example.com" "a####@example.com"

masker: make-masker
masker/mask-phones
masker/with-mask-char #"#"
assert-equal "custom phone" masker/process "090-1234-5678" "###-####-5678"

masker: make-masker
masker/mask-emails
masker/mask-phones
masker/with-mask-char #"#"
assert-equal "custom combined" masker/process "Contact: alice@example.com or 090-1234-5678." "Contact: a####@example.com or ###-####-5678."

; Configuration behavior
masker: make-masker
assert-equal "no masks" masker/process "alice@example.com 090-1234-5678" "alice@example.com 090-1234-5678"

masker: make-masker
masker/mask-emails
assert-equal "emails only" masker/process "alice@example.com 090-1234-5678" "a****@example.com 090-1234-5678"

masker: make-masker
masker/mask-phones
assert-equal "phones only" masker/process "alice@example.com 090-1234-5678" "alice@example.com ***-****-5678"

masker: make-masker
masker/mask-emails
masker/mask-phones
assert-equal "both masks" masker/process "alice@example.com 090-1234-5678" "a****@example.com ***-****-5678"

if empty? failures [
    print "All tests passed."
    quit/return 0
]

print "Failures:"
foreach failure failures [print failure]
quit/return 1
