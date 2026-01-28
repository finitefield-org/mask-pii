# mask-pii Zsh plugin
# Public API functions are documented in English per repository guidelines.

MASK_PII_VERSION="0.2.0"

typeset -gA MASK_PII_MASK_EMAIL
typeset -gA MASK_PII_MASK_PHONE
typeset -gA MASK_PII_MASK_CHAR

# _mask_pii_validate_name ensures the provided name is a safe shell identifier.
# Usage: _mask_pii_validate_name <name>
_mask_pii_validate_name() {
  emulate -L zsh
  setopt local_options no_shwordsplit

  local name=$1
  [[ $name == [A-Za-z_][A-Za-z0-9_]* ]]
}

# _mask_pii_require_masker checks that the named masker exists.
# Usage: _mask_pii_require_masker <name>
_mask_pii_require_masker() {
  emulate -L zsh
  setopt local_options no_shwordsplit

  local name=$1
  if ! _mask_pii_validate_name "$name"; then
    print -r -- "mask-pii: invalid masker name: $name" >&2
    return 1
  fi
  if [[ -z ${MASK_PII_MASK_EMAIL[$name]+set} ]]; then
    print -r -- "mask-pii: masker not initialized: $name" >&2
    return 1
  fi
  return 0
}

# mask_pii_new creates a new masker configuration in a named associative array.
# Usage: mask_pii_new <name>
mask_pii_new() {
  emulate -L zsh
  setopt local_options no_shwordsplit

  local name=$1
  if [[ -z $name ]]; then
    print -r -- "mask_pii_new: name is required" >&2
    return 1
  fi
  if ! _mask_pii_validate_name "$name"; then
    print -r -- "mask_pii_new: invalid name: $name" >&2
    return 1
  fi

  MASK_PII_MASK_EMAIL[$name]=0
  MASK_PII_MASK_PHONE[$name]=0
  MASK_PII_MASK_CHAR[$name]='*'
}

# mask_pii_mask_emails enables email masking on the named masker.
# Usage: mask_pii_mask_emails <name>
mask_pii_mask_emails() {
  emulate -L zsh
  setopt local_options no_shwordsplit

  local name=$1
  _mask_pii_require_masker "$name" || return 1
  MASK_PII_MASK_EMAIL[$name]=1
}

# mask_pii_mask_phones enables phone masking on the named masker.
# Usage: mask_pii_mask_phones <name>
mask_pii_mask_phones() {
  emulate -L zsh
  setopt local_options no_shwordsplit

  local name=$1
  _mask_pii_require_masker "$name" || return 1
  MASK_PII_MASK_PHONE[$name]=1
}

# mask_pii_with_mask_char sets the masking character on the named masker.
# Usage: mask_pii_with_mask_char <name> <char>
mask_pii_with_mask_char() {
  emulate -L zsh
  setopt local_options no_shwordsplit

  local name=$1
  _mask_pii_require_masker "$name" || return 1
  local mask_char=$2
  if [[ -z $mask_char ]]; then
    mask_char='*'
  fi
  MASK_PII_MASK_CHAR[$name]=$mask_char
}

# mask_pii_process scans input text and masks enabled PII patterns.
# Usage: mask_pii_process <name> <input>
mask_pii_process() {
  emulate -L zsh
  setopt local_options no_shwordsplit

  local name=$1
  _mask_pii_require_masker "$name" || return 1
  local input=$2

  local mask_email=${MASK_PII_MASK_EMAIL[$name]}
  local mask_phone=${MASK_PII_MASK_PHONE[$name]}
  local mask_char=${MASK_PII_MASK_CHAR[$name]}
  if [[ -z $mask_char ]]; then
    mask_char='*'
  fi

  if [[ $mask_email != 1 && $mask_phone != 1 ]]; then
    print -r -- "$input"
    return 0
  fi

  local result=$input
  if [[ $mask_email == 1 ]]; then
    result=$(_mask_pii_mask_emails_in_text "$result" "$mask_char")
  fi
  if [[ $mask_phone == 1 ]]; then
    result=$(_mask_pii_mask_phones_in_text "$result" "$mask_char")
  fi
  print -r -- "$result"
}

