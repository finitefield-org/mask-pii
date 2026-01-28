package require Tcl 8.6

namespace eval ::mask_pii {
    variable VERSION "0.2.0"
    namespace export Masker
}

# Masker is a configurable masker for email addresses and phone numbers.
oo::class create ::mask_pii::Masker {
    variable mask_email mask_phone mask_char

    # Create a new masker with all masks disabled by default.
    constructor {} {
        set mask_email 0
        set mask_phone 0
        set mask_char "*"
    }

    # Enable email address masking.
    method mask_emails {} {
        set mask_email 1
        return [self]
    }

    # Enable phone number masking.
    method mask_phones {} {
        set mask_phone 1
        return [self]
    }

    # Set the character used for masking.
    method with_mask_char {char} {
        if {$char eq ""} {
            set mask_char "*"
        } else {
            set mask_char [string index $char 0]
        }
        return [self]
    }

    # Process input text and mask enabled PII patterns.
    method process {input_text} {
        if {!$mask_email && !$mask_phone} {
            return $input_text
        }

        set result $input_text
        if {$mask_email} {
            set result [::mask_pii::mask_emails_in_text $result $mask_char]
        }
        if {$mask_phone} {
            set result [::mask_pii::mask_phones_in_text $result $mask_char]
        }
        return $result
    }
}

proc ::mask_pii::mask_emails_in_text {input_text mask_char} {
    set length [string length $input_text]
    set output ""
    set last 0
    set i 0

    while {$i < $length} {
        set ch [string index $input_text $i]
        if {$ch eq "@"} {
            set local_start $i
            while {$local_start > 0 && [::mask_pii::is_local_char [string index $input_text [expr {$local_start - 1}]]]} {
                incr local_start -1
            }
            set local_end $i

            set domain_start [expr {$i + 1}]
            set domain_end $domain_start
            while {$domain_end < $length && [::mask_pii::is_domain_char [string index $input_text $domain_end]]} {
                incr domain_end
            }

            if {$local_start < $local_end && $domain_start < $domain_end} {
                set candidate_end $domain_end
                set matched_end -1
                while {$candidate_end > $domain_start} {
                    set domain [::mask_pii::slice $input_text $domain_start [expr {$candidate_end - $domain_start}]]
                    if {[::mask_pii::is_valid_domain $domain]} {
                        set matched_end $candidate_end
                        break
                    }
                    incr candidate_end -1
                }

                if {$matched_end != -1} {
                    set local [::mask_pii::slice $input_text $local_start [expr {$local_end - $local_start}]]
                    set domain [::mask_pii::slice $input_text $domain_start [expr {$matched_end - $domain_start}]]
                    append output [::mask_pii::slice $input_text $last [expr {$local_start - $last}]]
                    append output [::mask_pii::mask_local $local $mask_char]
                    append output "@"
                    append output $domain
                    set last $matched_end
                    set i $matched_end
                    continue
                }
            }
        }
        incr i
    }

    append output [::mask_pii::slice $input_text $last [expr {$length - $last}]]
    return $output
}

proc ::mask_pii::mask_phones_in_text {input_text mask_char} {
    set length [string length $input_text]
    set output ""
    set last 0
    set i 0

    while {$i < $length} {
        if {[::mask_pii::is_phone_start [string index $input_text $i]]} {
            set end $i
            while {$end < $length && [::mask_pii::is_phone_char [string index $input_text $end]]} {
                incr end
            }

            set digit_count 0
            set last_digit_index -1
            for {set idx $i} {$idx < $end} {incr idx} {
                if {[::mask_pii::is_digit [string index $input_text $idx]]} {
                    incr digit_count
                    set last_digit_index $idx
                }
            }

            if {$last_digit_index != -1 && $digit_count >= 5} {
                set candidate_end [expr {$last_digit_index + 1}]
                set candidate [::mask_pii::slice $input_text $i [expr {$candidate_end - $i}]]
                append output [::mask_pii::slice $input_text $last [expr {$i - $last}]]
                append output [::mask_pii::mask_phone_candidate $candidate $mask_char]
                set last $candidate_end
                set i $candidate_end
                continue
            }

            set i $end
            continue
        }
        incr i
    }

    append output [::mask_pii::slice $input_text $last [expr {$length - $last}]]
    return $output
}

