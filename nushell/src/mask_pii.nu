# mask_pii provides masking utilities for common PII patterns.

# The current version of the Nushell module.
export const VERSION = "0.2.0"

# Create a new masker with all masks disabled by default.
export def "masker new" [] {
  {
    mask_email: false
    mask_phone: false
    mask_char: "*"
  }
}

# Enable email address masking.
export def mask_emails [] {
  $in | upsert mask_email true
}

# Enable phone number masking.
export def mask_phones [] {
  $in | upsert mask_phone true
}

# Set the character used for masking.
export def with_mask_char [char?] {
  let value = if $char == null {
    ""
  } else {
    $char | into string
  }

  let mask_char = if ($value | str length) == 0 {
    "*"
  } else {
    $value | str substring 0 1
  }

  $in | upsert mask_char $mask_char
}

# Process input text and mask enabled PII patterns.
export def process [text: string] {
  let masker = $in
  if (not $masker.mask_email) and (not $masker.mask_phone) {
    return $text
  }

  let mask_char = if $masker.mask_char == null or ($masker.mask_char | str length) == 0 {
    "*"
  } else {
    $masker.mask_char
  }

  mut result = $text
  if $masker.mask_email {
    $result = (mask_emails_in_text $result $mask_char)
  }
  if $masker.mask_phone {
    $result = (mask_phones_in_text $result $mask_char)
  }
  $result
}

# Get the character at the provided index.
def char_at [text: string, index: int] {
  $text | str substring $index 1
}

# Get a substring with a safe length.
def substr [text: string, start: int, length: int] {
  if $length <= 0 {
    ""
  } else {
    $text | str substring $start $length
  }
}

# Determine whether the character is a digit.
def is_digit [ch: string] {
  $ch >= "0" and $ch <= "9"
}

# Determine whether the character is alphabetic.
def is_alpha [ch: string] {
  ($ch >= "a" and $ch <= "z") or ($ch >= "A" and $ch <= "Z")
}

# Determine whether the character is alphanumeric.
def is_alnum [ch: string] {
  (is_alpha $ch) or (is_digit $ch)
}

# Determine whether the character is valid in the email local part.
def is_local_char [ch: string] {
  (is_alnum $ch) or ($ch in ["." "_" "%" "+" "-"])
}

# Determine whether the character is valid in the email domain.
def is_domain_char [ch: string] {
  (is_alnum $ch) or ($ch in ["-" "."])
}

# Validate an email domain based on the shared rules.
def is_valid_domain [domain: string] {
  if $domain == "" {
    return false
  }

  let length = ($domain | str length)
  if $length == 0 {
    return false
  }

  if (char_at $domain 0) == "." or (char_at $domain ($length - 1)) == "." {
    return false
  }

  let parts = ($domain | split row ".")
  if ($parts | length) < 2 {
    return false
  }

  for part in $parts {
    if $part == "" {
      return false
    }

    let part_len = ($part | str length)
    if $part_len == 0 {
      return false
    }

    if (char_at $part 0) == "-" or (char_at $part ($part_len - 1)) == "-" {
      return false
    }

    for idx in 0..<$part_len {
      let ch = (char_at $part $idx)
      if (not (is_alnum $ch)) and $ch != "-" {
        return false
      }
    }
  }

  let tld = ($parts | last)
  let tld_len = ($tld | str length)
  if $tld_len < 2 {
    return false
  }

  for idx in 0..<$tld_len {
    let ch = (char_at $tld $idx)
    if not (is_alpha $ch) {
      return false
    }
  }

  true
}

# Mask the local part of an email address.
def mask_local [local_part: string, mask_char: string] {
  let length = ($local_part | str length)
  if $length > 1 {
    let first = (char_at $local_part 0)
    let rest = ($mask_char | str repeat ($length - 1))
    $first + $rest
  } else {
    $mask_char
  }
}

