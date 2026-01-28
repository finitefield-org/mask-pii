#!/usr/bin/env bash

# MASK_PII_VERSION is the current release version of the mask-pii Bash package.
MASK_PII_VERSION="0.2.0"

# mask_pii_new creates a new masker configuration stored in the named associative array.
# Usage: mask_pii_new <masker_name>
mask_pii_new() {
  local name="$1"
  if [[ -z "$name" ]]; then
    printf 'mask-pii: masker name is required\n' >&2
    return 1
  fi
  if ! mask_pii__is_valid_name "$name"; then
    printf 'mask-pii: invalid masker name: %s\n' "$name" >&2
    return 1
  fi

  mask_pii__set_config "$name" "mask_email" "0"
  mask_pii__set_config "$name" "mask_phone" "0"
  mask_pii__set_config "$name" "mask_char" "*"
}

# mask_pii_mask_emails enables email masking on the named masker.
# Usage: mask_pii_mask_emails <masker_name>
mask_pii_mask_emails() {
  local name="$1"
  mask_pii__require_masker "$name" || return 1
  mask_pii__set_config "$name" "mask_email" "1"
}

# mask_pii_mask_phones enables phone masking on the named masker.
# Usage: mask_pii_mask_phones <masker_name>
mask_pii_mask_phones() {
  local name="$1"
  mask_pii__require_masker "$name" || return 1
  mask_pii__set_config "$name" "mask_phone" "1"
}

# mask_pii_with_mask_char sets the masking character on the named masker.
# Usage: mask_pii_with_mask_char <masker_name> <char>
mask_pii_with_mask_char() {
  local name="$1"
  local char="$2"
  mask_pii__require_masker "$name" || return 1

  if [[ -z "$char" ]]; then
    mask_pii__set_config "$name" "mask_char" "*"
  else
    mask_pii__set_config "$name" "mask_char" "${char:0:1}"
  fi
}

