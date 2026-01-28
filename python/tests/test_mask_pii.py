import os
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))

from mask_pii import Masker


class MaskPiiTestCase(unittest.TestCase):
    def assert_cases(self, masker, cases):
        for input_text, expected in cases:
            with self.subTest(input=input_text):
                self.assertEqual(masker.process(input_text), expected)

    def test_email_basic_cases(self):
        masker = Masker().mask_emails()
        self.assert_cases(
            masker,
            [
                ("alice@example.com", "a****@example.com"),
                ("a@b.com", "*@b.com"),
                ("ab@example.com", "a*@example.com"),
                ("a.b+c_d@example.co.jp", "a******@example.co.jp"),
            ],
        )

    def test_email_mixed_text(self):
        masker = Masker().mask_emails()
        self.assert_cases(
            masker,
            [
                ("Contact: alice@example.com.", "Contact: a****@example.com."),
                (
                    "alice@example.com and bob@example.org",
                    "a****@example.com and b**@example.org",
                ),
            ],
        )

    def test_email_edge_cases(self):
        masker = Masker().mask_emails()
        self.assert_cases(
            masker,
            [
                ("alice@example", "alice@example"),
                ("alice@localhost", "alice@localhost"),
                ("alice@@example.com", "alice@@example.com"),
                (
                    "first.last+tag@sub.domain.com",
                    "f*************@sub.domain.com",
                ),
            ],
        )

    def test_phone_basic_formats(self):
        masker = Masker().mask_phones()
        self.assert_cases(
            masker,
            [
                ("090-1234-5678", "***-****-5678"),
                ("Call (555) 123-4567", "Call (***) ***-4567"),
                ("Intl: +81 3 1234 5678", "Intl: +** * **** 5678"),
                ("+1 (800) 123-4567", "+* (***) ***-4567"),
            ],
        )

    def test_phone_short_and_boundary_lengths(self):
        masker = Masker().mask_phones()
        self.assert_cases(
            masker,
            [
                ("1234", "1234"),
                ("12345", "*2345"),
                ("12-3456", "**-3456"),
            ],
        )

    def test_phone_mixed_text(self):
        masker = Masker().mask_phones()
        self.assert_cases(
            masker,
            [
                (
                    "Tel: 090-1234-5678 ext. 99",
                    "Tel: ***-****-5678 ext. 99",
                ),
                (
                    "Numbers: 111-2222 and 333-4444",
                    "Numbers: ***-2222 and ***-4444",
                ),
            ],
        )

    def test_phone_edge_cases(self):
        masker = Masker().mask_phones()
        self.assert_cases(
            masker,
            [
                ("abcdef", "abcdef"),
                ("+", "+"),
                ("(12) 345 678", "(**) **5 678"),
            ],
        )

    def test_combined_masking(self):
        masker = Masker().mask_emails().mask_phones()
        self.assert_cases(
            masker,
            [
                (
                    "Contact: alice@example.com or 090-1234-5678.",
                    "Contact: a****@example.com or ***-****-5678.",
                ),
                (
                    "Email bob@example.org, phone +1 (800) 123-4567",
                    "Email b**@example.org, phone +* (***) ***-4567",
                ),
            ],
        )

    def test_custom_mask_character(self):
        email_masker = Masker().mask_emails().with_mask_char("#")
        phone_masker = Masker().mask_phones().with_mask_char("#")
        combined = Masker().mask_emails().mask_phones().with_mask_char("#")

        self.assert_cases(
            email_masker,
            [("alice@example.com", "a####@example.com")],
        )
        self.assert_cases(
            phone_masker,
            [("090-1234-5678", "###-####-5678")],
        )

        got = combined.process("Contact: alice@example.com or 090-1234-5678.")
        want = "Contact: a####@example.com or ###-####-5678."
        self.assertEqual(got, want)

    def test_masker_configuration(self):
        input_text = "alice@example.com 090-1234-5678"

        passthrough = Masker()
        self.assertEqual(passthrough.process(input_text), input_text)

        email_only = Masker().mask_emails()
        self.assertEqual(
            email_only.process(input_text),
            "a****@example.com 090-1234-5678",
        )

        phone_only = Masker().mask_phones()
        self.assertEqual(
            phone_only.process(input_text),
            "alice@example.com ***-****-5678",
        )

        both = Masker().mask_emails().mask_phones()
        self.assertEqual(
            both.process(input_text),
            "a****@example.com ***-****-5678",
        )

    def test_non_ascii_text_is_preserved(self):
        masker = Masker().mask_emails().mask_phones()
        input_text = "連絡先: alice@example.com と 090-1234-5678"
        expected = "連絡先: a****@example.com と ***-****-5678"
        self.assertEqual(masker.process(input_text), expected)


if __name__ == "__main__":
    unittest.main()
