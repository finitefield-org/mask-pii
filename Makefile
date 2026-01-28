.PHONY: test test-rust test-ruby test-go test-python test-php test-swift test-julia test-elixir build build-julia build-elixir php-deps python-venv publish-go publish-go-dry publish-ruby publish-ruby-dry publish-rust publish-rust-dry publish-python publish-python-dry publish-php publish-php-dry publish-swift publish-swift-dry publish-julia publish-julia-dry publish-elixir publish-elixir-dry publish-all publish-all-dry

GEM_VERSION := $(shell cd ruby && ruby -r./lib/mask_pii/version -e 'print MaskPII::VERSION')
VERSION := $(shell cat VERSION)
PYTHON_VENV := python/.venv
PYTHON_BIN := $(abspath $(PYTHON_VENV)/bin/python)

test: test-rust test-ruby test-go test-python test-php test-swift test-julia test-elixir

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

test-python: python-venv
	cd python && $(PYTHON_BIN) -m unittest discover -s tests

# Run PHP tests

test-php: php-deps
	cd php && composer test

# Run Swift tests

test-swift:
	swift test

# Run Julia tests

test-julia:
	julia --project=julia -e 'using Pkg; Pkg.test()'

# Run Elixir tests

test-elixir:
	cd elixir && mix test

# Build Julia package (instantiate + precompile)

build: build-julia build-elixir

build-julia:
	julia --project=julia -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'

# Build Elixir package (fetch deps + compile)

build-elixir:
	cd elixir && mix deps.get
	cd elixir && mix compile

php-deps:
	cd php && composer install

python-venv:
	python3 -m venv $(PYTHON_VENV)
	$(PYTHON_BIN) -m pip install -U pip
	$(PYTHON_BIN) -m pip install build twine

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

publish-python: python-venv
	cd python && $(PYTHON_BIN) -m build
	cd python && $(PYTHON_BIN) -m twine upload dist/*

publish-python-dry: python-venv
	cd python && $(PYTHON_BIN) -m build
	cd python && $(PYTHON_BIN) -m twine check dist/*

publish-php:
	cd php && composer validate

publish-php-dry:
	cd php && composer validate --strict

publish-swift:
	@echo "SwiftPM does not require an explicit publish step."
	@echo "Use git tags and push to GitHub for SwiftPM distribution."

publish-swift-dry:
	@echo "SwiftPM publish dry run: no operation."

publish-julia:
	@echo "Julia packages are registered via the General Registry."
	@echo "Use Registrator.jl on the repository and tag the release."
	@echo "For this repository, comment: @JuliaRegistrator register subdir=julia"

publish-julia-dry:
	@echo "Julia publish dry run: no operation."
	@echo "For this repository, comment: @JuliaRegistrator register subdir=julia"

publish-elixir:
	cd elixir && mix local.hex --force
	cd elixir && mix deps.get
	cd elixir && mix hex.publish

publish-elixir-dry:
	cd elixir && mix local.hex --force
	cd elixir && mix deps.get
	cd elixir && mix hex.publish --dry-run

publish-all: publish-rust publish-ruby publish-go publish-python publish-php publish-swift publish-julia publish-elixir

publish-all-dry: publish-rust-dry publish-ruby-dry publish-go-dry publish-python-dry publish-php-dry publish-swift-dry publish-julia-dry publish-elixir-dry
