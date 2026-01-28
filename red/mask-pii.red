Red [
    Title: "mask-pii"
    Name: "mask-pii"
    Type: 'library
    Version: 0.2.0
    Author: "Finite Field, K.K."
    Home: "https://finitefield.org/en/oss/mask-pii"
    Repository: "https://github.com/finitefield-org/mask-pii"
    Issues: "https://github.com/finitefield-org/mask-pii/issues"
    License: "MIT"
    Keywords: ["pii" "masking" "email" "phone" "privacy"]
    File: %mask-pii.red
]

; make-masker creates a new masker with all masks disabled by default.
make-masker: func [/local masker][
    masker: context [
        mask-email?: false
        mask-phone?: false
        mask-char: #"*"

        ; mask-emails enables email address masking.
        mask-emails: func [/local][
            mask-email?: true
            self
        ]

        ; mask-phones enables phone number masking.
        mask-phones: func [/local][
            mask-phone?: true
            self
        ]

        ; with-mask-char sets the character used for masking.
        with-mask-char: func [c [char!] /local][
            if c = #"^@" [c: #"*"]
            mask-char: c
            self
        ]

        ; process scans input text and masks enabled PII patterns.
        process: func [input [string!] /local current-char result][
            if all [not mask-email? not mask-phone?] [
                return input
            ]
            current-char: either mask-char = #"^@" [#"*"] [mask-char]
            result: input
            if mask-email? [
                result: mask-emails-in-text result current-char
            ]
            if mask-phone? [
                result: mask-phones-in-text result current-char
            ]
            result
        ]
    ]
    masker
]

mask-emails-in-text: func [input [string!] mask-char [char!] /local length output last i local-start local-end domain-start domain-end candidate-end matched-end local domain remaining][
    length: length? input
    output: make string! length
    last: 1
    i: 1
    while [i <= length][
        if pick input i = #"@" [
            local-start: i
            while [all [local-start > 1 is-local-char? pick input (local-start - 1)]] [
                local-start: local-start - 1
            ]
            local-end: i - 1
            domain-start: i + 1
            domain-end: domain-start
            while [all [domain-end <= length is-domain-char? pick input domain-end]] [
                domain-end: domain-end + 1
            ]
            domain-end: domain-end - 1
            if all [local-start <= local-end domain-start <= domain-end][
                candidate-end: domain-end
                matched-end: 0
                while [candidate-end >= domain-start][
                    domain: copy/part at input domain-start (candidate-end - domain-start + 1)
                    if is-valid-domain? domain [
                        matched-end: candidate-end
                        break
                    ]
                    candidate-end: candidate-end - 1
                ]
                if matched-end > 0 [
                    local: copy/part at input local-start (local-end - local-start + 1)
                    domain: copy/part at input domain-start (matched-end - domain-start + 1)
                    append output copy/part at input last (local-start - last)
                    append output mask-local local mask-char
                    append output #"@"
                    append output domain
                    last: matched-end + 1
                    i: matched-end
                ]
            ]
        ]
        i: i + 1
    ]
    remaining: length - last + 1
    if remaining > 0 [
        append output copy/part at input last remaining
    ]
    output
]

mask-phones-in-text: func [input [string!] mask-char [char!] /local length output last i ch end digit-count last-digit-index idx candidate-end candidate remaining][
    length: length? input
    output: make string! length
    last: 1
    i: 1
    while [i <= length][
        ch: pick input i
        if is-phone-start? ch [
            end: i
            while [all [end <= length is-phone-char? pick input end]] [
                end: end + 1
            ]
            end: end - 1
            digit-count: 0
            last-digit-index: 0
            idx: i
            while [idx <= end][
                if is-digit? pick input idx [
                    digit-count: digit-count + 1
                    last-digit-index: idx
                ]
                idx: idx + 1
            ]
            if all [last-digit-index > 0 digit-count >= 5] [
                candidate-end: last-digit-index
                candidate: copy/part at input i (candidate-end - i + 1)
                append output copy/part at input last (i - last)
                append output mask-phone-candidate candidate mask-char
                last: candidate-end + 1
                i: candidate-end
            ] else [
                i: end
            ]
        ]
        i: i + 1
    ]
    remaining: length - last + 1
    if remaining > 0 [
        append output copy/part at input last remaining
    ]
    output
]

mask-local: func [local [string!] mask-char [char!] /local result][
    if (length? local) > 1 [
        result: make string! (length? local)
        append result first local
        repeat _ ((length? local) - 1) [
            append result mask-char
        ]
        return result
    ]
    to string! mask-char
]

mask-phone-candidate: func [candidate [string!] mask-char [char!] /local digit-count current-index result][
    digit-count: 0
    foreach ch candidate [
        if is-digit? ch [digit-count: digit-count + 1]
    ]
    if digit-count <= 4 [
        return candidate
    ]
    current-index: 0
    result: make string! (length? candidate)
    foreach ch candidate [
        if is-digit? ch [
            current-index: current-index + 1
            if current-index <= (digit-count - 4) [
                append result mask-char
            ] else [
                append result ch
            ]
        ] else [
            append result ch
        ]
    ]
    result
]

is-local-char?: func [ch [char!] /local][
    any [
        all [ch >= #"a" ch <= #"z"]
        all [ch >= #"A" ch <= #"Z"]
        all [ch >= #"0" ch <= #"9"]
        ch = #"."
        ch = #"_"
        ch = #"%"
        ch = #"+"
        ch = #"-"
    ]
]

is-domain-char?: func [ch [char!] /local][
    any [
        all [ch >= #"a" ch <= #"z"]
        all [ch >= #"A" ch <= #"Z"]
        all [ch >= #"0" ch <= #"9"]
        ch = #"-"
        ch = #"."
    ]
]

is-valid-domain?: func [domain [string!] /local parts part tld][
    if any [
        empty? domain
        first domain = #"."
        last domain = #"."
    ] [return false]

    parts: split domain "."
    if (length? parts) < 2 [return false]

    foreach part parts [
        if empty? part [return false]
        if any [first part = #"-" last part = #"-"] [return false]
        foreach ch part [
            if not any [is-alpha-numeric? ch ch = #"-"] [return false]
        ]
    ]

    tld: last parts
    if (length? tld) < 2 [return false]
    foreach ch tld [
        if not is-alpha? ch [return false]
    ]

    true
]

is-phone-start?: func [ch [char!] /local][
    any [is-digit? ch ch = #"+" ch = #"("]
]

is-phone-char?: func [ch [char!] /local][
    any [
        is-digit? ch
        ch = #" "
        ch = #"-"
        ch = #"("
        ch = #")"
        ch = #"+"
    ]
]

is-digit?: func [ch [char!] /local][
    all [ch >= #"0" ch <= #"9"]
]

is-alpha?: func [ch [char!] /local][
    any [
        all [ch >= #"a" ch <= #"z"]
        all [ch >= #"A" ch <= #"Z"]
    ]
]

is-alpha-numeric?: func [ch [char!] /local][
    any [is-alpha? ch is-digit? ch]
]
