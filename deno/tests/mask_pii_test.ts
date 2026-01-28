import { assertEquals } from "https://deno.land/std@0.224.0/testing/asserts.ts";
import { Masker } from "../mod.ts";

Deno.test("Masker default is pass-through", () => {
  const masker = new Masker();
  const input = "Contact: alice@example.com or 090-1234-5678.";
  assertEquals(masker.process(input), input);
});

Deno.test("Masker email masking", () => {
  const masker = new Masker().maskEmails();
  const cases: Array<[string, string]> = [
    ["alice@example.com", "a****@example.com"],
    ["a@b.com", "*@b.com"],
    ["ab@example.com", "a*@example.com"],
    ["a.b+c_d@example.co.jp", "a******@example.co.jp"],
    ["Contact: alice@example.com.", "Contact: a****@example.com."],
    [
      "alice@example.com and bob@example.org",
      "a****@example.com and b**@example.org",
    ],
    ["alice@example", "alice@example"],
    ["alice@localhost", "alice@localhost"],
    ["alice@@example.com", "alice@@example.com"],
    [
      "first.last+tag@sub.domain.com",
      "f*************@sub.domain.com",
    ],
    [
      "こんにちは alice@example.com です",
      "こんにちは a****@example.com です",
    ],
  ];

  for (const [input, expected] of cases) {
    assertEquals(masker.process(input), expected);
  }
});

Deno.test("Masker phone masking", () => {
  const masker = new Masker().maskPhones();
  const cases: Array<[string, string]> = [
    ["090-1234-5678", "***-****-5678"],
    ["Call (555) 123-4567", "Call (***) ***-4567"],
    ["Intl: +81 3 1234 5678", "Intl: +** * **** 5678"],
    ["+1 (800) 123-4567", "+* (***) ***-4567"],
    ["1234", "1234"],
    ["12345", "*2345"],
    ["12-3456", "**-3456"],
    ["Tel: 090-1234-5678 ext. 99", "Tel: ***-****-5678 ext. 99"],
    [
      "Numbers: 111-2222 and 333-4444",
      "Numbers: ***-2222 and ***-4444",
    ],
    ["abcdef", "abcdef"],
    ["+", "+"],
    ["(12) 345 678", "(**) **5 678"],
    [
      "連絡先: 090-1234-5678",
      "連絡先: ***-****-5678",
    ],
  ];

  for (const [input, expected] of cases) {
    assertEquals(masker.process(input), expected);
  }
});

Deno.test("Masker combined masking", () => {
  const masker = new Masker().maskEmails().maskPhones();
  const cases: Array<[string, string]> = [
    [
      "Contact: alice@example.com or 090-1234-5678.",
      "Contact: a****@example.com or ***-****-5678.",
    ],
    [
      "Email bob@example.org, phone +1 (800) 123-4567",
      "Email b**@example.org, phone +* (***) ***-4567",
    ],
  ];

  for (const [input, expected] of cases) {
    assertEquals(masker.process(input), expected);
  }
});

Deno.test("Masker custom mask character", () => {
  const emailMasker = new Masker().maskEmails().withMaskChar("#");
  const phoneMasker = new Masker().maskPhones().withMaskChar("#");
  const bothMasker = new Masker().maskEmails().maskPhones().withMaskChar("#");

  assertEquals(emailMasker.process("alice@example.com"), "a####@example.com");
  assertEquals(phoneMasker.process("090-1234-5678"), "###-####-5678");
  assertEquals(
    bothMasker.process("Contact: alice@example.com or 090-1234-5678."),
    "Contact: a####@example.com or ###-####-5678.",
  );
});
