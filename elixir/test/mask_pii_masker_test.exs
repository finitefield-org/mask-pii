defmodule MaskPII.MaskerTest do
  use ExUnit.Case, async: true

  alias MaskPII.Masker

  defp assert_cases(masker, cases) do
    Enum.each(cases, fn {input, expected} ->
      assert Masker.process(masker, input) == expected
    end)
  end

  test "email basic cases" do
    masker = Masker.new() |> Masker.mask_emails()

    assert_cases(masker, [
      {"alice@example.com", "a****@example.com"},
      {"a@b.com", "*@b.com"},
      {"ab@example.com", "a*@example.com"},
      {"a.b+c_d@example.co.jp", "a******@example.co.jp"}
    ])
  end

  test "email mixed text" do
    masker = Masker.new() |> Masker.mask_emails()

    assert_cases(masker, [
      {"Contact: alice@example.com.", "Contact: a****@example.com."},
      {"alice@example.com and bob@example.org", "a****@example.com and b**@example.org"}
    ])
  end

  test "email edge cases" do
    masker = Masker.new() |> Masker.mask_emails()

    assert_cases(masker, [
      {"alice@example", "alice@example"},
      {"alice@localhost", "alice@localhost"},
      {"alice@@example.com", "alice@@example.com"},
      {"first.last+tag@sub.domain.com", "f*************@sub.domain.com"}
    ])
  end

  test "phone basic formats" do
    masker = Masker.new() |> Masker.mask_phones()

    assert_cases(masker, [
      {"090-1234-5678", "***-****-5678"},
      {"Call (555) 123-4567", "Call (***) ***-4567"},
      {"Intl: +81 3 1234 5678", "Intl: +** * **** 5678"},
      {"+1 (800) 123-4567", "+* (***) ***-4567"}
    ])
  end

  test "phone short and boundary lengths" do
    masker = Masker.new() |> Masker.mask_phones()

    assert_cases(masker, [
      {"1234", "1234"},
      {"12345", "*2345"},
      {"12-3456", "**-3456"}
    ])
  end

  test "phone mixed text" do
    masker = Masker.new() |> Masker.mask_phones()

    assert_cases(masker, [
      {"Tel: 090-1234-5678 ext. 99", "Tel: ***-****-5678 ext. 99"},
      {"Numbers: 111-2222 and 333-4444", "Numbers: ***-2222 and ***-4444"}
    ])
  end

  test "phone edge cases" do
    masker = Masker.new() |> Masker.mask_phones()

    assert_cases(masker, [
      {"abcdef", "abcdef"},
      {"+", "+"},
      {"(12) 345 678", "(**) **5 678"}
    ])
  end

  test "combined masking" do
    masker = Masker.new() |> Masker.mask_emails() |> Masker.mask_phones()

    assert_cases(masker, [
      {"Contact: alice@example.com or 090-1234-5678.",
       "Contact: a****@example.com or ***-****-5678."},
      {"Email bob@example.org, phone +1 (800) 123-4567",
       "Email b**@example.org, phone +* (***) ***-4567"}
    ])
  end

  test "custom mask character" do
    email_masker = Masker.new() |> Masker.mask_emails() |> Masker.with_mask_char("#")
    phone_masker = Masker.new() |> Masker.mask_phones() |> Masker.with_mask_char("#")
    combined = Masker.new() |> Masker.mask_emails() |> Masker.mask_phones() |> Masker.with_mask_char("#")

    assert_cases(email_masker, [{"alice@example.com", "a####@example.com"}])
    assert_cases(phone_masker, [{"090-1234-5678", "###-####-5678"}])

    assert Masker.process(combined, "Contact: alice@example.com or 090-1234-5678.") ==
             "Contact: a####@example.com or ###-####-5678."
  end

  test "masker configuration" do
    input = "alice@example.com 090-1234-5678"

    passthrough = Masker.new()
    assert Masker.process(passthrough, input) == input

    email_only = Masker.new() |> Masker.mask_emails()
    assert Masker.process(email_only, input) == "a****@example.com 090-1234-5678"

    phone_only = Masker.new() |> Masker.mask_phones()
    assert Masker.process(phone_only, input) == "alice@example.com ***-****-5678"

    both = Masker.new() |> Masker.mask_emails() |> Masker.mask_phones()
    assert Masker.process(both, input) == "a****@example.com ***-****-5678"
  end

  test "non-ascii text is preserved" do
    masker = Masker.new() |> Masker.mask_emails() |> Masker.mask_phones()
    input = "連絡先: alice@example.com と 090-1234-5678"
    expected = "連絡先: a****@example.com と ***-****-5678"

    assert Masker.process(masker, input) == expected
  end
end
