# mask-pii package registry rollout

Last audited: 2026-07-17 (JST)

This document is the implementation contract and progress tracker for publishing every language implementation in this repository to every applicable official or ecosystem-standard public package registry or catalog.

## Goal

- Make every implementation discoverable through the package distribution mechanism developers normally use for that language.
- Keep release versions aligned with the repository-level `VERSION` unless a registry already contains a historical exception.
- Record authentication, validation, publication, verification, and follow-up work separately so that a successful upload is not mistaken for a complete release.
- Never overwrite or move a version that has already been observed by a public registry, proxy, or user.

## Scope and definitions

The repository currently contains 36 language implementations. A target is included when it is one of the following:

1. An official language package registry or catalog.
2. The ecosystem's de facto standard public registry when the language itself does not operate one.
3. An official project directory, such as the Hare Project Library, when no package registry exists.

Community package managers that install directly from Git but have no authoritative catalog are documented as distribution channels, not as registry publication targets.

### Explicit non-goals

- This document does not authorize publishing, creating accounts, reserving namespaces, or changing external package ownership without an explicit execution request.
- This document does not require all languages to use identical package names; registry namespace collisions may require scoped or suffixed names.
- This document does not treat a GitHub tag alone as a registry listing when an applicable public registry or catalog exists.
- This document does not use `make publish-all`; each irreversible publication must be executed and verified independently.

## Status model

| Status | Meaning |
| --- | --- |
| `DONE` | Package/catalog entry is public, installable, owned by Finite Field, and its public page passed the quality checks. |
| `PARTIAL` | Public entry exists, but documentation, license, version, ownership, or install verification is incomplete. |
| `READY` | Manifest and package are ready; only credentials or the irreversible publish/submit action remains. |
| `BLOCKED` | Metadata, namespace, monorepo layout, registry configuration, or policy work is required before publication. |
| `N/A` | No applicable official or ecosystem-standard public registry/catalog exists. |

For progress updates, change both the status in the master table and the task checkboxes in the corresponding runbook. Add the verification date and public URL when a target reaches `DONE`.

## Current summary

| Metric | Count |
| --- | ---: |
| Language implementations | 36 |
| Registry/catalog targets | 25 |
| Public entries created | 7 |
| Fully complete (`DONE`) | 5 |
| Public but requiring follow-up (`PARTIAL`) | 2 |
| Registry/catalog targets still unpublished | 18 |
| No applicable registry/catalog (`N/A`) | 11 |

Current public entries:

- `DONE`: Rust, Ruby, Python, PHP, Elixir.
- `PARTIAL`: Go (`v0.2.0` is public but the tagged artifact has no detected license, so documentation is hidden); Julia (General entry exists at `0.1.0`, behind repository version `0.2.0`).

## Master progress tracker

