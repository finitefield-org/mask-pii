require "spec"
require "../src/mask_pii"

describe MaskPII::Masker do
  it "passes through when no masks are enabled" do
    masker = MaskPII::Masker.new
    masker.process("alice@example.com").should eq("alice@example.com")
  end

  it "masks emails" do
    masker = MaskPII::Masker.new.mask_emails

    cases = [
      {"alice@example.com", "a****@example.com"},
      {"a@b.com", "*@b.com"},
      {"ab@example.com", "a*@example.com"},
      {"a.b+c_d@example.co.jp", "a******@example.co.jp"},
      {"Contact: alice@example.com.", "Contact: a****@example.com."},
      {"alice@example.com and bob@example.org", "a****@example.com and b**@example.org"},
      {"alice@example", "alice@example"},
      {"alice@localhost", "alice@localhost"},
      {"alice@@example.com", "alice@@example.com"},
      {"first.last+tag@sub.domain.com", "f*************@sub.domain.com"},
    ]

    cases.each do |input, expected|
      masker.process(input).should eq(expected)
    end
  end

  it "masks phone numbers" do
    masker = MaskPII::Masker.new.mask_phones

    cases = [
      {"090-1234-5678", "***-****-5678"},
      {"Call (555) 123-4567", "Call (***) ***-4567"},
      {"Intl: +81 3 1234 5678", "Intl: +** * **** 5678"},
      {"+1 (800) 123-4567", "+* (***) ***-4567"},
      {"1234", "1234"},
      {"12345", "*2345"},
      {"12-3456", "**-3456"},
      {"Tel: 090-1234-5678 ext. 99", "Tel: ***-****-5678 ext. 99"},
      {"Numbers: 111-2222 and 333-4444", "Numbers: ***-2222 and ***-4444"},
      {"abcdef", "abcdef"},
      {"+", "+"},
      {"(12) 345 678", "(**) **5 678"},
    ]

    cases.each do |input, expected|
      masker.process(input).should eq(expected)
    end
  end

  it "masks emails and phones together" do
    masker = MaskPII::Masker.new.mask_emails.mask_phones

    cases = [
      {"Contact: alice@example.com or 090-1234-5678.", "Contact: a****@example.com or ***-****-5678."},
      {"Email bob@example.org, phone +1 (800) 123-4567", "Email b**@example.org, phone +* (***) ***-4567"},
    ]

    cases.each do |input, expected|
      masker.process(input).should eq(expected)
    end
  end

  it "supports custom mask characters" do
    masker = MaskPII::Masker.new.mask_emails.mask_phones.with_mask_char('#')

    cases = [
      {"alice@example.com", "a####@example.com"},
      {"090-1234-5678", "###-####-5678"},
      {"Contact: alice@example.com or 090-1234-5678.", "Contact: a####@example.com or ###-####-5678."},
    ]

    cases.each do |input, expected|
      masker.process(input).should eq(expected)
    end
  end

  it "leaves text unchanged when only email masking is enabled" do
    masker = MaskPII::Masker.new.mask_emails
    masker.process("Call 090-1234-5678").should eq("Call 090-1234-5678")
  end

  it "leaves text unchanged when only phone masking is enabled" do
    masker = MaskPII::Masker.new.mask_phones
    masker.process("Contact alice@example.com").should eq("Contact alice@example.com")
  end
end
