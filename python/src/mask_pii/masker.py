"""Core masking logic for the mask_pii package."""

from __future__ import annotations


class Masker:
    """A configurable masker for emails and phone numbers."""

    def __init__(self) -> None:
        """Create a new masker with all masks disabled by default."""
        self._mask_email = False
        self._mask_phone = False
        self._mask_char = "*"

    def mask_emails(self) -> "Masker":
        """Enable email address masking."""
        self._mask_email = True
        return self

    def mask_phones(self) -> "Masker":
        """Enable phone number masking."""
        self._mask_phone = True
        return self

    def with_mask_char(self, char: str | None) -> "Masker":
        """Set the character used for masking."""
        if not char:
            self._mask_char = "*"
        else:
            if not isinstance(char, str):
                char = str(char)
            self._mask_char = char[0]
        return self

    def process(self, input_text: str) -> str:
        """Process input text and mask enabled PII patterns."""
        if not self._mask_email and not self._mask_phone:
            return input_text

        mask_char = self._mask_char or "*"
        result = input_text
        if self._mask_email:
            result = _mask_emails_in_text(result, mask_char)
        if self._mask_phone:
            result = _mask_phones_in_text(result, mask_char)
        return result


def _mask_emails_in_text(input_text: str, mask_char: str) -> str:
    length = len(input_text)
    output: list[str] = []
    last = 0
    i = 0

    while i < length:
        if input_text[i] == "@":
            local_start = i
            while local_start > 0 and _is_local_char(input_text[local_start - 1]):
                local_start -= 1
            local_end = i

            domain_start = i + 1
            domain_end = domain_start
            while domain_end < length and _is_domain_char(input_text[domain_end]):
                domain_end += 1

            if local_start < local_end and domain_start < domain_end:
                candidate_end = domain_end
                matched_end = -1
                while candidate_end > domain_start:
                    domain = input_text[domain_start:candidate_end]
                    if _is_valid_domain(domain):
                        matched_end = candidate_end
                        break
                    candidate_end -= 1

                if matched_end != -1:
                    local = input_text[local_start:local_end]
                    domain = input_text[domain_start:matched_end]
                    output.append(input_text[last:local_start])
                    output.append(_mask_local(local, mask_char))
                    output.append("@")
                    output.append(domain)
                    last = matched_end
                    i = matched_end
                    continue
        i += 1

    output.append(input_text[last:])
    return "".join(output)


def _mask_phones_in_text(input_text: str, mask_char: str) -> str:
    length = len(input_text)
    output: list[str] = []
    last = 0
    i = 0

    while i < length:
        if _is_phone_start(input_text[i]):
            end = i
            while end < length and _is_phone_char(input_text[end]):
                end += 1

            digit_count = 0
            last_digit_index = -1
            for idx in range(i, end):
                if _is_digit(input_text[idx]):
                    digit_count += 1
                    last_digit_index = idx

            if last_digit_index != -1:
                candidate_end = last_digit_index + 1
                if digit_count >= 5:
                    candidate = input_text[i:candidate_end]
                    output.append(input_text[last:i])
                    output.append(_mask_phone_candidate(candidate, mask_char))
                    last = candidate_end
                    i = candidate_end
                    continue

            i = end
            continue
        i += 1

    output.append(input_text[last:])
    return "".join(output)


def _mask_local(local: str, mask_char: str) -> str:
    if len(local) > 1:
        return local[0] + (mask_char * (len(local) - 1))
    return mask_char


def _mask_phone_candidate(candidate: str, mask_char: str) -> str:
    digit_count = sum(1 for ch in candidate if _is_digit(ch))
    current_index = 0
    result_chars: list[str] = []

    for ch in candidate:
        if _is_digit(ch):
            current_index += 1
            if digit_count > 4 and current_index <= digit_count - 4:
                result_chars.append(mask_char)
            else:
                result_chars.append(ch)
        else:
            result_chars.append(ch)

    return "".join(result_chars)


def _is_local_char(ch: str) -> bool:
    return (
        _is_alpha(ch)
        or _is_digit(ch)
        or ch in {".", "_", "%", "+", "-"}
    )


def _is_domain_char(ch: str) -> bool:
    return _is_alpha(ch) or _is_digit(ch) or ch in {"-", "."}


def _is_valid_domain(domain: str) -> bool:
    if not domain or domain[0] == "." or domain[-1] == ".":
        return False

    parts = domain.split(".")
    if len(parts) < 2:
        return False

    for part in parts:
        if not part:
            return False
        if part[0] == "-" or part[-1] == "-":
            return False
        for ch in part:
            if not (_is_alnum(ch) or ch == "-"):
                return False

    tld = parts[-1]
    if len(tld) < 2:
        return False
    for ch in tld:
        if not _is_alpha(ch):
            return False

    return True


def _is_phone_start(ch: str) -> bool:
    return _is_digit(ch) or ch in {"+", "("}


def _is_phone_char(ch: str) -> bool:
    return _is_digit(ch) or ch in {" ", "-", "(", ")", "+"}


def _is_digit(ch: str) -> bool:
    return "0" <= ch <= "9"


def _is_alpha(ch: str) -> bool:
    return ("a" <= ch <= "z") or ("A" <= ch <= "Z")


def _is_alnum(ch: str) -> bool:
    return _is_alpha(ch) or _is_digit(ch)
