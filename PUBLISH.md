# PUBLISH

This document summarizes how to register and publish each language package in this repository.

Common notes
- Version: use the same version as `VERSION` across languages.
- Validate and test before publish.
- Use the Makefile targets when possible.
- Tagging: create tags on the main branch after merging and pushing changes.

## Tagging (common)

Lightweight tags
```bash
git tag vX.Y.Z
git push origin vX.Y.Z
```

Annotated tags (recommended)
```bash
git tag -a vX.Y.Z -m "release vX.Y.Z"
git push origin vX.Y.Z
```

Go module tags
```bash
git tag -a go/vX.Y.Z -m "go vX.Y.Z"
git push origin go/vX.Y.Z
```

## Go (pkg.go.dev via Go modules)

Registration
- Push the repository to GitHub.
- Publish a Git tag for Go with the `go/vX.Y.Z` format.

Publish (tag)
```bash
make publish-go
```

Dry run
```bash
make publish-go-dry
```

## Rust (crates.io via Cargo)

Registration
- Create an account on crates.io and obtain an API token.
- Configure the token locally: `cargo login <token>`.

Publish
```bash
make publish-rust
```

Dry run
```bash
make publish-rust-dry
```

## Ruby (RubyGems)

Registration
- Create an account on RubyGems and obtain an API key.
- Configure credentials per RubyGems documentation.

Publish
```bash
make publish-ruby
```

Dry run
```bash
make publish-ruby-dry
```

## Python (PyPI via pip)

Registration
- Create an account on PyPI and obtain an API token.
- Configure token for `twine`.

Publish
```bash
make publish-python
```

Dry run
```bash
make publish-python-dry
```

## PHP (Packagist via Composer)

Registration (Packagist)
- Push the repository to GitHub.
- Submit the repository URL on Packagist.
- Ensure `composer.json` exists at the repository root.

Publish
- Create a Git tag that matches the version in `VERSION`.
- Packagist will pick up the new tag automatically when GitHub webhooks are enabled.

Validate before publish
```bash
make publish-php-dry
```

Optional validate (non-strict)
```bash
make publish-php
```

## Zsh (Antigen)

Registration
- Ensure the plugin file `zsh/mask-pii.plugin.zsh` is in the repository.
- Users can install via Antigen or local checkout.

Publish
- Tag the release with the version in `VERSION`.
- Push the tag to GitHub for plugin managers to pick it up.

Dry run
```bash
make publish-zsh-dry
```

## Julia (General Registry via Pkg)

Registration
- Create a Julia package repository and ensure `Project.toml` is present.
- Use Registrator.jl to open a registration pull request to the General registry.

## Elixir (Hex)

Registration
- Create an account on Hex.pm and generate an API key.
- Configure credentials: `mix hex.user auth`.

Publish
```bash
make publish-elixir
```

Dry run
```bash
make publish-elixir-dry
```

## PowerShell (PowerShell Gallery)

Registration
- Create an account on PowerShell Gallery and obtain an API key.

Publish
```bash
make publish-powershell
```

Dry run
```bash
make publish-powershell-dry
```

## OCaml (opam)

Registration
- Create an opam package and submit it to opam-repository.
- Ensure the package version matches `VERSION`.

Publish
```bash
make publish-ocaml
```

Dry run
```bash
make publish-ocaml-dry
```

## Crystal (shards)

Registration
- Push the repository to GitHub.
- Ensure `crystal/shard.yml` exists and version matches `VERSION`.

Publish
- Tag the release with the version in `VERSION`.
- Push the tag to GitHub for shards to pick it up.

Dry run
```bash
make publish-crystal-dry
```

## Common Lisp (Quicklisp)

Registration
- Ensure `common-lisp/mask-pii.asd` loads via ASDF.
- Submit the project to Quicklisp for inclusion.

Publish
- Tag the release with the version in `VERSION`.

Dry run
```bash
make publish-common-lisp-dry
```
  - For this repository, use the subdir comment: `@JuliaRegistrator register subdir=julia`

Publish
- Tag the release with the version in `VERSION`.
- Merge the registry PR once CI passes.

Dry run
```bash
make publish-julia-dry
```

## Racket (Racket package catalog)

Registration
- Submit the repository to the Racket package catalog.
- Ensure the package metadata in `racket/info.rkt` is up to date.

Publish
```bash
make publish-racket
```

Dry run
```bash
make publish-racket-dry
```

## Red (Red package system)

Registration
- Red packages are distributed as source files. Ensure the `red/` folder is included in the repository.

Publish
```bash
make publish-red
```

Dry run
```bash
make publish-red-dry
```
