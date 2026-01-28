# Package metadata

name        = "mask_pii"
version     = "0.2.0"
author      = "Finite Field, K.K."
description = "A lightweight library to mask PII (Personally Identifiable Information) like emails and phone numbers."
license     = "MIT"

srcDir = "src"

# Package URLs
homepage = "https://finitefield.org/en/oss/mask-pii"
repository = "https://github.com/finitefield-org/mask-pii"
issues = "https://github.com/finitefield-org/mask-pii/issues"

# Search tags
# nimble uses `tags` for discoverability
tags = @["pii", "masking", "email", "phone", "privacy"]

requires "nim >= 1.6.0"

# Tasks

task test, "Run the test suite":
  exec "nim c -r --hints:off -d:release --path:src tests/test_mask_pii.nim"

task build, "Build the library":
  exec "nim c --app:lib --path:src src/mask_pii.nim"
