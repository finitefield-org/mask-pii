# mask-pii 公式パッケージ登録・進捗管理

最終調査日: 2026-07-17（JST）

この文書は、このリポジトリに存在するすべての言語実装を、利用可能な公式またはエコシステム標準のパッケージレジストリ／カタログへ登録するための実行仕様兼進捗表です。

## 目的

- 各言語の利用者が通常使うパッケージ取得方法で、すべての実装を発見・導入できるようにする。
- 既存の歴史的な例外を除き、公開バージョンをリポジトリ直下の `VERSION` にそろえる。
- 認証、事前検証、公開、インストール確認、公開後の改善を個別に記録する。
- 公開レジストリ、プロキシ、利用者から参照済みのバージョンやタグを上書き・移動しない。

## 対象範囲と定義

このリポジトリには現在36言語の実装があります。次のいずれかに該当する公開先を対象とします。

1. 言語公式のパッケージレジストリまたはカタログ。
2. 言語公式のレジストリがない場合、そのエコシステムで標準的に使われる公開レジストリ。
3. パッケージレジストリがない場合の公式プロジェクト一覧（Hare Project Libraryなど）。

Gitリポジトリを直接指定して取得するだけで、権威ある公開カタログを持たないコミュニティ製パッケージマネージャーは、配布方法として記録しますが、レジストリ登録対象には数えません。

### 対象外

- この文書だけでは、外部サービスへの公開、アカウント作成、名前空間予約、所有権変更を許可しない。実行には個別の明示的な依頼が必要。
- すべての言語で同一パッケージ名を強制しない。名前の衝突時はスコープ付き名称や接尾辞を使用する。
- 適用可能な公開レジストリ／カタログがある場合、GitHubタグだけでは登録完了としない。
- `make publish-all` は使用しない。不可逆な公開操作は、言語ごとに実行・確認する。

## ステータス定義

| ステータス | 意味 |
| --- | --- |
| `DONE` | 公開・導入可能で、Finite Fieldが所有し、公開ページの品質確認まで完了。 |
| `PARTIAL` | 公開ページは存在するが、文書、ライセンス、バージョン、所有権、導入確認のいずれかが未完了。 |
| `READY` | マニフェストとパッケージは準備済みで、認証または最終公開／申請だけが残っている。 |
| `BLOCKED` | メタデータ、名前空間、モノレポ構成、レジストリ設定、ポリシー対応が必要。 |
| `N/A` | 適用可能な公式またはエコシステム標準の公開レジストリ／カタログがない。 |

進捗更新時は、マスター進捗表のステータスと、該当runbookのチェックボックスを両方更新します。`DONE` へ変更する際は、確認日と公開URLも記録します。

### タスク番号の規則

- タスク番号は `<区分>-<2桁の連番>` とする（例: `GO-01`、`DENO-03`）。
- `PRE` は全登録先共通の事前確認、`REL` は共通リリース作業を表す。
- 言語別タスクは言語名を識別できる固定の区分を使う。番号は完了後も変更・再利用しない。
- 進捗報告、Issue、Pull Requestでは、該当するタスク番号を記載する。

## 現在の集計

| 項目 | 件数 |
| --- | ---: |
| 言語実装 | 36 |
| レジストリ／カタログ対象 | 25 |
| 公開ページ作成済み | 7 |
| 完了（`DONE`） | 5 |
| 公開済み・要改善（`PARTIAL`） | 2 |
| 未公開の登録対象 | 18 |
| 対象レジストリなし（`N/A`） | 11 |

公開済みの内訳:

- `DONE`: Rust、Ruby、Python、PHP、Elixir。
- `PARTIAL`: Go（`v0.2.0` は公開済みだが、タグ内のライセンスが検出されず文書が非表示）、Julia（Generalには `0.1.0` が登録済みで、リポジトリの `0.2.0` より古い）。

## マスター進捗表