_mask_pii_mask_emails_in_text() {
  emulate -L zsh
  setopt local_options no_shwordsplit
  local LC_ALL=C

  local input=$1
  local mask_char=$2
  local length=${#input}
  local output=""
  local last=1
  local i=1

  while (( i <= length )); do
    if [[ ${input[i]} == '@' ]]; then
      local local_start=$i
      while (( local_start > 1 )) && _mask_pii_is_local_char "${input[local_start-1]}"; do
        ((local_start--))
      done
      local local_end=$i

      local domain_start=$((i + 1))
      local domain_end=$domain_start
      while (( domain_end <= length )) && _mask_pii_is_domain_char "${input[domain_end]}"; do
        ((domain_end++))
      done

      if (( local_start < local_end && domain_start < domain_end )); then
        local candidate_end=$domain_end
        local matched_end=0
        local domain=""
        while (( candidate_end > domain_start )); do
          domain="${input[domain_start,$((candidate_end - 1))]}"
          if _mask_pii_is_valid_domain "$domain"; then
            matched_end=$candidate_end
            break
          fi
          ((candidate_end--))
        done

        if (( matched_end > 0 )); then
          local local_part="${input[local_start,$((local_end - 1))]}"
          local masked_local=$(_mask_pii_mask_local "$local_part" "$mask_char")
          if (( last <= local_start - 1 )); then
            output+="${input[$last,$((local_start - 1))]}"
          fi
          output+="${masked_local}@${domain}"
          last=$matched_end
          i=$((matched_end - 1))
        fi
      fi
    fi
    ((i++))
  done

  if (( last <= length )); then
    output+="${input[$last,$length]}"
  fi
  print -r -- "$output"
}

_mask_pii_mask_phones_in_text() {
  emulate -L zsh
  setopt local_options no_shwordsplit
  local LC_ALL=C

  local input=$1
  local mask_char=$2
  local length=${#input}
  local output=""
  local last=1
  local i=1

  while (( i <= length )); do
    if _mask_pii_is_phone_start "${input[i]}"; then
      local end=$i
      while (( end <= length )) && _mask_pii_is_phone_char "${input[end]}"; do
        ((end++))
      done

      local digit_count=0
      local last_digit_index=0
      local idx=$i
      while (( idx < end )); do
        if _mask_pii_is_digit "${input[idx]}"; then
          ((digit_count++))
          last_digit_index=$idx
        fi
        ((idx++))
      done

      if (( last_digit_index > 0 )); then
        local candidate_end=$((last_digit_index + 1))
        if (( digit_count >= 5 )); then
          local candidate="${input[$i,$last_digit_index]}"
          local masked=$(_mask_pii_mask_phone_candidate "$candidate" "$mask_char")
          if (( last <= i - 1 )); then
            output+="${input[$last,$((i - 1))]}"
          fi
          output+="$masked"
          last=$candidate_end
          i=$((candidate_end - 1))
        fi
      fi
      i=$((end - 1))
    fi
    ((i++))
  done

  if (( last <= length )); then
    output+="${input[$last,$length]}"
  fi
  print -r -- "$output"
}

_mask_pii_mask_local() {
  emulate -L zsh
  setopt local_options no_shwordsplit

  local local_part=$1
  local mask_char=$2
  local length=${#local_part}

  if (( length > 1 )); then
    local result="${local_part[1]}"
    local i=2
    while (( i <= length )); do
      result+="$mask_char"
      ((i++))
    done
    print -r -- "$result"
    return 0
  fi

  print -r -- "$mask_char"
}

_mask_pii_mask_phone_candidate() {
  emulate -L zsh
  setopt local_options no_shwordsplit
  local LC_ALL=C

  local candidate=$1
  local mask_char=$2
  local length=${#candidate}
  local digit_count=0
  local i=1

  while (( i <= length )); do
    if _mask_pii_is_digit "${candidate[i]}"; then
      ((digit_count++))
    fi
    ((i++))
  done

  if (( digit_count <= 4 )); then
    print -r -- "$candidate"
    return 0
  fi

  local result=""
  local current_index=0
  i=1
  while (( i <= length )); do
    local ch="${candidate[i]}"
    if _mask_pii_is_digit "$ch"; then
      ((current_index++))
      if (( current_index <= digit_count - 4 )); then
        result+="$mask_char"
      else
        result+="$ch"
      fi
    else
      result+="$ch"
    fi
    ((i++))
  done

  print -r -- "$result"
}

_mask_pii_is_local_char() {
  emulate -L zsh
  setopt local_options no_shwordsplit
  local ch=$1
  [[ $ch == [A-Za-z0-9._%+-] ]]
}

_mask_pii_is_domain_char() {
  emulate -L zsh
  setopt local_options no_shwordsplit
  local ch=$1
  [[ $ch == [A-Za-z0-9.-] ]]
}

_mask_pii_is_valid_domain() {
  emulate -L zsh
  setopt local_options no_shwordsplit
  local domain=$1

  if [[ -z $domain || ${domain[1]} == '.' || ${domain[-1]} == '.' ]]; then
    return 1
  fi

  local -a parts
  parts=("${(s:.:)domain}")
  if (( ${#parts} < 2 )); then
    return 1
  fi

  local part
  for part in $parts; do
    if [[ -z $part ]]; then
      return 1
    fi
    if [[ ${part[1]} == '-' || ${part[-1]} == '-' ]]; then
      return 1
    fi
    local i=1
    local length=${#part}
    while (( i <= length )); do
      local ch=${part[i]}
      if ! _mask_pii_is_alpha_numeric "$ch" && [[ $ch != '-' ]]; then
        return 1
      fi
      ((i++))
    done
  done

  local tld=${parts[-1]}
  if (( ${#tld} < 2 )); then
    return 1
  fi
  local i=1
  while (( i <= ${#tld} )); do
    if ! _mask_pii_is_alpha "${tld[i]}"; then
      return 1
    fi
    ((i++))
  done

  return 0
}

_mask_pii_is_phone_start() {
  emulate -L zsh
  setopt local_options no_shwordsplit
  local ch=$1
  _mask_pii_is_digit "$ch" || [[ $ch == '+' || $ch == '(' ]]
}

_mask_pii_is_phone_char() {
  emulate -L zsh
  setopt local_options no_shwordsplit
  local ch=$1
  _mask_pii_is_digit "$ch" || [[ $ch == ' ' || $ch == '-' || $ch == '(' || $ch == ')' || $ch == '+' ]]
}

_mask_pii_is_digit() {
  emulate -L zsh
  setopt local_options no_shwordsplit
  local ch=$1
  [[ $ch == [0-9] ]]
}

_mask_pii_is_alpha() {
  emulate -L zsh
  setopt local_options no_shwordsplit
  local ch=$1
  [[ $ch == [A-Za-z] ]]
}

_mask_pii_is_alpha_numeric() {
  emulate -L zsh
  setopt local_options no_shwordsplit
  local ch=$1
  [[ $ch == [A-Za-z0-9] ]]
}
