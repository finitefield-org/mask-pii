# mask-pii Fish implementation.

if not set -q __mask_pii_alpha
    set -g __mask_pii_alpha a b c d e f g h i j k l m n o p q r s t u v w x y z A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
end

if not set -q __mask_pii_digits
    set -g __mask_pii_digits 0 1 2 3 4 5 6 7 8 9
end

if not set -q __mask_pii_local_symbols
    set -g __mask_pii_local_symbols . _ % + -
end

if not set -q __mask_pii_domain_symbols
    set -g __mask_pii_domain_symbols - .
end

if not set -q __mask_pii_phone_symbols
    set -g __mask_pii_phone_symbols ' ' - '(' ')' +
end

# Public API
# Masks emails and/or phone numbers in input text.
function mask_pii --description "Mask emails and phone numbers in input text."
    set -l options 'e/emails' 'p/phones' 'm/mask-char=' 'h/help'
    argparse --name mask_pii $options -- $argv
    or return 1

    if set -q _flag_help
        __mask_pii_print_help
        return 0
    end

    set -l mask_emails 0
    set -l mask_phones 0
    if set -q _flag_emails
        set mask_emails 1
    end
    if set -q _flag_phones
        set mask_phones 1
    end

    set -l mask_char "*"
    if set -q _flag_mask_char
        set -l raw "$_flag_mask_char"
        set -l raw (string trim -- "$raw")
        if test -n "$raw"
            set mask_char (string sub -s 1 -l 1 -- "$raw")
        end
    end

    set -l input_text
    if test (count $argv) -gt 0
        set input_text $argv[1]
    else
        set input_text (cat)
    end

    if test $mask_emails -eq 0 -a $mask_phones -eq 0
        printf "%s" "$input_text"
        return 0
    end

    set -l result "$input_text"
    if test $mask_emails -eq 1
        set result (__mask_pii_mask_emails_in_text "$result" "$mask_char")
    end
    if test $mask_phones -eq 1
        set result (__mask_pii_mask_phones_in_text "$result" "$mask_char")
    end

    printf "%s" "$result"
end

# Public API
# Prints the current mask-pii version.
function mask_pii_version --description "Print the mask-pii version."
    set -l current_file (status --current-filename)
    set -l version_file (dirname "$current_file")/../VERSION
    if test -f "$version_file"
        printf "%s" (string trim -- (cat "$version_file"))
        return 0
    end
    printf "%s" "0.2.0"
end

function __mask_pii_print_help
    echo "mask_pii --emails --phones [--mask-char CHAR] [TEXT]"
    echo ""
    echo "Options:"
    echo "  -e, --emails        Enable email masking"
    echo "  -p, --phones        Enable phone masking"
    echo "  -m, --mask-char CHAR Set the mask character (default: *)"
    echo "  -h, --help          Show this help"
    echo ""
    echo "Pass TEXT as a single argument (quote it if it contains spaces)"
    echo "or pipe input via stdin."
end

