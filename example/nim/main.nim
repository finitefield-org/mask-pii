import mask_pii

let masker =
  newMasker()
    .maskEmails()
    .maskPhones()
    .withMaskChar('#')

let inputText = "Contact: alice@example.com or 090-1234-5678."
let outputText = masker.process(inputText)

echo outputText
