# frozen_string_literal: true

require "minitest/autorun"
require "mask_pii"

class TestMaskPII < Minitest::Test
  def test_email_basic_cases
    masker = MaskPII::Masker.new.mask_emails
    assert_cases(
      masker,
      "alice@example.com" => "a****@example.com",
      "a@b.com" => "*@b.com",
      "ab@example.com" => "a*@example.com",
      "a.b+c_d@example.co.jp" => "a******@example.co.jp"
    )
  end

  def test_email_mixed_text
    masker = MaskPII::Masker.new.mask_emails
    assert_cases(
      masker,
      "Contact: alice@example.com." => "Contact: a****@example.com.",
      "alice@example.com and bob@example.org" => "a****@example.com and b**@example.org"
    )
  end

  def test_email_edge_cases
    masker = MaskPII::Masker.new.mask_emails
    assert_cases(
      masker,
      "alice@example" => "alice@example",
      "alice@localhost" => "alice@localhost",
      "alice@@example.com" => "alice@@example.com",
      "first.last+tag@sub.domain.com" => "f*************@sub.domain.com"
    )
  end

  def test_phone_basic_formats
    masker = MaskPII::Masker.new.mask_phones
    assert_cases(
      masker,
      "090-1234-5678" => "***-****-5678",
      "Call (555) 123-4567" => "Call (***) ***-4567",
      "Intl: +81 3 1234 5678" => "Intl: +** * **** 5678",
      "+1 (800) 123-4567" => "+* (***) ***-4567"
    )
  end

  def test_phone_short_and_boundary_lengths
    masker = MaskPII::Masker.new.mask_phones
    assert_cases(
      masker,
      "1234" => "1234",
      "12345" => "*2345",
      "12-3456" => "**-3456"
    )
  end

  def test_phone_mixed_text
    masker = MaskPII::Masker.new.mask_phones
    assert_cases(
      masker,
      "Tel: 090-1234-5678 ext. 99" => "Tel: ***-****-5678 ext. 99",
      "Numbers: 111-2222 and 333-4444" => "Numbers: ***-2222 and ***-4444"
    )
  end

  def test_phone_edge_cases
    masker = MaskPII::Masker.new.mask_phones
    assert_cases(
      masker,
      "abcdef" => "abcdef",
      "+" => "+",
      "(12) 345 678" => "(**) **5 678"
    )
  end

  def test_combined_masking
    masker = MaskPII::Masker.new.mask_emails.mask_phones
    assert_cases(
      masker,
      "Contact: alice@example.com or 090-1234-5678." => "Contact: a****@example.com or ***-****-5678.",
      "Email bob@example.org, phone +1 (800) 123-4567" => "Email b**@example.org, phone +* (***) ***-4567"
    )
  end

  def test_custom_mask_character
    email_masker = MaskPII::Masker.new.mask_emails.with_mask_char("#")
    phone_masker = MaskPII::Masker.new.mask_phones.with_mask_char("#")
    combined = MaskPII::Masker.new.mask_emails.mask_phones.with_mask_char("#")

    assert_cases(
      email_masker,
      "alice@example.com" => 'a####@example.com'
    )

    assert_cases(
      phone_masker,
      "090-1234-5678" => "###-####-5678"
    )

    assert_equal 'Contact: a####@example.com or ###-####-5678.',
                 combined.process("Contact: alice@example.com or 090-1234-5678.")
  end

  def test_masker_configuration
    input = "alice@example.com 090-1234-5678"

    assert_equal input, MaskPII::Masker.new.process(input)

    email_only = MaskPII::Masker.new.mask_emails
    assert_equal "a****@example.com 090-1234-5678", email_only.process(input)

    phone_only = MaskPII::Masker.new.mask_phones
    assert_equal "alice@example.com ***-****-5678", phone_only.process(input)

    both = MaskPII::Masker.new.mask_emails.mask_phones
    assert_equal "a****@example.com ***-****-5678", both.process(input)
  end

  def test_non_ascii_text_is_preserved
    masker = MaskPII::Masker.new.mask_emails.mask_phones
    input = "連絡先: alice@example.com と 090-1234-5678"
    expected = "連絡先: a****@example.com と ***-****-5678"
    assert_equal expected, masker.process(input)
  end

  private

  def assert_cases(masker, cases)
    cases.each do |input, expected|
      assert_equal expected, masker.process(input)
    end
  end
end
