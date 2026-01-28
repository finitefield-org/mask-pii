module MaskPII
  ( Masker
  , newMasker
  , maskEmails
  , maskPhones
  , withMaskChar
  , process
  ) where

import Data.Array (Array, listArray, (!))

-- | Configuration for masking emails and phone numbers.
data Masker = Masker
  { maskerEmailEnabled :: Bool
  , maskerPhoneEnabled :: Bool
  , maskerChar :: Char
  }

-- | Create a new masker with all masks disabled.
newMasker :: Masker
newMasker = Masker
  { maskerEmailEnabled = False
  , maskerPhoneEnabled = False
  , maskerChar = '*'
  }

-- | Enable email address masking.
maskEmails :: Masker -> Masker
maskEmails masker = masker { maskerEmailEnabled = True }

-- | Enable phone number masking.
maskPhones :: Masker -> Masker
maskPhones masker = masker { maskerPhoneEnabled = True }

-- | Set the character used for masking. A null character resets to '*'.
withMaskChar :: Char -> Masker -> Masker
withMaskChar c masker = masker { maskerChar = if c == '\0' then '*' else c }

-- | Process input text and mask enabled PII patterns.
process :: Masker -> String -> String
process masker input
  | not (maskerEmailEnabled masker) && not (maskerPhoneEnabled masker) = input
  | otherwise =
      let maskChar = if maskerChar masker == '\0' then '*' else maskerChar masker
          afterEmails = if maskerEmailEnabled masker
            then maskEmailsInText input maskChar
            else input
      in if maskerPhoneEnabled masker
           then maskPhonesInText afterEmails maskChar
           else afterEmails

maskEmailsInText :: String -> Char -> String
maskEmailsInText input maskChar
  | null input = input
  | otherwise =
      let n = length input
          arr = listArray (0, n - 1) input
          go i lastIndex acc
            | i >= n = finalize lastIndex acc arr n
            | arr ! i == '@' =
                let localStart = scanLeftLocal arr (i - 1)
                    localEnd = i
                    domainStart = i + 1
                    domainEnd = scanRightDomain arr n domainStart
                in if localStart < localEnd && domainStart < domainEnd
                     then case findValidDomain arr domainStart domainEnd of
                       Just matchedEnd ->
                         let localPart = slice arr localStart localEnd
                             domainPart = slice arr domainStart matchedEnd
                             prefix = slice arr lastIndex localStart
                             masked = prefix ++ maskLocal localPart maskChar ++ "@" ++ domainPart
                         in go matchedEnd matchedEnd (masked : acc)
                       Nothing -> go (i + 1) lastIndex acc
                     else go (i + 1) lastIndex acc
            | otherwise = go (i + 1) lastIndex acc
      in concat (go 0 0 [])

maskPhonesInText :: String -> Char -> String
maskPhonesInText input maskChar
  | null input = input
  | otherwise =
      let n = length input
          arr = listArray (0, n - 1) input
          go i lastIndex acc
            | i >= n = finalize lastIndex acc arr n
            | isPhoneStart (arr ! i) =
                let endIndex = scanRightPhone arr n i
                    (digitCount, lastDigitIndex) = scanPhoneDigits arr i endIndex
                in if lastDigitIndex == -1
                     then go endIndex lastIndex acc
                     else if digitCount >= 5
                       then
                         let candidateEnd = lastDigitIndex + 1
                             candidate = slice arr i candidateEnd
                             prefix = slice arr lastIndex i
                             masked = prefix ++ maskPhoneCandidate candidate maskChar
                         in go candidateEnd candidateEnd (masked : acc)
                       else go endIndex lastIndex acc
            | otherwise = go (i + 1) lastIndex acc
      in concat (go 0 0 [])

finalize :: Int -> [String] -> Array Int Char -> Int -> [String]
finalize lastIndex acc arr n
  | lastIndex < n = reverse (slice arr lastIndex n : acc)
  | otherwise = reverse acc

slice :: Array Int Char -> Int -> Int -> String
slice arr start end
  | start >= end = ""
  | otherwise = [arr ! i | i <- [start .. end - 1]]

