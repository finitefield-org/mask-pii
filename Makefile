.PHONY: test test-awk test-rust test-ruby test-go test-python test-php test-swift test-julia test-elixir test-haskell test-hare test-tcl test-r test-d test-lua test-ocaml test-nim test-javascript test-bun test-common-lisp test-racket test-red test-perl test-groovy test-zsh test-pony build build-awk build-julia build-elixir build-haskell build-hare build-tcl build-r build-d build-lua build-ocaml build-nim build-javascript build-bun build-common-lisp build-racket build-red build-perl build-nushell build-groovy build-zsh build-pony php-deps python-venv publish-awk publish-awk-dry publish-go publish-go-dry publish-ruby publish-ruby-dry publish-rust publish-rust-dry publish-python publish-python-dry publish-php publish-php-dry publish-swift publish-swift-dry publish-julia publish-julia-dry publish-elixir publish-elixir-dry publish-haskell publish-haskell-dry publish-hare publish-hare-dry publish-tcl publish-tcl-dry publish-d publish-d-dry publish-r publish-r-dry publish-lua publish-lua-dry publish-nim publish-nim-dry publish-javascript publish-javascript-dry publish-bun publish-bun-dry publish-common-lisp publish-common-lisp-dry publish-racket publish-racket-dry publish-red publish-red-dry publish-perl publish-perl-dry publish-nushell publish-nushell-dry publish-groovy publish-zsh publish-zsh-dry publish-pony publish-pony-dry publish-all publish-all-dry test-crystal build-crystal publish-crystal publish-crystal-dry test-zig build-zig publish-zig publish-zig-dry test-nushell test-deno build-deno publish-deno publish-deno-dry test-fish build-fish publish-fish publish-fish-dry test-v build-v publish-v publish-v-dry test-powershell build-powershell publish-powershell publish-powershell-dry test-carbon build-carbon publish-carbon publish-carbon-dry test-odin build-odin publish-odin publish-odin-dry test-bash build-bash publish-bash publish-bash-dry

GEM_VERSION := $(shell cd ruby && ruby -r./lib/mask_pii/version -e 'print MaskPII::VERSION')
VERSION := $(shell cat VERSION)
PYTHON_VENV := python/.venv
PYTHON_BIN := $(abspath $(PYTHON_VENV)/bin/python)

test: test-carbon test-awk test-rust test-ruby test-go test-python test-php test-swift test-julia test-elixir test-haskell test-hare test-tcl test-d test-r test-lua test-ocaml test-nim test-javascript test-bun test-crystal test-common-lisp test-racket test-red test-perl test-groovy test-deno test-zig test-nushell test-zsh test-pony test-fish test-odin test-v test-powershell test-bash

# Run Carbon tests

test-carbon:
	@echo "Carbon tooling is experimental. Run the Carbon test harness in carbon/tests if available."

# Run AWK tests

test-awk:
	awk -f awk/src/mask_pii.awk -f awk/tests/test_mask_pii.awk

# Run Bash tests

test-bash:
	bash bash/tests/test_mask_pii.sh

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

# Run Haskell tests

test-haskell:
	cd haskell && cabal test

# Run Hare tests

test-hare:
	cd hare && hare test ./maskpii

# Run PowerShell tests

test-powershell:
	pwsh -NoProfile -Command "Invoke-Pester -Path ./powershell/tests -Output Detailed"

# Run Odin tests

test-odin:
	odin test odin/mask_pii -collection:mask_pii=./odin/mask_pii

# Run Tcl tests

test-tcl:
	tclsh tcl/tests/mask_pii.test

# Run V tests

test-v:
	cd v && v test .

# Run Fish tests

test-fish:
	cd fish && fish tests/run.fish

# Run Zsh tests

test-zsh:
	zsh zsh/tests/test_mask_pii.zsh

# Run Pony tests

test-pony:
	cd pony/test && ponyc . && ./test

# Run D tests

