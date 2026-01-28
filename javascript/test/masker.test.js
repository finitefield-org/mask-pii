"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const { Masker } = require("../src/index.js");

function maskWith({ emails, phones, maskChar }, input) {
  const masker = new Masker();
  if (emails) {
    masker.maskEmails();
  }
  if (phones) {
    masker.maskPhones();
  }
  if (maskChar !== undefined) {
    masker.withMaskChar(maskChar);
  }
  return masker.process(input);
}

test("Masker configuration behavior", () => {
  const input = "Contact: alice@example.com or 090-1234-5678.";
  assert.equal(maskWith({}, input), input);
  assert.equal(
    maskWith({ emails: true }, input),
    "Contact: a****@example.com or 090-1234-5678."
  );
  assert.equal(
    maskWith({ phones: true }, input),
    "Contact: alice@example.com or ***-****-5678."
  );
  assert.equal(
    maskWith({ emails: true, phones: true }, input),
    "Contact: a****@example.com or ***-****-5678."
  );
});

test("Email masking basic cases", () => {
  assert.equal(
    maskWith({ emails: true }, "alice@example.com"),
    "a****@example.com"
  );
  assert.equal(maskWith({ emails: true }, "a@b.com"), "*@b.com");
  assert.equal(
    maskWith({ emails: true }, "ab@example.com"),
    "a*@example.com"
  );
  assert.equal(
    maskWith({ emails: true }, "a.b+c_d@example.co.jp"),
    "a******@example.co.jp"
  );
});

test("Email masking mixed text", () => {
  assert.equal(
    maskWith({ emails: true }, "Contact: alice@example.com."),
    "Contact: a****@example.com."
  );
  assert.equal(
    maskWith({ emails: true }, "alice@example.com and bob@example.org"),
    "a****@example.com and b**@example.org"
  );
});

test("Email masking edge cases", () => {
  assert.equal(
    maskWith({ emails: true }, "alice@example"),
    "alice@example"
  );
  assert.equal(
    maskWith({ emails: true }, "alice@localhost"),
    "alice@localhost"
  );
  assert.equal(
    maskWith({ emails: true }, "alice@@example.com"),
    "alice@@example.com"
  );
  assert.equal(
    maskWith({ emails: true }, "first.last+tag@sub.domain.com"),
    "f*************@sub.domain.com"
  );
});

test("Phone masking basic cases", () => {
  assert.equal(
    maskWith({ phones: true }, "090-1234-5678"),
    "***-****-5678"
  );
  assert.equal(
    maskWith({ phones: true }, "Call (555) 123-4567"),
    "Call (***) ***-4567"
  );
  assert.equal(
    maskWith({ phones: true }, "Intl: +81 3 1234 5678"),
    "Intl: +** * **** 5678"
  );
  assert.equal(
    maskWith({ phones: true }, "+1 (800) 123-4567"),
    "+* (***) ***-4567"
  );
});

test("Phone masking short numbers", () => {
  assert.equal(maskWith({ phones: true }, "1234"), "1234");
  assert.equal(maskWith({ phones: true }, "12345"), "*2345");
  assert.equal(maskWith({ phones: true }, "12-3456"), "**-3456");
});

test("Phone masking mixed text", () => {
  assert.equal(
    maskWith({ phones: true }, "Tel: 090-1234-5678 ext. 99"),
    "Tel: ***-****-5678 ext. 99"
  );
  assert.equal(
    maskWith({ phones: true }, "Numbers: 111-2222 and 333-4444"),
    "Numbers: ***-2222 and ***-4444"
  );
});

test("Phone masking edge cases", () => {
  assert.equal(maskWith({ phones: true }, "abcdef"), "abcdef");
  assert.equal(maskWith({ phones: true }, "+"), "+");
  assert.equal(
    maskWith({ phones: true }, "(12) 345 678"),
    "(**) **5 678"
  );
});

test("Combined masking", () => {
  assert.equal(
    maskWith(
      { emails: true, phones: true },
      "Contact: alice@example.com or 090-1234-5678."
    ),
    "Contact: a****@example.com or ***-****-5678."
  );
  assert.equal(
    maskWith(
      { emails: true, phones: true },
      "Email bob@example.org, phone +1 (800) 123-4567"
    ),
    "Email b**@example.org, phone +* (***) ***-4567"
  );
});

test("Custom mask character", () => {
  assert.equal(
    maskWith({ emails: true, maskChar: "#" }, "alice@example.com"),
    "a####@example.com"
  );
  assert.equal(
    maskWith({ phones: true, maskChar: "#" }, "090-1234-5678"),
    "###-####-5678"
  );
  assert.equal(
    maskWith(
      { emails: true, phones: true, maskChar: "#" },
      "Contact: alice@example.com or 090-1234-5678."
    ),
    "Contact: a####@example.com or ###-####-5678."
  );
});
