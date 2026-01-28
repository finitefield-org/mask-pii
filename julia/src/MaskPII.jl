module MaskPII

export Masker, mask_emails, mask_phones, with_mask_char, process

"""
    Masker()

Create a new masker with all masks disabled by default.
"""
mutable struct Masker
    mask_email::Bool
    mask_phone::Bool
    mask_char::Char
end

Masker() = Masker(false, false, '*')

"""
    mask_emails(masker::Masker) -> Masker

Enable email address masking.
"""
function mask_emails(masker::Masker)
    masker.mask_email = true
    return masker
end

"""
    mask_phones(masker::Masker) -> Masker

Enable phone number masking.
"""
function mask_phones(masker::Masker)
    masker.mask_phone = true
    return masker
end

"""
    with_mask_char(masker::Masker, char::Char) -> Masker

Set the character used for masking.
"""
function with_mask_char(masker::Masker, char::Char)
    masker.mask_char = char
    return masker
end

"""
    with_mask_char(masker::Masker, char::AbstractString) -> Masker

Set the character used for masking. The string must contain exactly one character.
"""
function with_mask_char(masker::Masker, char::AbstractString)
    if length(char) != 1
        throw(ArgumentError("mask character must be a single character string"))
    end
    return with_mask_char(masker, only(char))
end

"""
    process(masker::Masker, input::AbstractString) -> String

Process input text and mask enabled PII patterns.
"""
function process(masker::Masker, input::AbstractString)
    result = String(input)

    if masker.mask_email
        result = mask_emails_in_text(result, masker.mask_char)
    end

    if masker.mask_phone
        result = mask_phones_in_text(result, masker.mask_char)
    end

    return result
end

@inline function is_ascii_digit(byte::UInt8)
    return byte >= UInt8('0') && byte <= UInt8('9')
end

@inline function is_local_byte(byte::UInt8)
    return (
        (byte >= UInt8('a') && byte <= UInt8('z')) ||
        (byte >= UInt8('A') && byte <= UInt8('Z')) ||
        (byte >= UInt8('0') && byte <= UInt8('9')) ||
        byte == UInt8('.') ||
        byte == UInt8('_') ||
        byte == UInt8('%') ||
        byte == UInt8('+') ||
        byte == UInt8('-')
    )
end

@inline function is_domain_byte(byte::UInt8)
    return (
        (byte >= UInt8('a') && byte <= UInt8('z')) ||
        (byte >= UInt8('A') && byte <= UInt8('Z')) ||
        (byte >= UInt8('0') && byte <= UInt8('9')) ||
        byte == UInt8('-') ||
        byte == UInt8('.')
    )
end

@inline function is_phone_start(byte::UInt8)
    return is_ascii_digit(byte) || byte == UInt8('+') || byte == UInt8('(')
end

@inline function is_phone_char(byte::UInt8)
    return is_ascii_digit(byte) || byte == UInt8(' ') || byte == UInt8('-') || byte == UInt8('(') || byte == UInt8(')') || byte == UInt8('+')
end

@inline function is_ascii_alpha(char::Char)
    return (char >= 'a' && char <= 'z') || (char >= 'A' && char <= 'Z')
end

@inline function is_ascii_alphanumeric(char::Char)
    return is_ascii_alpha(char) || (char >= '0' && char <= '9')
end

function is_valid_domain(domain::AbstractString)
    if isempty(domain)
        return false
    end
    if first(domain) == '.' || last(domain) == '.'
        return false
    end

    parts = split(domain, '.')
    if length(parts) < 2
        return false
    end

    for part in parts
        if isempty(part)
            return false
        end
        if startswith(part, "-") || endswith(part, "-")
            return false
        end
        for c in part
            if !(is_ascii_alphanumeric(c) || c == '-')
                return false
            end
        end
    end

    tld = parts[end]
    if length(tld) < 2
        return false
    end
    for c in tld
        if !is_ascii_alpha(c)
            return false
        end
    end

    return true
end

function append_segment!(output::IOBuffer, input::AbstractString, start_idx::Int, end_idx_exclusive::Int)
    if start_idx >= end_idx_exclusive
        return
    end
    end_idx_inclusive = prevind(input, end_idx_exclusive)
    write(output, SubString(input, start_idx, end_idx_inclusive))
end

function mask_local(local_part::AbstractString, mask_char::Char)
    local_length = length(local_part)
    if local_length > 1
        output = IOBuffer()
        write(output, first(local_part))
        for _ in 2:local_length
            write(output, mask_char)
        end
        return String(take!(output))
    end

    return string(mask_char)
end

function mask_phone_candidate(candidate::AbstractString, mask_char::Char)
    bytes = codeunits(candidate)
    digit_count = count(is_ascii_digit, bytes)
    current_index = 0
    output = IOBuffer()

    for byte in bytes
        if is_ascii_digit(byte)
            current_index += 1
            if digit_count > 4 && current_index <= digit_count - 4
                write(output, mask_char)
            else
                write(output, Char(byte))
            end
        else
            write(output, Char(byte))
        end
    end

    return String(take!(output))
end

function mask_emails_in_text(input::AbstractString, mask_char::Char)
    bytes = codeunits(input)
    len = length(bytes)
    output = IOBuffer()
    last = 1
    i = 1

    while i <= len
        if bytes[i] == UInt8('@')
            local_start = i
            while local_start > 1 && is_local_byte(bytes[local_start - 1])
                local_start -= 1
            end
            local_end = i

            domain_start = i + 1
            domain_end = domain_start
            while domain_end <= len && is_domain_byte(bytes[domain_end])
                domain_end += 1
            end

            if local_start < local_end && domain_start < domain_end
                candidate_end = domain_end
                matched_end = 0
                while candidate_end > domain_start
                    domain = SubString(input, domain_start, candidate_end - 1)
                    if is_valid_domain(domain)
                        matched_end = candidate_end
                        break
                    end
                    candidate_end -= 1
                end

                if matched_end != 0
                    local_part = SubString(input, local_start, local_end - 1)
                    append_segment!(output, input, last, local_start)
                    write(output, mask_local(local_part, mask_char))
                    write(output, '@')
                    write(output, SubString(input, domain_start, matched_end - 1))
                    last = matched_end
                    i = matched_end
                    continue
                end
            end
        end

        i += 1
    end

    append_segment!(output, input, last, len + 1)
    return String(take!(output))
end

function mask_phones_in_text(input::AbstractString, mask_char::Char)
    bytes = codeunits(input)
    len = length(bytes)
    output = IOBuffer()
    last = 1
    i = 1

    while i <= len
        if is_phone_start(bytes[i])
            end_idx = i
            while end_idx <= len && is_phone_char(bytes[end_idx])
                end_idx += 1
            end

            digit_count = 0
            last_digit = 0
            for idx in i:(end_idx - 1)
                if is_ascii_digit(bytes[idx])
                    digit_count += 1
                    last_digit = idx
                end
            end

            if last_digit != 0
                candidate_end = last_digit + 1
                if digit_count >= 5
                    candidate = SubString(input, i, candidate_end - 1)
                    append_segment!(output, input, last, i)
                    write(output, mask_phone_candidate(candidate, mask_char))
                    last = candidate_end
                    i = candidate_end
                    continue
                end
            end

            i = end_idx
            continue
        end

        i += 1
    end

    append_segment!(output, input, last, len + 1)
    return String(take!(output))
end

end