test-d:
	cd d && dub test

# Run Zig tests

test-zig:
	cd zig && zig build test

# Run Racket tests

test-racket:
	cd racket && raco test tests

# Run Red tests

test-red:
	red -r red/tests/test-mask-pii.red

# Run R tests

test-r:
	cd r && R CMD check --no-manual --no-build-vignettes .

# Run Lua tests

test-lua:
	cd lua && lua tests/test_mask_pii.lua

# Run OCaml tests

test-ocaml:
	cd ocaml && dune runtest

# Run Nim tests

test-nim:
	cd nim && nimble test

# Run JavaScript tests

test-javascript:
	cd javascript && npm test

# Run Bun tests

test-bun:
	cd bun && bun test

# Run Deno tests

test-deno:
	cd deno && deno test

# Run Perl tests

test-perl:
	cd perl && prove -l t

# Run Nushell tests

test-nushell:
	nu nushell/tests/test_mask_pii.nu

# Run Groovy tests

test-groovy:
	cd groovy && gradle test

# Run Crystal tests

test-crystal:
	cd crystal && crystal spec

# Run Common Lisp tests

test-common-lisp:
	cd common-lisp && sbcl --non-interactive --eval '(require :asdf)' --load mask-pii.asd --eval '(asdf:test-system :mask-pii)' --eval '(quit)'

# Build Julia package (instantiate + precompile)

build: build-carbon build-awk build-julia build-elixir build-haskell build-hare build-tcl build-d build-r build-lua build-ocaml build-nim build-javascript build-bun build-crystal build-common-lisp build-racket build-red build-zig build-nushell build-perl build-groovy build-deno build-fish build-zsh build-pony build-odin build-v build-powershell build-bash

# Build Carbon package

build-carbon:
	@echo "Carbon tooling is experimental. No build step is configured."

build-awk:
	@echo "AWK build: no compilation required."

build-bash:
	@echo "Bash build: no compilation required."

build-julia:
	julia --project=julia -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'

# Build Elixir package (fetch deps + compile)

build-elixir:
	cd elixir && mix deps.get
	cd elixir && mix compile

# Build Haskell package

build-haskell:
	cd haskell && cabal build

# Build Hare module

build-hare:
	cd hare && hare build ./maskpii

# Validate PowerShell module manifest

build-powershell:
	pwsh -NoProfile -Command "Test-ModuleManifest -Path ./powershell/MaskPII/MaskPII.psd1"

# Build Odin package (typecheck)

build-odin:
	odin check odin/mask_pii -collection:mask_pii=./odin/mask_pii

# Build Tcl package

build-tcl:
	@echo "Tcl package build: no build step required."

# Build V module (no standalone build step required)

build-v:
	@echo "V modules are built when imported; no standalone build step."

# Build Fish package (no build step required)

build-fish:
	@echo "Fish package build: no operation."

# Build D package

build-d:
	cd d && dub build

# Build Zig package

build-zig:
	cd zig && zig build

# Build Racket package

build-racket:
	@echo "Racket packages are built during installation via raco pkg."

# Build Red package

build-red:
	@echo "Red packages are distributed as source files. No build step required."

# Build R package

build-r:
	cd r && R CMD build .

# Build Lua rock

build-lua:
	cd lua && luarocks make mask-pii-$(VERSION)-1.rockspec

# Build OCaml package

build-ocaml:
	cd ocaml && dune build

# Build Nim package

build-nim:
	cd nim && nimble build

# Build JavaScript package

build-javascript:
	cd javascript && npm pack

# Build Bun package

build-bun:
	cd bun && bun run build

# Build Deno module (type check)

build-deno:
	cd deno && deno task check

# Build Perl package

build-perl:
	cd perl && perl Makefile.PL
	cd perl && make

# Build Nushell module (no-op)

build-nushell:
	@echo "Nushell modules do not require a build step."

# Build Groovy package

build-groovy:
	cd groovy && gradle build

