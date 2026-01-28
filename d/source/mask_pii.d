module mask_pii;

import std.array : appender;
import std.conv : to;
import std.string : split;

/// The current version of the mask_pii package.
enum string VERSION = "0.2.0";

/// A configurable masker for emails and phone numbers.
struct Masker {
    private bool maskEmail = false;
    private bool maskPhone = false;
    private char maskChar = '*';

    /// Enable email address masking.
    Masker maskEmails() {
        auto updated = this;
        updated.maskEmail = true;
        return updated;
    }

    /// Enable phone number masking.
    Masker maskPhones() {
        auto updated = this;
        updated.maskPhone = true;
        return updated;
    }

    /// Set the character used for masking.
    Masker withMaskChar(char c) {
        auto updated = this;
        updated.maskChar = c == '\0' ? '*' : c;
        return updated;
    }

    /// Process input text and mask enabled PII patterns.
    string process(string inputText) const {
        if (!maskEmail && !maskPhone) {
            return inputText;
        }

        char effectiveMask = maskChar == '\0' ? '*' : maskChar;
        string result = inputText;
        if (maskEmail) {
            result = maskEmailsInText(result, effectiveMask);
        }
        if (maskPhone) {
            result = maskPhonesInText(result, effectiveMask);
        }
        return result;
    }
}

private:

string maskEmailsInText(string inputText, char maskChar) {
    auto bytes = cast(const(ubyte)[]) inputText;
    size_t len = bytes.length;
    auto output = appender!string();
    size_t last = 0;
    size_t i = 0;

    while (i < len) {
        if (bytes[i] == cast(ubyte) '@') {
            size_t localStart = i;
            while (localStart > 0 && isLocalByte(bytes[localStart - 1])) {
                localStart -= 1;
            }
            size_t localEnd = i;

            size_t domainStart = i + 1;
            size_t domainEnd = domainStart;
            while (domainEnd < len && isDomainByte(bytes[domainEnd])) {
                domainEnd += 1;
            }

            if (localStart < localEnd && domainStart < domainEnd) {
                size_t candidateEnd = domainEnd;
                size_t matchedEnd = 0;
                bool matched = false;
                while (candidateEnd > domainStart) {
                    string domain = inputText[domainStart .. candidateEnd];
                    if (isValidDomain(domain)) {
                        matchedEnd = candidateEnd;
                        matched = true;
                        break;
                    }
                    candidateEnd -= 1;
                }

                if (matched) {
                    string local = inputText[localStart .. localEnd];
                    string domain = inputText[domainStart .. matchedEnd];
                    output.put(inputText[last .. localStart]);
                    output.put(maskLocal(local, maskChar));
                    output.put('@');
                    output.put(domain);
                    last = matchedEnd;
                    i = matchedEnd;
                    continue;
                }
            }
        }
        i += 1;
    }

    output.put(inputText[last .. $]);
    return output.data;
}

