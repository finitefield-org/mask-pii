open Alcotest

let check_case name masker input expected =
  let actual = Mask_pii.process masker input in
  check string name expected actual

let email_masker = Mask_pii.mask_emails Mask_pii.new_masker
let phone_masker = Mask_pii.mask_phones Mask_pii.new_masker
let both_masker = Mask_pii.mask_phones (Mask_pii.mask_emails Mask_pii.new_masker)
let custom_masker =
  Mask_pii.with_mask_char '#'
    (Mask_pii.mask_phones (Mask_pii.mask_emails Mask_pii.new_masker))

let email_cases =
  [ ("alice@example.com", "a****@example.com")
  ; ("a@b.com", "*@b.com")
  ; ("ab@example.com", "a*@example.com")
  ; ("a.b+c_d@example.co.jp", "a******@example.co.jp")
  ; ("Contact: alice@example.com.", "Contact: a****@example.com.")
  ; ("alice@example.com and bob@example.org", "a****@example.com and b**@example.org")
  ; ("alice@example", "alice@example")
  ; ("alice@localhost", "alice@localhost")
  ; ("alice@@example.com", "alice@@example.com")
  ; ("first.last+tag@sub.domain.com", "f*************@sub.domain.com")
  ]

let phone_cases =
  [ ("090-1234-5678", "***-****-5678")
  ; ("Call (555) 123-4567", "Call (***) ***-4567")
  ; ("Intl: +81 3 1234 5678", "Intl: +** * **** 5678")
  ; ("+1 (800) 123-4567", "+* (***) ***-4567")
  ; ("1234", "1234")
  ; ("12345", "*2345")
  ; ("12-3456", "**-3456")
  ; ("Tel: 090-1234-5678 ext. 99", "Tel: ***-****-5678 ext. 99")
  ; ("Numbers: 111-2222 and 333-4444", "Numbers: ***-2222 and ***-4444")
  ; ("abcdef", "abcdef")
  ; ("+", "+")
  ; ("(12) 345 678", "(**) **5 678")
  ]

let combined_cases =
  [ ("Contact: alice@example.com or 090-1234-5678.",
     "Contact: a****@example.com or ***-****-5678.")
  ; ("Email bob@example.org, phone +1 (800) 123-4567",
     "Email b**@example.org, phone +* (***) ***-4567")
  ]

let custom_cases =
  [ ("alice@example.com", "a####@example.com")
  ; ("090-1234-5678", "###-####-5678")
  ; ("Contact: alice@example.com or 090-1234-5678.",
     "Contact: a####@example.com or ###-####-5678.")
  ]

let config_cases =
  [ ("Masker.new", Mask_pii.new_masker,
     "Contact: alice@example.com or 090-1234-5678.",
     "Contact: alice@example.com or 090-1234-5678.")
  ; ("mask_emails only", email_masker,
     "Contact: alice@example.com or 090-1234-5678.",
     "Contact: a****@example.com or 090-1234-5678.")
  ; ("mask_phones only", phone_masker,
     "Contact: alice@example.com or 090-1234-5678.",
     "Contact: alice@example.com or ***-****-5678.")
  ; ("mask_emails + mask_phones", both_masker,
     "Contact: alice@example.com or 090-1234-5678.",
     "Contact: a****@example.com or ***-****-5678.")
  ]

let () =
  let email_tests =
    List.mapi
      (fun idx (input, expected) ->
        test_case
          (Printf.sprintf "email_%02d" (idx + 1))
          `Quick
          (fun () -> check_case "email" email_masker input expected))
      email_cases
  in
  let phone_tests =
    List.mapi
      (fun idx (input, expected) ->
        test_case
          (Printf.sprintf "phone_%02d" (idx + 1))
          `Quick
          (fun () -> check_case "phone" phone_masker input expected))
      phone_cases
  in
  let combined_tests =
    List.mapi
      (fun idx (input, expected) ->
        test_case
          (Printf.sprintf "combined_%02d" (idx + 1))
          `Quick
          (fun () -> check_case "combined" both_masker input expected))
      combined_cases
  in
  let custom_tests =
    List.mapi
      (fun idx (input, expected) ->
        test_case
          (Printf.sprintf "custom_%02d" (idx + 1))
          `Quick
          (fun () -> check_case "custom" custom_masker input expected))
      custom_cases
  in
  let config_tests =
    List.mapi
      (fun idx (name, masker, input, expected) ->
        test_case
          (Printf.sprintf "config_%02d" (idx + 1))
          `Quick
          (fun () -> check_case name masker input expected))
      config_cases
  in
  run
    "mask-pii"
    [ ("emails", email_tests)
    ; ("phones", phone_tests)
    ; ("combined", combined_tests)
    ; ("custom", custom_tests)
    ; ("config", config_tests)
    ]