proc ::mask_pii::mask_local {local mask_char} {
    set length [string length $local]
    if {$length > 1} {
        return "[string index $local 0][string repeat $mask_char [expr {$length - 1}]]"
    }
    return $mask_char
}

proc ::mask_pii::mask_phone_candidate {candidate mask_char} {
    set length [string length $candidate]
    set digit_count 0
    for {set idx 0} {$idx < $length} {incr idx} {
        if {[::mask_pii::is_digit [string index $candidate $idx]]} {
            incr digit_count
        }
    }

    set current_index 0
    set output ""
    for {set idx 0} {$idx < $length} {incr idx} {
        set ch [string index $candidate $idx]
        if {[::mask_pii::is_digit $ch]} {
            incr current_index
            if {$digit_count > 4 && $current_index <= $digit_count - 4} {
                append output $mask_char
            } else {
                append output $ch
            }
        } else {
            append output $ch
        }
    }

    return $output
}

proc ::mask_pii::slice {text start length} {
    if {$length <= 0} {
        return ""
    }
    set end [expr {$start + $length - 1}]
    return [string range $text $start $end]
}

proc ::mask_pii::is_local_char {ch} {
    return [expr {[::mask_pii::is_alpha $ch]
        || [::mask_pii::is_digit $ch]
        || $ch eq "."
        || $ch eq "_"
        || $ch eq "%"
        || $ch eq "+"
        || $ch eq "-"}]
}

proc ::mask_pii::is_domain_char {ch} {
    return [expr {[::mask_pii::is_alpha $ch]
        || [::mask_pii::is_digit $ch]
        || $ch eq "-"
        || $ch eq "."}]
}

proc ::mask_pii::is_valid_domain {domain} {
    if {$domain eq ""} {
        return 0
    }
    if {[string index $domain 0] eq "." || [string index $domain end] eq "."} {
        return 0
    }

    set parts [split $domain "."]
    if {[llength $parts] < 2} {
        return 0
    }

    foreach part $parts {
        if {$part eq ""} {
            return 0
        }
        if {[string index $part 0] eq "-" || [string index $part end] eq "-"} {
            return 0
        }
        set part_length [string length $part]
        for {set idx 0} {$idx < $part_length} {incr idx} {
            set ch [string index $part $idx]
            if {![::mask_pii::is_alnum $ch] && $ch ne "-"} {
                return 0
            }
        }
    }

    set tld [lindex $parts end]
    if {[string length $tld] < 2} {
        return 0
    }
    set tld_length [string length $tld]
    for {set idx 0} {$idx < $tld_length} {incr idx} {
        if {![::mask_pii::is_alpha [string index $tld $idx]]} {
            return 0
        }
    }

    return 1
}

proc ::mask_pii::is_phone_start {ch} {
    return [expr {[::mask_pii::is_digit $ch] || $ch eq "+" || $ch eq "("}]
}

proc ::mask_pii::is_phone_char {ch} {
    return [expr {[::mask_pii::is_digit $ch]
        || $ch eq " "
        || $ch eq "-"
        || $ch eq "("
        || $ch eq ")"
        || $ch eq "+"}]
}

proc ::mask_pii::is_digit {ch} {
    if {$ch eq ""} {
        return 0
    }
    scan $ch %c code
    return [expr {$code >= 48 && $code <= 57}]
}

proc ::mask_pii::is_alpha {ch} {
    if {$ch eq ""} {
        return 0
    }
    scan $ch %c code
    return [expr {($code >= 65 && $code <= 90) || ($code >= 97 && $code <= 122)}]
}

proc ::mask_pii::is_alnum {ch} {
    return [expr {[::mask_pii::is_alpha $ch] || [::mask_pii::is_digit $ch]}]
}

package provide mask_pii $::mask_pii::VERSION
