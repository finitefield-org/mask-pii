# frozen_string_literal: true

require "mask_pii/version"

# Top-level namespace for the mask-pii Ruby library.
module MaskPII
  # A configurable masker for common PII such as emails and phone numbers.
  class Masker
    # Create a new masker with all masks disabled by default.
    def initialize
      @mask_email = false
      @mask_phone = false
      @mask_char = "*"
    end

    # Enable email address masking.
    # @return [Masker] the current masker instance
    def mask_emails
      @mask_email = true
      self
    end

    # Enable phone number masking.
    # @return [Masker] the current masker instance
    def mask_phones
      @mask_phone = true
      self
    end

    # Set the character used for masking.
    # @param char [String] a single-character string to use for masking
    # @return [Masker] the current masker instance
    def with_mask_char(char)
      @mask_char = char.to_s[0] || "*"
      self
    end

    # Process input text and mask enabled PII patterns.
    # @param input [String] text to scan and mask
    # @return [String] masked output text
    def process(input)
      result = input.to_s.dup

      result = mask_emails_in_text(result) if @mask_email
      result = mask_phones_in_text(result) if @mask_phone

      result
    end

    private

    def mask_emails_in_text(text)
      bytes = text.bytes
      len = bytes.length
      output = String.new(encoding: text.encoding)
      last = 0
      i = 0

      while i < len
        if bytes[i] == 64
          local_start = i
          while local_start > 0 && local_char?(bytes[local_start - 1])
            local_start -= 1
          end
          local_end = i

          domain_start = i + 1
          domain_end = domain_start
          while domain_end < len && domain_char?(bytes[domain_end])
            domain_end += 1
          end

          if local_start < local_end && domain_start < domain_end
            candidate_end = domain_end
            matched_domain_end = nil
            while candidate_end > domain_start
              domain = slice_bytes(text, domain_start, candidate_end - domain_start)
              if valid_domain?(domain)
                matched_domain_end = candidate_end
                break
              end
              candidate_end -= 1
            end

            if matched_domain_end
              local = slice_bytes(text, local_start, local_end - local_start)
              domain = slice_bytes(text, domain_start, matched_domain_end - domain_start)
              output << slice_bytes(text, last, local_start - last)
              output << mask_local(local)
              output << "@"
              output << domain
              last = matched_domain_end
              i = matched_domain_end
              next
            end
          end
        end

        i += 1
      end

      output << slice_bytes(text, last, len - last)
      output
    end

    def mask_phones_in_text(text)
      bytes = text.bytes
      len = bytes.length
      output = String.new(encoding: text.encoding)
      last = 0
      i = 0

      while i < len
        if phone_start?(bytes[i])
          end_index = i
          while end_index < len && phone_char?(bytes[end_index])
            end_index += 1
          end

          digit_count = 0
          last_digit = nil
          idx = i
          while idx < end_index
            if digit?(bytes[idx])
              digit_count += 1
              last_digit = idx
            end
            idx += 1
          end

          if last_digit && digit_count >= 5
            candidate_end = last_digit + 1
            candidate = slice_bytes(text, i, candidate_end - i)
            output << slice_bytes(text, last, i - last)
            output << mask_phone_candidate(candidate)
            last = candidate_end
            i = candidate_end
            next
          end

          i = end_index
          next
        end

        i += 1
      end

      output << slice_bytes(text, last, len - last)
      output
    end

    def mask_local(local)
      if local.bytesize > 1
        slice_bytes(local, 0, 1) + (@mask_char * (local.bytesize - 1))
      else
        @mask_char
      end
    end

    def mask_phone_candidate(candidate)
      bytes = candidate.bytes
      digit_count = bytes.count { |byte| digit?(byte) }
      current_index = 0
      output = String.new(encoding: candidate.encoding)

      bytes.each do |byte|
        if digit?(byte)
          current_index += 1
          if digit_count > 4 && current_index <= digit_count - 4
            output << @mask_char
          else
            output << byte
          end
        else
          output << byte
        end
      end

      output
    end

    def slice_bytes(text, start_index, length)
      slice = text.byteslice(start_index, length)
      slice.force_encoding(text.encoding)
    end

    def local_char?(byte)
      alpha?(byte) || digit?(byte) || byte == 46 || byte == 95 || byte == 37 || byte == 43 || byte == 45
    end

    def domain_char?(byte)
      alpha?(byte) || digit?(byte) || byte == 45 || byte == 46
    end

    def valid_domain?(domain)
      return false if domain.start_with?(".") || domain.end_with?(".")

      parts = domain.split(".")
      return false if parts.length < 2

      parts.each do |part|
        return false if part.empty?
        return false if part.start_with?("-") || part.end_with?("-")
        return false unless part.bytes.all? { |byte| alpha?(byte) || digit?(byte) || byte == 45 }
      end

      tld = parts.last
      return false if tld.length < 2
      return false unless tld.bytes.all? { |byte| alpha?(byte) }

      true
    end

    def phone_start?(byte)
      digit?(byte) || byte == 43 || byte == 40
    end

    def phone_char?(byte)
      digit?(byte) || byte == 32 || byte == 45 || byte == 40 || byte == 41 || byte == 43
    end

    def digit?(byte)
      byte >= 48 && byte <= 57
    end

    def alpha?(byte)
      (byte >= 65 && byte <= 90) || (byte >= 97 && byte <= 122)
    end
  end
end