# Mask a phone candidate while preserving formatting.
def mask_phone_candidate [candidate: string, mask_char: string] {
  let length = ($candidate | str length)
  mut digit_count = 0
  for idx in 0..<$length {
    let ch = (char_at $candidate $idx)
    if (is_digit $ch) {
      $digit_count = $digit_count + 1
    }
  }

  mut current_index = 0
  mut output = []
  for idx in 0..<$length {
    let ch = (char_at $candidate $idx)
    if (is_digit $ch) {
      $current_index = $current_index + 1
      if $digit_count > 4 and $current_index <= ($digit_count - 4) {
        $output = ($output | append $mask_char)
      } else {
        $output = ($output | append $ch)
      }
    } else {
      $output = ($output | append $ch)
    }
  }

  $output | str join ""
}

# Determine whether the character can start a phone number.
def is_phone_start [ch: string] {
  (is_digit $ch) or ($ch == "+") or ($ch == "(")
}

# Determine whether the character can appear in a phone number.
def is_phone_char [ch: string] {
  (is_digit $ch) or ($ch in [" " "-" "(" ")" "+"])
}

# Mask email addresses in text.
def mask_emails_in_text [input_text: string, mask_char: string] {
  let length = ($input_text | str length)
  mut output = []
  mut last = 0
  mut i = 0

  while $i < $length {
    if (char_at $input_text $i) == "@" {
      mut local_start = $i
      while $local_start > 0 and (is_local_char (char_at $input_text ($local_start - 1))) {
        $local_start = $local_start - 1
      }

      let local_end = $i
      let domain_start = $i + 1
      mut domain_end = $domain_start
      while $domain_end < $length and (is_domain_char (char_at $input_text $domain_end)) {
        $domain_end = $domain_end + 1
      }

      if $local_start < $local_end and $domain_start < $domain_end {
        mut candidate_end = $domain_end
        mut matched_end = -1
        while $candidate_end > $domain_start {
          let domain = (substr $input_text $domain_start ($candidate_end - $domain_start))
          if (is_valid_domain $domain) {
            $matched_end = $candidate_end
            break
          }
          $candidate_end = $candidate_end - 1
        }

        if $matched_end != -1 {
          let local_part = (substr $input_text $local_start ($local_end - $local_start))
          $output = ($output | append (substr $input_text $last ($local_start - $last)))
          $output = ($output | append (mask_local $local_part $mask_char))
          $output = ($output | append "@")
          $output = ($output | append (substr $input_text $domain_start ($matched_end - $domain_start)))
          $last = $matched_end
          $i = $matched_end
          continue
        }
      }
    }

    $i = $i + 1
  }

  $output = ($output | append (substr $input_text $last ($length - $last)))
  $output | str join ""
}

# Mask phone numbers in text.
def mask_phones_in_text [input_text: string, mask_char: string] {
  let length = ($input_text | str length)
  mut output = []
  mut last = 0
  mut i = 0

  while $i < $length {
    if (is_phone_start (char_at $input_text $i)) {
      mut end_pos = $i
      while $end_pos < $length and (is_phone_char (char_at $input_text $end_pos)) {
        $end_pos = $end_pos + 1
      }

      mut digit_count = 0
      mut last_digit_index = -1
      for idx in $i..<$end_pos {
        if (is_digit (char_at $input_text $idx)) {
          $digit_count = $digit_count + 1
          $last_digit_index = $idx
        }
      }

      if $last_digit_index != -1 {
        if $digit_count >= 5 {
          let candidate = (substr $input_text $i ($last_digit_index - $i + 1))
          $output = ($output | append (substr $input_text $last ($i - $last)))
          $output = ($output | append (mask_phone_candidate $candidate $mask_char))
          $last = $last_digit_index + 1
          $i = $last
          continue
        }
      }

      $i = $end_pos
      continue
    }

    $i = $i + 1
  }

  $output = ($output | append (substr $input_text $last ($length - $last)))
  $output | str join ""
}
