"use strict";

/**
 * A configurable masker for emails and phone numbers.
 */
class Masker {
  /**
   * Create a new masker with all masks disabled by default.
   */
  constructor() {
    this._maskEmail = false;
    this._maskPhone = false;
    this._maskChar = "*";
  }

  /**
   * Enable email address masking.
   * @returns {Masker} The current masker instance.
   */
  maskEmails() {
    this._maskEmail = true;
    return this;
  }

  /**
   * Enable phone number masking.
   * @returns {Masker} The current masker instance.
   */
  maskPhones() {
    this._maskPhone = true;
    return this;
  }

  /**
   * Set the character used for masking.
   * @param {string|number|null|undefined} char The mask character.
   * @returns {Masker} The current masker instance.
   */
  withMaskChar(char) {
    if (!char) {
      this._maskChar = "*";
      return this;
    }
    let value = char;
    if (typeof value !== "string") {
      value = String(value);
    }
    this._maskChar = value ? value[0] : "*";
    return this;
  }

  /**
   * Process input text and mask enabled PII patterns.
   * @param {string} inputText The input text to scan.
   * @returns {string} The masked output.
   */
  process(inputText) {
    if (!this._maskEmail && !this._maskPhone) {
      return inputText;
    }

    const maskChar = this._maskChar || "*";
    let result = inputText;
    if (this._maskEmail) {
      result = maskEmailsInText(result, maskChar);
    }
    if (this._maskPhone) {
      result = maskPhonesInText(result, maskChar);
    }
    return result;
  }
}

/**
 * Mask email addresses found in text.
 * @param {string} inputText The input string.
 * @param {string} maskChar The mask character.
 * @returns {string} The masked string.
 */
function maskEmailsInText(inputText, maskChar) {
  const length = inputText.length;
  const output = [];
  let last = 0;
  let i = 0;

  while (i < length) {
    if (inputText[i] === "@") {
      let localStart = i;
      while (localStart > 0 && isLocalChar(inputText[localStart - 1])) {
        localStart -= 1;
      }
      const localEnd = i;

      const domainStart = i + 1;
      let domainEnd = domainStart;
      while (domainEnd < length && isDomainChar(inputText[domainEnd])) {
        domainEnd += 1;
      }

      if (localStart < localEnd && domainStart < domainEnd) {
        let candidateEnd = domainEnd;
        let matchedEnd = -1;
        while (candidateEnd > domainStart) {
          const domain = inputText.slice(domainStart, candidateEnd);
          if (isValidDomain(domain)) {
            matchedEnd = candidateEnd;
            break;
          }
          candidateEnd -= 1;
        }

        if (matchedEnd !== -1) {
          const local = inputText.slice(localStart, localEnd);
          const domain = inputText.slice(domainStart, matchedEnd);
          output.push(inputText.slice(last, localStart));
          output.push(maskLocal(local, maskChar));
          output.push("@");
          output.push(domain);
          last = matchedEnd;
          i = matchedEnd;
          continue;
        }
      }
    }
    i += 1;
  }

  output.push(inputText.slice(last));
  return output.join("");
}

/**
 * Mask phone numbers found in text.
 * @param {string} inputText The input string.
 * @param {string} maskChar The mask character.
 * @returns {string} The masked string.
 */
function maskPhonesInText(inputText, maskChar) {
  const length = inputText.length;
  const output = [];
  let last = 0;
  let i = 0;

  while (i < length) {
    if (isPhoneStart(inputText[i])) {
      let end = i;
      while (end < length && isPhoneChar(inputText[end])) {
        end += 1;
      }

      let digitCount = 0;
      let lastDigitIndex = -1;
      for (let idx = i; idx < end; idx += 1) {
        if (isDigit(inputText[idx])) {
          digitCount += 1;
          lastDigitIndex = idx;
        }
      }

      if (lastDigitIndex !== -1) {
        const candidateEnd = lastDigitIndex + 1;
        if (digitCount >= 5) {
          const candidate = inputText.slice(i, candidateEnd);
          output.push(inputText.slice(last, i));
          output.push(maskPhoneCandidate(candidate, maskChar));
          last = candidateEnd;
          i = candidateEnd;
          continue;
        }
      }

      i = end;
      continue;
    }
    i += 1;
  }

  output.push(inputText.slice(last));
  return output.join("");
}

