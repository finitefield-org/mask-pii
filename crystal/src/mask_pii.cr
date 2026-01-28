# MaskPII provides a configurable masker for emails and phone numbers.
module MaskPII
  # Masker is a configurable masker for emails and phone numbers.
  class Masker
    @mask_email : Bool
    @mask_phone : Bool
    @mask_char : Char

    # Create a new masker with all masks disabled by default.
    def initialize
      @mask_email = false
      @mask_phone = false
      @mask_char = '*'
    end

    # Enable email address masking.
    def mask_emails : self
      @mask_email = true
      self
    end

    # Enable phone number masking.
    def mask_phones : self
      @mask_phone = true
      self
    end

    # Set the character used for masking.
    def with_mask_char(char : Char | String | Nil) : self
      case char
      when Nil
        @mask_char = '*'
      when Char
        @mask_char = char
      when String
        @mask_char = char.empty? ? '*' : char[0]
      end
      self
    end

    # Process input text and mask enabled PII patterns.
    def process(input : String) : String
      return input unless @mask_email || @mask_phone

      result = input
      if @mask_email
        result = mask_emails_in_text(result, @mask_char)
      end
      if @mask_phone
        result = mask_phones_in_text(result, @mask_char)
      end
      result
    end

    private def mask_emails_in_text(input : String, mask_char : Char) : String
      bytes = input.to_slice
      length = bytes.size
      builder = String::Builder.new(capacity: input.bytesize)
      last = 0
      i = 0

      while i < length
        if bytes[i] == '@'.ord.to_u8
          local_start = i
          while local_start > 0 && is_local_byte(bytes[local_start - 1])
            local_start -= 1
          end
          local_end = i

          domain_start = i + 1
          domain_end = domain_start
          while domain_end < length && is_domain_byte(bytes[domain_end])
            domain_end += 1
          end

          if local_start < local_end && domain_start < domain_end
            candidate_end = domain_end
            matched_end = -1
            while candidate_end > domain_start
              domain = input.byte_slice(domain_start, candidate_end - domain_start)
              if is_valid_domain(domain)
                matched_end = candidate_end
                break
              end
              candidate_end -= 1
            end

            if matched_end != -1
              local = input.byte_slice(local_start, local_end - local_start)
              domain = input.byte_slice(domain_start, matched_end - domain_start)
              builder << input.byte_slice(last, local_start - last)
              builder << mask_local(local, mask_char)
              builder << '@'
              builder << domain
              last = matched_end
              i = matched_end - 1
            end
          end
        end
        i += 1
      end

      builder << input.byte_slice(last, length - last)
      builder.to_s
    end

    private def mask_phones_in_text(input : String, mask_char : Char) : String
      bytes = input.to_slice
      length = bytes.size
      builder = String::Builder.new(capacity: input.bytesize)
      last = 0
      i = 0

      while i < length
        if is_phone_start(bytes[i])
          endpoint = i
          while endpoint < length && is_phone_byte(bytes[endpoint])
            endpoint += 1
          end

          digit_count = 0
          last_digit_index = -1
          idx = i
          while idx < endpoint
            if is_digit(bytes[idx])
              digit_count += 1
              last_digit_index = idx
            end
            idx += 1
          end

          if last_digit_index != -1
            candidate_end = last_digit_index + 1
            if digit_count >= 5
              candidate = input.byte_slice(i, candidate_end - i)
              builder << input.byte_slice(last, i - last)
              builder << mask_phone_candidate(candidate, mask_char)
              last = candidate_end
              i = candidate_end - 1
            else
              i = endpoint - 1
            end
          else
            i = endpoint - 1
          end
        end
        i += 1
      end

      builder << input.byte_slice(last, length - last)
      builder.to_s
    end

    private def mask_local(local : String, mask_char : Char) : String
      if local.bytesize > 1
        builder = String::Builder.new(capacity: local.bytesize)
        builder << local[0]
        (local.bytesize - 1).times { builder << mask_char }
        builder.to_s
      else
        mask_char.to_s
      end
    end

    private def mask_phone_candidate(candidate : String, mask_char : Char) : String
      bytes = candidate.to_slice
      digit_count = 0
      bytes.each do |byte|
        digit_count += 1 if is_digit(byte)
      end

      current_index = 0
      builder = String::Builder.new(capacity: candidate.bytesize)
      bytes.each do |byte|
        if is_digit(byte)
          current_index += 1
          if digit_count > 4 && current_index <= digit_count - 4
            builder << mask_char
          else
            builder << byte.chr
          end
        else
          builder << byte.chr
        end
      end
      builder.to_s
    end

    private def is_local_byte(byte : UInt8) : Bool
      (byte >= 'a'.ord.to_u8 && byte <= 'z'.ord.to_u8) ||
        (byte >= 'A'.ord.to_u8 && byte <= 'Z'.ord.to_u8) ||
        (byte >= '0'.ord.to_u8 && byte <= '9'.ord.to_u8) ||
        byte == '.'.ord.to_u8 ||
        byte == '_'.ord.to_u8 ||
        byte == '%'.ord.to_u8 ||
        byte == '+'.ord.to_u8 ||
        byte == '-'.ord.to_u8
    end

    private def is_domain_byte(byte : UInt8) : Bool
      (byte >= 'a'.ord.to_u8 && byte <= 'z'.ord.to_u8) ||
        (byte >= 'A'.ord.to_u8 && byte <= 'Z'.ord.to_u8) ||
        (byte >= '0'.ord.to_u8 && byte <= '9'.ord.to_u8) ||
        byte == '-'.ord.to_u8 ||
        byte == '.'.ord.to_u8
    end

    private def is_valid_domain(domain : String) : Bool
      return false if domain.empty?
      return false if domain.byte_slice(0, 1) == "." || domain.byte_slice(domain.bytesize - 1, 1) == "."

      parts = domain.split('.')
      return false if parts.size < 2

      parts.each do |part|
        return false if part.empty?
        return false if part.starts_with?("-") || part.ends_with?("-")
        part.each_byte do |byte|
          return false unless is_alpha_numeric(byte) || byte == '-'.ord.to_u8
        end
      end

      tld = parts.last
      return false if tld.bytesize < 2
      tld.each_byte do |byte|
        return false unless is_alpha(byte)
      end

      true
    end

    private def is_phone_start(byte : UInt8) : Bool
      is_digit(byte) || byte == '+'.ord.to_u8 || byte == '('.ord.to_u8
    end

    private def is_phone_byte(byte : UInt8) : Bool
      is_digit(byte) ||
        byte == ' '.ord.to_u8 ||
        byte == '-'.ord.to_u8 ||
        byte == '('.ord.to_u8 ||
        byte == ')'.ord.to_u8 ||
        byte == '+'.ord.to_u8
    end

    private def is_digit(byte : UInt8) : Bool
      byte >= '0'.ord.to_u8 && byte <= '9'.ord.to_u8
    end

    private def is_alpha(byte : UInt8) : Bool
      (byte >= 'a'.ord.to_u8 && byte <= 'z'.ord.to_u8) ||
        (byte >= 'A'.ord.to_u8 && byte <= 'Z'.ord.to_u8)
    end

    private def is_alpha_numeric(byte : UInt8) : Bool
      is_alpha(byte) || is_digit(byte)
    end
  end
end
