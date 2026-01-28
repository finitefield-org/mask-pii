# frozen_string_literal: true

require_relative "lib/mask_pii/version"

Gem::Specification.new do |spec|
  spec.name = "mask-pii"
  spec.version = MaskPII::VERSION
  spec.summary = "A lightweight library to mask PII (emails and phone numbers)."
  spec.description = "A lightweight, customizable Ruby library for masking PII such as email addresses and phone numbers."
  spec.authors = ["Finite Field, K.K."]
  spec.email = ["dev@finitefield.org"]
  spec.homepage = "https://finitefield.org/en/oss/mask-pii"
  spec.license = "MIT OR Apache-2.0"
  spec.required_ruby_version = ">= 2.7.0"

  spec.files = Dir.chdir(__dir__) { Dir["lib/**/*", "README.md", "LICENSE*", "test/**/*"] }
  spec.require_paths = ["lib"]

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "https://github.com/finitefield-org/mask-pii",
    "rubygems_mfa_required" => "true"
  }
end
