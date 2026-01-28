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
