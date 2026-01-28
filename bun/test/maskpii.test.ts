import { describe, expect, test } from "bun:test";
import { Masker } from "../src/index";

type TestCase = {
  input: string;
  expected: string;
};

function assertCases(masker: Masker, cases: TestCase[]) {
  for (const tc of cases) {
    expect(masker.process(tc.input)).toBe(tc.expected);
  }
}

describe("Email masking", () => {
  test("basic cases", () => {
    const masker = new Masker().maskEmails();
    assertCases(masker, [
      { input: "alice@example.com", expected: "a****@example.com" },
      { input: "a@b.com", expected: "*@b.com" },
      { input: "ab@example.com", expected: "a*@example.com" },
      { input: "a.b+c_d@example.co.jp", expected: "a******@example.co.jp" },
    ]);
  });

  test("mixed text", () => {
    const masker = new Masker().maskEmails();
    assertCases(masker, [
      { input: "Contact: alice@example.com.", expected: "Contact: a****@example.com." },
      {
        input: "alice@example.com and bob@example.org",
        expected: "a****@example.com and b**@example.org",
      },
    ]);
  });

  test("edge cases", () => {
    const masker = new Masker().maskEmails();
    assertCases(masker, [
      { input: "alice@example", expected: "alice@example" },
      { input: "alice@localhost", expected: "alice@localhost" },
      { input: "alice@@example.com", expected: "alice@@example.com" },
      { input: "first.last+tag@sub.domain.com", expected: "f*************@sub.domain.com" },
    ]);
  });
});

describe("Phone masking", () => {
  test("basic international formats", () => {
    const masker = new Masker().maskPhones();
    assertCases(masker, [
      { input: "090-1234-5678", expected: "***-****-5678" },
      { input: "Call (555) 123-4567", expected: "Call (***) ***-4567" },
      { input: "Intl: +81 3 1234 5678", expected: "Intl: +** * **** 5678" },
      { input: "+1 (800) 123-4567", expected: "+* (***) ***-4567" },
    ]);
  });

  test("short numbers and boundary lengths", () => {
    const masker = new Masker().maskPhones();
    assertCases(masker, [
      { input: "1234", expected: "1234" },
      { input: "12345", expected: "*2345" },
      { input: "12-3456", expected: "**-3456" },
    ]);
  });

  test("mixed text", () => {
    const masker = new Masker().maskPhones();
    assertCases(masker, [
      { input: "Tel: 090-1234-5678 ext. 99", expected: "Tel: ***-****-5678 ext. 99" },
      { input: "Numbers: 111-2222 and 333-4444", expected: "Numbers: ***-2222 and ***-4444" },
    ]);
  });

  test("edge cases", () => {
    const masker = new Masker().maskPhones();
    assertCases(masker, [
      { input: "abcdef", expected: "abcdef" },
      { input: "+", expected: "+" },
      { input: "(12) 345 678", expected: "(**) **5 678" },
    ]);
  });
});

describe("Combined masking", () => {
  test("emails and phones", () => {
    const masker = new Masker().maskEmails().maskPhones();
    assertCases(masker, [
      {
        input: "Contact: alice@example.com or 090-1234-5678.",
        expected: "Contact: a****@example.com or ***-****-5678.",
      },
      {
        input: "Email bob@example.org, phone +1 (800) 123-4567",
        expected: "Email b**@example.org, phone +* (***) ***-4567",
      },
    ]);
  });
});

describe("Custom mask character", () => {
  test("custom character", () => {
    const emailMasker = new Masker().maskEmails().withMaskChar("#");
    const phoneMasker = new Masker().maskPhones().withMaskChar("#");
    const combined = new Masker().maskEmails().maskPhones().withMaskChar("#");

    assertCases(emailMasker, [{ input: "alice@example.com", expected: "a####@example.com" }]);
    assertCases(phoneMasker, [{ input: "090-1234-5678", expected: "###-####-5678" }]);

    expect(combined.process("Contact: alice@example.com or 090-1234-5678.")).toBe(
      "Contact: a####@example.com or ###-####-5678."
    );
  });
});

describe("Masker configuration", () => {
  test("behavior by enabled masks", () => {
    const input = "alice@example.com 090-1234-5678";

    const passthrough = new Masker();
    expect(passthrough.process(input)).toBe(input);

    const emailOnly = new Masker().maskEmails();
    expect(emailOnly.process(input)).toBe("a****@example.com 090-1234-5678");

    const phoneOnly = new Masker().maskPhones();
    expect(phoneOnly.process(input)).toBe("alice@example.com ***-****-5678");

    const both = new Masker().maskEmails().maskPhones();
    expect(both.process(input)).toBe("a****@example.com ***-****-5678");
  });
});

describe("Stability", () => {
  test("non-ASCII text is preserved", () => {
    const masker = new Masker().maskEmails().maskPhones();
    const input = "連絡先: alice@example.com と 090-1234-5678";
    const expected = "連絡先: a****@example.com と ***-****-5678";
    expect(masker.process(input)).toBe(expected);
  });
});