/**
 * Mask the local part of an email address.
 * @param {string} local The local part.
 * @param {string} maskChar The mask character.
 * @returns {string} The masked local part.
 */
function maskLocal(local, maskChar) {
  if (local.length > 1) {
    return local[0] + maskChar.repeat(local.length - 1);
  }
  return maskChar;
}

/**
 * Mask a phone number candidate string.
 * @param {string} candidate The candidate phone string.
 * @param {string} maskChar The mask character.
 * @returns {string} The masked candidate.
 */
function maskPhoneCandidate(candidate, maskChar) {
  let digitCount = 0;
  for (const ch of candidate) {
    if (isDigit(ch)) {
      digitCount += 1;
    }
  }

  let currentIndex = 0;
  const result = [];
  for (const ch of candidate) {
    if (isDigit(ch)) {
      currentIndex += 1;
      if (digitCount > 4 && currentIndex <= digitCount - 4) {
        result.push(maskChar);
      } else {
        result.push(ch);
      }
    } else {
      result.push(ch);
    }
  }
  return result.join("");
}

/**
 * Check if a character is valid in the local part of an email address.
 * @param {string} ch The character to check.
 * @returns {boolean} True if the character is valid.
 */
function isLocalChar(ch) {
  return (
    isAlpha(ch) ||
    isDigit(ch) ||
    ch === "." ||
    ch === "_" ||
    ch === "%" ||
    ch === "+" ||
    ch === "-"
  );
}

/**
 * Check if a character is valid in the domain part of an email address.
 * @param {string} ch The character to check.
 * @returns {boolean} True if the character is valid.
 */
function isDomainChar(ch) {
  return isAlpha(ch) || isDigit(ch) || ch === "-" || ch === ".";
}

/**
 * Validate a domain string.
 * @param {string} domain The domain string.
 * @returns {boolean} True if the domain is valid.
 */
function isValidDomain(domain) {
  if (!domain || domain[0] === "." || domain[domain.length - 1] === ".") {
    return false;
  }

  const parts = domain.split(".");
  if (parts.length < 2) {
    return false;
  }

  for (const part of parts) {
    if (!part) {
      return false;
    }
    if (part[0] === "-" || part[part.length - 1] === "-") {
      return false;
    }
    for (const ch of part) {
      if (!(isAlphaNumeric(ch) || ch === "-")) {
        return false;
      }
    }
  }

  const tld = parts[parts.length - 1];
  if (tld.length < 2) {
    return false;
  }
  for (const ch of tld) {
    if (!isAlpha(ch)) {
      return false;
    }
  }

  return true;
}

/**
 * Check if a character can start a phone number.
 * @param {string} ch The character to check.
 * @returns {boolean} True if it can start a phone number.
 */
function isPhoneStart(ch) {
  return isDigit(ch) || ch === "+" || ch === "(";
}

/**
 * Check if a character is allowed in a phone number candidate.
 * @param {string} ch The character to check.
 * @returns {boolean} True if the character is allowed.
 */
function isPhoneChar(ch) {
  return (
    isDigit(ch) ||
    ch === " " ||
    ch === "-" ||
    ch === "(" ||
    ch === ")" ||
    ch === "+"
  );
}

/**
 * Check if a character is a digit.
 * @param {string} ch The character to check.
 * @returns {boolean} True if the character is a digit.
 */
function isDigit(ch) {
  return ch >= "0" && ch <= "9";
}

/**
 * Check if a character is an ASCII alphabetic letter.
 * @param {string} ch The character to check.
 * @returns {boolean} True if the character is alphabetic.
 */
function isAlpha(ch) {
  return (ch >= "a" && ch <= "z") || (ch >= "A" && ch <= "Z");
}

/**
 * Check if a character is an ASCII alphanumeric character.
 * @param {string} ch The character to check.
 * @returns {boolean} True if the character is alphanumeric.
 */
function isAlphaNumeric(ch) {
  return isAlpha(ch) || isDigit(ch);
}

module.exports = {
  Masker,
};
