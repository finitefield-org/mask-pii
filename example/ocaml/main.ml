open Mask_pii

let () =
  let masker =
    new_masker
    |> mask_emails
    |> mask_phones
    |> with_mask_char '#'
  in
  let result = process masker "Contact: alice@example.com or 090-1234-5678." in
  print_endline result
