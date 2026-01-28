import XCTest
@testable import MaskPII

final class MaskPIITests: XCTestCase {
    private func assertCases(_ masker: Masker, cases: [(String, String)], file: StaticString = #file, line: UInt = #line) {
        for (input, expected) in cases {
            XCTAssertEqual(masker.process(input), expected, file: file, line: line)
        }
    }

    func testEmailBasicCases() {
        let masker = Masker().maskEmails()
        assertCases(masker, cases: [
            ("alice@example.com", "a****@example.com"),
            ("a@b.com", "*@b.com"),
            ("ab@example.com", "a*@example.com"),
            ("a.b+c_d@example.co.jp", "a******@example.co.jp")
        ])
    }

    func testEmailMixedText() {
        let masker = Masker().maskEmails()
        assertCases(masker, cases: [
            ("Contact: alice@example.com.", "Contact: a****@example.com."),
            ("alice@example.com and bob@example.org", "a****@example.com and b**@example.org")
        ])
    }

    func testEmailEdgeCases() {
        let masker = Masker().maskEmails()
        assertCases(masker, cases: [
            ("alice@example", "alice@example"),
            ("alice@localhost", "alice@localhost"),
            ("alice@@example.com", "alice@@example.com"),
            ("first.last+tag@sub.domain.com", "f*************@sub.domain.com")
        ])
    }

    func testPhoneBasicFormats() {
        let masker = Masker().maskPhones()
        assertCases(masker, cases: [
            ("090-1234-5678", "***-****-5678"),
            ("Call (555) 123-4567", "Call (***) ***-4567"),
            ("Intl: +81 3 1234 5678", "Intl: +** * **** 5678"),
            ("+1 (800) 123-4567", "+* (***) ***-4567")
        ])
    }

    func testPhoneShortAndBoundaryLengths() {
        let masker = Masker().maskPhones()
        assertCases(masker, cases: [
            ("1234", "1234"),
            ("12345", "*2345"),
            ("12-3456", "**-3456")
        ])
    }

    func testPhoneMixedText() {
        let masker = Masker().maskPhones()
        assertCases(masker, cases: [
            ("Tel: 090-1234-5678 ext. 99", "Tel: ***-****-5678 ext. 99"),
            ("Numbers: 111-2222 and 333-4444", "Numbers: ***-2222 and ***-4444")
        ])
    }

    func testPhoneEdgeCases() {
        let masker = Masker().maskPhones()
        assertCases(masker, cases: [
            ("abcdef", "abcdef"),
            ("+", "+"),
            ("(12) 345 678", "(**) **5 678")
        ])
    }

    func testCombinedMasking() {
        let masker = Masker().maskEmails().maskPhones()
        assertCases(masker, cases: [
            ("Contact: alice@example.com or 090-1234-5678.", "Contact: a****@example.com or ***-****-5678."),
            ("Email bob@example.org, phone +1 (800) 123-4567", "Email b**@example.org, phone +* (***) ***-4567")
        ])
    }

    func testCustomMaskCharacter() {
        let emailMasker = Masker().maskEmails().withMaskChar("#")
        let phoneMasker = Masker().maskPhones().withMaskChar("#")
        let combined = Masker().maskEmails().maskPhones().withMaskChar("#")

        assertCases(emailMasker, cases: [("alice@example.com", "a####@example.com")])
        assertCases(phoneMasker, cases: [("090-1234-5678", "###-####-5678")])
        XCTAssertEqual(
            combined.process("Contact: alice@example.com or 090-1234-5678."),
            "Contact: a####@example.com or ###-####-5678."
        )
    }

    func testMaskerConfiguration() {
        let input = "alice@example.com 090-1234-5678"

        let passthrough = Masker()
        XCTAssertEqual(passthrough.process(input), input)

        let emailOnly = Masker().maskEmails()
        XCTAssertEqual(emailOnly.process(input), "a****@example.com 090-1234-5678")

        let phoneOnly = Masker().maskPhones()
        XCTAssertEqual(phoneOnly.process(input), "alice@example.com ***-****-5678")

        let both = Masker().maskEmails().maskPhones()
        XCTAssertEqual(both.process(input), "a****@example.com ***-****-5678")
    }

    func testNonAsciiTextIsPreserved() {
        let masker = Masker().maskEmails().maskPhones()
        let input = "連絡先: alice@example.com と 090-1234-5678"
        let expected = "連絡先: a****@example.com と ***-****-5678"
        XCTAssertEqual(masker.process(input), expected)
    }
}