| 言語 | 登録先 | パッケージ識別子 | 状態 | 公開版 | 担当 | 次の作業／根拠 |
| --- | --- | --- | --- | --- | --- | --- |
| AWK | なし・Gitソース配布 | `awk/` | `N/A` | — | — | Git導入手順を維持する。`awk-pkg` は任意のコミュニティ配布。 |
| Bash | なし・Git/bpkg配布 | `finitefield-org/mask-pii/bash` | `N/A` | — | — | タグ付きGit導入手順を維持する。 |
| Bun | npm | 推奨: `@finitefield-org/mask-pii-bun` | `BLOCKED` | — | 未割当 | スコープと名前を確保し、マニフェストを変更する。現在の非スコープ名は衝突し、JavaScript版とも重複。 |
| Carbon | なし・パッケージングは実験段階 | `carbon/` | `N/A` | — | — | 安定した公開レジストリが定義された時点で再調査する。 |
| Common Lisp | Quicklisp | システム名 `mask-pii` | `BLOCKED` | — | 未割当 | モノレポ内ASDFの検出可否を確認後、Quicklispへ申請する。 |
| Crystal | Shards＋標準的な検索インデックス | shard名 `mask_pii` | `BLOCKED` | — | 未割当 | サブディレクトリから導入できることを確認してからインデックスへ申請する。 |
| D | DUB | `mask-pii` | `BLOCKED` | — | 未割当 | DUBのリポジトリ直下要件と現在の `d/` 配置を解決する。古い `dub publish` ターゲットは使わない。 |
| Deno | JSR | 推奨: `@finitefield/mask-pii` | `BLOCKED` | — | 未割当 | JSRスコープを確保し、非スコープの `deno.json` 名を変更する。 |
| Elixir | Hex | `mask_pii` | `DONE` | `0.2.0` | Finite Field | 2026-07-17確認: https://hex.pm/packages/mask_pii |
| Fish | なし・FisherはGitから取得 | `finitefield-org/mask-pii` | `N/A` | — | — | Git/Fisher導入手順を維持する。 |
| Go | Go Module Proxy／pkg.go.dev | `github.com/finitefield-org/mask-pii/go` | `PARTIAL` | `0.2.0` | Finite Field | 2026-07-17確認: https://pkg.go.dev/github.com/finitefield-org/mask-pii/go 。次回リリースでライセンスと文書を修正。 |
| Groovy | Maven Central | `org.finitefield:mask-pii` | `BLOCKED` | — | 未割当 | Centralの名前空間、署名、認証情報、公開先リポジトリを設定する。 |
| Hare | 公式Hare Project Library | `maskpii` | `READY` | Git | 未割当 | `HAREPATH` 手順確認後、hare-devメーリングリストへパッチを送る。 |
| Haskell | Hackage | `mask-pii` | `READY` | — | 未割当 | source distributionを検証し、Hackageアカウントで公開する。 |
| JavaScript | npm | 推奨: `@finitefield-org/mask-pii` | `BLOCKED` | — | 未割当 | 非スコープ名 `mask-pii` は別所有者のため、スコープを確保しマニフェストと導入手順を更新する。 |
| Julia | General Registry | `MaskPII` | `PARTIAL` | `0.1.0` | Finite Field | 2026-07-17確認: https://juliahub.com/ui/Packages/General/MaskPII 。次回リリースで共通バージョンへ合わせる。 |
| Lua | LuaRocks | `mask-pii` | `BLOCKED` | — | 未割当 | rockspecのモノレポ内ソースパスを修正・検証する。 |
| Nim | Nim package list／Nimble | `mask_pii` | `BLOCKED` | — | 未割当 | package-list申請で `nim/` サブディレクトリを扱えるか確認する。 |
| Nushell | なし・Git／ファイル配布 | `nushell/` | `N/A` | — | — | Git導入手順を維持し、公式レジストリ登場時に再調査する。 |
| OCaml | opam repository | `mask-pii` | `BLOCKED` | — | 未割当 | 不変URLとチェックサムを持つopam-repository用バージョンディレクトリを作る。 |
| Odin | サードパーティ用レジストリなし | `odin/mask_pii` | `N/A` | — | — | collection-pathによる導入手順を維持する。 |
| Perl | CPAN／PAUSE | distribution `Mask-PII`／module `Mask::PII` | `READY` | — | 未割当 | PAUSE名前空間権限を取得し、検証済みdistributionをアップロードする。 |
| PHP | Packagist | `finitefield-org/mask-pii` | `DONE` | `0.2.0` | Finite Field | 2026-07-17確認: https://packagist.org/packages/finitefield-org/mask-pii |
| Pony | なし・CorralはGit依存を解決 | `pony/mask_pii` | `N/A` | — | — | タグ付きGit／Corral導入手順を維持する。 |
| PowerShell | PowerShell Gallery | `MaskPII` | `READY` | — | 未割当 | マニフェスト検証後、APIキーで公開し、クリーン環境で導入確認する。 |
| Python | PyPI | `mask-pii` | `DONE` | `0.2.0` | Finite Field | 2026-07-17確認: https://pypi.org/project/mask-pii/ |
| R | CRAN | `maskpii` | `BLOCKED` | — | 未割当 | `R CMD check --as-cran` の問題を解消し、CRAN用ライセンス形式を確認する。 |
| Racket | Racket Package Catalog | `mask-pii` | `BLOCKED` | — | 未割当 | パッケージ内ライセンスを追加し、`racket/` を指すカタログソースを検証する。 |
| Red | なし・ソースファイル配布 | `red/mask-pii.red` | `N/A` | — | — | Git／ファイル導入手順を維持する。 |
| Ruby | RubyGems | `mask-pii` | `DONE` | `0.2.0` | Finite Field | 2026-07-17確認: https://rubygems.org/gems/mask-pii |
| Rust | crates.io | `mask-pii` | `DONE` | `0.2.0` | Finite Field | 2026-07-17確認: https://crates.io/crates/mask-pii |
| Swift | Swift Package Index（SwiftPM配布はGit） | リポジトリURL | `READY` | Gitタグ `v0.2.0` | 未割当 | Swift Package Indexへ申請し、ビルド互換性を確認する。 |
| Tcl | 権威あるレジストリなし | パッケージ名 `mask_pii` | `N/A` | — | — | `pkgIndex.tcl`／Git導入を維持し、第三者カタログは任意とする。 |
| V | VPM | VPM互換のowner/package名 | `BLOCKED` | — | 未割当 | モノレポのサブディレクトリ対応を確認し、非対応なら分離／ミラーする。 |
| Zig | なし・公式パッケージマネージャーはURL/hash方式 | `zig/` | `N/A` | — | — | URL/hash依存を文書化し、存在しないレジストリへの申請は行わない。 |
| Zsh | なし・各種マネージャーはGitから取得 | `finitefield-org/mask-pii` | `N/A` | — | — | タグ付きGit導入手順を維持する。 |

