import Foundation

/// A configurable masker for common PII such as emails and phone numbers.
public final class Masker {
    private var maskEmail: Bool
    private var maskPhone: Bool
    private var maskChar: Character

    /// Creates a new masker with all masks disabled by default.
    public init() {
        self.maskEmail = false
        self.maskPhone = false
        self.maskChar = "*"
    }

    /// Enables email address masking.
    @discardableResult
    public func maskEmails() -> Self {
        maskEmail = true
        return self
    }

    /// Enables phone number masking.
    @discardableResult
    public func maskPhones() -> Self {
        maskPhone = true
        return self
    }

    /// Sets the character used for masking.
    @discardableResult
    public func withMaskChar(_ char: Character) -> Self {
        maskChar = char
        return self
    }

    /// Processes input text and masks enabled PII patterns.
    public func process(_ input: String) -> String {
        var result = input
        let maskBytes = Array(String(maskChar).utf8)

        if maskEmail {
            result = String(decoding: maskEmailsInText(Array(result.utf8), maskChar: maskBytes), as: UTF8.self)
        }

        if maskPhone {
            result = String(decoding: maskPhonesInText(Array(result.utf8), maskChar: maskBytes), as: UTF8.self)
        }

        return result
    }
}

private func maskEmailsInText(_ input: [UInt8], maskChar: [UInt8]) -> [UInt8] {
    let len = input.count
    var output: [UInt8] = []
    output.reserveCapacity(len)

    var last = 0
    var i = 0

    while i < len {
        if input[i] == asciiAt {
            var localStart = i
            while localStart > 0 && isLocalByte(input[localStart - 1]) {
                localStart -= 1
            }
            let localEnd = i
            let domainStart = i + 1
            var domainEnd = domainStart
            while domainEnd < len && isDomainByte(input[domainEnd]) {
                domainEnd += 1
            }

            if localStart < localEnd && domainStart < domainEnd {
                var candidateEnd = domainEnd
                var matchedEnd: Int? = nil
                while candidateEnd > domainStart {
                    if isValidDomain(input[domainStart..<candidateEnd]) {
                        matchedEnd = candidateEnd
                        break
                    }
                    candidateEnd -= 1
                }

                if let validEnd = matchedEnd {
                    output.append(contentsOf: input[last..<localStart])
                    output.append(contentsOf: maskLocal(input[localStart..<localEnd], maskChar: maskChar))
                    output.append(asciiAt)
                    output.append(contentsOf: input[domainStart..<validEnd])
                    last = validEnd
                    i = validEnd
                    continue
                }
            }
        }

        i += 1
    }

    output.append(contentsOf: input[last..<len])
    return output
}

private func maskPhonesInText(_ input: [UInt8], maskChar: [UInt8]) -> [UInt8] {
    let len = input.count
    var output: [UInt8] = []
    output.reserveCapacity(len)

    var last = 0
    var i = 0

    while i < len {
        if isPhoneStart(input[i]) {
            var end = i
            while end < len && isPhoneChar(input[end]) {
                end += 1
            }

            var digitCount = 0
            var lastDigitIndex: Int? = nil
            var idx = i
            while idx < end {
                if isAsciiDigit(input[idx]) {
                    digitCount += 1
                    lastDigitIndex = idx
                }
                idx += 1
            }

            if let lastDigit = lastDigitIndex {
                let candidateEnd = lastDigit + 1
                if digitCount >= 5 {
                    output.append(contentsOf: input[last..<i])
                    output.append(contentsOf: maskPhoneCandidate(input[i..<candidateEnd], maskChar: maskChar))
                    last = candidateEnd
                    i = candidateEnd
                    continue
                }
            }

            i = end
            continue
        }

        i += 1
    }

    output.append(contentsOf: input[last..<len])
    return output
}

private func maskLocal(_ local: ArraySlice<UInt8>, maskChar: [UInt8]) -> [UInt8] {
    let length = local.count
    if length > 1 {
        var result: [UInt8] = []
        result.reserveCapacity(1 + (length - 1) * maskChar.count)
        if let first = local.first {
            result.append(first)
        }
        if length > 1 {
            for _ in 1..<length {
                result.append(contentsOf: maskChar)
            }
        }
        return result
    }

    return maskChar
}

