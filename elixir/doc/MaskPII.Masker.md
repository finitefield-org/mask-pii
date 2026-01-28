# `MaskPII.Masker`
[🔗](https://github.com/finitefield-org/mask-pii/blob/main/lib/mask_pii/masker.ex#L1)

A configurable masker for common PII such as emails and phone numbers.

# `t`
[🔗](https://github.com/finitefield-org/mask-pii/blob/main/lib/mask_pii/masker.ex#L10)

```elixir
@type t() :: %MaskPII.Masker{
  mask_char: String.t(),
  mask_email: boolean(),
  mask_phone: boolean()
}
```

# `mask_emails`
[🔗](https://github.com/finitefield-org/mask-pii/blob/main/lib/mask_pii/masker.ex#L28)

```elixir
@spec mask_emails(t()) :: t()
```

Enable email address masking.

# `mask_phones`
[🔗](https://github.com/finitefield-org/mask-pii/blob/main/lib/mask_pii/masker.ex#L36)

```elixir
@spec mask_phones(t()) :: t()
```

Enable phone number masking.

# `new`
[🔗](https://github.com/finitefield-org/mask-pii/blob/main/lib/mask_pii/masker.ex#L20)

```elixir
@spec new() :: t()
```

Create a new masker with all masks disabled by default.

# `process`
[🔗](https://github.com/finitefield-org/mask-pii/blob/main/lib/mask_pii/masker.ex#L52)

```elixir
@spec process(t(), String.t()) :: String.t()
```

Process input text and mask enabled PII patterns.

# `with_mask_char`
[🔗](https://github.com/finitefield-org/mask-pii/blob/main/lib/mask_pii/masker.ex#L44)

```elixir
@spec with_mask_char(t(), String.t() | integer() | nil) :: t()
```

Set the character used for masking.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
