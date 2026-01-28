"""A configurable masker for common PII such as emails and phone numbers."""
class Masker
  var _mask_email: Bool
  var _mask_phone: Bool
  var _mask_char: U8

  """Create a new masker with all masks disabled by default."""
  new create() =>
    _mask_email = false
    _mask_phone = false
    _mask_char = '*'

  """Enable email address masking."""
  fun ref mask_emails(): Masker =>
    _mask_email = true
    this

  """Enable phone number masking."""
  fun ref mask_phones(): Masker =>
    _mask_phone = true
    this

  """Set the character used for masking."""
  fun ref with_mask_char(c: U8): Masker =>
    _mask_char = if c == 0 then '*' else c end
    this

  """Process input text and mask enabled PII patterns."""
  fun process(input: String box): String =>
    if (not _mask_email) and (not _mask_phone) then
      input.clone()
    else
      let mask_char = if _mask_char == 0 then '*' else _mask_char end
      var result = input.clone()
      if _mask_email then
        result = _MaskerUtil.mask_emails_in_text(result, mask_char)
      end
      if _mask_phone then
        result = _MaskerUtil.mask_phones_in_text(result, mask_char)
      end
      result
    end

primitive _MaskerUtil
  fun mask_emails_in_text(input: String box, mask_char: U8): String =>
    if input.size() == 0 then
      input.clone()
    else
      let bytes = _to_bytes(input)
      let n = bytes.size()
      let out = Array[U8](n)
      var last: USize = 0
      var i: USize = 0

      while i < n do
        var advanced = false
        if _byte_at(bytes, i) == '@' then
          let local_start = _scan_left_local(bytes, i)
          let local_end = i
          let domain_start = i + 1
          let domain_end = _scan_right_domain(bytes, n, domain_start)

          if (local_start < local_end) and (domain_start < domain_end) then
            let matched_end = _find_valid_domain(bytes, domain_start, domain_end)
            if matched_end != 0 then
              _append_slice(out, bytes, last, local_start)
              _append_masked_local(out, bytes, local_start, local_end, mask_char)
              out.push('@')
              _append_slice(out, bytes, domain_start, matched_end)
              last = matched_end
              i = matched_end
              advanced = true
            end
          end
        end
        if not advanced then
          i = i + 1
        end
      end

      _append_slice(out, bytes, last, n)
      String.from_array(out)
    end

  fun mask_phones_in_text(input: String box, mask_char: U8): String =>
    if input.size() == 0 then
      input.clone()
    else
      let bytes = _to_bytes(input)
      let n = bytes.size()
      let out = Array[U8](n)
      var last: USize = 0
      var i: USize = 0

      while i < n do
        if _is_phone_start(_byte_at(bytes, i)) then
          let end_index = _scan_right_phone(bytes, n, i)
          let (digit_count, last_digit_index) = _scan_phone_digits(bytes, i, end_index)

          if (last_digit_index < end_index) and (digit_count >= 5) then
            let candidate_end = last_digit_index + 1
            _append_slice(out, bytes, last, i)
            _append_masked_phone(out, bytes, i, candidate_end, mask_char)
            last = candidate_end
            i = candidate_end
          else
            i = end_index
          end
        else
          i = i + 1
        end
      end

      _append_slice(out, bytes, last, n)
      String.from_array(out)
    end

  fun _to_bytes(input: String box): Array[U8] =>
    let bytes = Array[U8](input.size())
    for c in input.values() do
      bytes.push(c)
    end
    bytes

  fun _append_slice(out: Array[U8] ref, bytes: Array[U8] box, start: USize, end: USize) =>
    if start >= end then
      None
    else
      var i = start
      while i < end do
        out.push(_byte_at(bytes, i))
        i = i + 1
      end
    end

  fun _append_masked_local(out: Array[U8] ref, bytes: Array[U8] box, start: USize, end: USize, mask_char: U8) =>
    let len = end - start
    if len == 0 then
      None
    elseif len == 1 then
      out.push(mask_char)
    else
      out.push(_byte_at(bytes, start))
      var i: USize = 1
      while i < len do
        out.push(mask_char)
        i = i + 1
      end
    end

  fun _append_masked_phone(out: Array[U8] ref, bytes: Array[U8] box, start: USize, end: USize, mask_char: U8) =>
    var digit_count: USize = 0
    var i = start
    while i < end do
      if _is_digit(_byte_at(bytes, i)) then
        digit_count = digit_count + 1
      end
      i = i + 1
    end

    if digit_count <= 4 then
      _append_slice(out, bytes, start, end)
    else
      let mask_until = digit_count - 4
      var masked_digits: USize = 0
      var j = start
      while j < end do
        let c = _byte_at(bytes, j)
        if _is_digit(c) then
          masked_digits = masked_digits + 1
          if masked_digits <= mask_until then
            out.push(mask_char)
          else
            out.push(c)
          end
        else
          out.push(c)
        end
        j = j + 1
      end
    end

  fun _scan_left_local(bytes: Array[U8] box, at: USize): USize =>
    var idx = at
    while idx > 0 do
      let prev = idx - 1
      if _is_local_char(_byte_at(bytes, prev)) then
        idx = prev
      else
        break
      end
    end
    idx

  fun _scan_right_domain(bytes: Array[U8] box, n: USize, start: USize): USize =>
    var idx = start
    while idx < n do
      if _is_domain_char(_byte_at(bytes, idx)) then
        idx = idx + 1
      else
        break
      end
    end
    idx

  fun _scan_right_phone(bytes: Array[U8] box, n: USize, start: USize): USize =>
    var idx = start
    while idx < n do
      if _is_phone_char(_byte_at(bytes, idx)) then
        idx = idx + 1
      else
        break
      end
    end
    idx

  fun _scan_phone_digits(bytes: Array[U8] box, start: USize, end: USize): (USize, USize) =>
    var count: USize = 0
    var last: USize = end
    var idx = start
    while idx < end do
      if _is_digit(_byte_at(bytes, idx)) then
        count = count + 1
        last = idx
      end
      idx = idx + 1
    end
    (count, last)

  fun _find_valid_domain(bytes: Array[U8] box, start: USize, end: USize): USize =>
    var idx = end
    while idx > start do
      if _is_valid_domain(bytes, start, idx) then
        return idx
      end
      idx = idx - 1
    end
    0

  fun _is_valid_domain(bytes: Array[U8] box, start: USize, end: USize): Bool =>
    if end <= start then
      return false
    end
    if _byte_at(bytes, start) == '.' then
      return false
    end
    if _byte_at(bytes, end - 1) == '.' then
      return false
    end

    var labels: USize = 0
    var label_start = start
    var i = start
    while i <= end do
      if i == end then
        let label_end = i
        let label_len = label_end - label_start
        if label_len == 0 then
          return false
        end
        if _byte_at(bytes, label_start) == '-' then
          return false
        end
        if _byte_at(bytes, label_end - 1) == '-' then
          return false
        end
        var j = label_start
        while j < label_end do
          let c = _byte_at(bytes, j)
          if (not _is_alpha_numeric(c)) and (c != '-') then
            return false
          end
          j = j + 1
        end
        labels = labels + 1

        if i == end then
          if label_len < 2 then
            return false
          end
          var k = label_start
          while k < label_end do
            if not _is_alpha(_byte_at(bytes, k)) then
              return false
            end
            k = k + 1
          end
        end
        label_start = i + 1
      else
        if _byte_at(bytes, i) == '.' then
          let label_end = i
          let label_len = label_end - label_start
          if label_len == 0 then
            return false
          end
          if _byte_at(bytes, label_start) == '-' then
            return false
          end
          if _byte_at(bytes, label_end - 1) == '-' then
            return false
          end
          var j = label_start
          while j < label_end do
            let c = _byte_at(bytes, j)
            if (not _is_alpha_numeric(c)) and (c != '-') then
              return false
            end
            j = j + 1
          end
          labels = labels + 1
          label_start = i + 1
        end
      end
      i = i + 1
    end

    labels >= 2

  fun _is_local_char(c: U8): Bool =>
    (_is_alpha_numeric(c)) or (c == '.') or (c == '_') or (c == '%') or (c == '+') or (c == '-')

  fun _is_domain_char(c: U8): Bool =>
    (_is_alpha_numeric(c)) or (c == '-') or (c == '.')

  fun _is_phone_start(c: U8): Bool =>
    _is_digit(c) or (c == '+') or (c == '(')

  fun _is_phone_char(c: U8): Bool =>
    _is_digit(c) or (c == ' ') or (c == '-') or (c == '(') or (c == ')') or (c == '+')

  fun _is_digit(c: U8): Bool =>
    (c >= '0') and (c <= '9')

  fun _is_alpha(c: U8): Bool =>
    ((c >= 'a') and (c <= 'z')) or ((c >= 'A') and (c <= 'Z'))

  fun _is_alpha_numeric(c: U8): Bool =>
    _is_alpha(c) or _is_digit(c)

  fun _byte_at(bytes: Array[U8] box, i: USize): U8 =>
    try
      bytes(i)?
    else
      0
    end