scanLeftLocal :: Array Int Char -> Int -> Int
scanLeftLocal arr idx
  | idx < 0 = 0
  | isLocalChar (arr ! idx) = scanLeftLocal arr (idx - 1)
  | otherwise = idx + 1

scanRightDomain :: Array Int Char -> Int -> Int -> Int
scanRightDomain arr n idx
  | idx >= n = n
  | isDomainChar (arr ! idx) = scanRightDomain arr n (idx + 1)
  | otherwise = idx

scanRightPhone :: Array Int Char -> Int -> Int -> Int
scanRightPhone arr n idx
  | idx >= n = n
  | isPhoneChar (arr ! idx) = scanRightPhone arr n (idx + 1)
  | otherwise = idx

scanPhoneDigits :: Array Int Char -> Int -> Int -> (Int, Int)
scanPhoneDigits arr start end = go start 0 (-1)
  where
    go idx count lastIdx
      | idx >= end = (count, lastIdx)
      | isDigit (arr ! idx) = go (idx + 1) (count + 1) idx
      | otherwise = go (idx + 1) count lastIdx

findValidDomain :: Array Int Char -> Int -> Int -> Maybe Int
findValidDomain arr start end
  | end <= start = Nothing
  | isValidDomain (slice arr start end) = Just end
  | otherwise = findValidDomain arr start (end - 1)

maskLocal :: String -> Char -> String
maskLocal local maskChar
  | length local > 1 = head local : replicate (length local - 1) maskChar
  | otherwise = [maskChar]

maskPhoneCandidate :: String -> Char -> String
maskPhoneCandidate candidate maskChar =
  let digitCount = length (filter isDigit candidate)
      maskUntil = digitCount - 4
      go _ [] acc = reverse acc
      go idx (c : cs) acc
        | isDigit c =
            let nextIdx = idx + 1
            in if nextIdx <= maskUntil
                 then go nextIdx cs (maskChar : acc)
                 else go nextIdx cs (c : acc)
        | otherwise = go idx cs (c : acc)
  in if digitCount <= 4
       then candidate
       else go 0 candidate []

isLocalChar :: Char -> Bool
isLocalChar c
  | c >= 'a' && c <= 'z' = True
  | c >= 'A' && c <= 'Z' = True
  | c >= '0' && c <= '9' = True
  | c == '.' || c == '_' || c == '%' || c == '+' || c == '-' = True
  | otherwise = False

isDomainChar :: Char -> Bool
isDomainChar c
  | c >= 'a' && c <= 'z' = True
  | c >= 'A' && c <= 'Z' = True
  | c >= '0' && c <= '9' = True
  | c == '-' || c == '.' = True
  | otherwise = False

isValidDomain :: String -> Bool
isValidDomain domain
  | null domain = False
  | head domain == '.' || last domain == '.' = False
  | length parts < 2 = False
  | otherwise = all validLabel parts && validTld (last parts)
  where
    parts = splitOnChar '.' domain
    validLabel label
      | null label = False
      | head label == '-' || last label == '-' = False
      | otherwise = all (\c -> isAlphaNumeric c || c == '-') label
    validTld tld = length tld >= 2 && all isAlpha tld

isPhoneStart :: Char -> Bool
isPhoneStart c = isDigit c || c == '+' || c == '('

isPhoneChar :: Char -> Bool
isPhoneChar c = isDigit c || c == ' ' || c == '-' || c == '(' || c == ')' || c == '+'

isDigit :: Char -> Bool
isDigit c = c >= '0' && c <= '9'

isAlpha :: Char -> Bool
isAlpha c = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')

isAlphaNumeric :: Char -> Bool
isAlphaNumeric c = isAlpha c || isDigit c

splitOnChar :: Char -> String -> [String]
splitOnChar delimiter = go [] []
  where
    go current acc [] = reverse (reverse current : acc)
    go current acc (c : cs)
      | c == delimiter = go [] (reverse current : acc) cs
      | otherwise = go (c : current) acc cs
