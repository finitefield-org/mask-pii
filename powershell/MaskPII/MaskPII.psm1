Set-StrictMode -Version Latest

<#
.SYNOPSIS
Provides a configurable masker for emails and phone numbers.
#>
class Masker {
    [bool]$MaskEmailsEnabled
    [bool]$MaskPhonesEnabled
    [char]$MaskChar

    <#
    .SYNOPSIS
    Creates a new masker with all masking disabled by default.
    #>
    Masker() {
        $this.MaskEmailsEnabled = $false
        $this.MaskPhonesEnabled = $false
        $this.MaskChar = '*'
    }

    <#
    .SYNOPSIS
    Enables email address masking.
    #>
    [Masker] MaskEmails() {
        $this.MaskEmailsEnabled = $true
        return $this
    }

    <#
    .SYNOPSIS
    Enables phone number masking.
    #>
    [Masker] MaskPhones() {
        $this.MaskPhonesEnabled = $true
        return $this
    }

    <#
    .SYNOPSIS
    Sets the character used for masking.
    #>
    [Masker] WithMaskChar([char]$MaskChar) {
        if ($MaskChar -eq [char]0) {
            $MaskChar = '*'
        }
        $this.MaskChar = $MaskChar
        return $this
    }

    <#
    .SYNOPSIS
    Scans input text and masks enabled PII patterns.
    #>
    [string] Process([string]$Input) {
        if (-not $this.MaskEmailsEnabled -and -not $this.MaskPhonesEnabled) {
            return $Input
        }

        $maskChar = $this.MaskChar
        if ($maskChar -eq [char]0) {
            $maskChar = '*'
        }

        $result = $Input
        if ($this.MaskEmailsEnabled) {
            $result = [Masker]::MaskEmailsInText($result, $maskChar)
        }
        if ($this.MaskPhonesEnabled) {
            $result = [Masker]::MaskPhonesInText($result, $maskChar)
        }
        return $result
    }

    hidden static [string] MaskEmailsInText([string]$Input, [char]$MaskChar) {
        $length = $Input.Length
        $builder = [System.Text.StringBuilder]::new($length)
        $last = 0

        for ($i = 0; $i -lt $length; $i++) {
            if ($Input[$i] -eq '@') {
                $localStart = $i
                while ($localStart -gt 0 -and [Masker]::IsLocalChar($Input[$localStart - 1])) {
                    $localStart--
                }
                $localEnd = $i

                $domainStart = $i + 1
                $domainEnd = $domainStart
                while ($domainEnd -lt $length -and [Masker]::IsDomainChar($Input[$domainEnd])) {
                    $domainEnd++
                }

                if ($localStart -lt $localEnd -and $domainStart -lt $domainEnd) {
                    $candidateEnd = $domainEnd
                    $matchedEnd = -1

                    while ($candidateEnd -gt $domainStart) {
                        $domain = $Input.Substring($domainStart, $candidateEnd - $domainStart)
                        if ([Masker]::IsValidDomain($domain)) {
                            $matchedEnd = $candidateEnd
                            break
                        }
                        $candidateEnd--
                    }

                    if ($matchedEnd -ne -1) {
                        $local = $Input.Substring($localStart, $localEnd - $localStart)
                        $domain = $Input.Substring($domainStart, $matchedEnd - $domainStart)

                        [void]$builder.Append($Input.Substring($last, $localStart - $last))
                        [void]$builder.Append([Masker]::MaskLocal($local, $MaskChar))
                        [void]$builder.Append('@')
                        [void]$builder.Append($domain)

                        $last = $matchedEnd
                        $i = $matchedEnd - 1
                        continue
                    }
                }
            }
        }

        [void]$builder.Append($Input.Substring($last))
        return $builder.ToString()
    }

    hidden static [string] MaskPhonesInText([string]$Input, [char]$MaskChar) {
        $length = $Input.Length
        $builder = [System.Text.StringBuilder]::new($length)
        $last = 0

        for ($i = 0; $i -lt $length; $i++) {
            if ([Masker]::IsPhoneStart($Input[$i])) {
                $end = $i
                while ($end -lt $length -and [Masker]::IsPhoneChar($Input[$end])) {
                    $end++
                }

                $digitCount = 0
                $lastDigitIndex = -1
                for ($idx = $i; $idx -lt $end; $idx++) {
                    if ([Masker]::IsDigit($Input[$idx])) {
                        $digitCount++
                        $lastDigitIndex = $idx
                    }
                }

                if ($lastDigitIndex -ne -1) {
                    $candidateEnd = $lastDigitIndex + 1
                    if ($digitCount -ge 5) {
                        $candidate = $Input.Substring($i, $candidateEnd - $i)
                        [void]$builder.Append($Input.Substring($last, $i - $last))
                        [void]$builder.Append([Masker]::MaskPhoneCandidate($candidate, $MaskChar))
                        $last = $candidateEnd
                        $i = $candidateEnd - 1
                        continue
                    }
                }

                $i = $end - 1
                continue
            }
        }

        [void]$builder.Append($Input.Substring($last))
        return $builder.ToString()
    }

