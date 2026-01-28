use "path:../../pony/mask_pii"

actor Main
  new create(env: Env) =>
    let masker = Masker
    masker.mask_emails()
    masker.mask_phones()
    masker.with_mask_char('#')

    let input = "Contact: alice@example.com or 090-1234-5678."
    let output = masker.process(input)

    env.out.print(output)
