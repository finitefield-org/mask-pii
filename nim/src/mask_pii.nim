## A lightweight, configurable masker for emails and phone numbers.

import strutils

## Current package version.
const Version* = "0.2.0"

type Masker* = ref object
  ## A configurable masker for emails and phone numbers.
  maskEmail: bool
  maskPhone: bool
  maskChar: char

proc newMasker*(): Masker =
  ## Create a new masker with all masks disabled by default.
  Masker(maskEmail: false, maskPhone: false, maskChar: '*')

proc maskEmails*(m: Masker): Masker =
  ## Enable email address masking.
  m.maskEmail = true
  m

proc maskPhones*(m: Masker): Masker =
  ## Enable phone number masking.
  m.maskPhone = true
  m

proc withMaskChar*(m: Masker; c: char): Masker =
  ## Set the character used for masking.
  if c == '\0':
    m.maskChar = '*'
  else:
    m.maskChar = c
  m

proc process*(m: Masker; inputText: string): string =
  ## Process input text and mask enabled PII patterns.
  if not m.maskEmail and not m.maskPhone:
    return inputText

  var maskChar = m.maskChar
  if maskChar == '\0':
    maskChar = '*'

  var resultText = inputText
  if m.maskEmail:
    resultText = maskEmailsInText(resultText, maskChar)
  if m.maskPhone:
    resultText = maskPhonesInText(resultText, maskChar)
  resultText

proc maskEmailsInText(inputText: string; maskChar: char): string =
  var output = newStringOfCap(inputText.len)
  var last = 0
  var i = 0
  while i < inputText.len:
    if inputText[i] == '@':
      var localStart = i
      while localStart > 0 and isLocalChar(inputText[localStart - 1]):
        dec localStart
      let localEnd = i

      var domainStart = i + 1
      var domainEnd = domainStart
      while domainEnd < inputText.len and isDomainChar(inputText[domainEnd]):
        inc domainEnd

      if localStart < localEnd and domainStart < domainEnd:
        var candidateEnd = domainEnd
        var matchedEnd = -1
        while candidateEnd > domainStart:
          let domain = inputText[domainStart ..< candidateEnd]
          if isValidDomain(domain):
            matchedEnd = candidateEnd
            break
          dec candidateEnd

        if matchedEnd != -1:
          let localPart = inputText[localStart ..< localEnd]
          let domainPart = inputText[domainStart ..< matchedEnd]
          output.add(inputText[last ..< localStart])
          output.add(maskLocal(localPart, maskChar))
          output.add("@")
          output.add(domainPart)
          last = matchedEnd
          i = matchedEnd
          continue
    inc i

  output.add(inputText[last ..< inputText.len])
  output

proc maskPhonesInText(inputText: string; maskChar: char): string =
  var output = newStringOfCap(inputText.len)
  var last = 0
  var i = 0
  while i < inputText.len:
    if isPhoneStart(inputText[i]):
      var endIndex = i
      while endIndex < inputText.len and isPhoneChar(inputText[endIndex]):
        inc endIndex

      var digitCount = 0
      var lastDigitIndex = -1
      for idx in i ..< endIndex:
        if isDigit(inputText[idx]):
          inc digitCount
          lastDigitIndex = idx

      if lastDigitIndex != -1:
        let candidateEnd = lastDigitIndex + 1
        if digitCount >= 5:
          let candidate = inputText[i ..< candidateEnd]
          output.add(inputText[last ..< i])
          output.add(maskPhoneCandidate(candidate, maskChar))
          last = candidateEnd
          i = candidateEnd
          continue

      i = endIndex
      continue
    inc i

  output.add(inputText[last ..< inputText.len])
  output

proc maskLocal(localPart: string; maskChar: char): string =
  if localPart.len > 1:
    $localPart[0] & repeat(maskChar, localPart.len - 1)
  else:
    $maskChar

proc maskPhoneCandidate(candidate: string; maskChar: char): string =
  var digitCount = 0
  for ch in candidate:
    if isDigit(ch):
      inc digitCount

  var currentIndex = 0
  var resultText = newStringOfCap(candidate.len)
  for ch in candidate:
    if isDigit(ch):
      inc currentIndex
      if digitCount > 4 and currentIndex <= digitCount - 4:
        resultText.add(maskChar)
      else:
        resultText.add(ch)
    else:
      resultText.add(ch)
  resultText

proc isLocalChar(ch: char): bool =
  isAlpha(ch) or isDigit(ch) or ch in {'.', '_', '%', '+', '-'}

proc isDomainChar(ch: char): bool =
  isAlpha(ch) or isDigit(ch) or ch in {'-', '.'}

proc isValidDomain(domain: string): bool =
  if domain.len == 0 or domain[0] == '.' or domain[^1] == '.':
    return false

  let parts = domain.split('.')
  if parts.len < 2:
    return false

  for part in parts:
    if part.len == 0:
      return false
    if part[0] == '-' or part[^1] == '-':
      return false
    for ch in part:
      if not (isAlphaNumeric(ch) or ch == '-'):
        return false

  let tld = parts[^1]
  if tld.len < 2:
    return false
  for ch in tld:
    if not isAlpha(ch):
      return false

  true

proc isPhoneStart(ch: char): bool =
  isDigit(ch) or ch in {'+', '('}

proc isPhoneChar(ch: char): bool =
  isDigit(ch) or ch in {' ', '-', '(', ')', '+'}

proc isDigit(ch: char): bool =
  ch >= '0' and ch <= '9'

proc isAlpha(ch: char): bool =
  (ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'Z')

proc isAlphaNumeric(ch: char): bool =
  isAlpha(ch) or isDigit(ch)
