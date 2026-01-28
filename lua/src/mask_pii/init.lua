---mask_pii provides masking utilities for common PII patterns.
local function mask_emails_in_text(input_text, mask_char) end
local function mask_phones_in_text(input_text, mask_char) end

---Masker builds masking configuration for emails and phone numbers.
local Masker = {}
Masker.__index = Masker

---Create a new masker with all masks disabled by default.
---@return table
function Masker.new()
  local self = setmetatable({}, Masker)
  self._mask_email = false
  self._mask_phone = false
  self._mask_char = "*"
  return self
end

---Enable email address masking.
---@return table
function Masker:mask_emails()
  self._mask_email = true
  return self
end

---Enable phone number masking.
---@return table
function Masker:mask_phones()
  self._mask_phone = true
  return self
end

---Set the character used for masking.
---@param char any
---@return table
function Masker:with_mask_char(char)
  if char == nil then
    self._mask_char = "*"
    return self
  end

  local value = tostring(char)
  if value == "" then
    self._mask_char = "*"
  else
    self._mask_char = value:sub(1, 1)
  end
  return self
end

---Process input text and mask enabled PII patterns.
---@param input_text string
---@return string
function Masker:process(input_text)
  if not self._mask_email and not self._mask_phone then
    return input_text
  end

  local mask_char = self._mask_char
  if mask_char == nil or mask_char == "" then
    mask_char = "*"
  end

  local result = input_text
  if self._mask_email then
    result = mask_emails_in_text(result, mask_char)
  end
  if self._mask_phone then
    result = mask_phones_in_text(result, mask_char)
  end
  return result
end

local function is_digit(ch)
  return ch >= "0" and ch <= "9"
end

local function is_alpha(ch)
  return (ch >= "a" and ch <= "z") or (ch >= "A" and ch <= "Z")
end

local function is_alnum(ch)
  return is_alpha(ch) or is_digit(ch)
end

local function is_local_char(ch)
  return is_alpha(ch) or is_digit(ch) or ch == "." or ch == "_" or ch == "%" or ch == "+" or ch == "-"
end

local function is_domain_char(ch)
  return is_alpha(ch) or is_digit(ch) or ch == "-" or ch == "."
end

local function is_valid_domain(domain)
  if domain == "" then
    return false
  end
  if domain:sub(1, 1) == "." or domain:sub(-1, -1) == "." then
    return false
  end

  local parts = {}
  for part in string.gmatch(domain, "[^.]+") do
    table.insert(parts, part)
  end
  if #parts < 2 then
    return false
  end

  for _, part in ipairs(parts) do
    if part == "" then
      return false
    end
    if part:sub(1, 1) == "-" or part:sub(-1, -1) == "-" then
      return false
    end
    for i = 1, #part do
      local ch = part:sub(i, i)
      if not (is_alnum(ch) or ch == "-") then
        return false
      end
    end
  end

  local tld = parts[#parts]
  if #tld < 2 then
    return false
  end
  for i = 1, #tld do
    local ch = tld:sub(i, i)
    if not is_alpha(ch) then
      return false
    end
  end

  return true
end

local function mask_local(local_part, mask_char)
  if #local_part > 1 then
    return local_part:sub(1, 1) .. string.rep(mask_char, #local_part - 1)
  end
  return mask_char
end

local function mask_phone_candidate(candidate, mask_char)
  local digit_count = 0
  for i = 1, #candidate do
    if is_digit(candidate:sub(i, i)) then
      digit_count = digit_count + 1
    end
  end

  local current_index = 0
  local result_chars = {}
  for i = 1, #candidate do
    local ch = candidate:sub(i, i)
    if is_digit(ch) then
      current_index = current_index + 1
      if digit_count > 4 and current_index <= digit_count - 4 then
        table.insert(result_chars, mask_char)
      else
        table.insert(result_chars, ch)
      end
    else
      table.insert(result_chars, ch)
    end
  end

  return table.concat(result_chars)
end

local function is_phone_start(ch)
  return is_digit(ch) or ch == "+" or ch == "("
end

local function is_phone_char(ch)
  return is_digit(ch) or ch == " " or ch == "-" or ch == "(" or ch == ")" or ch == "+"
end

local function mask_emails_in_text(input_text, mask_char)
  local length = #input_text
  local output = {}
  local last = 1
  local i = 1

  while i <= length do
    if input_text:sub(i, i) == "@" then
      local local_start = i
      while local_start > 1 and is_local_char(input_text:sub(local_start - 1, local_start - 1)) do
        local_start = local_start - 1
      end
      local local_end = i - 1

      local domain_start = i + 1
      local domain_end = domain_start
      while domain_end <= length and is_domain_char(input_text:sub(domain_end, domain_end)) do
        domain_end = domain_end + 1
      end

      if local_start <= local_end and domain_start <= domain_end - 1 then
        local candidate_end = domain_end - 1
        local matched_end = nil
        while candidate_end >= domain_start do
          local domain = input_text:sub(domain_start, candidate_end)
          if is_valid_domain(domain) then
            matched_end = candidate_end
            break
          end
          candidate_end = candidate_end - 1
        end

        if matched_end ~= nil then
          local local_part = input_text:sub(local_start, local_end)
          table.insert(output, input_text:sub(last, local_start - 1))
          table.insert(output, mask_local(local_part, mask_char))
          table.insert(output, "@")
          table.insert(output, input_text:sub(domain_start, matched_end))
          last = matched_end + 1
          i = matched_end + 1
        else
          i = i + 1
        end
      else
        i = i + 1
      end
    else
      i = i + 1
    end
  end

  table.insert(output, input_text:sub(last))
  return table.concat(output)
end

local function mask_phones_in_text(input_text, mask_char)
  local length = #input_text
  local output = {}
  local last = 1
  local i = 1

  while i <= length do
    if is_phone_start(input_text:sub(i, i)) then
      local end_pos = i
      while end_pos <= length and is_phone_char(input_text:sub(end_pos, end_pos)) do
        end_pos = end_pos + 1
      end

      local digit_count = 0
      local last_digit_index = nil
      for idx = i, end_pos - 1 do
        if is_digit(input_text:sub(idx, idx)) then
          digit_count = digit_count + 1
          last_digit_index = idx
        end
      end

      if last_digit_index ~= nil then
        local candidate_end = last_digit_index
        if digit_count >= 5 then
          local candidate = input_text:sub(i, candidate_end)
          table.insert(output, input_text:sub(last, i - 1))
          table.insert(output, mask_phone_candidate(candidate, mask_char))
          last = candidate_end + 1
          i = candidate_end + 1
        else
          i = end_pos
        end
      else
        i = end_pos
      end
    else
      i = i + 1
    end
  end

  table.insert(output, input_text:sub(last))
  return table.concat(output)
end

return {
  Masker = Masker,
  _VERSION = "0.2.0",
}