## 共通リリース規則

### バージョン方針

1. 現在の基準バージョンは `VERSION` の値（最終調査時点で `0.2.0`）。
2. 公開済みの名前／バージョンの組を再公開・置換しない。
3. `v0.2.0`、`go/v0.2.0`、その他取得済みのタグを移動しない。
4. ソース変更なしで検証に合格する未登録パッケージは、既存の `0.2.0` を初回公開に使用できる。
5. 有効なパッケージにするためソースやメタデータ変更が必要な場合は、全言語共通の `0.2.1` リリースへまとめる。Julia `0.1.0` のような既存例外は明記する。

### 認証情報と権限

- トークン、APIキー、パスワード、OTP、署名鍵、認証ファイルをリポジトリやコマンド履歴へ残さない。
- 公式対応している場合はOIDC／Trusted Publishingを優先し、それ以外は権限を限定したトークンをOSの資格情報ストアまたはCI secretに保存する。
- 対応サービスではMFAを有効にする。
- 所有者はアカウント／組織名で記録し、秘密情報や確認用メール情報は記録しない。
- 不可逆な公開／アップロード／申請の直前に、人間の実行者が対象を確認する。

### 全登録先共通の事前確認

- [ ] **PRE-01** 作業ツリーと対象コミットを特定し、無関係な変更を除外した。
- [ ] **PRE-02** パッケージ版が予定版と一致するか、例外を記録した。
- [ ] **PRE-03** 公開物にREADME、再配布可能なライセンス、リポジトリURL、Issue URL、該当言語ページまたは公式プロジェクトページを含めた。
- [ ] **PRE-04** 対象言語の単体テストが成功した。
- [ ] **PRE-05** レジストリ固有のdry-run／パッケージ検査が成功した。
- [ ] **PRE-06** 公開ファイルにsecret、キャッシュ、認証情報、不要な巨大ファイルが含まれないことを確認した。
- [ ] **PRE-07** 公開メタデータ変更前にパッケージ名と名前空間の所有権を確認した。
- [ ] **PRE-08** クリーンな一時プロジェクトで、公開識別子を使って導入・実行できた。
- [ ] **PRE-09** 対応フィールドがある場合、公開ページの版、ライセンス、リポジトリ、finitefield.orgリンクを確認した。ない場合は公開README／API文書を確認した。
- [ ] **PRE-10** この文書へ状態、公開URL、確認日、残作業を反映した。

## 実行順序

不可逆な公開は1件ずつ行い、導入確認が終わるまで次へ進みません。

1. ソース変更不要の `READY`: Haskell、Hare、Perl、PowerShell、Swift Package Index。
2. メタデータ／構成変更が必要な `BLOCKED`: D、Deno、JavaScript、Bun、Groovy、Lua、Nim、OCaml、R、Racket、V、Common Lisp、Crystal。
3. 共通 `0.2.1` 品質改善リリース: Goのライセンス／文書、Juliaの版統一、手順1〜2で判明した全変更。

## 公開済みパッケージの保守runbook

### Go — Go Module Proxy／pkg.go.dev（`PARTIAL`）