| Language | Required target | Package identifier | Status | Published version | Owner | Next action / evidence |
| --- | --- | --- | --- | --- | --- | --- |
| AWK | None; Git source distribution | `awk/` | `N/A` | — | — | Keep Git install instructions; `awk-pkg` is optional community distribution. |
| Bash | None; Git/bpkg source distribution | `finitefield-org/mask-pii/bash` | `N/A` | — | — | Keep tagged Git installation instructions. |
| Bun | npm | Recommended: `@finitefield-org/mask-pii-bun` | `BLOCKED` | — | Unassigned | Reserve scope/name and change manifest; current unscoped name collides and duplicates JavaScript. |
| Carbon | None; packaging remains experimental | `carbon/` | `N/A` | — | — | Re-audit when Carbon defines a stable public package registry. |
| Common Lisp | Quicklisp | System `mask-pii` | `BLOCKED` | — | Unassigned | Validate monorepo discovery, then submit project to Quicklisp. |
| Crystal | Official Shards workflow plus a standard shard index | Shard `mask_pii` | `BLOCKED` | — | Unassigned | Validate monorepo/subdirectory consumption; submit to a shard index only after Git install works. |
| D | DUB package registry | `mask-pii` | `BLOCKED` | — | Unassigned | Resolve DUB's repository-root requirement for the current `d/` subdirectory; do not use the stale `dub publish` Makefile target. |
| Deno | JSR | Recommended: `@finitefield/mask-pii` | `BLOCKED` | — | Unassigned | Reserve JSR scope and replace unscoped `deno.json` name. |
| Elixir | Hex | `mask_pii` | `DONE` | `0.2.0` | Finite Field | Verified 2026-07-17: https://hex.pm/packages/mask_pii |
| Fish | None; Fisher installs from Git | `finitefield-org/mask-pii` | `N/A` | — | — | Keep tagged Git/Fisher instructions. |
| Go | Go Module Proxy and pkg.go.dev | `github.com/finitefield-org/mask-pii/go` | `PARTIAL` | `0.2.0` | Finite Field | Verified 2026-07-17: https://pkg.go.dev/github.com/finitefield-org/mask-pii/go; fix license/docs in the next coordinated release. |
| Groovy | Maven Central | `org.finitefield:mask-pii` | `BLOCKED` | — | Unassigned | Configure Central namespace, signing, credentials, and a remote publishing repository. |
| Hare | Official Hare Project Library | `maskpii` | `READY` | Git | Unassigned | Submit a patch to the hare-dev mailing list after validating HAREPATH instructions. |
| Haskell | Hackage | `mask-pii` | `READY` | — | Unassigned | Validate source distribution and publish with a Hackage account. |
| JavaScript | npm | Recommended: `@finitefield-org/mask-pii` | `BLOCKED` | — | Unassigned | The unscoped `mask-pii` name belongs to another publisher; reserve scope and update manifest/import docs. |
| Julia | General Registry | `MaskPII` | `PARTIAL` | `0.1.0` | Finite Field | Verified 2026-07-17: https://juliahub.com/ui/Packages/General/MaskPII; bring to the coordinated version in the next release. |
| Lua | LuaRocks | `mask-pii` | `BLOCKED` | — | Unassigned | Fix/verify the monorepo source layout in the rockspec before upload. |
| Nim | Nim package list/Nimble | `mask_pii` | `BLOCKED` | — | Unassigned | Confirm and encode the `nim/` subdirectory in the package-list submission. |
| Nushell | None; module distribution is Git/file based | `nushell/` | `N/A` | — | — | Keep Git installation instructions; re-audit if an official registry is introduced. |
| OCaml | opam repository | `mask-pii` | `BLOCKED` | — | Unassigned | Create the opam-repository version directory with immutable URL and checksum. |
| Odin | None for third-party packages | `odin/mask_pii` | `N/A` | — | — | Keep collection-path installation instructions. |
| Perl | CPAN/PAUSE | Distribution `Mask-PII` / module `Mask::PII` | `READY` | — | Unassigned | Obtain PAUSE namespace permission and upload the validated distribution. |
| PHP | Packagist | `finitefield-org/mask-pii` | `DONE` | `0.2.0` | Finite Field | Verified 2026-07-17: https://packagist.org/packages/finitefield-org/mask-pii |
| Pony | None; Corral resolves source-control dependencies | `pony/mask_pii` | `N/A` | — | — | Keep tagged Git/Corral instructions. |
| PowerShell | PowerShell Gallery | `MaskPII` | `READY` | — | Unassigned | Validate the manifest, publish with an API key, and install-test in a clean scope. |
| Python | PyPI | `mask-pii` | `DONE` | `0.2.0` | Finite Field | Verified 2026-07-17: https://pypi.org/project/mask-pii/ |
| R | CRAN | `maskpii` | `BLOCKED` | — | Unassigned | Resolve all `R CMD check --as-cran` errors/notes and confirm CRAN license format. |
| Racket | Racket Package Catalog | `mask-pii` | `BLOCKED` | — | Unassigned | Add package-local license and validate a catalog source that targets the `racket/` subdirectory. |
| Red | None; source-file distribution | `red/mask-pii.red` | `N/A` | — | — | Keep Git/file installation instructions. |
| Ruby | RubyGems | `mask-pii` | `DONE` | `0.2.0` | Finite Field | Verified 2026-07-17: https://rubygems.org/gems/mask-pii |
| Rust | crates.io | `mask-pii` | `DONE` | `0.2.0` | Finite Field | Verified 2026-07-17: https://crates.io/crates/mask-pii |
| Swift | Swift Package Index; SwiftPM distribution remains Git based | Repository URL | `READY` | Git tag `v0.2.0` | Unassigned | Submit https://github.com/finitefield-org/mask-pii to Swift Package Index and confirm build compatibility. |
| Tcl | None authoritative; Teapot/ActiveState is optional | Package `mask_pii` | `N/A` | — | — | Keep `pkgIndex.tcl`/Git instructions; treat third-party catalogs as optional. |
| V | VPM | A VPM-compatible owner/package name | `BLOCKED` | — | Unassigned | Determine whether VPM supports a monorepo subdirectory; otherwise split or mirror the V package. |
| Zig | None; official package manager resolves URLs/hashes | `zig/` | `N/A` | — | — | Document URL/hash dependency; do not invent a registry submission. |
| Zsh | None; Antigen and similar managers install from Git | `finitefield-org/mask-pii` | `N/A` | — | — | Keep tagged Git instructions. |

