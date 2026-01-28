/**
 * The current version of the mask-pii Deno module.
 */
export const VERSION = "0.2.0";

/**
 * A configurable masker for emails and phone numbers.
 */
export class Masker {
  private maskEmail = false;
  private maskPhone = false;
  private maskChar = "*";

  /**
   * Create a new masker with all masks disabled by default.
   */
  constructor() {}

  /**
   * Enable email address masking.
   */
  maskEmails(): Masker {
    this.maskEmail = true;
    return this;
  }

  /**
   * Enable phone number masking.
   */
  maskPhones(): Masker {
    this.maskPhone = true;
    return this;
  }

  /**
   * Set the character used for masking.
   */
  withMaskChar(char: string | null | undefined): Masker {
    if (!char || char.length === 0) {
      this.maskChar = "*";
    } else {
      this.maskChar = char[0];
    }
    return this;
  }

  /**
   * Process input text and mask enabled PII patterns.
   */
  process(input: string): string {
    if (!this.maskEmail && !this.maskPhone) {
      return input;
    }

    const maskChar = this.maskChar || "*";
    let result = input;
    if (this.maskEmail) {
      result = maskEmailsInText(result, maskChar);
    }
    if (this.maskPhone) {
      result = maskPhonesInText(result, maskChar);
    }
    return result;
  }
}

function maskEmailsInText(input: string, maskChar: string): string {
  const length = input.length;
  const output: string[] = [];
  let last = 0;
  let i = 0;

  while (i < length) {
    if (input[i] === "@") {
      let localStart = i;
      while (localStart > 0 && isLocalChar(input[localStart - 1])) {
        localStart -= 1;
      }
      const localEnd = i;

      const domainStart = i + 1;
      let domainEnd = domainStart;
      while (domainEnd < length && isDomainChar(input[domainEnd])) {
        domainEnd += 1;
      }

      if (localStart < localEnd && domainStart < domainEnd) {
        let candidateEnd = domainEnd;
        let matchedEnd = -1;
        while (candidateEnd > domainStart) {
          const domain = input.slice(domainStart, candidateEnd);
          if (isValidDomain(domain)) {
            matchedEnd = candidateEnd;
            break;
          }
          candidateEnd -= 1;
        }

        if (matchedEnd !== -1) {
          const local = input.slice(localStart, localEnd);
          const domain = input.slice(domainStart, matchedEnd);
          output.push(input.slice(last, localStart));
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

  output.push(input.slice(last));
  return output.join("");
}

function maskPhonesInText(input: string, maskChar: string): string {
  const length = input.length;
  const output: string[] = [];
  let last = 0;
  let i = 0;

  while (i < length) {
    if (isPhoneStart(input[i])) {
      let end = i;
      while (end < length && isPhoneChar(input[end])) {
        end += 1;
      }

      let digitCount = 0;
      let lastDigitIndex = -1;
      for (let idx = i; idx < end; idx += 1) {
        if (isDigit(input[idx])) {
          digitCount += 1;
          lastDigitIndex = idx;
        }
      }

      if (lastDigitIndex !== -1) {
        const candidateEnd = lastDigitIndex + 1;
        if (digitCount >= 5) {
          const candidate = input.slice(i, candidateEnd);
          output.push(input.slice(last, i));
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

  output.push(input.slice(last));
  return output.join("");
}

function maskLocal(local: string, maskChar: string): string {
  if (local.length > 1) {
    return local[0] + maskChar.repeat(local.length - 1);
  }
  return maskChar;
}

function maskPhoneCandidate(candidate: string, maskChar: string): string {
  let digitCount = 0;
  for (const ch of candidate) {
    if (isDigit(ch)) {
      digitCount += 1;
    }
  }

  let currentIndex = 0;
  const result: string[] = [];
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

function isLocalChar(ch: string): boolean {
  return isAlpha(ch) || isDigit(ch) || ch === "." || ch === "_" ||
    ch === "%" || ch === "+" || ch === "-";
}

function isDomainChar(ch: string): boolean {
  return isAlpha(ch) || isDigit(ch) || ch === "-" || ch === ".";
}

function isValidDomain(domain: string): boolean {
  if (domain.length === 0 || domain.startsWith(".") || domain.endsWith(".")) {
    return false;
  }

  const parts = domain.split(".");
  if (parts.length < 2) {
    return false;
  }

  for (const part of parts) {
    if (part.length === 0) {
      return false;
    }
    if (part.startsWith("-") || part.endsWith("-")) {
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

function isPhoneStart(ch: string): boolean {
  return isDigit(ch) || ch === "+" || ch === "(";
}

function isPhoneChar(ch: string): boolean {
  return isDigit(ch) || ch === " " || ch === "-" || ch === "(" ||
    ch === ")" || ch === "+";
}

function isDigit(ch: string): boolean {
  return ch >= "0" && ch <= "9";
}

function isAlpha(ch: string): boolean {
  return (ch >= "a" && ch <= "z") || (ch >= "A" && ch <= "Z");
}

function isAlphaNumeric(ch: string): boolean {
  return isAlpha(ch) || isDigit(ch);
}