# Build Crystal package

build-crystal:
	cd crystal && shards build

# Build Common Lisp system

build-common-lisp:
	cd common-lisp && sbcl --non-interactive --eval '(require :asdf)' --load mask-pii.asd --eval '(asdf:compile-system :mask-pii)' --eval '(quit)'

# Build Zsh plugin

build-zsh:
	@echo "Zsh plugins require no build step."

# Build Pony example

build-pony:
	cd example/pony && ponyc .

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

publish-awk:
	@echo "AWK publish: follow the awk-pkg registry instructions."

publish-awk-dry:
	@echo "AWK publish dry run: no operation."

publish-bash:
	@echo "Bash packages for bpkg are distributed via Git tags on GitHub."
	@echo "Push the repository and tag the release to publish."

publish-bash-dry:
	@echo "Bash publish dry run: no operation."

publish-go-dry:
	@echo "git tag -a go/v$(VERSION) -m \"go v$(VERSION)\""
	@echo "git push origin go/v$(VERSION)"

publish-zig:
	git tag -a zig/v$(VERSION) -m "zig v$(VERSION)"
	git push origin zig/v$(VERSION)

publish-zig-dry:
	@echo "git tag -a zig/v$(VERSION) -m \"zig v$(VERSION)\""
	@echo "git push origin zig/v$(VERSION)"

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

