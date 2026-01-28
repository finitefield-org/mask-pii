package org.finitefield.maskpii

/**
 * A configurable masker for emails and phone numbers.
 */
class Masker {
    private boolean maskEmail = false
    private boolean maskPhone = false
    private char maskChar = '*'

    /**
     * Create a new masker with all masks disabled by default.
     */
    Masker() {
    }

    /**
     * Enable email address masking.
     *
     * @return this masker instance
     */
    Masker maskEmails() {
        maskEmail = true
        return this
    }

    /**
     * Enable phone number masking.
     *
     * @return this masker instance
     */
    Masker maskPhones() {
        maskPhone = true
        return this
    }

    /**
     * Set the character used for masking.
     *
     * @param charValue the masking character (uses the first character of the input)
     * @return this masker instance
     */
    Masker withMaskChar(Object charValue) {
        if (!charValue) {
            maskChar = '*'
            return this
        }
        String value = charValue.toString()
        maskChar = value ? value.charAt(0) : '*'
        return this
    }

    /**
     * Process input text and mask enabled PII patterns.
     *
     * @param inputText input text to process
     * @return masked text
     */
    String process(String inputText) {
        if (!maskEmail && !maskPhone) {
            return inputText
        }

        char activeMask = maskChar ?: '*'
        String result = inputText
        if (maskEmail) {
            result = maskEmailsInText(result, activeMask)
        }
        if (maskPhone) {
            result = maskPhonesInText(result, activeMask)
        }
        return result
    }

    private static String maskEmailsInText(String inputText, char maskChar) {
        int length = inputText.length()
        StringBuilder output = new StringBuilder()
        int last = 0
        int i = 0

        while (i < length) {
            if (inputText.charAt(i) == '@') {
                int localStart = i
                while (localStart > 0 && isLocalChar(inputText.charAt(localStart - 1))) {
                    localStart--
                }
                int localEnd = i

                int domainStart = i + 1
                int domainEnd = domainStart
                while (domainEnd < length && isDomainChar(inputText.charAt(domainEnd))) {
                    domainEnd++
                }

                if (localStart < localEnd && domainStart < domainEnd) {
                    int candidateEnd = domainEnd
                    int matchedEnd = -1
                    while (candidateEnd > domainStart) {
                        String domain = inputText.substring(domainStart, candidateEnd)
                        if (isValidDomain(domain)) {
                            matchedEnd = candidateEnd
                            break
                        }
                        candidateEnd--
                    }

                    if (matchedEnd != -1) {
                        String local = inputText.substring(localStart, localEnd)
                        String domain = inputText.substring(domainStart, matchedEnd)
                        output.append(inputText, last, localStart)
                        output.append(maskLocal(local, maskChar))
                        output.append('@')
                        output.append(domain)
                        last = matchedEnd
                        i = matchedEnd
                        continue
                    }
                }
            }
            i++
        }

        output.append(inputText, last, length)
        return output.toString()
    }

    private static String maskPhonesInText(String inputText, char maskChar) {
        int length = inputText.length()
        StringBuilder output = new StringBuilder()
        int last = 0
        int i = 0

        while (i < length) {
            if (isPhoneStart(inputText.charAt(i))) {
                int end = i
                while (end < length && isPhoneChar(inputText.charAt(end))) {
                    end++
                }

                int digitCount = 0
                int lastDigitIndex = -1
                for (int idx = i; idx < end; idx++) {
                    if (isDigit(inputText.charAt(idx))) {
                        digitCount++
                        lastDigitIndex = idx
                    }
                }

                if (lastDigitIndex != -1) {
                    int candidateEnd = lastDigitIndex + 1
                    if (digitCount >= 5) {
                        String candidate = inputText.substring(i, candidateEnd)
                        output.append(inputText, last, i)
                        output.append(maskPhoneCandidate(candidate, maskChar))
                        last = candidateEnd
                        i = candidateEnd
                        continue
                    }
                }

                i = end
                continue
            }
            i++
        }

        output.append(inputText, last, length)
        return output.toString()
    }

    private static String maskLocal(String local, char maskChar) {
        if (local.length() > 1) {
            StringBuilder builder = new StringBuilder()
            builder.append(local.charAt(0))
            for (int i = 1; i < local.length(); i++) {
                builder.append(maskChar)
            }
            return builder.toString()
        }
        return String.valueOf(maskChar)
    }

    private static String maskPhoneCandidate(String candidate, char maskChar) {
        int digitCount = 0
        for (int i = 0; i < candidate.length(); i++) {
            if (isDigit(candidate.charAt(i))) {
                digitCount++
            }
        }

        int currentIndex = 0
        StringBuilder result = new StringBuilder()
        for (int i = 0; i < candidate.length(); i++) {
            char ch = candidate.charAt(i)
            if (isDigit(ch)) {
                currentIndex++
                if (digitCount > 4 && currentIndex <= digitCount - 4) {
                    result.append(maskChar)
                } else {
                    result.append(ch)
                }
            } else {
                result.append(ch)
            }
        }

        return result.toString()
    }

    private static boolean isLocalChar(char ch) {
        return isAlpha(ch) || isDigit(ch) || ch == '.' || ch == '_' || ch == '%' || ch == '+' || ch == '-'
    }

    private static boolean isDomainChar(char ch) {
        return isAlpha(ch) || isDigit(ch) || ch == '-' || ch == '.'
    }

    private static boolean isValidDomain(String domain) {
        if (!domain || domain.charAt(0) == '.' || domain.charAt(domain.length() - 1) == '.') {
            return false
        }

        String[] parts = domain.split('\\.')
        if (parts.length < 2) {
            return false
        }

        for (String part : parts) {
            if (!part) {
                return false
            }
            if (part.charAt(0) == '-' || part.charAt(part.length() - 1) == '-') {
                return false
            }
            for (int i = 0; i < part.length(); i++) {
                char ch = part.charAt(i)
                if (!(isAlnum(ch) || ch == '-')) {
                    return false
                }
            }
        }

        String tld = parts[parts.length - 1]
        if (tld.length() < 2) {
            return false
        }
        for (int i = 0; i < tld.length(); i++) {
            if (!isAlpha(tld.charAt(i))) {
                return false
            }
        }

        return true
    }

    private static boolean isPhoneStart(char ch) {
        return isDigit(ch) || ch == '+' || ch == '('
    }

    private static boolean isPhoneChar(char ch) {
        return isDigit(ch) || ch == ' ' || ch == '-' || ch == '(' || ch == ')' || ch == '+'
    }

    private static boolean isDigit(char ch) {
        return ch >= '0' && ch <= '9'
    }

    private static boolean isAlpha(char ch) {
        return (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z')
    }

    private static boolean isAlnum(char ch) {
        return isAlpha(ch) || isDigit(ch)
    }
}