## Global release rules

### Version policy

1. The desired current release is the value in `VERSION` (`0.2.0` at the last audit).
2. Do not republish or replace an existing name/version pair.
3. Do not move `v0.2.0`, `go/v0.2.0`, or any version already fetched by a registry/proxy.
4. Initial registry entries should use existing `0.2.0` artifacts when they pass that registry's validation without source changes.
5. Changes required to make a package valid must be accumulated for a coordinated `0.2.1` release across language manifests. Historical exceptions, currently Julia `0.1.0`, must be recorded rather than hidden.

### Credential and permission policy

- Never place tokens, API keys, passwords, OTPs, signing keys, or generated credential files in this repository or command history.
- Prefer OIDC/trusted publishing when the registry officially supports it; otherwise use a narrowly scoped token stored in the operator's credential store or CI secrets.
- Enable MFA for every publisher account that supports it.
- Record package ownership by account/organization name, not by secret or email verification data.
- A human operator must confirm the final irreversible publish/upload/submit action.

### Mandatory preflight for every target

- [ ] Working tree and target commit are identified; unrelated changes are excluded.
- [ ] Package version matches the intended release or an exception is documented.
- [ ] Package-local README, redistributable license, repository URL, issue URL, and the applicable finitefield.org language page (or canonical project page) are present in the published artifact.
- [ ] Unit tests pass for the language implementation.
- [ ] Registry-specific dry-run/package inspection passes.
- [ ] Published file list contains source and documentation but no secrets, caches, generated credentials, unrelated language directories, or oversized artifacts.
- [ ] Package name and namespace ownership are confirmed before editing public metadata.
- [ ] Installation is tested in a clean temporary project using the exact public package identifier.
- [ ] Public registry page shows the expected version, license, repository, and finitefield.org link where those metadata fields are supported; otherwise the published README/API documentation is checked.
- [ ] Status, public URL, verification date, and remaining follow-up are updated in this document.

## Execution order

Publish one target at a time in this order. Do not start the next irreversible publication until the previous target has an install verification result.

1. `READY` targets requiring no source change: Haskell, Hare catalog, Perl, PowerShell, Swift Package Index.
2. `BLOCKED` targets requiring metadata/layout work: D, Deno, JavaScript, Bun, Groovy, Lua, Nim, OCaml, R, Racket, V, Common Lisp, Crystal.
3. Coordinated `0.2.1` quality release: Go license/documentation, Julia version alignment, and every metadata change accumulated during steps 1–2.

## Registered package maintenance runbooks

### Go — Go Module Proxy and pkg.go.dev (`PARTIAL`)