function __mask_pii_mask_emails_in_text
    set -l input_text $argv[1]
    set -l mask_char $argv[2]
    set -l length (string length -- "$input_text")
    set -l parts
    set -l last 1
    set -l i 1

    while test $i -le $length
        set -l ch (string sub -s $i -l 1 -- "$input_text")
        if test "$ch" = "@"
            set -l local_start $i
            while test $local_start -gt 1
                set -l prev_index (math $local_start - 1)
                set -l prev_char (string sub -s $prev_index -l 1 -- "$input_text")
                if __mask_pii_is_local_char "$prev_char"
                    set local_start $prev_index
                else
                    break
                end
            end

            set -l local_len (math $i - $local_start)
            set -l domain_start (math $i + 1)
            set -l domain_end $domain_start
            while test $domain_end -le $length
                set -l domain_char (string sub -s $domain_end -l 1 -- "$input_text")
                if __mask_pii_is_domain_char "$domain_char"
                    set domain_end (math $domain_end + 1)
                else
                    break
                end
            end

            if test $local_len -gt 0 -a $domain_start -lt $domain_end
                set -l candidate_end (math $domain_end - 1)
                set -l matched_end -1
                while test $candidate_end -ge $domain_start
                    set -l domain_len (math $candidate_end - $domain_start + 1)
                    set -l domain (string sub -s $domain_start -l $domain_len -- "$input_text")
                    if __mask_pii_is_valid_domain "$domain"
                        set matched_end $candidate_end
                        break
                    end
                    set candidate_end (math $candidate_end - 1)
                end

                if test $matched_end -ne -1
                    if test $local_start -gt $last
                        set -l prefix_len (math $local_start - $last)
                        set -l prefix (string sub -s $last -l $prefix_len -- "$input_text")
                        set parts $parts "$prefix"
                    end

                    set -l local (string sub -s $local_start -l $local_len -- "$input_text")
                    set -l masked_local (__mask_pii_mask_local "$local" "$mask_char")
                    set -l domain_len (math $matched_end - $domain_start + 1)
                    set -l domain (string sub -s $domain_start -l $domain_len -- "$input_text")

                    set parts $parts "$masked_local" "@" "$domain"
                    set last (math $matched_end + 1)
                    set i $last
                    continue
                end
            end
        end
        set i (math $i + 1)
    end

    if test $last -le $length
        set -l suffix_len (math $length - $last + 1)
        set -l suffix (string sub -s $last -l $suffix_len -- "$input_text")
        set parts $parts "$suffix"
    end

    string join "" -- $parts
end

function __mask_pii_mask_phones_in_text
    set -l input_text $argv[1]
    set -l mask_char $argv[2]
    set -l length (string length -- "$input_text")
    set -l parts
    set -l last 1
    set -l i 1

    while test $i -le $length
        set -l ch (string sub -s $i -l 1 -- "$input_text")
        if __mask_pii_is_phone_start "$ch"
            set -l end $i
            while test $end -le $length
                set -l end_char (string sub -s $end -l 1 -- "$input_text")
                if __mask_pii_is_phone_char "$end_char"
                    set end (math $end + 1)
                else
                    break
                end
            end

            set -l digit_count 0
            set -l last_digit_index -1
            set -l idx $i
            while test $idx -lt $end
                set -l idx_char (string sub -s $idx -l 1 -- "$input_text")
                if __mask_pii_is_digit "$idx_char"
                    set digit_count (math $digit_count + 1)
                    set last_digit_index $idx
                end
                set idx (math $idx + 1)
            end

            if test $last_digit_index -ne -1
                if test $digit_count -ge 5
                    set -l candidate_end $last_digit_index
                    if test $i -gt $last
                        set -l prefix_len (math $i - $last)
                        set -l prefix (string sub -s $last -l $prefix_len -- "$input_text")
                        set parts $parts "$prefix"
                    end
                    set -l candidate_len (math $candidate_end - $i + 1)
                    set -l candidate (string sub -s $i -l $candidate_len -- "$input_text")
                    set -l masked_candidate (__mask_pii_mask_phone_candidate "$candidate" "$mask_char")
                    set parts $parts "$masked_candidate"
                    set last (math $candidate_end + 1)
                    set i $last
                    continue
                end
            end

            set i $end
            continue
        end
        set i (math $i + 1)
    end

    if test $last -le $length
        set -l suffix_len (math $length - $last + 1)
        set -l suffix (string sub -s $last -l $suffix_len -- "$input_text")
        set parts $parts "$suffix"
    end

    string join "" -- $parts
end

function __mask_pii_mask_local
    set -l local $argv[1]
    set -l mask_char $argv[2]
    set -l length (string length -- "$local")
    if test $length -gt 1
        set -l masked_tail (string repeat -n (math $length - 1) -- "$mask_char")
        printf "%s" (string sub -s 1 -l 1 -- "$local")"$masked_tail"
        return 0
    end
    printf "%s" "$mask_char"
end

