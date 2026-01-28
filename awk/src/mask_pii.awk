# mask_pii provides masking utilities for common PII patterns.

# Create a new masker with all masks disabled by default.
function mask_pii_new(masker) {
  delete masker
  masker["mask_email"] = 0
  masker["mask_phone"] = 0
  masker["mask_char"] = "*"
  return 1
}

# Enable email address masking.
function mask_pii_mask_emails(masker) {
  masker["mask_email"] = 1
  return 1
}

# Enable phone number masking.
function mask_pii_mask_phones(masker) {
  masker["mask_phone"] = 1
  return 1
}

# Set the character used for masking.
function mask_pii_with_mask_char(masker, char, value) {
  if (char == "") {
    masker["mask_char"] = "*"
    return 1
  }
  value = substr(char, 1, 1)
  if (value == "") {
    value = "*"
  }
  masker["mask_char"] = value
  return 1
}

# Process input text and mask enabled PII patterns.
function mask_pii_process(masker, input_text, mask_char, result) {
  if (!masker["mask_email"] && !masker["mask_phone"]) {
    return input_text
  }

  mask_char = masker["mask_char"]
  if (mask_char == "") {
    mask_char = "*"
  }

  result = input_text
  if (masker["mask_email"]) {
    result = mask_emails_in_text(result, mask_char)
  }
  if (masker["mask_phone"]) {
    result = mask_phones_in_text(result, mask_char)
  }
  return result
}

# Return the library version.
function mask_pii_version() {
  return "0.2.0"
}

function is_digit(ch) {
  return ch >= "0" && ch <= "9"
}

function is_alpha(ch) {
  return (ch >= "a" && ch <= "z") || (ch >= "A" && ch <= "Z")
}

function is_alnum(ch) {
  return is_alpha(ch) || is_digit(ch)
}

function is_local_char(ch) {
  return is_alnum(ch) || ch == "." || ch == "_" || ch == "%" || ch == "+" || ch == "-"
}

function is_domain_char(ch) {
  return is_alnum(ch) || ch == "-" || ch == "."
}

function is_valid_domain(domain, part_count, parts, i, part, tld, ch, ch_index) {
  if (domain == "") {
    return 0
  }
  if (substr(domain, 1, 1) == "." || substr(domain, length(domain), 1) == ".") {
    return 0
  }

  part_count = split(domain, parts, ".")
  if (part_count < 2) {
    return 0
  }

  for (i = 1; i <= part_count; i++) {
    part = parts[i]
    if (part == "") {
      return 0
    }
    if (substr(part, 1, 1) == "-" || substr(part, length(part), 1) == "-") {
      return 0
    }
    for (ch_index = 1; ch_index <= length(part); ch_index++) {
      ch = substr(part, ch_index, 1)
      if (!(is_alnum(ch) || ch == "-")) {
        return 0
      }
    }
  }

  tld = parts[part_count]
  if (length(tld) < 2) {
    return 0
  }
  for (i = 1; i <= length(tld); i++) {
    ch = substr(tld, i, 1)
    if (!is_alpha(ch)) {
      return 0
    }
  }
  return 1
}

function repeat_char(ch, count, result, i) {
  result = ""
  for (i = 0; i < count; i++) {
    result = result ch
  }
  return result
}

function mask_local(local_part, mask_char) {
  if (length(local_part) > 1) {
    return substr(local_part, 1, 1) repeat_char(mask_char, length(local_part) - 1)
  }
  return mask_char
}

function mask_phone_candidate(candidate, mask_char, digit_count, i, ch, current_index, result) {
  digit_count = 0
  for (i = 1; i <= length(candidate); i++) {
    if (is_digit(substr(candidate, i, 1))) {
      digit_count++
    }
  }

  current_index = 0
  result = ""
  for (i = 1; i <= length(candidate); i++) {
    ch = substr(candidate, i, 1)
    if (is_digit(ch)) {
      current_index++
      if (digit_count > 4 && current_index <= digit_count - 4) {
        result = result mask_char
      } else {
        result = result ch
      }
    } else {
      result = result ch
    }
  }
  return result
}

function is_phone_start(ch) {
  return is_digit(ch) || ch == "+" || ch == "("
}

function is_phone_char(ch) {
  return is_digit(ch) || ch == " " || ch == "-" || ch == "(" || ch == ")" || ch == "+"
}

function mask_emails_in_text(input_text, mask_char, len, output, last, i, local_start, local_end, domain_start, domain_end, candidate_end, matched_end, local_part, domain) {
  len = length(input_text)
  output = ""
  last = 1
  i = 1

  while (i <= len) {
    if (substr(input_text, i, 1) == "@") {
      local_start = i
      while (local_start > 1 && is_local_char(substr(input_text, local_start - 1, 1))) {
        local_start--
      }
      local_end = i - 1

      domain_start = i + 1
      domain_end = domain_start
      while (domain_end <= len && is_domain_char(substr(input_text, domain_end, 1))) {
        domain_end++
      }

      if (local_start <= local_end && domain_start <= domain_end - 1) {
        candidate_end = domain_end - 1
        matched_end = 0
        while (candidate_end >= domain_start) {
          domain = substr(input_text, domain_start, candidate_end - domain_start + 1)
          if (is_valid_domain(domain)) {
            matched_end = candidate_end
            break
          }
          candidate_end--
        }

        if (matched_end > 0) {
          local_part = substr(input_text, local_start, local_end - local_start + 1)
          output = output substr(input_text, last, local_start - last) mask_local(local_part, mask_char) "@" substr(input_text, domain_start, matched_end - domain_start + 1)
          last = matched_end + 1
          i = matched_end + 1
          continue
        }
      }
    }
    i++
  }

  output = output substr(input_text, last)
  return output
}

function mask_phones_in_text(input_text, mask_char, len, output, last, i, end_pos, digit_count, last_digit_index, idx, candidate_end, candidate) {
  len = length(input_text)
  output = ""
  last = 1
  i = 1

  while (i <= len) {
    if (is_phone_start(substr(input_text, i, 1))) {
      end_pos = i
      while (end_pos <= len && is_phone_char(substr(input_text, end_pos, 1))) {
        end_pos++
      }

      digit_count = 0
      last_digit_index = 0
      for (idx = i; idx <= end_pos - 1; idx++) {
        if (is_digit(substr(input_text, idx, 1))) {
          digit_count++
          last_digit_index = idx
        }
      }

      if (last_digit_index > 0) {
        candidate_end = last_digit_index
        if (digit_count >= 5) {
          candidate = substr(input_text, i, candidate_end - i + 1)
          output = output substr(input_text, last, i - last) mask_phone_candidate(candidate, mask_char)
          last = candidate_end + 1
          i = candidate_end + 1
          continue
        }
      }

      i = end_pos
      continue
    }
    i++
  }

  output = output substr(input_text, last)
  return output
}
