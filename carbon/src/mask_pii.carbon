package MaskPII library "mask_pii";

/// Version is the current release version of the mask-pii Carbon package.
let Version: String = "0.2.0";

/// Masker is a configurable masker for emails and phone numbers.
class Masker {
  var mask_email: bool;
  var mask_phone: bool;
  var mask_char: char;

  /// Creates a new masker with all masks disabled by default.
  fn Create() -> Self {
    return {.mask_email = false, .mask_phone = false, .mask_char = '*'};
  }

  /// Enables email address masking.
  fn MaskEmails[ref self: Self]() -> Self {
    self.mask_email = true;
    return self;
  }

  /// Enables phone number masking.
  fn MaskPhones[ref self: Self]() -> Self {
    self.mask_phone = true;
    return self;
  }

  /// Sets the character used for masking.
  fn WithMaskChar[ref self: Self](mask_char: char) -> Self {
    if mask_char == '\0' {
      self.mask_char = '*';
    } else {
      self.mask_char = mask_char;
    }
    return self;
  }

  /// Processes input text and masks enabled PII patterns.
  fn Process[self: Self](input: String) -> String {
    if !self.mask_email && !self.mask_phone {
      return input;
    }

    var mask_char: char = self.mask_char;
    if mask_char == '\0' {
      mask_char = '*';
    }

    var result: String = input;
    if self.mask_email {
      result = MaskEmailsInText(result, mask_char);
    }
    if self.mask_phone {
      result = MaskPhonesInText(result, mask_char);
    }
    return result;
  }
}

/// Creates a new masker with all masks disabled by default.
fn New() -> Masker {
  return Masker.Create();
}

fn MaskEmailsInText(input: String, mask_char: char) -> String {
  let length: i32 = input.Size();
  var output: String = "";
  var last: i32 = 0;
  var i: i32 = 0;

  while i < length {
    if input[i] == '@' {
      var local_start: i32 = i;
      while local_start > 0 && IsLocalChar(input[local_start - 1]) {
        local_start -= 1;
      }
      let local_end: i32 = i;

      let domain_start: i32 = i + 1;
      var domain_end: i32 = domain_start;
      while domain_end < length && IsDomainChar(input[domain_end]) {
        domain_end += 1;
      }

      if local_start < local_end && domain_start < domain_end {
        var candidate_end: i32 = domain_end;
        var matched_end: i32 = -1;
        while candidate_end > domain_start {
          let domain: String = Substring(input, domain_start, candidate_end);
          if IsValidDomain(domain) {
            matched_end = candidate_end;
            break;
          }
          candidate_end -= 1;
        }

        if matched_end != -1 {
          let local: String = Substring(input, local_start, local_end);
          let domain: String = Substring(input, domain_start, matched_end);
          AppendRange(output, input, last, local_start);
          output += MaskLocal(local, mask_char);
          output += "@";
          output += domain;
          last = matched_end;
          i = matched_end;
          continue;
        }
      }
    }
    i += 1;
  }

  AppendRange(output, input, last, length);
  return output;
}

fn MaskPhonesInText(input: String, mask_char: char) -> String {
  let length: i32 = input.Size();
  var output: String = "";
  var last: i32 = 0;
  var i: i32 = 0;

  while i < length {
    if IsPhoneStart(input[i]) {
      var end: i32 = i;
      while end < length && IsPhoneChar(input[end]) {
        end += 1;
      }

      var digit_count: i32 = 0;
      var last_digit_index: i32 = -1;
      var idx: i32 = i;
      while idx < end {
        if IsDigit(input[idx]) {
          digit_count += 1;
          last_digit_index = idx;
        }
        idx += 1;
      }

      if last_digit_index != -1 {
        let candidate_end: i32 = last_digit_index + 1;
        if digit_count >= 5 {
          let candidate: String = Substring(input, i, candidate_end);
          AppendRange(output, input, last, i);
          output += MaskPhoneCandidate(candidate, mask_char);
          last = candidate_end;
          i = candidate_end;
          continue;
        }
      }

      i = end;
      continue;
    }
    i += 1;
  }

  AppendRange(output, input, last, length);
  return output;
}

fn MaskLocal(local: String, mask_char: char) -> String {
  let length: i32 = local.Size();
  if length > 1 {
    var result: String = "";
    result += local[0];
    var i: i32 = 1;
    while i < length {
      result += mask_char;
      i += 1;
    }
    return result;
  }
  var masked: String = "";
  masked += mask_char;
  return masked;
}

fn MaskPhoneCandidate(candidate: String, mask_char: char) -> String {
  let length: i32 = candidate.Size();
  var digit_count: i32 = 0;
  var i: i32 = 0;
  while i < length {
    if IsDigit(candidate[i]) {
      digit_count += 1;
    }
    i += 1;
  }

  var current_index: i32 = 0;
  var result: String = "";
  i = 0;
  while i < length {
    let ch: char = candidate[i];
    if IsDigit(ch) {
      current_index += 1;
      if digit_count > 4 && current_index <= digit_count - 4 {
        result += mask_char;
      } else {
        result += ch;
      }
    } else {
      result += ch;
    }
    i += 1;
  }
  return result;
}

fn Substring(input: String, start: i32, end: i32) -> String {
  var result: String = "";
  var i: i32 = start;
  while i < end {
    result += input[i];
    i += 1;
  }
  return result;
}

fn AppendRange[ref output: String](input: String, start: i32, end: i32) {
  var i: i32 = start;
  while i < end {
    output += input[i];
    i += 1;
  }
}

fn IsLocalChar(ch: char) -> bool {
  return IsAlpha(ch) || IsDigit(ch) || ch == '.' || ch == '_' || ch == '%' || ch == '+' || ch == '-';
}

fn IsDomainChar(ch: char) -> bool {
  return IsAlpha(ch) || IsDigit(ch) || ch == '-' || ch == '.';
}

fn IsValidDomain(domain: String) -> bool {
  let length: i32 = domain.Size();
  if length == 0 || domain[0] == '.' || domain[length - 1] == '.' {
    return false;
  }

  var has_dot: bool = false;
  var label_start: i32 = 0;
  var tld_length: i32 = 0;
  var tld_alpha: bool = true;
  var i: i32 = 0;

  while i < length {
    let ch: char = domain[i];
    if ch == '.' {
      has_dot = true;
      if label_start == i {
        return false;
      }
      if domain[label_start] == '-' || domain[i - 1] == '-' {
        return false;
      }
      label_start = i + 1;
      tld_length = 0;
      tld_alpha = true;
    } else {
      if !(IsAlnum(ch) || ch == '-') {
        return false;
      }
      tld_length += 1;
      if !IsAlpha(ch) {
        tld_alpha = false;
      }
    }
    i += 1;
  }

  if label_start == length {
    return false;
  }
  if domain[label_start] == '-' || domain[length - 1] == '-' {
    return false;
  }
  if !has_dot {
    return false;
  }
  if tld_length < 2 || !tld_alpha {
    return false;
  }

  return true;
}

fn IsPhoneStart(ch: char) -> bool {
  return IsDigit(ch) || ch == '+' || ch == '(';
}

fn IsPhoneChar(ch: char) -> bool {
  return IsDigit(ch) || ch == ' ' || ch == '-' || ch == '(' || ch == ')' || ch == '+';
}

fn IsDigit(ch: char) -> bool {
  return ch >= '0' && ch <= '9';
}

fn IsAlpha(ch: char) -> bool {
  return (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z');
}

fn IsAlnum(ch: char) -> bool {
  return IsAlpha(ch) || IsDigit(ch);
}