string maskPhonesInText(string inputText, char maskChar) {
    auto bytes = cast(const(ubyte)[]) inputText;
    size_t len = bytes.length;
    auto output = appender!string();
    size_t last = 0;
    size_t i = 0;

    while (i < len) {
        if (isPhoneStart(bytes[i])) {
            size_t end = i;
            while (end < len && isPhoneChar(bytes[end])) {
                end += 1;
            }

            size_t digitCount = 0;
            size_t lastDigitIndex = 0;
            bool hasLastDigit = false;
            for (size_t idx = i; idx < end; idx += 1) {
                if (isDigit(bytes[idx])) {
                    digitCount += 1;
                    lastDigitIndex = idx;
                    hasLastDigit = true;
                }
            }

            if (hasLastDigit) {
                size_t candidateEnd = lastDigitIndex + 1;
                if (digitCount >= 5) {
                    string candidate = inputText[i .. candidateEnd];
                    output.put(inputText[last .. i]);
                    output.put(maskPhoneCandidate(candidate, maskChar));
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

    output.put(inputText[last .. $]);
    return output.data;
}

string maskLocal(string local, char maskChar) {
    if (local.length > 1) {
        auto output = appender!string();
        output.put(local[0]);
        for (size_t idx = 1; idx < local.length; idx += 1) {
            output.put(maskChar);
        }
        return output.data;
    }
    return to!string(maskChar);
}

string maskPhoneCandidate(string candidate, char maskChar) {
    auto bytes = cast(const(ubyte)[]) candidate;
    size_t digitCount = 0;
    foreach (byteValue; bytes) {
        if (isDigit(byteValue)) {
            digitCount += 1;
        }
    }

    size_t currentIndex = 0;
    auto output = appender!string();
    foreach (byteValue; bytes) {
        if (isDigit(byteValue)) {
            currentIndex += 1;
            if (digitCount > 4 && currentIndex <= digitCount - 4) {
                output.put(maskChar);
            } else {
                output.put(cast(char) byteValue);
            }
        } else {
            output.put(cast(char) byteValue);
        }
    }

    return output.data;
}

bool isLocalByte(ubyte byteValue) {
    return isAlpha(byteValue)
        || isDigit(byteValue)
        || byteValue == cast(ubyte) '.'
        || byteValue == cast(ubyte) '_'
        || byteValue == cast(ubyte) '%'
        || byteValue == cast(ubyte) '+'
        || byteValue == cast(ubyte) '-';
}

bool isDomainByte(ubyte byteValue) {
    return isAlpha(byteValue)
        || isDigit(byteValue)
        || byteValue == cast(ubyte) '-'
        || byteValue == cast(ubyte) '.';
}

bool isValidDomain(string domain) {
    if (domain.length == 0 || domain[0] == '.' || domain[$ - 1] == '.') {
        return false;
    }

    string[] parts = split(domain, ".");
    if (parts.length < 2) {
        return false;
    }

    foreach (part; parts) {
        if (part.length == 0) {
            return false;
        }
        if (part[0] == '-' || part[$ - 1] == '-') {
            return false;
        }
        foreach (ch; part) {
            ubyte byteValue = cast(ubyte) ch;
            if (!(isAlnum(byteValue) || byteValue == cast(ubyte) '-')) {
                return false;
            }
        }
    }

    string tld = parts[$ - 1];
    if (tld.length < 2) {
        return false;
    }
    foreach (ch; tld) {
        if (!isAlpha(cast(ubyte) ch)) {
            return false;
        }
    }

    return true;
}

bool isPhoneStart(ubyte byteValue) {
    return isDigit(byteValue) || byteValue == cast(ubyte) '+' || byteValue == cast(ubyte) '(';
}

bool isPhoneChar(ubyte byteValue) {
    return isDigit(byteValue)
        || byteValue == cast(ubyte) ' '
        || byteValue == cast(ubyte) '-'
        || byteValue == cast(ubyte) '('
        || byteValue == cast(ubyte) ')'
        || byteValue == cast(ubyte) '+';
}

bool isDigit(ubyte byteValue) {
    return byteValue >= cast(ubyte) '0' && byteValue <= cast(ubyte) '9';
}

bool isAlpha(ubyte byteValue) {
    return (byteValue >= cast(ubyte) 'a' && byteValue <= cast(ubyte) 'z')
        || (byteValue >= cast(ubyte) 'A' && byteValue <= cast(ubyte) 'Z');
}

bool isAlnum(ubyte byteValue) {
    return isAlpha(byteValue) || isDigit(byteValue);
}

unittest {
    struct MaskCase {
        string input;
        string expected;
    }

    void assertCases(Masker masker, const MaskCase[] cases) {
        foreach (testCase; cases) {
            assert(masker.process(testCase.input) == testCase.expected);
        }
    }

    auto emailMasker = Masker().maskEmails();
    assertCases(emailMasker, [
        MaskCase("alice@example.com", "a****@example.com"),
        MaskCase("a@b.com", "*@b.com"),
        MaskCase("ab@example.com", "a*@example.com"),
        MaskCase("a.b+c_d@example.co.jp", "a******@example.co.jp"),
    ]);

    assertCases(emailMasker, [
        MaskCase("Contact: alice@example.com.", "Contact: a****@example.com."),
        MaskCase(
            "alice@example.com and bob@example.org",
            "a****@example.com and b**@example.org",
        ),
    ]);

    assertCases(emailMasker, [
        MaskCase("alice@example", "alice@example"),
        MaskCase("alice@localhost", "alice@localhost"),
        MaskCase("alice@@example.com", "alice@@example.com"),
        MaskCase(
            "first.last+tag@sub.domain.com",
            "f*************@sub.domain.com",
        ),
    ]);

    auto phoneMasker = Masker().maskPhones();
    assertCases(phoneMasker, [
        MaskCase("090-1234-5678", "***-****-5678"),
        MaskCase("Call (555) 123-4567", "Call (***) ***-4567"),
        MaskCase("Intl: +81 3 1234 5678", "Intl: +** * **** 5678"),
        MaskCase("+1 (800) 123-4567", "+* (***) ***-4567"),
    ]);

    assertCases(phoneMasker, [
        MaskCase("1234", "1234"),
        MaskCase("12345", "*2345"),
        MaskCase("12-3456", "**-3456"),
    ]);

    assertCases(phoneMasker, [
        MaskCase("Tel: 090-1234-5678 ext. 99", "Tel: ***-****-5678 ext. 99"),
        MaskCase("Numbers: 111-2222 and 333-4444", "Numbers: ***-2222 and ***-4444"),
    ]);

    assertCases(phoneMasker, [
        MaskCase("abcdef", "abcdef"),
        MaskCase("+", "+"),
        MaskCase("(12) 345 678", "(**) **5 678"),
    ]);

    auto combined = Masker().maskEmails().maskPhones();
    assertCases(combined, [
        MaskCase(
            "Contact: alice@example.com or 090-1234-5678.",
            "Contact: a****@example.com or ***-****-5678.",
        ),
        MaskCase(
            "Email bob@example.org, phone +1 (800) 123-4567",
            "Email b**@example.org, phone +* (***) ***-4567",
        ),
    ]);

    auto emailCustom = Masker().maskEmails().withMaskChar('#');
    auto phoneCustom = Masker().maskPhones().withMaskChar('#');
    auto combinedCustom = Masker().maskEmails().maskPhones().withMaskChar('#');

    assertCases(emailCustom, [MaskCase("alice@example.com", "a####@example.com")]);
    assertCases(phoneCustom, [MaskCase("090-1234-5678", "###-####-5678")]);
    assert(
        combinedCustom.process("Contact: alice@example.com or 090-1234-5678.")
        == "Contact: a####@example.com or ###-####-5678."
    );

    string input = "alice@example.com 090-1234-5678";
    assert(Masker().process(input) == input);
    assert(
        Masker().maskEmails().process(input)
        == "a****@example.com 090-1234-5678"
    );
    assert(
        Masker().maskPhones().process(input)
        == "alice@example.com ***-****-5678"
    );
    assert(
        Masker().maskEmails().maskPhones().process(input)
        == "a****@example.com ***-****-5678"
    );

    auto nonAsciiMasker = Masker().maskEmails().maskPhones();
    assert(
        nonAsciiMasker.process("連絡先: alice@example.com と 090-1234-5678")
        == "連絡先: a****@example.com と ***-****-5678"
    );
}
