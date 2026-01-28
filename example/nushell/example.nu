use ../../nushell/src/mask_pii.nu *

let masker = (masker new | mask_emails | mask_phones)
let input = "Contact: alice@example.com or 090-1234-5678."
let output = ($masker | process $input)
$output