function __mask_pii_mask_phone_candidate
    set -l candidate $argv[1]
    set -l mask_char $argv[2]
    set -l length (string length -- "$candidate")
    set -l digit_count 0
    set -l idx 1
    while test $idx -le $length
        set -l ch (string sub -s $idx -l 1 -- "$candidate")
        if __mask_pii_is_digit "$ch"
            set digit_count (math $digit_count + 1)
        end
        set idx (math $idx + 1)
    end

    if test $digit_count -le 4
        printf "%s" "$candidate"
        return 0
    end

    set -l current_index 0
    set -l parts
    set -l idx 1
    while test $idx -le $length
        set -l ch (string sub -s $idx -l 1 -- "$candidate")
        if __mask_pii_is_digit "$ch"
            set current_index (math $current_index + 1)
            if test $current_index -le (math $digit_count - 4)
                set parts $parts "$mask_char"
            else
                set parts $parts "$ch"
            end
        else
            set parts $parts "$ch"
        end
        set idx (math $idx + 1)
    end

    string join "" -- $parts
end

function __mask_pii_is_local_char
    set -l ch $argv[1]
    if __mask_pii_is_alpha "$ch"
        return 0
    end
    if __mask_pii_is_digit "$ch"
        return 0
    end
    if contains -- "$ch" $__mask_pii_local_symbols
        return 0
    end
    return 1
end

function __mask_pii_is_domain_char
    set -l ch $argv[1]
    if __mask_pii_is_alpha "$ch"
        return 0
    end
    if __mask_pii_is_digit "$ch"
        return 0
    end
    if contains -- "$ch" $__mask_pii_domain_symbols
        return 0
    end
    return 1
end

function __mask_pii_is_valid_domain
    set -l domain $argv[1]
    if test -z "$domain"
        return 1
    end

    set -l first (string sub -s 1 -l 1 -- "$domain")
    set -l last (string sub -s (string length -- "$domain") -l 1 -- "$domain")
    if test "$first" = "." -o "$last" = "."
        return 1
    end

    set -l parts (string split . -- "$domain")
    if test (count $parts) -lt 2
        return 1
    end

    for part in $parts
        if test -z "$part"
            return 1
        end
        set -l part_first (string sub -s 1 -l 1 -- "$part")
        set -l part_last (string sub -s (string length -- "$part") -l 1 -- "$part")
        if test "$part_first" = "-" -o "$part_last" = "-"
            return 1
        end
        set -l part_len (string length -- "$part")
        set -l idx 1
        while test $idx -le $part_len
            set -l ch (string sub -s $idx -l 1 -- "$part")
            if __mask_pii_is_alnum "$ch"
                set idx (math $idx + 1)
                continue
            end
            if test "$ch" = "-"
                set idx (math $idx + 1)
                continue
            end
            return 1
        end
    end

    set -l tld $parts[-1]
    if test (string length -- "$tld") -lt 2
        return 1
    end
    set -l tld_len (string length -- "$tld")
    set -l idx 1
    while test $idx -le $tld_len
        set -l ch (string sub -s $idx -l 1 -- "$tld")
        if not __mask_pii_is_alpha "$ch"
            return 1
        end
        set idx (math $idx + 1)
    end

    return 0
end

function __mask_pii_is_phone_start
    set -l ch $argv[1]
    if __mask_pii_is_digit "$ch"
        return 0
    end
    if test "$ch" = "+" -o "$ch" = "("
        return 0
    end
    return 1
end

function __mask_pii_is_phone_char
    set -l ch $argv[1]
    if __mask_pii_is_digit "$ch"
        return 0
    end
    if contains -- "$ch" $__mask_pii_phone_symbols
        return 0
    end
    return 1
end

function __mask_pii_is_digit
    set -l ch $argv[1]
    contains -- "$ch" $__mask_pii_digits
end

function __mask_pii_is_alpha
    set -l ch $argv[1]
    contains -- "$ch" $__mask_pii_alpha
end

function __mask_pii_is_alnum
    set -l ch $argv[1]
    if __mask_pii_is_alpha "$ch"
        return 0
    end
    if __mask_pii_is_digit "$ch"
        return 0
    end
    return 1
end