# mask_pii_process applies the configured masks to the input text and prints the result.
# Usage: mask_pii_process <masker_name> <input_text>
mask_pii_process() {
  local name="$1"
  local input="$2"
  if [[ -z "$name" ]]; then
    printf 'mask-pii: masker name is required\n' >&2
    return 1
  fi
  if [[ -z "$input" && $# -lt 2 ]]; then
    printf 'mask-pii: input text is required\n' >&2
    return 1
  fi

  mask_pii__require_masker "$name" || return 1
  local mask_email
  local mask_phone
  local mask_char
  mask_email=$(mask_pii__get_config "$name" "mask_email")
  mask_phone=$(mask_pii__get_config "$name" "mask_phone")
  mask_char=$(mask_pii__get_config "$name" "mask_char")

  if [[ -z "$mask_char" ]]; then
    mask_char="*"
  fi

  if [[ "$mask_email" != "1" && "$mask_phone" != "1" ]]; then
    printf '%s' "$input"
    return 0
  fi

  local result="$input"
  if [[ "$mask_email" == "1" ]]; then
    result=$(mask_pii__mask_emails_in_text "$result" "$mask_char")
  fi
  if [[ "$mask_phone" == "1" ]]; then
    result=$(mask_pii__mask_phones_in_text "$result" "$mask_char")
  fi

  printf '%s' "$result"
}

mask_pii__mask_emails_in_text() {
  local input="$1"
  local mask_char="$2"
  local length=${#input}
  local output=""
  local last=0
  local i=0

  while (( i < length )); do
    local ch="${input:i:1}"
    if [[ "$ch" == "@" ]]; then
      local local_start=$i
      while (( local_start > 0 )); do
        local prev="${input:local_start-1:1}"
        if mask_pii__is_local_char "$prev"; then
          ((local_start--))
        else
          break
        fi
      done
      local local_end=$i

      local domain_start=$((i + 1))
      local domain_end=$domain_start
      while (( domain_end < length )); do
        local dom_ch="${input:domain_end:1}"
        if mask_pii__is_domain_char "$dom_ch"; then
          ((domain_end++))
        else
          break
        fi
      done

      if (( local_start < local_end && domain_start < domain_end )); then
        local candidate_end=$domain_end
        local matched_end=-1
        while (( candidate_end > domain_start )); do
          local domain="${input:domain_start:candidate_end-domain_start}"
          if mask_pii__is_valid_domain "$domain"; then
            matched_end=$candidate_end
            break
          fi
          ((candidate_end--))
        done

        if (( matched_end != -1 )); then
          local local_part="${input:local_start:local_end-local_start}"
          local domain_part="${input:domain_start:matched_end-domain_start}"
          output+="${input:last:local_start-last}"
          output+="$(mask_pii__mask_local "$local_part" "$mask_char")"
          output+="@${domain_part}"
          last=$matched_end
          i=$matched_end
          continue
        fi
      fi
    fi
    ((i++))
  done

  output+="${input:last}"
  printf '%s' "$output"
}

mask_pii__mask_phones_in_text() {
  local input="$1"
  local mask_char="$2"
  local length=${#input}
  local output=""
  local last=0
  local i=0

  while (( i < length )); do
    local ch="${input:i:1}"
    if mask_pii__is_phone_start "$ch"; then
      local end=$i
      while (( end < length )); do
        local end_ch="${input:end:1}"
        if mask_pii__is_phone_char "$end_ch"; then
          ((end++))
        else
          break
        fi
      done

      local digit_count=0
      local last_digit_index=-1
      local idx=$i
      while (( idx < end )); do
        local digit_ch="${input:idx:1}"
        if mask_pii__is_digit "$digit_ch"; then
          ((digit_count++))
          last_digit_index=$idx
        fi
        ((idx++))
      done

      if (( last_digit_index != -1 )); then
        local candidate_end=$((last_digit_index + 1))
        if (( digit_count >= 5 )); then
          local candidate="${input:i:candidate_end-i}"
          output+="${input:last:i-last}"
          output+="$(mask_pii__mask_phone_candidate "$candidate" "$mask_char")"
          last=$candidate_end
          i=$candidate_end
          continue
        fi
      fi

      i=$end
      continue
    fi
    ((i++))
  done

  output+="${input:last}"
  printf '%s' "$output"
}

mask_pii__mask_local() {
  local local_part="$1"
  local mask_char="$2"
  local length=${#local_part}
  if (( length > 1 )); then
    local result="${local_part:0:1}"
    local i=1
    while (( i < length )); do
      result+="$mask_char"
      ((i++))
    done
    printf '%s' "$result"
  else
    printf '%s' "$mask_char"
  fi
}

mask_pii__mask_phone_candidate() {
  local candidate="$1"
  local mask_char="$2"
  local digit_count=0
  local i=0
  local length=${#candidate}

  while (( i < length )); do
    local ch="${candidate:i:1}"
    if mask_pii__is_digit "$ch"; then
      ((digit_count++))
    fi
    ((i++))
  done

  local current_index=0
  local result=""
  i=0
  while (( i < length )); do
    local ch="${candidate:i:1}"
    if mask_pii__is_digit "$ch"; then
      ((current_index++))
      if (( digit_count > 4 && current_index <= digit_count - 4 )); then
        result+="$mask_char"
      else
        result+="$ch"
      fi
    else
      result+="$ch"
    fi
    ((i++))
  done

  printf '%s' "$result"
}

mask_pii__is_local_char() {
  local ch="$1"
  if mask_pii__is_alpha "$ch"; then
    return 0
  fi
  if mask_pii__is_digit "$ch"; then
    return 0
  fi
  case "$ch" in
    "."|"_"|"%"|"+"|"-") return 0 ;;
  esac
  return 1
}

mask_pii__is_domain_char() {
  local ch="$1"
  if mask_pii__is_alpha "$ch"; then
    return 0
  fi
  if mask_pii__is_digit "$ch"; then
    return 0
  fi
  case "$ch" in
    "."|"-") return 0 ;;
  esac
  return 1
}

mask_pii__is_valid_domain() {
  local domain="$1"
  if [[ -z "$domain" ]]; then
    return 1
  fi
  if [[ "${domain:0:1}" == "." || "${domain: -1}" == "." ]]; then
    return 1
  fi

  local -a parts=()
  local current=""
  local i=0
  local length=${#domain}
  while (( i < length )); do
    local ch="${domain:i:1}"
    if [[ "$ch" == "." ]]; then
      parts+=("$current")
      current=""
    else
      current+="$ch"
    fi
    ((i++))
  done
  parts+=("$current")

  if (( ${#parts[@]} < 2 )); then
    return 1
  fi

  local part
  for part in "${parts[@]}"; do
    if [[ -z "$part" ]]; then
      return 1
    fi
    if [[ "${part:0:1}" == "-" || "${part: -1}" == "-" ]]; then
      return 1
    fi
    local j=0
    local part_len=${#part}
    while (( j < part_len )); do
      local part_ch="${part:j:1}"
      if mask_pii__is_alnum "$part_ch"; then
        :
      elif [[ "$part_ch" == "-" ]]; then
        :
      else
        return 1
      fi
      ((j++))
    done
  done

  local tld="${parts[${#parts[@]}-1]}"
  if (( ${#tld} < 2 )); then
    return 1
  fi
  local k=0
  local tld_len=${#tld}
  while (( k < tld_len )); do
    local tld_ch="${tld:k:1}"
    if ! mask_pii__is_alpha "$tld_ch"; then
      return 1
    fi
    ((k++))
  done

  return 0
}

mask_pii__is_phone_start() {
  local ch="$1"
  if mask_pii__is_digit "$ch"; then
    return 0
  fi
  case "$ch" in
    "+"|"(") return 0 ;;
  esac
  return 1
}

mask_pii__is_phone_char() {
  local ch="$1"
  if mask_pii__is_digit "$ch"; then
    return 0
  fi
  case "$ch" in
    " "|"-"|"("|")"|"+") return 0 ;;
  esac
  return 1
}

mask_pii__is_digit() {
  local ch="$1"
  case "$ch" in
    [0-9]) return 0 ;;
  esac
  return 1
}

mask_pii__is_alpha() {
  local ch="$1"
  case "$ch" in
    [A-Za-z]) return 0 ;;
  esac
  return 1
}

mask_pii__is_alnum() {
  local ch="$1"
  if mask_pii__is_alpha "$ch"; then
    return 0
  fi
  if mask_pii__is_digit "$ch"; then
    return 0
  fi
  return 1
}

mask_pii__config_var() {
  local name="$1"
  local key="$2"
  printf 'mask_pii_%s_%s' "$name" "$key"
}

mask_pii__set_config() {
  local name="$1"
  local key="$2"
  local value="$3"
  local var
  var=$(mask_pii__config_var "$name" "$key")
  printf -v "$var" '%s' "$value"
}

mask_pii__get_config() {
  local name="$1"
  local key="$2"
  local var
  var=$(mask_pii__config_var "$name" "$key")
  printf '%s' "${!var-}"
}

mask_pii__is_valid_name() {
  local name="$1"
  if [[ -z "$name" ]]; then
    return 1
  fi
  case "$name" in
    [0-9]*|*[^a-zA-Z0-9_]*) return 1 ;;
  esac
  return 0
}

mask_pii__require_masker() {
  local name="$1"
  if ! mask_pii__is_valid_name "$name"; then
    printf 'mask-pii: invalid masker name: %s\n' "$name" >&2
    return 1
  fi
  local var
  var=$(mask_pii__config_var "$name" "mask_char")
  if [[ -z "${!var+x}" ]]; then
    printf 'mask-pii: unknown masker: %s\n' "$name" >&2
    return 1
  fi
  return 0
}
