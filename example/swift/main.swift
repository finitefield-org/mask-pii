import MaskPII

let masker = Masker()
    .maskEmails()
    .maskPhones()
    .withMaskChar("#")

let input = "Contact: alice@example.com or 090-1234-5678."
let output = masker.process(input)

print(output)
// Output: "Contact: a####@example.com or ###-####-5678."
