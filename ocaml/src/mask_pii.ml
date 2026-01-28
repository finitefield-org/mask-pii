(** Core masking logic for the mask-pii package. *)

type masker = {
  mask_email : bool;
  mask_phone : bool;
  mask_char : char;
}

(** Create a new masker with all masks disabled by default. *)
let new_masker =
  { mask_email = false; mask_phone = false; mask_char = '*' }

(** Enable email address masking. *)
let mask_emails masker = { masker with mask_email = true }

(** Enable phone number masking. *)
let mask_phones masker = { masker with mask_phone = true }

(**
   Set the character used for masking.

   A null character ('\000') resets the mask character to '*'.
*)
let with_mask_char ch masker =
  let mask_char = if ch = '\000' then '*' else ch in
  { masker with mask_char }

let is_digit ch = ch >= '0' && ch <= '9'

let is_alpha ch =
  (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z')

let is_alnum ch = is_alpha ch || is_digit ch

let is_local_char ch =
  is_alpha ch
  || is_digit ch
  || ch = '.'
  || ch = '_'
  || ch = '%'
  || ch = '+'
  || ch = '-'

let is_domain_char ch =
  is_alpha ch || is_digit ch || ch = '-' || ch = '.'

let split_on_char delimiter text =
  let length = String.length text in
  let rec loop idx current acc =
    if idx >= length then
      List.rev (String.concat "" (List.rev current) :: acc)
    else if text.[idx] = delimiter then
      loop (idx + 1) [] (String.concat "" (List.rev current) :: acc)
    else
      loop (idx + 1) (String.make 1 text.[idx] :: current) acc
  in
  loop 0 [] []

let is_valid_domain domain =
  let length = String.length domain in
  if length = 0 then
    false
  else if domain.[0] = '.' || domain.[length - 1] = '.' then
    false
  else
    let parts = split_on_char '.' domain in
    if List.length parts < 2 then
      false
    else
      let valid_label label =
        let label_len = String.length label in
        if label_len = 0 then
          false
        else if label.[0] = '-' || label.[label_len - 1] = '-' then
          false
        else
          let rec check idx =
            if idx >= label_len then
              true
            else if is_alnum label.[idx] || label.[idx] = '-' then
              check (idx + 1)
            else
              false
          in
          check 0
      in
      let tld = List.hd (List.rev parts) in
      let tld_len = String.length tld in
      let valid_tld =
        tld_len >= 2
        &&
        let rec check idx =
          if idx >= tld_len then
            true
          else if is_alpha tld.[idx] then
            check (idx + 1)
          else
            false
        in
        check 0
      in
      List.for_all valid_label parts && valid_tld

let mask_local local mask_char =
  let length = String.length local in
  if length > 1 then
    let masked_tail = String.make (length - 1) mask_char in
    String.make 1 local.[0] ^ masked_tail
  else
    String.make 1 mask_char

let mask_phone_candidate candidate mask_char =
  let length = String.length candidate in
  let digit_count =
    let count = ref 0 in
    for i = 0 to length - 1 do
      if is_digit candidate.[i] then incr count
    done;
    !count
  in
  if digit_count <= 4 then
    candidate
  else
    let mask_until = digit_count - 4 in
    let buffer = Buffer.create length in
    let current = ref 0 in
    for i = 0 to length - 1 do
      let ch = candidate.[i] in
      if is_digit ch then (
        incr current;
        if !current <= mask_until then
          Buffer.add_char buffer mask_char
        else
          Buffer.add_char buffer ch)
      else
        Buffer.add_char buffer ch
    done;
    Buffer.contents buffer

let mask_emails_in_text input mask_char =
  let length = String.length input in
  let buffer = Buffer.create length in
  let rec loop idx last =
    if idx >= length then (
      Buffer.add_substring buffer input last (length - last);
      Buffer.contents buffer)
    else if input.[idx] = '@' then
      let local_start = ref idx in
      while !local_start > 0 && is_local_char input.[!local_start - 1] do
        decr local_start
      done;
      let local_end = idx in
      let domain_start = idx + 1 in
      let domain_end = ref domain_start in
      while !domain_end < length && is_domain_char input.[!domain_end] do
        incr domain_end
      done;
      if !local_start < local_end && domain_start < !domain_end then
        let candidate_end = ref !domain_end in
        let matched_end = ref (-1) in
        while !candidate_end > domain_start && !matched_end = -1 do
          let domain =
            String.sub input domain_start (!candidate_end - domain_start)
          in
          if is_valid_domain domain then
            matched_end := !candidate_end
          else
            decr candidate_end
        done;
        if !matched_end <> -1 then (
          Buffer.add_substring buffer input last (!local_start - last);
          let local =
            String.sub input !local_start (local_end - !local_start)
          in
          Buffer.add_string buffer (mask_local local mask_char);
          Buffer.add_char buffer '@';
          Buffer.add_substring
            buffer
            input
            domain_start
            (!matched_end - domain_start);
          loop !matched_end !matched_end)
        else
          loop (idx + 1) last
      else
        loop (idx + 1) last
    else
      loop (idx + 1) last
  in
  loop 0 0

let is_phone_start ch = is_digit ch || ch = '+' || ch = '('

let is_phone_char ch =
  is_digit ch || ch = ' ' || ch = '-' || ch = '(' || ch = ')' || ch = '+'

let mask_phones_in_text input mask_char =
  let length = String.length input in
  let buffer = Buffer.create length in
  let rec loop idx last =
    if idx >= length then (
      Buffer.add_substring buffer input last (length - last);
      Buffer.contents buffer)
    else if is_phone_start input.[idx] then
      let end_idx = ref idx in
      while !end_idx < length && is_phone_char input.[!end_idx] do
        incr end_idx
      done;
      let digit_count = ref 0 in
      let last_digit_index = ref (-1) in
      for i = idx to !end_idx - 1 do
        if is_digit input.[i] then (
          incr digit_count;
          last_digit_index := i)
      done;
      if !last_digit_index = -1 then
        loop !end_idx last
      else if !digit_count >= 5 then
        let candidate_end = !last_digit_index + 1 in
        let candidate = String.sub input idx (candidate_end - idx) in
        Buffer.add_substring buffer input last (idx - last);
        Buffer.add_string buffer (mask_phone_candidate candidate mask_char);
        loop candidate_end candidate_end
      else
        loop !end_idx last
    else
      loop (idx + 1) last
  in
  loop 0 0

(** Process input text and mask enabled PII patterns. *)
let process masker input =
  if (not masker.mask_email) && not masker.mask_phone then
    input
  else
    let mask_char = if masker.mask_char = '\000' then '*' else masker.mask_char in
    let after_emails =
      if masker.mask_email then
        mask_emails_in_text input mask_char
      else
        input
    in
    if masker.mask_phone then
      mask_phones_in_text after_emails mask_char
    else
      after_emails
