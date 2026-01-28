.PHONY: test test-rust test-ruby test-go test-python publish-go publish-go-dry publish-ruby publish-ruby-dry publish-rust publish-rust-dry publish-python publish-python-dry publish-all publish-all-dry

GEM_VERSION := $(shell cd ruby && ruby -r./lib/mask_pii/version -e 'print MaskPII::VERSION')
VERSION := $(shell cat VERSION)

test: test-rust test-ruby test-go test-python

# Run Rust tests

test-rust:
	cd rust && cargo test

# Run Ruby tests

test-ruby:
	cd ruby && ruby -Ilib -Itest test/test_mask_pii.rb

# Run Go tests

test-go:
	cd go && go test ./...

# Run Python tests

test-python:
	cd python && python3 -m unittest discover -s tests

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

publish-go:
	git tag -a go/v$(VERSION) -m "go v$(VERSION)"
	git push origin go/v$(VERSION)

publish-go-dry:
	@echo "git tag -a go/v$(VERSION) -m \"go v$(VERSION)\""
	@echo "git push origin go/v$(VERSION)"

publish-python:
	cd python && python3 -m build
	cd python && python3 -m twine upload dist/*

publish-python-dry:
	cd python && python3 -m build
	cd python && python3 -m twine check dist/*

publish-all: publish-rust publish-ruby publish-go publish-python

publish-all-dry: publish-rust-dry publish-ruby-dry publish-go-dry publish-python-dry
