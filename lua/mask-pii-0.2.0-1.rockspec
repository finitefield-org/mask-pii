package = "mask-pii"
version = "0.2.0-1"

source = {
  url = "https://github.com/finitefield-org/mask-pii",
  tag = "v0.2.0",
}

description = {
  summary = "Mask email addresses and phone numbers in text.",
  detailed = [[
mask-pii is a lightweight, customizable library for masking Personally Identifiable Information (PII)
such as email addresses and phone numbers.
  ]],
  homepage = "https://finitefield.org/en/oss/mask-pii",
  license = "MIT",
  issues = "https://github.com/finitefield-org/mask-pii/issues",
  labels = { "pii", "masking", "email", "phone", "privacy" },
}

dependencies = {
  "lua >= 5.1",
}

build = {
  type = "builtin",
  modules = {
    ["mask_pii"] = "src/mask_pii/init.lua",
  },
}
