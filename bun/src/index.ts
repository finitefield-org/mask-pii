/**
 * A configurable masker for common PII such as emails and phone numbers.
 */
export class Masker {
  private maskEmail = false;
  private maskPhone = false;
  private maskChar = "*";

  /**
   * Enables email address masking.
   */
  maskEmails(): this {
    this.maskEmail = true;
    return this;
  }

  /**
   * Enables phone number masking.
   */
  maskPhones(): this {
    this.maskPhone = true;
    return this;
  }

  /**
   * Sets the character used for masking.
   */
  withMaskChar(char: string): this {
    if (char.length === 0) {
      this.maskChar = "*";
      return this;
    }
    this.maskChar = char[0] ?? "*";
    return this;
  }

  /**
   * Scans input text and masks enabled PII patterns.
   */
  process(input: string): string {
    if (!this.maskEmail && !this.maskPhone) {
      return input;
    }

    let result = input;
    if (this.maskEmail) {
      result = maskEmailsInText(result, this.maskChar);
    }
    if (this.maskPhone) {
      result = maskPhonesInText(result, this.maskChar);
    }
    return result;
  }
}

function maskEmailsInText(input: string, maskChar: string): string {
  const length = input.length;
  const output: string[] = [];
  let last = 0;

  for (let i = 0; i < length; i += 1) {
    if (input[i] === "@") {
      let localStart = i;
      while (localStart > 0 && isLocalChar(input.charCodeAt(localStart - 1))) {
        localStart -= 1;
      }
      const localEnd = i;

      const domainStart = i + 1;
      let domainEnd = domainStart;
      while (domainEnd < length && isDomainChar(input.charCodeAt(domainEnd))) {
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
          i = matchedEnd - 1;
        }
      }
    }
  }

  output.push(input.slice(last));
  return output.join("");
}

function maskPhonesInText(input: string, maskChar: string): string {
  const length = input.length;
  const output: string[] = [];
  let last = 0;

  for (let i = 0; i < length; i += 1) {
    if (isPhoneStart(input.charCodeAt(i))) {
      let end = i;
      while (end < length && isPhoneChar(input.charCodeAt(end))) {
        end += 1;
      }

      let digitCount = 0;
      let lastDigitIndex = -1;
      for (let idx = i; idx < end; idx += 1) {
        if (isDigit(input.charCodeAt(idx))) {
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
          i = candidateEnd - 1;
          continue;
        }
      }

      i = end - 1;
    }
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
  for (let i = 0; i < candidate.length; i += 1) {
    if (isDigit(candidate.charCodeAt(i))) {
      digitCount += 1;
    }
  }

  let currentIndex = 0;
  const result: string[] = [];
  for (let i = 0; i < candidate.length; i += 1) {
    const code = candidate.charCodeAt(i);
    if (isDigit(code)) {
      currentIndex += 1;
      if (digitCount > 4 && currentIndex <= digitCount - 4) {
        result.push(maskChar);
      } else {
        result.push(candidate[i]);
      }
    } else {
      result.push(candidate[i]);
    }
  }

  return result.join("");
}

function isLocalChar(code: number): boolean {
  return (
    (code >= 97 && code <= 122) ||
    (code >= 65 && code <= 90) ||
    (code >= 48 && code <= 57) ||
    code === 46 ||
    code === 95 ||
    code === 37 ||
    code === 43 ||
    code === 45
  );
}

function isDomainChar(code: number): boolean {
  return (
    (code >= 97 && code <= 122) ||
    (code >= 65 && code <= 90) ||
    (code >= 48 && code <= 57) ||
    code === 45 ||
    code === 46
  );
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
    for (let i = 0; i < part.length; i += 1) {
      const code = part.charCodeAt(i);
      if (!isAlphaNumeric(code) && code !== 45) {
        return false;
      }
    }
  }

  const tld = parts[parts.length - 1];
  if (tld.length < 2) {
    return false;
  }
  for (let i = 0; i < tld.length; i += 1) {
    if (!isAlpha(tld.charCodeAt(i))) {
      return false;
    }
  }

  return true;
}

function isPhoneStart(code: number): boolean {
  return isDigit(code) || code === 43 || code === 40;
}

function isPhoneChar(code: number): boolean {
  return isDigit(code) || code === 32 || code === 45 || code === 40 || code === 41 || code === 43;
}

function isDigit(code: number): boolean {
  return code >= 48 && code <= 57;
}

function isAlpha(code: number): boolean {
  return (code >= 97 && code <= 122) || (code >= 65 && code <= 90);
}

function isAlphaNumeric(code: number): boolean {
  return isAlpha(code) || isDigit(code);
}