publish-haskell:
	cd haskell && cabal check
	cd haskell && cabal v2-sdist
	cd haskell && cabal upload --publish dist-newstyle/sdist/*.tar.gz

publish-haskell-dry:
	cd haskell && cabal check
	cd haskell && cabal v2-sdist
	@echo "Dry run: skipping cabal upload"

publish-hare:
	@echo "Hare packages are published via harepm."
	@echo "Use harepm tooling to publish the module once configured."

publish-hare-dry:
	@echo "Hare publish dry run: no operation."

publish-powershell:
	@echo "Publish to PowerShell Gallery:"
	@echo "pwsh -NoProfile -Command \"Publish-Module -Path ./powershell/MaskPII -NuGetApiKey <API_KEY>\""

publish-powershell-dry:
	pwsh -NoProfile -Command "Test-ModuleManifest -Path ./powershell/MaskPII/MaskPII.psd1"

publish-odin:
	@echo "Odin packages are distributed via the Odin package system."
	@echo "Tag the release and update documentation as needed."

publish-odin-dry:
	@echo "Odin publish dry run: no operation."

publish-carbon:
	@echo "Carbon publish is experimental. Tag and publish per the Carbon toolchain documentation."

publish-carbon-dry:
	@echo "Carbon publish dry run: no operation."

publish-tcl:
	@echo "Tcl package publish: use teacup or your registry workflow."

publish-tcl-dry:
	@echo "Tcl package publish dry run: no operation."

publish-v:
	@echo "V publish uses the V package manager."
	@echo "Run: v publish"

publish-v-dry:
	@echo "V publish dry run: no operation."

publish-d:
	cd d && dub publish

publish-d-dry:
	cd d && dub publish --dry-run

publish-racket:
	@echo "Racket packages are published to the Racket package catalog."
	@echo "Ensure the repository is tagged and submit via the catalog UI."

publish-racket-dry:
	@echo "Racket publish dry run: no operation."

publish-r:
	cd r && R CMD check --as-cran
	@echo "Submit the generated tar.gz to CRAN."

publish-r-dry:
	cd r && R CMD check --as-cran --no-manual

publish-lua:
	cd lua && luarocks upload mask-pii-$(VERSION)-1.rockspec

publish-lua-dry:
	cd lua && luarocks lint mask-pii-$(VERSION)-1.rockspec

publish-ocaml:
	@echo "OCaml packages are published via opam-repository."
	@echo "Prepare an opam package and submit a PR to opam-repository."

publish-ocaml-dry:
	@echo "OCaml publish dry run: no operation."

publish-nim:
	cd nim && nimble publish

publish-nim-dry:
	cd nim && nimble publish --dryrun

publish-javascript:
	cd javascript && npm publish

publish-javascript-dry:
	cd javascript && npm publish --dry-run

publish-bun:
	cd bun && bun publish

publish-bun-dry:
	cd bun && bun publish --dry-run

publish-deno:
	@echo "Deno modules are published via deno.land/x using git tags."
	@echo "Tag a release (e.g., v$(VERSION)) and push to GitHub."

publish-deno-dry:
	@echo "Deno publish dry run: no operation."
	@echo "deno.land/x releases are triggered by Git tags."

publish-nushell:
	@echo "Nushell modules are distributed via module registries or Git repositories."
	@echo "Tag the release and publish to the registry of your choice."

publish-nushell-dry:
	@echo "Nushell publish dry run: no operation."

publish-perl:
	cd perl && perl Makefile.PL
	cd perl && make dist
	cd perl && cpan-upload Mask-PII-$(VERSION).tar.gz

publish-perl-dry:
	cd perl && perl Makefile.PL
	cd perl && make dist
	cd perl && tar -tf Mask-PII-$(VERSION).tar.gz > /dev/null

publish-groovy:
	cd groovy && gradle publish

publish-groovy-dry:
	cd groovy && gradle publishToMavenLocal

publish-crystal:
	@echo "Crystal shards are distributed via Git tags."
	@echo "Tag the release and push to GitHub for shards to pick it up."

publish-crystal-dry:
	@echo "Crystal publish dry run: no operation."

publish-common-lisp:
	@echo "Common Lisp systems are distributed via Quicklisp."
	@echo "Submit the project to Quicklisp and tag the release."

publish-common-lisp-dry:
	@echo "Common Lisp publish dry run: no operation."
	@echo "Submit the project to Quicklisp and tag the release."

publish-fish:
	@echo "Fish plugins are distributed via Fisher by tagging releases."
	@echo "Tag the repository with v$(VERSION) and push to GitHub."

publish-fish-dry:
	@echo "Fish publish dry run: no operation."

publish-zsh:
	@echo "Zsh plugins are distributed via GitHub; no publish step required."

publish-zsh-dry:
	@echo "Zsh publish dry run: no operation."

publish-pony:
	@echo "Pony packages are distributed via source control and corral."
	@echo "Tag the release and push to GitHub."

publish-pony-dry:
	@echo "Pony publish dry run: no operation."

publish-red:
	@echo "Red packages are distributed via the Red package system."
	@echo "Tag the release and publish the red/ folder."

publish-red-dry:
	@echo "Red publish dry run: no operation."

publish-all: publish-carbon publish-awk publish-rust publish-ruby publish-go publish-python publish-php publish-swift publish-julia publish-elixir publish-haskell publish-hare publish-d publish-tcl publish-racket publish-r publish-lua publish-ocaml publish-nim publish-javascript publish-bun publish-perl publish-nushell publish-groovy publish-common-lisp publish-crystal publish-zig publish-red publish-deno publish-fish publish-zsh publish-pony publish-v publish-odin publish-powershell publish-bash

publish-all-dry: publish-carbon-dry publish-awk-dry publish-rust-dry publish-ruby-dry publish-go-dry publish-python-dry publish-php-dry publish-swift-dry publish-julia-dry publish-elixir-dry publish-haskell-dry publish-hare-dry publish-d-dry publish-tcl-dry publish-racket-dry publish-lua-dry publish-ocaml-dry publish-nim-dry publish-javascript-dry publish-bun-dry publish-perl-dry publish-nushell-dry publish-groovy-dry publish-common-lisp-dry publish-r-dry publish-crystal-dry publish-zig-dry publish-red-dry publish-deno-dry publish-fish-dry publish-zsh-dry publish-pony-dry publish-v-dry publish-odin-dry publish-powershell-dry publish-bash-dry
