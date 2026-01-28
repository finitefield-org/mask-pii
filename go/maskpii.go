// Package maskpii provides a configurable masker for emails and phone numbers.
package maskpii

import "strings"

// Masker is a configurable masker for common PII such as emails and phone numbers.
type Masker struct {
	maskEmail bool
	maskPhone bool
	maskChar  rune
}

// New creates a new masker with all masks disabled by default.
func New() *Masker {
	return &Masker{
		maskEmail: false,
		maskPhone: false,
		maskChar:  '*',
	}
}

// MaskEmails enables email address masking.
func (m *Masker) MaskEmails() *Masker {
	m.maskEmail = true
	return m
}

// MaskPhones enables phone number masking.
func (m *Masker) MaskPhones() *Masker {
	m.maskPhone = true
	return m
}

// WithMaskChar sets the character used for masking.
func (m *Masker) WithMaskChar(c rune) *Masker {
	if c == 0 {
		c = '*'
	}
	m.maskChar = c
	return m
}

// Process scans input text and masks enabled PII patterns.
func (m *Masker) Process(input string) string {
	if !m.maskEmail && !m.maskPhone {
		return input
	}
	maskChar := m.maskChar
	if maskChar == 0 {
		maskChar = '*'
	}

	result := input
	if m.maskEmail {
		result = maskEmailsInText(result, maskChar)
	}
	if m.maskPhone {
		result = maskPhonesInText(result, maskChar)
	}
	return result
}

func maskEmailsInText(input string, maskChar rune) string {
	bytes := []byte(input)
	length := len(bytes)
	var output strings.Builder
	output.Grow(len(input))
	last := 0
	for i := 0; i < length; i++ {
		if bytes[i] == '@' {
			localStart := i
			for localStart > 0 && isLocalByte(bytes[localStart-1]) {
				localStart--
			}
			localEnd := i

			domainStart := i + 1
			domainEnd := domainStart
			for domainEnd < length && isDomainByte(bytes[domainEnd]) {
				domainEnd++
			}

			if localStart < localEnd && domainStart < domainEnd {
				candidateEnd := domainEnd
				matchedEnd := -1
				for candidateEnd > domainStart {
					domain := input[domainStart:candidateEnd]
					if isValidDomain(domain) {
						matchedEnd = candidateEnd
						break
					}
					candidateEnd--
				}

				if matchedEnd != -1 {
					local := input[localStart:localEnd]
					domain := input[domainStart:matchedEnd]
					output.WriteString(input[last:localStart])
					output.WriteString(maskLocal(local, maskChar))
					output.WriteByte('@')
					output.WriteString(domain)
					last = matchedEnd
					i = matchedEnd - 1
					continue
				}
			}
		}
	}

	output.WriteString(input[last:])
	return output.String()
}

func maskPhonesInText(input string, maskChar rune) string {
	bytes := []byte(input)
	length := len(bytes)
	var output strings.Builder
	output.Grow(len(input))
	last := 0
	for i := 0; i < length; i++ {
		if isPhoneStart(bytes[i]) {
			end := i
			for end < length && isPhoneChar(bytes[end]) {
				end++
			}

			digitCount := 0
			lastDigitIndex := -1
			for idx := i; idx < end; idx++ {
				if isDigit(bytes[idx]) {
					digitCount++
					lastDigitIndex = idx
				}
			}

			if lastDigitIndex != -1 {
				candidateEnd := lastDigitIndex + 1
				if digitCount >= 5 {
					candidate := input[i:candidateEnd]
					output.WriteString(input[last:i])
					output.WriteString(maskPhoneCandidate(candidate, maskChar))
					last = candidateEnd
					i = candidateEnd - 1
					continue
				}
			}

			i = end - 1
			continue
		}
	}

	output.WriteString(input[last:])
	return output.String()
}

func maskLocal(local string, maskChar rune) string {
	if len(local) > 1 {
		var result strings.Builder
		result.Grow(len(local))
		result.WriteByte(local[0])
		for i := 1; i < len(local); i++ {
			result.WriteRune(maskChar)
		}
		return result.String()
	}
	return string(maskChar)
}

func maskPhoneCandidate(candidate string, maskChar rune) string {
	bytes := []byte(candidate)
	digitCount := 0
	for _, b := range bytes {
		if isDigit(b) {
			digitCount++
		}
	}

	currentIndex := 0
	var result strings.Builder
	result.Grow(len(candidate))
	for _, b := range bytes {
		if isDigit(b) {
			currentIndex++
			if digitCount > 4 && currentIndex <= digitCount-4 {
				result.WriteRune(maskChar)
			} else {
				result.WriteByte(b)
			}
		} else {
			result.WriteByte(b)
		}
	}
	return result.String()
}

func isLocalByte(b byte) bool {
	switch {
	case b >= 'a' && b <= 'z':
		return true
	case b >= 'A' && b <= 'Z':
		return true
	case b >= '0' && b <= '9':
		return true
	case b == '.' || b == '_' || b == '%' || b == '+' || b == '-':
		return true
	default:
		return false
	}
}

func isDomainByte(b byte) bool {
	switch {
	case b >= 'a' && b <= 'z':
		return true
	case b >= 'A' && b <= 'Z':
		return true
	case b >= '0' && b <= '9':
		return true
	case b == '-' || b == '.':
		return true
	default:
		return false
	}
}

func isValidDomain(domain string) bool {
	if len(domain) == 0 || domain[0] == '.' || domain[len(domain)-1] == '.' {
		return false
	}

	parts := strings.Split(domain, ".")
	if len(parts) < 2 {
		return false
	}

	for _, part := range parts {
		if part == "" {
			return false
		}
		if part[0] == '-' || part[len(part)-1] == '-' {
			return false
		}
		for i := 0; i < len(part); i++ {
			b := part[i]
			if !(isAlphaNumeric(b) || b == '-') {
				return false
			}
		}
	}

	tld := parts[len(parts)-1]
	if len(tld) < 2 {
		return false
	}
	for i := 0; i < len(tld); i++ {
		if !isAlpha(tld[i]) {
			return false
		}
	}

	return true
}

func isPhoneStart(b byte) bool {
	return isDigit(b) || b == '+' || b == '('
}

func isPhoneChar(b byte) bool {
	return isDigit(b) || b == ' ' || b == '-' || b == '(' || b == ')' || b == '+'
}

func isDigit(b byte) bool {
	return b >= '0' && b <= '9'
}

func isAlpha(b byte) bool {
	return (b >= 'a' && b <= 'z') || (b >= 'A' && b <= 'Z')
}

func isAlphaNumeric(b byte) bool {
	return isAlpha(b) || isDigit(b)
}