    hidden static [string] MaskLocal([string]$Local, [char]$MaskChar) {
        if ($Local.Length -gt 1) {
            $builder = [System.Text.StringBuilder]::new($Local.Length)
            [void]$builder.Append($Local[0])
            for ($i = 1; $i -lt $Local.Length; $i++) {
                [void]$builder.Append($MaskChar)
            }
            return $builder.ToString()
        }
        return $MaskChar.ToString()
    }

    hidden static [string] MaskPhoneCandidate([string]$Candidate, [char]$MaskChar) {
        $digitCount = 0
        foreach ($ch in $Candidate.ToCharArray()) {
            if ([Masker]::IsDigit($ch)) {
                $digitCount++
            }
        }

        $currentIndex = 0
        $builder = [System.Text.StringBuilder]::new($Candidate.Length)
        foreach ($ch in $Candidate.ToCharArray()) {
            if ([Masker]::IsDigit($ch)) {
                $currentIndex++
                if ($digitCount -gt 4 -and $currentIndex -le ($digitCount - 4)) {
                    [void]$builder.Append($MaskChar)
                } else {
                    [void]$builder.Append($ch)
                }
            } else {
                [void]$builder.Append($ch)
            }
        }

        return $builder.ToString()
    }

    hidden static [bool] IsLocalChar([char]$Char) {
        return ([Masker]::IsAlphaNumeric($Char) -or $Char -eq '.' -or $Char -eq '_' -or $Char -eq '%' -or $Char -eq '+' -or $Char -eq '-')
    }

    hidden static [bool] IsDomainChar([char]$Char) {
        return ([Masker]::IsAlphaNumeric($Char) -or $Char -eq '-' -or $Char -eq '.')
    }

    hidden static [bool] IsValidDomain([string]$Domain) {
        if ([string]::IsNullOrEmpty($Domain)) {
            return $false
        }
        if ($Domain[0] -eq '.' -or $Domain[$Domain.Length - 1] -eq '.') {
            return $false
        }

        $parts = $Domain.Split('.')
        if ($parts.Length -lt 2) {
            return $false
        }

        foreach ($part in $parts) {
            if ([string]::IsNullOrEmpty($part)) {
                return $false
            }
            if ($part[0] -eq '-' -or $part[$part.Length - 1] -eq '-') {
                return $false
            }
            foreach ($ch in $part.ToCharArray()) {
                if (-not ([Masker]::IsAlphaNumeric($ch) -or $ch -eq '-')) {
                    return $false
                }
            }
        }

        $tld = $parts[$parts.Length - 1]
        if ($tld.Length -lt 2) {
            return $false
        }
        foreach ($ch in $tld.ToCharArray()) {
            if (-not [Masker]::IsAlpha($ch)) {
                return $false
            }
        }

        return $true
    }

    hidden static [bool] IsPhoneStart([char]$Char) {
        return ([Masker]::IsDigit($Char) -or $Char -eq '+' -or $Char -eq '(')
    }

    hidden static [bool] IsPhoneChar([char]$Char) {
        return ([Masker]::IsDigit($Char) -or $Char -eq ' ' -or $Char -eq '-' -or $Char -eq '(' -or $Char -eq ')' -or $Char -eq '+')
    }

    hidden static [bool] IsDigit([char]$Char) {
        $code = [int]$Char
        return ($code -ge [int]'0' -and $code -le [int]'9')
    }

    hidden static [bool] IsAlpha([char]$Char) {
        $code = [int]$Char
        return (($code -ge [int]'a' -and $code -le [int]'z') -or ($code -ge [int]'A' -and $code -le [int]'Z'))
    }

    hidden static [bool] IsAlphaNumeric([char]$Char) {
        return ([Masker]::IsAlpha($Char) -or [Masker]::IsDigit($Char))
    }
}

<#
.SYNOPSIS
Creates a new masker with all masking disabled by default.
#>
function New-Masker {
    return [Masker]::new()
}

Export-ModuleMember -Function New-Masker -Class Masker