private func maskPhoneCandidate(_ candidate: ArraySlice<UInt8>, maskChar: [UInt8]) -> [UInt8] {
    let digitCount = candidate.reduce(0) { count, byte in
        count + (isAsciiDigit(byte) ? 1 : 0)
    }

    var currentIndex = 0
    var result: [UInt8] = []
    result.reserveCapacity(candidate.count * max(1, maskChar.count))

    for byte in candidate {
        if isAsciiDigit(byte) {
            currentIndex += 1
            if digitCount > 4 && currentIndex <= digitCount - 4 {
                result.append(contentsOf: maskChar)
            } else {
                result.append(byte)
            }
        } else {
            result.append(byte)
        }
    }

    return result
}

private func isLocalByte(_ byte: UInt8) -> Bool {
    return isAsciiAlphaNumeric(byte)
        || byte == asciiDot
        || byte == asciiUnderscore
        || byte == asciiPercent
        || byte == asciiPlus
        || byte == asciiHyphen
}

private func isDomainByte(_ byte: UInt8) -> Bool {
    return isAsciiAlphaNumeric(byte) || byte == asciiHyphen || byte == asciiDot
}

private func isValidDomain(_ domain: ArraySlice<UInt8>) -> Bool {
    if domain.isEmpty {
        return false
    }
    if domain.first == asciiDot || domain.last == asciiDot {
        return false
    }

    var parts: [ArraySlice<UInt8>] = []
    var partStart = domain.startIndex
    var idx = domain.startIndex

    while idx < domain.endIndex {
        if domain[idx] == asciiDot {
            if idx == partStart {
                return false
            }
            parts.append(domain[partStart..<idx])
            partStart = domain.index(after: idx)
        }
        idx = domain.index(after: idx)
    }

    if partStart == domain.endIndex {
        return false
    }
    parts.append(domain[partStart..<domain.endIndex])

    if parts.count < 2 {
        return false
    }

    for part in parts {
        if part.isEmpty {
            return false
        }
        if part.first == asciiHyphen || part.last == asciiHyphen {
            return false
        }
        for byte in part {
            if !(isAsciiAlphaNumeric(byte) || byte == asciiHyphen) {
                return false
            }
        }
    }

    guard let tld = parts.last else {
        return false
    }
    if tld.count < 2 {
        return false
    }
    for byte in tld {
        if !isAsciiAlpha(byte) {
            return false
        }
    }

    return true
}

private func isPhoneStart(_ byte: UInt8) -> Bool {
    return isAsciiDigit(byte) || byte == asciiPlus || byte == asciiLeftParen
}

private func isPhoneChar(_ byte: UInt8) -> Bool {
    return isAsciiDigit(byte)
        || byte == asciiSpace
        || byte == asciiHyphen
        || byte == asciiLeftParen
        || byte == asciiRightParen
        || byte == asciiPlus
}

private func isAsciiDigit(_ byte: UInt8) -> Bool {
    return byte >= asciiZero && byte <= asciiNine
}

private func isAsciiAlpha(_ byte: UInt8) -> Bool {
    return (byte >= asciiUpperA && byte <= asciiUpperZ) || (byte >= asciiLowerA && byte <= asciiLowerZ)
}

private func isAsciiAlphaNumeric(_ byte: UInt8) -> Bool {
    return isAsciiDigit(byte) || isAsciiAlpha(byte)
}

private let asciiAt: UInt8 = 64
private let asciiDot: UInt8 = 46
private let asciiHyphen: UInt8 = 45
private let asciiPlus: UInt8 = 43
private let asciiUnderscore: UInt8 = 95
private let asciiPercent: UInt8 = 37
private let asciiSpace: UInt8 = 32
private let asciiLeftParen: UInt8 = 40
private let asciiRightParen: UInt8 = 41
private let asciiZero: UInt8 = 48
private let asciiNine: UInt8 = 57
private let asciiUpperA: UInt8 = 65
private let asciiUpperZ: UInt8 = 90
private let asciiLowerA: UInt8 = 97
private let asciiLowerZ: UInt8 = 122
