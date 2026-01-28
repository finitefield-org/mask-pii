import MaskPII library "mask_pii";

fn Main() {
  var masker: Masker = New()
    .MaskEmails()
    .MaskPhones()
    .WithMaskChar('#');

  let input: String = "Contact: alice@example.com or 090-1234-5678.";
  let output: String = masker.Process(input);

  // Output: "Contact: a####@example.com or ###-####-5678."
}