Official references: [Publishing a module](https://go.dev/doc/modules/publishing), [pkg.go.dev package addition](https://pkg.go.dev/about).

Current evidence:

- Module path: `github.com/finitefield-org/mask-pii/go` in `go/go.mod`.
- Required monorepo tag form: `go/vX.Y.Z`.
- `go/v0.2.0` is public and resolves through the Go Module Proxy.
- pkg.go.dev reports `License: None detected`; documentation is hidden because the tag does not contain the current `go/LICENSE.md`.

Completed:

- [x] Push `go/v0.2.0` to GitHub.
- [x] Request the module from `proxy.golang.org`.
- [x] Confirm `v0.2.0` on pkg.go.dev.

Next coordinated release:

- [ ] Ensure `go/LICENSE.md` is present in the tagged module tree.
- [ ] Add `https://finitefield.org/oss/mask-pii/go/` to the package comment and Go README.
- [ ] Run `cd go && go mod tidy && go test ./...`.
- [ ] Create and push `go/v0.2.1` only after the repository-wide `0.2.1` release commit is approved.
- [ ] Run `GOPROXY=https://proxy.golang.org go list -m github.com/finitefield-org/mask-pii/go@v0.2.1`.
- [ ] Confirm pkg.go.dev detects the license and renders documentation.

Never delete or retag `go/v0.2.0`.

### Rust — crates.io (`DONE`)

Official reference: [Cargo publishing](https://doc.rust-lang.org/cargo/reference/publishing.html).

- [x] Package `mask-pii` version `0.2.0` is public.
- [x] Public page links to the Finite Field repository/site and shows a redistributable license.
- [ ] For the next release, run `make publish-rust-dry`, inspect `cargo package --list`, then run `make publish-rust` with the authorized owner account.
- [ ] After publication, test `cargo add mask-pii` in a clean project.

### Ruby — RubyGems (`DONE`)

Official reference: [Publishing a gem](https://guides.rubygems.org/publishing/).

- [x] Gem `mask-pii` version `0.2.0` is public and owned by Finite Field.
- [ ] For the next release, run `make publish-ruby-dry`, inspect the gem specification/file list, then run `make publish-ruby`.
- [ ] Test `gem install mask-pii -v X.Y.Z` without a local gem file.

### Python — PyPI (`DONE`)

Official reference: [Packaging Python projects](https://packaging.python.org/en/latest/tutorials/packaging-projects/).

- [x] Distribution `mask-pii` version `0.2.0` is public.
- [ ] Prefer PyPI Trusted Publishing for future automation; manual Twine upload remains an approved fallback.
- [ ] Run `make publish-python-dry`, inspect both sdist and wheel, then run `make publish-python`.
- [ ] Test `python -m pip install --no-cache-dir mask-pii==X.Y.Z` in a fresh virtual environment.

### PHP — Packagist (`DONE`)

Official reference: [Packagist package submission and updates](https://packagist.org/about).

- [x] Package `finitefield-org/mask-pii` version `0.2.0` is public.
- [x] GitHub repository integration is present.
- [ ] For the next release, run `make publish-php-dry`, push the coordinated Git tag, and confirm Packagist ingests it.
- [ ] Test `composer require finitefield-org/mask-pii:X.Y.Z` in a clean project.

### Elixir — Hex (`DONE`)

Official reference: [Mix Hex publish task](https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html).

- [x] Package `mask_pii` version `0.2.0` is public.
- [ ] Run `make publish-elixir-dry` before every future release.
- [ ] Publish with `make publish-elixir` only from the intended clean commit.
- [ ] Test `mix hex.info mask_pii X.Y.Z` and a clean Mix dependency install.

### Julia — General Registry (`PARTIAL`)

Official reference: [Registrator.jl](https://github.com/JuliaRegistries/Registrator.jl).

Current evidence:

- Package `MaskPII`, UUID `e51ab4cc-94ad-4aad-a579-d543f796cd4d`, is in General at `0.1.0`.
- `julia/Project.toml` is still `0.1.0` while repository `VERSION` is `0.2.0`; do not claim Julia `0.2.0` is published.

Tasks:

- [x] Initial General registration completed.
- [ ] Decide the coordinated next version and update `julia/Project.toml` with the same release version.
- [ ] Run `make publish-julia-dry` and `julia --project=julia -e 'using Pkg; Pkg.test()'`.
- [ ] Comment `@JuliaRegistrator register subdir=julia` on the approved release commit.
- [ ] Merge/observe the General registry PR and verify `Pkg.add("MaskPII")` in a clean depot.

## Unpublished registry/catalog runbooks

### D — DUB (`BLOCKED`)

Target: https://code.dlang.org/packages/mask-pii

Official reference: [Publishing packages](https://dub.pm/dub-guide/publishing/).

Blocker: DUB registration is performed on the DUB website and the registry monitors repository tags; it is not performed by a `dub publish` CLI command. DUB's documented workflow expects the package recipe and contents at the registered repository root, while this repository stores `dub.json` and the D source under `d/`. The current Makefile's `publish-d` and `publish-d-dry` targets therefore must not be used.

- [ ] Confirm DUB account ownership and availability of the `mask-pii` package name.
- [ ] Ask DUB maintainers or validate in a non-publishing workflow whether a registry entry can target a repository subdirectory.
- [ ] If subdirectories are unsupported, obtain approval for a D-only split/mirror repository or an equivalent layout change; preserve the canonical source and release provenance.
- [ ] Run `make test-d`, `cd d && dub build`, and inspect `d/dub.json`, source inclusion, README, and `d/LICENSE.md`.
- [ ] Register the exact approved repository URL through the DUB website.
- [ ] Create an immutable SemVer tag in that registered repository only after the layout and artifact have passed review; allow DUB's tag monitor to index it.
- [ ] Verify `dub add mask-pii` and `dub test` in a clean D project.
- [ ] Mark `DONE` only after the DUB page shows repository, license, the applicable finitefield.org URL, and the intended version.

### Deno — JSR (`BLOCKED`)

Official reference: [Publishing packages to JSR](https://jsr.io/docs/publishing-packages).

Blocker: JSR requires a scoped name, while `deno/deno.json` currently declares unscoped `mask-pii`.

- [ ] Reserve an organization-owned JSR scope; recommended first choice is `@finitefield`.
- [ ] Set the package name to the approved scoped identifier, recommended `@finitefield/mask-pii`.
- [ ] Add an explicit publish include list containing `mod.ts`, source, README, and license.
- [ ] Update Deno installation/import documentation to the final JSR identifier.
- [ ] Run `deno test`, `deno check mod.ts`, and `deno publish --dry-run` from `deno/`.
- [ ] Link the JSR package to `finitefield-org/mask-pii` and prefer GitHub OIDC for publication.
- [ ] Publish, then verify `deno add jsr:@finitefield/mask-pii@X.Y.Z` in a clean project.

Do not follow the obsolete Makefile text that refers to new `deno.land/x` publication; new publication work targets JSR.

### JavaScript — npm (`BLOCKED`)

Official reference: [Publishing scoped public packages](https://docs.npmjs.com/creating-and-publishing-scoped-public-packages/).

Blocker: the unscoped npm name `mask-pii` is owned by another publisher.

- [ ] Confirm an npm organization scope controlled by Finite Field; recommended package name is `@finitefield-org/mask-pii`.
- [ ] Update `javascript/package.json` name, repository directory metadata, README install/import examples, and package tests.
- [ ] Add `publishConfig.access = "public"` and an explicit `files` list if missing.
- [ ] Run `npm test` and `npm publish --dry-run` from `javascript/`; inspect the tarball file list.
- [ ] Publish with `npm publish --access public` using MFA/trusted publishing.
- [ ] Verify install and import from a clean Node project.

### Bun — npm (`BLOCKED`)

Bun consumes and publishes npm packages; the JavaScript and Bun implementations cannot both own the same npm name.

- [ ] Approve a distinct scoped name, recommended `@finitefield-org/mask-pii-bun`.
- [ ] Update `bun/package.json`, README, build output, and import examples.
- [ ] Run `bun test`, `bun run build`, and `bun publish --dry-run`.
- [ ] Inspect that `dist/`, type declarations, README, and license are included.
- [ ] Publish and verify installation with Bun in a clean project.

### Groovy — Maven Central (`BLOCKED`)

Official reference: [Maven Central Publisher Portal guide](https://central.sonatype.org/publish/publish-portal-guide/).

Blocker: `groovy/build.gradle` defines a Maven publication but no Central remote repository, credentials, namespace verification, or signing configuration.

- [ ] Verify ownership of the `org.finitefield` namespace in Maven Central.
- [ ] Confirm the final coordinate `org.finitefield:mask-pii:X.Y.Z`.
- [ ] Add Central publishing and signing configuration without committing secrets.
- [ ] Ensure POM contains name, description, URL, license, developers, and SCM metadata.
- [ ] Run tests, generate sources/Groovydoc jars, and publish to Maven Local for inspection.
- [ ] Upload and validate the deployment in the Central Portal, then explicitly publish it.
- [ ] Verify dependency resolution from Maven Central in a clean Gradle project.

### Haskell — Hackage (`READY`)

Official entry point: https://hackage.haskell.org/upload

- [ ] Confirm Hackage account and package-name availability/maintainership.
- [ ] Run `make test-haskell` and `make publish-haskell-dry`.
- [ ] Inspect the generated source distribution and confirm README/license/changelog inclusion.
- [ ] Upload a package candidate first when available; install-test the candidate.
- [ ] Run the final Hackage upload with human confirmation.
- [ ] Verify `cabal update && cabal install mask-pii-X.Y.Z` in a clean environment.

### Hare — official Project Library (`READY`)

Official reference: [Hare Project Library](https://harelang.org/project-library/).

Hare has no official package manager. Completion means inclusion in the official project directory plus working Git/HAREPATH instructions.

- [ ] Run Hare tests and validate the documented `HAREPATH` layout from a clean clone.
- [ ] Prepare a small patch adding mask-pii to the appropriate Project Library category.
- [ ] Send the patch to the hare-dev mailing list as requested by the official directory.
- [ ] Record the accepted directory URL and verification date.

Do not run the current `publish-hare` Makefile target as if `harepm` were an official registry; its text must be corrected in implementation work.

### Lua — LuaRocks (`BLOCKED`)

Reference: https://github.com/luarocks/luarocks/wiki/Uploading-rocks

Blocker: `lua/mask-pii-0.2.0-1.rockspec` points at the repository root but its module paths are relative to `lua/`; a downloaded source archive must be proven to build before upload.

- [ ] Make the rockspec source/archive and source directory resolve the monorepo layout deterministically.
- [ ] Ensure the immutable source tag/archive contains `lua/LICENSE.md` and README.
- [ ] Run `make test-lua` and `make publish-lua-dry`.
- [ ] Build/install the rock locally from the exact rockspec in a clean LuaRocks tree.
- [ ] Authenticate and run `make publish-lua` only after the local install passes.
- [ ] Verify `luarocks install mask-pii 0.2.0-1` from the public server.

### Nim — Nim package list/Nimble (`BLOCKED`)

Reference: https://github.com/nim-lang/packages#submitting-a-package

Blocker: the Nimble manifest is in `nim/`; the public package-list entry must explicitly support that monorepo subdirectory or the package must be split/mirrored.

- [ ] Confirm the package-list schema and approved subdirectory mechanism.
- [ ] Validate `nim/mask_pii.nimble`, package name, tags, license, and repository metadata.
- [ ] Run `make test-nim` and `make publish-nim-dry`.
- [ ] Submit the package-list PR or `nimble publish` workflow dictated by current Nimble documentation.
- [ ] Verify `nimble install mask_pii` in a clean Nimble directory.

### OCaml — opam repository (`BLOCKED`)

Official reference: [Packaging with opam](https://opam.ocaml.org/doc/Packaging.html).

- [ ] Create the registry file `packages/mask-pii/mask-pii.X.Y.Z/opam` in a fork of `ocaml/opam-repository`.
- [ ] Use an immutable release archive URL and record its SHA256/SHA512 checksum.
- [ ] Ensure build/test dependencies and constraints match `ocaml/mask-pii.opam`.
- [ ] Run local opam lint/build tests against the packaged archive.
- [ ] Submit the opam-repository PR and resolve CI/reviewer findings.
- [ ] Verify `opam install mask-pii.X.Y.Z` from the merged repository.

### Perl — CPAN/PAUSE (`READY`)

Official reference: [PAUSE and CPAN upload](https://www.cpan.org/modules/04pause.html).

- [ ] Create/confirm the PAUSE account and first-come permission for `Mask::PII`.
- [ ] Run `make test-perl` and `make publish-perl-dry`.
- [ ] Inspect `Mask-PII-X.Y.Z.tar.gz`, META files, README, license, and module version.
- [ ] Upload through PAUSE/CPAN with the authorized account.
- [ ] Wait for indexing, then verify the MetaCPAN page and `cpanm Mask::PII` in a clean Perl environment.

### PowerShell — PowerShell Gallery (`READY`)

Official reference: [Publishing to PowerShell Gallery](https://learn.microsoft.com/powershell/gallery/how-to/publishing-packages/publishing-a-package).

- [ ] Confirm the PowerShell Gallery account, API key, and `MaskPII` name availability.
- [ ] Run `make test-powershell` and `make publish-powershell-dry`.
- [ ] Confirm `Test-ModuleManifest` reports version, exported commands, tags, license URI, project URI, and repository metadata.
- [ ] Run `Publish-Module -Path ./powershell/MaskPII -NuGetApiKey $PS_GALLERY_KEY` without exposing the key in shell history.
- [ ] Verify `Find-Module MaskPII` and install/import it in a clean PowerShell scope.

### R — CRAN (`BLOCKED`)

Official references: [CRAN repository policy](https://cran.r-project.org/web/packages/policies.html), [submission form](https://cran.r-project.org/submit.html).

- [ ] Run `R CMD build r` and `R CMD check --as-cran` on the resulting tarball, not only the source directory.
- [ ] Resolve all errors, warnings, and notes or document why a CRAN-accepted note is unavoidable.
- [ ] Confirm `MIT + file LICENSE` uses the CRAN-required license file format and that package metadata includes valid maintainer contact details.
- [ ] Check current R release, R-devel, and relevant platform builders where practical.
- [ ] Submit the tarball through the CRAN form and complete maintainer email confirmation.
- [ ] Address CRAN reviewer feedback and verify `install.packages("maskpii")` after acceptance.

### Racket — Package Catalog (`BLOCKED`)

Official catalog: https://pkgs.racket-lang.org/

Blockers: `racket/` has no package-local license file, and the catalog source must resolve the monorepo subdirectory.

- [ ] Add a package-local redistributable license in the next coordinated release.
- [ ] Validate `raco pkg install` directly from the proposed catalog source URL.
- [ ] Run `make test-racket` and package metadata validation.
- [ ] Submit `mask-pii` to the catalog with the working source URL.
- [ ] Verify catalog metadata, build status, documentation, license, and clean `raco pkg install mask-pii`.

### Swift — Swift Package Index (`READY`)

References: [SwiftPM package definition](https://docs.swift.org/package-manager/PackageDescription/PackageDescription.html), [Add a package to Swift Package Index](https://swiftpackageindex.com/add-a-package).

SwiftPM distribution itself is decentralized; the public catalog target is Swift Package Index.

- [ ] Run `swift test` from the repository root and confirm supported platforms/toolchain.
- [ ] Confirm `Package.swift`, root license, README, and `v0.2.0` tag resolve correctly from a clean consumer package.
- [ ] Submit `https://github.com/finitefield-org/mask-pii` to Swift Package Index.
- [ ] Resolve build-matrix failures and confirm the package page shows products, platforms, license, and documentation.

### V — VPM (`BLOCKED`)

Official catalog: https://vpm.vlang.io/

Blocker: VPM normally expects package metadata at the submitted repository root; `v/v.mod` is in a monorepo subdirectory.

- [ ] Confirm current VPM support for a subdirectory package with the VPM maintainers/docs.
- [ ] If unsupported, create an approved split/mirror release repository without changing canonical source ownership.
- [ ] Run V tests and validate `v.mod`, license, README, and version in the exact submitted layout.
- [ ] Submit the package through VPM.
- [ ] Verify `v install <approved-owner>.<approved-name>` in a clean V module directory.

### Common Lisp — Quicklisp (`BLOCKED`)

Reference: [Quicklisp project inclusion FAQ](https://www.quicklisp.org/beta/faq.html).

- [ ] Load and test `common-lisp/mask-pii.asd` with a clean ASDF environment.
- [ ] Confirm Quicklisp can discover the ASDF system inside the `common-lisp/` subdirectory of the release archive.
- [ ] Ensure the release source is immutable and contains README/license.
- [ ] Submit the project using the current Quicklisp project-submission process.
- [ ] After the next Quicklisp dist update, verify `(ql:quickload :mask-pii)`.

### Crystal — Shards and shard discovery (`BLOCKED`)

Official reference: [Writing and releasing Shards](https://crystal-lang.org/reference/latest/guides/writing_shards.html).

Crystal's official Shards tool resolves source repositories; discovery indexes are community services rather than a single official registry.

- [ ] Confirm consumers can reference the `crystal/` subdirectory from the canonical repository; if not, create an approved split/mirror repository.
- [ ] Run `make test-crystal` and `make publish-crystal-dry`.
- [ ] Validate `shard.yml`, README, license, version tag, and a clean consumer `shards install`.
- [ ] Submit the working repository to one established shard index for discoverability.
- [ ] Record the index URL, while continuing to describe Git tags as the source of truth.

## Languages without a registry/catalog target

These rows are complete when their Git/file installation instructions and release tag have been verified. They do not count as unpublished registry work.

| Language | Standard distribution | Verification |
| --- | --- | --- |
| AWK | Copy/source `awk/src/mask_pii.awk`; optional `awk-pkg` | Run AWK tests and follow README from a clean checkout. |
| Bash | Git/bpkg | Install using the documented GitHub path and run Bash tests. |
| Carbon | Source/toolchain experiment | Re-audit packaging when Carbon stabilizes it. |
| Fish | Fisher from Git | Install from Git and run `fish/tests/run.fish`. |
| Nushell | Git/file module | Import the module from a clean checkout and run tests. |
| Odin | Collection path | Build/test using the documented `-collection` mapping. |
| Pony | Git/Corral source dependency | Validate a clean source-control dependency and tests. |
| Red | Source file | Load `red/mask-pii.red` and run Red tests. |
| Tcl | `pkgIndex.tcl` plus Git/file install | Add `tcl/` to `auto_path`, require the package, and run tests. |
| Zig | URL/hash package dependency | Validate `zig build test` and document the immutable source URL/hash. |
| Zsh | Git plugin managers | Source the plugin from a clean clone and run Zsh tests. |

## Acceptance criteria

A registry/catalog target is `DONE` only when all applicable criteria are satisfied:

1. The public page exists under an account or organization controlled by Finite Field.
2. The intended version is immutable and downloadable from the public service.
3. A clean consumer can install and execute a minimal masking example without local paths, unpublished Git commits, or credentialed endpoints.
4. The public page shows a redistributable license, source repository, and the applicable `https://finitefield.org/oss/mask-pii/<language>/` page (or canonical mask-pii project page) where the service exposes those metadata fields; otherwise the published README or API documentation contains the canonical website URL.
5. Published documentation explains that masking is opt-in and includes email and phone examples consistent with tests.
6. No secret, cache, credential, or private artifact is included. Registry-built monorepo source archives may contain unrelated language directories only when the service offers no package-level file selection and the consumer's import/autoload surface remains limited to the intended implementation.
7. This document contains the final URL, version, verification date, owner, and any remaining follow-up.

Catalog-only targets such as Hare and Swift Package Index replace criterion 2 with a working immutable Git tag and replace criterion 3 with the ecosystem's documented Git installation flow.

## Failure handling, rollback, and immutability

- Public package versions generally cannot be overwritten. Fix defects with a new coordinated patch version.
- If a registry supports yank/deprecate/retract, use it only for security, legal, malware, or unusable-artifact incidents; record the reason and replacement version.
- Never delete and recreate a package merely to repair metadata unless the registry explicitly guarantees that no published version or namespace ownership is lost.
- If a name is owned by another publisher, stop and choose an organization-scoped name; do not contact users, transfer money, or file a dispute without explicit authorization.
- If an upload succeeds but indexing times out, verify the registry page/API before retrying. A retry may collide with an already immutable version.
- If installation verification fails after publication, mark the target `PARTIAL`, stop the rollout, open a documented fix for the next version, and continue only after assessing whether other languages share the defect.

## Coordinated `0.2.1` backlog

This is the collection point for fixes discovered during initial registration. Do not create the release until every checked item has an implementation and validation result.

- [ ] Include package-local licenses in every published artifact; Go and Racket are known follow-ups.
- [ ] Add canonical per-language finitefield.org URLs to package metadata and API/package comments where supported.
- [ ] Align Julia with the coordinated version.
- [ ] Resolve final npm names for JavaScript and Bun.
- [ ] Reserve and apply the final JSR scope/name for Deno.
- [ ] Fix every confirmed monorepo packaging issue: D, Lua, Nim, V, Crystal, Common Lisp, Racket, and any new findings.
- [ ] Configure Maven Central publication/signing for Groovy.
- [ ] Correct stale Makefile guidance, including D `dub publish`, Deno `deno.land/x`, and Hare `harepm`, in a separate implementation task.
- [ ] Run language tests and registry dry-runs from the release commit.
- [ ] Update `CHANGELOG.md`, `VERSION`, language manifests, README installation commands, website package pages, and this tracker.
- [ ] Create immutable release tags only after review and approval.

## Progress update template

Append this block to the relevant language runbook while work is active, then collapse it into the master row after completion.

```text
Operator:
Started (JST):
Target registry/catalog:
Package identifier:
Intended version:
Dry-run command and result:
Publish/submit action:
Public URL:
Clean install command and result:
License/repository/website metadata result:
Completed (JST):
Remaining follow-up:
```

## Reference files

- Repository version: `VERSION`
- Common tests/builds/publication helpers: `Makefile`
- Release history: `CHANGELOG.md`
- Language implementation inventory: `README.md`
- Language manifests: each language directory and the repository-root `Package.swift`/`composer.json`
