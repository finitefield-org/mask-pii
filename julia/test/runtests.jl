using Test
using MaskPII

function assert_cases(masker::Masker, cases)
    for (input, expected) in cases
        @test process(masker, input) == expected
    end
end

@testset "Email masking basic cases" begin
    masker = mask_emails(Masker())
    assert_cases(masker, [
        ("alice@example.com", "a****@example.com"),
        ("a@b.com", "*@b.com"),
        ("ab@example.com", "a*@example.com"),
        ("a.b+c_d@example.co.jp", "a******@example.co.jp"),
    ])
end

@testset "Email masking mixed text" begin
    masker = mask_emails(Masker())
    assert_cases(masker, [
        ("Contact: alice@example.com.", "Contact: a****@example.com."),
        ("alice@example.com and bob@example.org", "a****@example.com and b**@example.org"),
    ])
end

@testset "Email masking edge cases" begin
    masker = mask_emails(Masker())
    assert_cases(masker, [
        ("alice@example", "alice@example"),
        ("alice@localhost", "alice@localhost"),
        ("alice@@example.com", "alice@@example.com"),
        ("first.last+tag@sub.domain.com", "f*************@sub.domain.com"),
    ])
end

@testset "Phone masking basic formats" begin
    masker = mask_phones(Masker())
    assert_cases(masker, [
        ("090-1234-5678", "***-****-5678"),
        ("Call (555) 123-4567", "Call (***) ***-4567"),
        ("Intl: +81 3 1234 5678", "Intl: +** * **** 5678"),
        ("+1 (800) 123-4567", "+* (***) ***-4567"),
    ])
end

@testset "Phone masking short and boundary lengths" begin
    masker = mask_phones(Masker())
    assert_cases(masker, [
        ("1234", "1234"),
        ("12345", "*2345"),
        ("12-3456", "**-3456"),
    ])
end

@testset "Phone masking mixed text" begin
    masker = mask_phones(Masker())
    assert_cases(masker, [
        ("Tel: 090-1234-5678 ext. 99", "Tel: ***-****-5678 ext. 99"),
        ("Numbers: 111-2222 and 333-4444", "Numbers: ***-2222 and ***-4444"),
    ])
end

@testset "Phone masking edge cases" begin
    masker = mask_phones(Masker())
    assert_cases(masker, [
        ("abcdef", "abcdef"),
        ("+", "+"),
        ("(12) 345 678", "(**) **5 678"),
    ])
end

@testset "Combined masking" begin
    masker = mask_phones(mask_emails(Masker()))
    assert_cases(masker, [
        ("Contact: alice@example.com or 090-1234-5678.", "Contact: a****@example.com or ***-****-5678."),
        ("Email bob@example.org, phone +1 (800) 123-4567", "Email b**@example.org, phone +* (***) ***-4567"),
    ])
end

@testset "Custom mask character" begin
    email_masker = with_mask_char(mask_emails(Masker()), '#')
    phone_masker = with_mask_char(mask_phones(Masker()), '#')
    combined = with_mask_char(mask_phones(mask_emails(Masker())), '#')

    assert_cases(email_masker, [("alice@example.com", "a####@example.com")])
    assert_cases(phone_masker, [("090-1234-5678", "###-####-5678")])
    @test process(combined, "Contact: alice@example.com or 090-1234-5678.") == "Contact: a####@example.com or ###-####-5678."
end

@testset "Masker configuration" begin
    input = "alice@example.com 090-1234-5678"

    passthrough = Masker()
    @test process(passthrough, input) == input

    email_only = mask_emails(Masker())
    @test process(email_only, input) == "a****@example.com 090-1234-5678"

    phone_only = mask_phones(Masker())
    @test process(phone_only, input) == "alice@example.com ***-****-5678"

    both = mask_phones(mask_emails(Masker()))
    @test process(both, input) == "a****@example.com ***-****-5678"
end

@testset "Non-ASCII text preserved" begin
    masker = mask_phones(mask_emails(Masker()))
    input = "連絡先: alice@example.com と 090-1234-5678"
    expected = "連絡先: a****@example.com と ***-****-5678"
    @test process(masker, input) == expected
end
