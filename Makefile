.PHONY: test test-rust test-ruby publish-ruby publish-ruby-dry publish-rust publish-rust-dry publish-all publish-all-dry

GEM_VERSION := $(shell cd ruby && ruby -r./lib/mask_pii/version -e 'print MaskPII::VERSION')

test: test-rust test-ruby

# Run Rust tests

test-rust:
	cd rust && cargo test

# Run Ruby tests

test-ruby:
	cd ruby && ruby -Ilib -Itest test/test_mask_pii.rb

# Build and publish the Ruby gem

publish-ruby:
	cd ruby && gem build mask-pii.gemspec
	cd ruby && gem push mask-pii-$(GEM_VERSION).gem

publish-ruby-dry:
	cd ruby && gem build mask-pii.gemspec
	cd ruby && gem specification mask-pii-$(GEM_VERSION).gem > /dev/null
	cd ruby && gem install --local --no-document --ignore-dependencies mask-pii-$(GEM_VERSION).gem

.PHONY: publish-rust

# Publish the Rust crate

publish-rust:
	cd rust && cargo publish

publish-rust-dry:
	cd rust && cargo publish --dry-run

publish-all: publish-rust publish-ruby

publish-all-dry: publish-rust-dry publish-ruby-dry
