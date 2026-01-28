Red [
    Title: "mask-pii Red example"
]

do %../../red/mask-pii.red

masker: make-masker
masker/mask-emails
masker/mask-phones
masker/with-mask-char #"#"

input: "Contact: alice@example.com or 090-1234-5678."
output: masker/process input

print output
