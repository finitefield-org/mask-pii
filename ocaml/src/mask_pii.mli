(**
   mask-pii provides masking utilities for common PII patterns.

   The API exposes a builder-style configuration for masking emails and
   phone numbers without using regular expressions.
*)

type masker
(** Configuration for masking emails and phone numbers. *)

val new_masker : masker
(** Create a new masker with all masks disabled by default. *)

val mask_emails : masker -> masker
(** Enable email address masking. *)

val mask_phones : masker -> masker
(** Enable phone number masking. *)

val with_mask_char : char -> masker -> masker
(**
   Set the character used for masking.

   A null character ('\000') resets the mask character to '*'.
*)

val process : masker -> string -> string
(**
   Process input text and mask enabled PII patterns.

   If no masking options are enabled, the input is returned unchanged.
*)
