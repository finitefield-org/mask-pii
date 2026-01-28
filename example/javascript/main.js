"use strict";

const { Masker } = require("../../javascript/src/index.js");

const masker = new Masker()
  .maskEmails()
  .maskPhones()
  .withMaskChar("#");

const input = "Contact: alice@example.com or 090-1234-5678.";
const output = masker.process(input);
console.log(output);
