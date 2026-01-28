import { Masker } from "https://deno.land/x/mask_pii@v0.2.0/mod.ts";

const masker = new Masker()
  .maskEmails()
  .maskPhones()
  .withMaskChar("#");

const inputText = "Contact: alice@example.com or 090-1234-5678.";
console.log(masker.process(inputText));
