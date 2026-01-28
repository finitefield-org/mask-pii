import { Masker } from "mask-pii";

const masker = new Masker().maskEmails().maskPhones().withMaskChar("#");

const input = "Contact: alice@example.com or 090-1234-5678.";
const output = masker.process(input);

console.log(output);
// Output: "Contact: a####@example.com or ###-####-5678."