公式資料: [Publishing a module](https://go.dev/doc/modules/publishing)、[pkg.go.devへの追加](https://pkg.go.dev/about)

現状:

- module pathは `go/go.mod` の `github.com/finitefield-org/mask-pii/go`。
- モノレポ用タグ形式は `go/vX.Y.Z`。
- `go/v0.2.0` はGo Module Proxyとpkg.go.devで公開済み。
- pkg.go.devは `License: None detected` と表示し、タグに現在の `go/LICENSE.md` が含まれないため文書を表示していない。

- [x] **GO-01** `go/v0.2.0` をGitHubへpushした。
- [x] **GO-02** `proxy.golang.org` からmoduleを要求した。
- [x] **GO-03** pkg.go.devで `v0.2.0` を確認した。
- [ ] **GO-04** 次回タグに `go/LICENSE.md` が含まれることを確認する。
- [ ] **GO-05** package commentとGo READMEへ `https://finitefield.org/oss/mask-pii/go/` を追加する。
- [ ] **GO-06** `cd go && go mod tidy && go test ./...` を実行する。
- [ ] **GO-07** 共通 `0.2.1` コミット承認後に限り `go/v0.2.1` を作成・pushする。
- [ ] **GO-08** `GOPROXY=https://proxy.golang.org go list -m github.com/finitefield-org/mask-pii/go@v0.2.1` を実行する。
- [ ] **GO-09** pkg.go.devでライセンス検出と文書表示を確認する。

`go/v0.2.0` は削除・付け替えしません。

### Rust — crates.io（`DONE`）

公式資料: [Cargo publishing](https://doc.rust-lang.org/cargo/reference/publishing.html)

- [x] **RUST-01** `mask-pii` `0.2.0` が公開済み。
- [x] **RUST-02** 公開ページのリポジトリ、サイト、ライセンスを確認済み。
- [ ] **RUST-03** 次回は `make publish-rust-dry` と `cargo package --list` を確認後、承認済み所有者で `make publish-rust` を実行する。
- [ ] **RUST-04** クリーンなプロジェクトで `cargo add mask-pii` を確認する。

### Ruby — RubyGems（`DONE`）

公式資料: [Publishing a gem](https://guides.rubygems.org/publishing/)

- [x] **RUBY-01** `mask-pii` `0.2.0` がFinite Field所有で公開済み。
- [ ] **RUBY-02** 次回は `make publish-ruby-dry` とgem内容を確認後、`make publish-ruby` を実行する。
- [ ] **RUBY-03** ローカルgemを使わず `gem install mask-pii -v X.Y.Z` を確認する。

### Python — PyPI（`DONE`）

公式資料: [Packaging Python projects](https://packaging.python.org/en/latest/tutorials/packaging-projects/)

- [x] **PY-01** `mask-pii` `0.2.0` が公開済み。
- [ ] **PY-02** 今後はPyPI Trusted Publishingを優先し、手動Twine uploadは代替手段とする。
- [ ] **PY-03** `make publish-python-dry` でsdistとwheelを検査後、`make publish-python` を実行する。
- [ ] **PY-04** 新規venvで `python -m pip install --no-cache-dir mask-pii==X.Y.Z` を確認する。

### PHP — Packagist（`DONE`）

公式資料: [Packagistへの登録と更新](https://packagist.org/about)

- [x] **PHP-01** `finitefield-org/mask-pii` `0.2.0` が公開済み。
- [x] **PHP-02** GitHub連携を確認済み。
- [ ] **PHP-03** 次回は `make publish-php-dry` 後に共通タグをpushし、Packagistへの反映を確認する。
- [ ] **PHP-04** クリーンなプロジェクトで `composer require finitefield-org/mask-pii:X.Y.Z` を確認する。

### Elixir — Hex（`DONE`）

公式資料: [Mix Hex publish](https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html)

- [x] **EX-01** `mask_pii` `0.2.0` が公開済み。
- [ ] **EX-02** 次回公開前に `make publish-elixir-dry` を実行する。
- [ ] **EX-03** 対象のクリーンなコミットからのみ `make publish-elixir` を実行する。
- [ ] **EX-04** `mix hex.info mask_pii X.Y.Z` と新規Mixプロジェクトからの導入を確認する。

### Julia — General Registry（`PARTIAL`）

公式資料: [Registrator.jl](https://github.com/JuliaRegistries/Registrator.jl)

- [x] **JL-01** UUID `e51ab4cc-94ad-4aad-a579-d543f796cd4d` の `MaskPII` `0.1.0` をGeneralへ登録済み。
- [ ] **JL-02** 次の共通バージョンを決め、`julia/Project.toml` を同じ版へ更新する。
- [ ] **JL-03** `make publish-julia-dry` と `julia --project=julia -e 'using Pkg; Pkg.test()'` を実行する。
- [ ] **JL-04** 承認済みリリースコミットへ `@JuliaRegistrator register subdir=julia` とコメントする。
- [ ] **JL-05** Generalへのmerge後、クリーンなdepotで `Pkg.add("MaskPII")` を確認する。

## 未公開レジストリ／カタログのrunbook

### D — DUB（`BLOCKED`）

公式資料: [Publishing packages](https://dub.pm/dub-guide/publishing/)

DUBはCLIの `dub publish` ではなく、Webサイトへリポジトリを登録しタグを監視する方式です。公式手順はパッケージ定義を登録リポジトリ直下に置く前提ですが、現在は `d/dub.json` 以下にあります。Makefileの `publish-d`／`publish-d-dry` は使用しません。

- [ ] **D-01** DUBアカウントと `mask-pii` 名の空きを確認する。
- [ ] **D-02** サブディレクトリを登録できるか、非公開操作での検証またはDUB管理者への確認を行う。
- [ ] **D-03** 非対応なら、D専用split／mirrorリポジトリまたは同等の構成変更について承認を得る。
- [ ] **D-04** `make test-d`、`cd d && dub build` を実行し、マニフェスト、README、ライセンス、収録ファイルを確認する。
- [ ] **D-05** DUB Webサイトへ承認済みのリポジトリURLを登録し、そのリポジトリへ不変のSemVerタグを作る。
- [ ] **D-06** クリーンなDプロジェクトで `dub add mask-pii` と `dub test` を確認する。

### Deno — JSR（`BLOCKED`）

公式資料: [JSRへの公開](https://jsr.io/docs/publishing-packages)

JSRはスコープ付き名称が必須ですが、現在の `deno/deno.json` は非スコープの `mask-pii` です。

- [ ] **DENO-01** 組織所有のJSRスコープを確保する。第一候補は `@finitefield`。
- [ ] **DENO-02** パッケージ名を承認済み識別子（推奨 `@finitefield/mask-pii`）へ変更する。
- [ ] **DENO-03** `mod.ts`、source、README、licenseの明示的な公開対象を設定する。
- [ ] **DENO-04** 導入／import文書を最終識別子へ更新する。
- [ ] **DENO-05** `deno/` で `deno test`、`deno check mod.ts`、`deno publish --dry-run` を実行する。
- [ ] **DENO-06** GitHub OIDCを優先して公開し、クリーン環境で `deno add jsr:@finitefield/mask-pii@X.Y.Z` を確認する。

Makefileに残る新規 `deno.land/x` 公開手順は古いため使用しません。

### JavaScript — npm（`BLOCKED`）

公式資料: [スコープ付きpublic packageの公開](https://docs.npmjs.com/creating-and-publishing-scoped-public-packages/)

非スコープ名 `mask-pii` は別の公開者が所有しています。

- [ ] **JS-01** Finite Field管理のnpm organization scopeを確認する。推奨名は `@finitefield-org/mask-pii`。
- [ ] **JS-02** `javascript/package.json` の名前、repository directory、README、テストを更新する。
- [ ] **JS-03** `publishConfig.access = "public"` と必要に応じて明示的な `files` を追加する。
- [ ] **JS-04** `javascript/` で `npm test` と `npm publish --dry-run` を行い、tarball内容を確認する。
- [ ] **JS-05** MFA／Trusted Publishingで公開し、クリーンなNodeプロジェクトから導入・importする。

### Bun — npm（`BLOCKED`）

Bunもnpmパッケージを使用するため、JavaScript版とBun版は同じnpm名を所有できません。

- [ ] **BUN-01** 別のスコープ付き名称（推奨 `@finitefield-org/mask-pii-bun`）を承認する。
- [ ] **BUN-02** `bun/package.json`、README、build出力、import例を更新する。
- [ ] **BUN-03** `bun test`、`bun run build`、`bun publish --dry-run` を実行する。
- [ ] **BUN-04** `dist/`、型定義、README、licenseを確認して公開し、Bunのクリーンプロジェクトから導入する。

### Groovy — Maven Central（`BLOCKED`）

公式資料: [Maven Central Publisher Portal](https://central.sonatype.org/publish/publish-portal-guide/)

`groovy/build.gradle` にはpublication定義がありますが、Central公開先、認証、名前空間確認、署名設定がありません。

- [ ] **GRV-01** Maven Centralで `org.finitefield` 名前空間の所有権を確認する。
- [ ] **GRV-02** 座標 `org.finitefield:mask-pii:X.Y.Z` を確定する。
- [ ] **GRV-03** secretをコミットせず、Central公開と署名を設定する。
- [ ] **GRV-04** POMへ名称、説明、URL、license、developers、SCMを含める。
- [ ] **GRV-05** テスト、sources／Groovydoc jar生成、Maven Localへの公開と検査を行う。
- [ ] **GRV-06** Central Portalで検証・公開後、クリーンなGradleプロジェクトから解決する。

### Haskell — Hackage（`READY`）

公式入口: https://hackage.haskell.org/upload

- [ ] **HS-01** Hackageアカウント、名前の空き、maintainershipを確認する。
- [ ] **HS-02** `make test-haskell` と `make publish-haskell-dry` を実行する。
- [ ] **HS-03** source distributionのREADME、license、changelogを確認する。
- [ ] **HS-04** 利用可能ならpackage candidateを先にupload・導入確認する。
- [ ] **HS-05** 人間の最終確認後にuploadし、クリーン環境で `cabal update && cabal install mask-pii-X.Y.Z` を確認する。

### Hare — 公式Project Library（`READY`）

公式資料: [Hare Project Library](https://harelang.org/project-library/)

Hareには公式パッケージマネージャーがありません。公式一覧への掲載とGit／`HAREPATH` 手順の動作を完了条件とします。

- [ ] **HARE-01** Hareテストと、クリーンcloneからの `HAREPATH` 構成を確認する。
- [ ] **HARE-02** Project Libraryの適切なカテゴリへmask-piiを追加する小さなpatchを作る。
- [ ] **HARE-03** 公式案内どおりhare-devメーリングリストへ送る。
- [ ] **HARE-04** 採用後のURLと確認日を記録する。

Makefileの `harepm` を前提にした `publish-hare` は使用しません。

### Lua — LuaRocks（`BLOCKED`）

資料: [Uploading rocks](https://github.com/luarocks/luarocks/wiki/Uploading-rocks)

`lua/mask-pii-0.2.0-1.rockspec` はリポジトリ直下を取得しますが、module pathは `lua/` 相対です。取得アーカイブからのbuildを実証する必要があります。

- [ ] **LUA-01** rockspecのsource／source.dirとモノレポ構成を決定的に解決する。
- [ ] **LUA-02** 不変タグ／アーカイブに `lua/LICENSE.md` とREADMEが含まれることを確認する。
- [ ] **LUA-03** `make test-lua`、`make publish-lua-dry`、クリーンなLuaRocks treeでのlocal installを行う。
- [ ] **LUA-04** 成功後にのみuploadし、公開サーバーから `luarocks install mask-pii 0.2.0-1` を確認する。

### Nim — Nim package list／Nimble（`BLOCKED`）

資料: [パッケージ申請](https://github.com/nim-lang/packages#submitting-a-package)

- [ ] **NIM-01** package-listが `nim/` サブディレクトリを扱えるか確認する。非対応ならsplit／mirrorを検討する。
- [ ] **NIM-02** `nim/mask_pii.nimble` の名前、tag、license、repository metadataを確認する。
- [ ] **NIM-03** `make test-nim` と `make publish-nim-dry` を実行する。
- [ ] **NIM-04** 現行資料に従ってpackage-list PRまたは `nimble publish` を行う。
- [ ] **NIM-05** クリーンなNimble環境で `nimble install mask_pii` を確認する。

### OCaml — opam repository（`BLOCKED`）

公式資料: [Packaging with opam](https://opam.ocaml.org/doc/Packaging.html)

- [ ] **OCAML-01** `ocaml/opam-repository` のforkへ `packages/mask-pii/mask-pii.X.Y.Z/opam` を作る。
- [ ] **OCAML-02** 不変のrelease archive URLとSHA256／SHA512を設定する。
- [ ] **OCAML-03** `ocaml/mask-pii.opam` とbuild／test依存を一致させる。
- [ ] **OCAML-04** パッケージアーカイブに対するlint／buildを行う。
- [ ] **OCAML-05** opam-repository PRのCI／レビューを解決し、merge後に `opam install mask-pii.X.Y.Z` を確認する。

### Perl — CPAN／PAUSE（`READY`）

公式資料: [PAUSEとCPAN upload](https://www.cpan.org/modules/04pause.html)

- [ ] **PERL-01** PAUSEアカウントと `Mask::PII` のfirst-come権限を確認する。
- [ ] **PERL-02** `make test-perl` と `make publish-perl-dry` を実行する。
- [ ] **PERL-03** `Mask-PII-X.Y.Z.tar.gz`、META、README、license、module versionを確認する。
- [ ] **PERL-04** 承認済みアカウントでuploadし、index後にMetaCPANと `cpanm Mask::PII` を確認する。

### PowerShell — PowerShell Gallery（`READY`）

公式資料: [Publishing to PowerShell Gallery](https://learn.microsoft.com/powershell/gallery/how-to/publishing-packages/publishing-a-package)

- [ ] **PS-01** Galleryアカウント、APIキー、`MaskPII` 名の空きを確認する。
- [ ] **PS-02** `make test-powershell` と `make publish-powershell-dry` を実行する。
- [ ] **PS-03** `Test-ModuleManifest` で版、export、tag、license URI、project URI、repositoryを確認する。
- [ ] **PS-04** キーを履歴へ露出せず `Publish-Module -Path ./powershell/MaskPII -NuGetApiKey $PS_GALLERY_KEY` を実行する。
- [ ] **PS-05** `Find-Module MaskPII` とクリーンscopeへのinstall／importを確認する。

### R — CRAN（`BLOCKED`）

公式資料: [CRAN policy](https://cran.r-project.org/web/packages/policies.html)、[submission](https://cran.r-project.org/submit.html)

- [ ] **R-01** `R CMD build r` 後のtarballに対して `R CMD check --as-cran` を実行する。
- [ ] **R-02** error／warning／noteを解消し、許容されるnoteだけ理由を記録する。
- [ ] **R-03** `MIT + file LICENSE` とmaintainer連絡先がCRAN要件を満たすことを確認する。
- [ ] **R-04** 現行R、R-devel、可能なplatform builderで確認する。
- [ ] **R-05** CRAN formから提出し、メール確認とreviewer指摘へ対応する。
- [ ] **R-06** 採用後 `install.packages("maskpii")` を確認する。

### Racket — Package Catalog（`BLOCKED`）

公式カタログ: https://pkgs.racket-lang.org/

`racket/` にパッケージ内licenseがなく、カタログsourceもモノレポのサブディレクトリを解決する必要があります。

- [ ] **RKT-01** 次回共通リリースでパッケージ内licenseを追加する。
- [ ] **RKT-02** 提案するsource URLから `raco pkg install` を直接検証する。
- [ ] **RKT-03** `make test-racket` とmetadata検証を行う。
- [ ] **RKT-04** 動作するsource URLで `mask-pii` を申請する。
- [ ] **RKT-05** catalog metadata、build、文書、license、クリーンな `raco pkg install mask-pii` を確認する。

### Swift — Swift Package Index（`READY`）

資料: [SwiftPM package definition](https://docs.swift.org/package-manager/PackageDescription/PackageDescription.html)、[Swift Package Indexへの追加](https://swiftpackageindex.com/add-a-package)

SwiftPM自体は分散型のため、公開カタログとしてSwift Package Indexを対象にします。

- [ ] **SWIFT-01** リポジトリ直下で `swift test` を実行し、platform／toolchainを確認する。
- [ ] **SWIFT-02** クリーンなconsumerから `Package.swift`、root license、README、`v0.2.0` tagを確認する。
- [ ] **SWIFT-03** `https://github.com/finitefield-org/mask-pii` をSwift Package Indexへ申請する。
- [ ] **SWIFT-04** build matrixの問題を解消し、products、platforms、license、文書を確認する。

### V — VPM（`BLOCKED`）

公式カタログ: https://vpm.vlang.io/

VPMは通常、申請リポジトリ直下のmetadataを前提としますが、現在の `v.mod` は `v/` にあります。

- [ ] **V-01** VPMのサブディレクトリ対応を現行資料／管理者へ確認する。
- [ ] **V-02** 非対応なら、canonical sourceの所有権を維持したsplit／mirrorを承認する。
- [ ] **V-03** 申請する構成でVテスト、`v.mod`、license、README、versionを確認する。
- [ ] **V-04** VPMへ申請し、クリーン環境で `v install <owner>.<name>` を確認する。

### Common Lisp — Quicklisp（`BLOCKED`）

資料: [Quicklisp inclusion FAQ](https://www.quicklisp.org/beta/faq.html)

- [ ] **CL-01** クリーンなASDF環境で `common-lisp/mask-pii.asd` をload・testする。
- [ ] **CL-02** release archive内の `common-lisp/` からQuicklispがASDF systemを検出できるか確認する。
- [ ] **CL-03** 不変sourceにREADMEとlicenseが含まれることを確認する。
- [ ] **CL-04** 現行のQuicklisp申請方法で提出する。
- [ ] **CL-05** dist更新後に `(ql:quickload :mask-pii)` を確認する。

### Crystal — Shards／検索インデックス（`BLOCKED`）

公式資料: [Writing and releasing Shards](https://crystal-lang.org/reference/latest/guides/writing_shards.html)

Shardsはソースリポジトリを解決します。単一の公式レジストリはなく、検索インデックスはコミュニティサービスです。

- [ ] **CR-01** canonical repositoryの `crystal/` をconsumerから参照できるか確認し、非対応ならsplit／mirrorを承認する。
- [ ] **CR-02** `make test-crystal` と `make publish-crystal-dry` を実行する。
- [ ] **CR-03** `shard.yml`、README、license、version tag、クリーンな `shards install` を確認する。
- [ ] **CR-04** 発見性のため、確立したshard indexを1つ選定して申請する。
- [ ] **CR-05** index URLを記録し、Git tagをsource of truthとして文書化する。

## レジストリ／カタログ対象がない言語

次の言語はGit／ファイル導入とrelease tagが確認できれば完了です。未公開レジストリ件数には含めません。

| 言語 | 標準的な配布方法 | 確認方法 |
| --- | --- | --- |
| AWK | `awk/src/mask_pii.awk` をcopy／source | テストとREADME手順をクリーンcheckoutで実行する。 |
| Bash | Git／bpkg | 文書化したGitHub pathから導入してテストする。 |
| Carbon | source／実験的toolchain | パッケージング安定後に再調査する。 |
| Fish | GitからFisherで導入 | Gitから導入し `fish/tests/run.fish` を実行する。 |
| Nushell | Git／module file | クリーンcheckoutからmoduleをimportしてtestする。 |
| Odin | collection path | 文書化した `-collection` mappingでbuild／testする。 |
| Pony | Git／Corral dependency | クリーンなsource-control dependencyとtestを確認する。 |
| Red | source file | `red/mask-pii.red` をloadしてtestする。 |
| Tcl | `pkgIndex.tcl`＋Git | `tcl/` を `auto_path` へ追加しrequire／testする。 |
| Zig | URL/hash dependency | `zig build test` と不変source URL/hashを確認する。 |
| Zsh | Git plugin manager | クリーンcloneからpluginをsourceしてtestする。 |

## 完了条件

登録対象を `DONE` にするには、適用可能な項目をすべて満たす必要があります。

1. Finite Field管理のアカウント／組織配下に公開ページがある。
2. 予定版が公開サービスから不変の形で取得できる。
3. ローカルpath、未公開commit、認証付きendpointを使わず、クリーンなconsumerで導入して最小のmasking例を実行できる。
4. 対応フィールドがある場合、公開ページに再配布可能なlicense、source repository、該当言語ページまたは公式プロジェクトページが表示される。ない場合は公開README／API文書に公式URLがある。
5. 公開文書にmaskingがopt-inであることと、testに合致するemail／phone例がある。
6. secret、cache、credential、private artifactがない。レジストリ側がファイル選択を提供しないモノレポarchiveでは、consumerのimport／autoload範囲が対象実装だけに限定されることを確認する。
7. この文書に最終URL、版、確認日、所有者、残作業が記録されている。

HareやSwift Package Indexなどのカタログのみの対象は、項目2を「動作する不変Git tag」、項目3を「エコシステム標準のGit導入手順」に読み替えます。

## 失敗時の対応と不変性

- 公開版は通常上書きできないため、修正は新しい共通patch versionで行う。
- yank／deprecate／retractはsecurity、法的問題、malware、利用不能artifactの場合だけ使用し、理由と代替版を記録する。
- レジストリが名前・所有権・公開版を保持すると明示しない限り、metadata修正目的でpackageを削除・再作成しない。
- 名前が別所有者に使われている場合は組織scope名を選ぶ。明示的な許可なしに連絡、金銭支払い、異議申立てを行わない。
- upload後にindexがtimeoutした場合、再試行前に公開page／APIを確認する。
- 公開後の導入確認に失敗したら `PARTIAL` とし、次版の修正を記録して、他言語への影響を評価するまで展開を止める。

## 共通 `0.2.1` バックログ

- [ ] **REL-01** 全公開artifactへパッケージ内licenseを含める。既知の対象はGoとRacket。
- [ ] **REL-02** 対応するmetadata／package commentへ言語別finitefield.org URLを追加する。
- [ ] **REL-03** Juliaを共通バージョンへ合わせる。
- [ ] **REL-04** JavaScriptとBunの最終npm名を決める。
- [ ] **REL-05** DenoのJSR scope／nameを確保・反映する。
- [ ] **REL-06** D、Lua、Nim、V、Crystal、Common Lisp、Racketのモノレポ問題と、新たに判明した問題を解決する。
- [ ] **REL-07** GroovyのMaven Central公開／署名を設定する。
- [ ] **REL-08** Makefileの古いD `dub publish`、Deno `deno.land/x`、Hare `harepm` を別実装タスクで修正する。
- [ ] **REL-09** release commitから全言語testとregistry dry-runを行う。
- [ ] **REL-10** `CHANGELOG.md`、`VERSION`、各manifest、README導入例、Webサイト、進捗表を更新する。
- [ ] **REL-11** review／承認後にのみ不変のrelease tagを作る。

## 作業中の進捗記録テンプレート

対象言語のrunbookへ一時的に追記し、完了時にマスター進捗表へ集約します。

```text
担当者:
開始日時（JST）:
登録先:
パッケージ識別子:
予定バージョン:
dry-runコマンドと結果:
公開／申請操作:
公開URL:
クリーン導入コマンドと結果:
license／repository／website metadataの確認結果:
完了日時（JST）:
残作業:
```

## 参照ファイル

- リポジトリ共通バージョン: `VERSION`
- 共通test／build／公開補助: `Makefile`
- リリース履歴: `CHANGELOG.md`
- 言語実装一覧: `README.md`
- 各言語のmanifest: 各言語ディレクトリ、およびリポジトリ直下の `Package.swift`／`composer.json`
