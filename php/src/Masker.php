<?php

declare(strict_types=1);

namespace MaskPII;

/**
 * A configurable masker for common PII such as emails and phone numbers.
 */
final class Masker
{
    private bool $maskEmail = false;
    private bool $maskPhone = false;
    private string $maskChar = "*";

    /**
     * Create a new masker with all masks disabled by default.
     */
    public function __construct()
    {
    }

    /**
     * Enable email address masking.
     */
    public function maskEmails(): self
    {
        $this->maskEmail = true;
        return $this;
    }

    /**
     * Enable phone number masking.
     */
    public function maskPhones(): self
    {
        $this->maskPhone = true;
        return $this;
    }

    /**
     * Set the character used for masking.
     *
     * The first character of the provided string is used.
     */
    public function withMaskChar(?string $char): self
    {
        if ($char === null || $char == "") {
            $this->maskChar = "*";
        } else {
            $this->maskChar = $char[0];
        }
        return $this;
    }

    /**
     * Process input text and mask enabled PII patterns.
     */
    public function process(string $input): string
    {
        if (!$this->maskEmail && !$this->maskPhone) {
            return $input;
        }

        $result = $input;
        if ($this->maskEmail) {
            $result = $this->maskEmailsInText($result);
        }
        if ($this->maskPhone) {
            $result = $this->maskPhonesInText($result);
        }
        return $result;
    }

    private function maskEmailsInText(string $text): string
    {
        $length = strlen($text);
        $output = "";
        $last = 0;

        for ($i = 0; $i < $length; $i++) {
            if ($text[$i] === "@") {
                $localStart = $i;
                while ($localStart > 0 && $this->isLocalChar($text[$localStart - 1])) {
                    $localStart -= 1;
                }
                $localEnd = $i;

                $domainStart = $i + 1;
                $domainEnd = $domainStart;
                while ($domainEnd < $length && $this->isDomainChar($text[$domainEnd])) {
                    $domainEnd += 1;
                }

                if ($localStart < $localEnd && $domainStart < $domainEnd) {
                    $candidateEnd = $domainEnd;
                    $matchedEnd = -1;
                    while ($candidateEnd > $domainStart) {
                        $domain = substr($text, $domainStart, $candidateEnd - $domainStart);
                        if ($this->isValidDomain($domain)) {
                            $matchedEnd = $candidateEnd;
                            break;
                        }
                        $candidateEnd -= 1;
                    }

                    if ($matchedEnd !== -1) {
                        $local = substr($text, $localStart, $localEnd - $localStart);
                        $domain = substr($text, $domainStart, $matchedEnd - $domainStart);
                        $output .= substr($text, $last, $localStart - $last);
                        $output .= $this->maskLocal($local);
                        $output .= "@" . $domain;
                        $last = $matchedEnd;
                        $i = $matchedEnd - 1;
                        continue;
                    }
                }
            }
        }

        $output .= substr($text, $last);
        return $output;
    }

    private function maskPhonesInText(string $text): string
    {
        $length = strlen($text);
        $output = "";
        $last = 0;

        for ($i = 0; $i < $length; $i++) {
            if ($this->isPhoneStart($text[$i])) {
                $end = $i;
                while ($end < $length && $this->isPhoneChar($text[$end])) {
                    $end += 1;
                }

                $digitCount = 0;
                $lastDigitIndex = -1;
                for ($idx = $i; $idx < $end; $idx++) {
                    if ($this->isDigit($text[$idx])) {
                        $digitCount += 1;
                        $lastDigitIndex = $idx;
                    }
                }

                if ($lastDigitIndex !== -1 && $digitCount >= 5) {
                    $candidateEnd = $lastDigitIndex + 1;
                    $candidate = substr($text, $i, $candidateEnd - $i);
                    $output .= substr($text, $last, $i - $last);
                    $output .= $this->maskPhoneCandidate($candidate);
                    $last = $candidateEnd;
                    $i = $candidateEnd - 1;
                    continue;
                }

                $i = $end - 1;
                continue;
            }
        }

        $output .= substr($text, $last);
        return $output;
    }

    private function maskLocal(string $local): string
    {
        if (strlen($local) > 1) {
            return $local[0] . str_repeat($this->maskChar, strlen($local) - 1);
        }
        return $this->maskChar;
    }

    private function maskPhoneCandidate(string $candidate): string
    {
        $digitCount = 0;
        $length = strlen($candidate);
        for ($i = 0; $i < $length; $i++) {
            if ($this->isDigit($candidate[$i])) {
                $digitCount += 1;
            }
        }

        $currentIndex = 0;
        $output = "";
        for ($i = 0; $i < $length; $i++) {
            $ch = $candidate[$i];
            if ($this->isDigit($ch)) {
                $currentIndex += 1;
                if ($digitCount > 4 && $currentIndex <= $digitCount - 4) {
                    $output .= $this->maskChar;
                } else {
                    $output .= $ch;
                }
            } else {
                $output .= $ch;
            }
        }

        return $output;
    }

    private function isLocalChar(string $ch): bool
    {
        return $this->isAlpha($ch)
            || $this->isDigit($ch)
            || $ch === "."
            || $ch === "_"
            || $ch === "%"
            || $ch === "+"
            || $ch === "-";
    }

    private function isDomainChar(string $ch): bool
    {
        return $this->isAlpha($ch) || $this->isDigit($ch) || $ch === "-" || $ch === ".";
    }

    private function isValidDomain(string $domain): bool
    {
        if ($domain === "" || $domain[0] === "." || $domain[strlen($domain) - 1] === ".") {
            return false;
        }

        $parts = explode(".", $domain);
        if (count($parts) < 2) {
            return false;
        }

        foreach ($parts as $part) {
            if ($part === "") {
                return false;
            }
            if ($part[0] === "-" || $part[strlen($part) - 1] === "-") {
                return false;
            }
            $partLength = strlen($part);
            for ($i = 0; $i < $partLength; $i++) {
                $ch = $part[$i];
                if (!$this->isAlnum($ch) && $ch !== "-") {
                    return false;
                }
            }
        }

        $tld = $parts[count($parts) - 1];
        if (strlen($tld) < 2) {
            return false;
        }
        $tldLength = strlen($tld);
        for ($i = 0; $i < $tldLength; $i++) {
            if (!$this->isAlpha($tld[$i])) {
                return false;
            }
        }

        return true;
    }

    private function isPhoneStart(string $ch): bool
    {
        return $this->isDigit($ch) || $ch === "+" || $ch === "(";
    }

    private function isPhoneChar(string $ch): bool
    {
        return $this->isDigit($ch) || $ch === " " || $ch === "-" || $ch === "(" || $ch === ")" || $ch === "+";
    }

    private function isDigit(string $ch): bool
    {
        return $ch >= "0" && $ch <= "9";
    }

    private function isAlpha(string $ch): bool
    {
        return ($ch >= "A" && $ch <= "Z") || ($ch >= "a" && $ch <= "z");
    }

    private function isAlnum(string $ch): bool
    {
        return $this->isAlpha($ch) || $this->isDigit($ch);
    }
}
