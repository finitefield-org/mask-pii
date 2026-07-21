# mask-pii 公式パッケージ登録ロードマップ

策定日: 2026-07-21（JST）

対象リリース: `0.2.1`

この文書は、mask-piiの全言語ページを先に整備し、各実装を共通の`0.2.1`リリース候補として検証した後、公式またはエコシステム標準のパッケージレジストリ／カタログへ順番に登録するための実行計画です。

言語ごとの登録先、パッケージ識別子、現在の状態、公開URL、個別runbookは[`PUBLISH.md`](PUBLISH.md)を正本とします。この文書には全体の順序、依存関係、リリースゲート、サイトとの同期方法だけを記載し、言語別手順を重複させません。

## 1. 意思決定

### 1.1 採用する進め方

今後の未公開パッケージは、原則として`0.2.0`ではなく共通の`0.2.1`を初回公開版とします。すでに公開済みの`0.2.0`および既存タグは変更せず、必要な修正を`0.2.1`へ積み上げます。

作業順序は次のとおりです。

1. 不可逆な新規公開を一時停止する。
2. finitefield.orgの全36言語ページについて、不足するインストール手順を棚卸しする。
3. 英語ページを正本として完成させ、全ロケールへ反映してデプロイする。
4. 全実装のソース、パッケージ定義、README、ライセンス、Webリンクを`0.2.1`向けに整える。
5. リリース候補を一つのコミットに固定し、テストと配布物検査を完了する。
6. 共通タグとエコシステム固有タグを、同じ承認済みコミットから作成する。
7. レジストリ／カタログへの公開を一件ずつ実行し、クリーン導入を確認する。
8. 公開済みページへ切り替え、`PUBLISH.md`へ公開URLと確認日を記録する。

### 1.2 この順序を採用する理由

- Go、Swift、PowerShellなどでは、`v0.2.0`作成後にライセンス、ソース、テスト、文書の修正が必要になっている。
- 公開済みの版は上書きできない、または上書きすべきでないため、修正前の成果物を先に登録すると追加のpatch releaseが必要になる。
- 言語ページのインストール欄が空、README参照だけ、または未公開レジストリのコマンドを示す状態では、登録後の利用者が導入方法を判断できない。
- 可逆な作業である文書、メタデータ、テストをまとめて先に進め、不可逆な公開だけを直列化すると、手戻りと版の不一致を抑えられる。

### 1.3 明示的な非目標

- すべての言語へ同一のパッケージ名を強制しない。
- 公式または標準的な登録先がない言語に、無理に第三者レジストリを割り当てない。
- 外部サービスの審査完了を、`0.2.1`タグ作成の必須条件にはしない。
- 公開済みの`v0.2.0`、`go/v0.2.0`、Julia `0.1.0`などを削除、移動、再作成しない。
- 一括公開コマンドで複数レジストリへ同時に公開しない。

## 2. 文書とリポジトリの責務

| 対象 | 正本 | 記録する内容 |
| --- | --- | --- |
| 全体の実行順序 | `PUBLISH_ROADMAP.md` | フェーズ、ゲート、依存関係、停止条件、ロールバック |
| 言語別進捗 | `PUBLISH.md` | 登録先、識別子、状態、タスク、公開URL、確認日 |
| 実装と配布物 | mask-piiリポジトリ | ソース、manifest、README、license、test、release tag |
| 言語別Webページ | finitefield-siteリポジトリ | 英語正本、翻訳、template、生成テスト、デプロイ |
| 共通版 | `VERSION` | リポジトリ全体の基準バージョン |
| 変更履歴 | `CHANGELOG.md` | `0.2.1`の利用者向け変更点 |

finitefield-site側の主な対象は、`web/content/entities/articles/oss/mask-pii/<language>/`、対応するtemplate、および生成テストです。サイト側には既存の作業中変更が存在する可能性があるため、着手時に別タスクまたは専用ブランチで変更範囲を分離します。

## 3. 進捗モデル

`PUBLISH.md`の`DONE`、`PARTIAL`、`READY`、`BLOCKED`、`N/A`は公開全体の状態として維持します。これとは別に、作業中は次のゲートを記録します。

| ゲート | 意味 | 通過条件 |
| --- | --- | --- |
| `S0 INVENTORIED` | 現状を記録済み | URL、登録先、識別子、現在版、不足項目が判明している |
| `S1 SITE_READY` | Web正本が準備済み | 英語ページの状態、導入方法、例、リンクが検証済み |
| `S2 ARTIFACT_READY` | 配布物を作成可能 | testとregistry dry-runが成功し、必須ファイルを収録する |
| `S3 RELEASED` | 不変sourceが存在 | 承認済みコミットと必要なタグがremoteに存在する |
| `S4 SUBMITTED` | 外部登録を実行済み | upload、申請、PR、catalog追加のいずれかを実行した |
| `S5 VERIFIED` | 公開利用を確認済み | 公開サービスからクリーン導入し、最小例が成功した |

各言語の`S0`から`S5`までを順番に進めます。審査型レジストリでは`S4`のまま待機できますが、`S5`になるまで`DONE`にはしません。登録先がない`N/A`言語は、Webページと不変Git sourceの確認をもって`S3`相当まで進めます。

ゲートは`PUBLISH.md`のマスター進捗表にある「次の作業／根拠」欄の先頭へ`Gate: S0`の形式で記録します。`SITE-01`では同文書へ「言語ページ進捗表」を追加し、言語、route、Web状態、現在の導入元、不足項目、確認日を管理します。これにより、登録状態とWeb整備状態を別々の表へ重複転記せず追跡します。

## 4. 不可逆操作の凍結

この文書の`SITE-06`、`REL-09`、`REL-10`が完了し、release commitのreview Findingsがゼロになるまで、release tagの作成とpushを停止します。`REL-11`が完了するまで、本番レジストリ／カタログに対する次の操作も停止します。

- 新規package versionのuploadまたはpublish
- レジストリへの初回登録
- カタログへの掲載申請またはPull Request
- Swift Package Index、DUBなどGitタグを監視するサービスへの登録

次の可逆な準備は継続できます。

- アカウント作成と承認待ち
- MFA、OIDC、APIキー、名前空間の準備
- パッケージ名の空き確認
- manifest、README、license、test、dry-runの修正
- candidate、sandbox、local registryなど本番公開を伴わない検証
- Webページの作成と、「公開予定」状態でのデプロイ

APIキー、token、パスワード、OTP、署名秘密鍵は、この文書、Issue、チャット、リポジトリ、シェル履歴へ記録しません。

## 5. 言語ページのコンテンツ契約

### 5.1 必須情報

全36言語の英語ページに、少なくとも次を含めます。

1. 言語名と実装の概要。
2. 配布状態。
3. 現在実行できるインストール方法。
4. `import`、`require`、`source`などの読み込み方法。
5. emailとphoneの少なくとも一方を含む最小実行例。
6. 例に対応する期待結果。
7. masking対象がopt-inであることの説明。
8. GitHubの実装ディレクトリとREADMEへのリンク。
9. licenseへのリンク。
10. 公開済みの場合は公式パッケージページ、版、確認日。
11. 未公開の場合は予定識別子、予定版、利用可能になる条件。

### 5.2 配布状態の表示規則

サイトでは次の状態を区別し、利用できないコマンドを通常のインストール手順として表示しません。

| 状態 | 主インストール欄 | 予定コマンド |
| --- | --- | --- |
| `published` | 公式レジストリから実行できるコマンド | 不要 |
| `planned` | 現在動作するGit／source導入方法 | 「0.2.1公開後」の注記付きで別表示可 |
| `git-only` | tagまたはcommitを固定したGit導入方法 | レジストリ名を表示しない |
| `source-only` | copy、source、collection pathなど | レジストリ名を表示しない |
| `unavailable` | インストール不可の理由 | 実行コマンドを表示しない |

公開後の切り替えは、各翻訳ファイルを手作業で変更するのではなく、可能な限り非翻訳の状態値、版、URL、コマンドを一か所で変更して生成します。

### 5.3 翻訳規則

- `en.json`を意味上の正本とする。
- package ID、version、URL、コマンド、コード、期待結果は翻訳しない。
- 見出し、説明、状態ラベル、注意書きだけを翻訳対象とする。
- 英語版で必須キーと技術内容を確定してから全ロケールへ展開する。
- 既存ロケールを一部だけ更新した状態で完了としない。
- 翻訳完了判定にはfinitefield-siteの生成テストと、対象ページの未翻訳／欠落件数ゼロを使用する。

### 5.4 Webページの検証条件

- 36言語すべてにrouteと英語entityがある。
- installationのコード欄が空文字、空白のみ、空コードブロックのいずれでもない。
- 「READMEを参照してください」だけで導入説明を終えていない。
- ページの状態と`PUBLISH.md`の状態が矛盾しない。
- 公式レジストリURL、GitHub URL、README、licenseがHTTP成功または有効な内部リンクになる。
- コマンドは対応するREADMEまたはmanifestと一致する。
- デスクトップとモバイルでcode blockが読め、コピー操作が利用できる。
- locale fallbackによって英語以外のページだけ古いコマンドへ戻らない。

## 6. サイト整備タスク

- [x] **SITE-01** 全36言語について、route、英語entity、現在のインストール欄、README、登録先、公開状態、不足キーを棚卸しし、結果を`PUBLISH.md`へ反映する。
- [x] **SITE-02** `published`、`planned`、`git-only`、`source-only`、`unavailable`を表現できる共通コンテンツ構造を決定し、コマンドとURLを翻訳本文から分離する。
- [x] **SITE-03** 全36言語の英語ページをコンテンツ契約どおりに完成させる。コマンドと最小例はmask-piiリポジトリのREADME、manifest、testを根拠にする。
- [x] **SITE-04** 36言語のroute数、必須キー、空インストール欄、placeholderだけの説明、リンク、版、識別子を検査する自動テストを追加し、成功させる。
- [ ] **SITE-05** 英語正本を全ロケールへ展開し、翻訳対象の残件数を全言語・全ロケールでゼロにする。
- [ ] **SITE-06** finitefield.orgへデプロイし、代表ページと全routeのHTTP応答、表示、内部リンク、locale切替を確認する。未公開packageは`planned`表示のままとする。

`SITE-03`と`SITE-04`は言語単位で並行できます。`SITE-05`は英語のキー構造を確定した後に開始し、`SITE-06`はすべてのサイトテスト成功後に実行します。

## 7. 0.2.1リリース候補の作成

### 7.1 バージョン適用範囲

- `VERSION`を`0.2.1`へ更新する。
- versionを持つ全manifest、module metadata、rockspec、recipe、生成対象を`0.2.1`へそろえる。
- source配布だけの言語も`v0.2.1`の同じsource snapshotへ含める。
- 公開済みpackageは、`0.2.0`を維持したまま新しい`0.2.1`を追加公開する。
- レジストリ固有の制約で版表現が異なる場合は、同値関係を`PUBLISH.md`へ記録する。

### 7.2 リリースを阻害するもの

次はタグ作成前に解消します。

- testまたはregistry dry-runの失敗
- package ID、scope、座標の未決定
- 配布物のREADMEまたは再配布可能なlicenseの欠落
- manifestとsource内versionの不一致
- packageから参照する存在しないWebページ
- 公開物へのsecret、credential、cache、private artifactの混入
- monorepoのサブディレクトリを登録先が解決できず、採用構成も未決定の状態
- `0.2.1`向けの導入例が実際のexport／module pathと一致しない状態

次はタグ作成を阻害しませんが、当該言語の`S4`以降を待機させます。

- PAUSE、Hackage、Centralなど外部アカウントの承認待ち
- カタログ管理者のreview待ち
- レジストリのindex反映待ち
- 人間によるMFA、OTP、署名、最終publish操作待ち

### 7.3 既存共通タスクとの対応

実装は`PUBLISH.md`の`REL-01`から`REL-11`を使用します。特に次の依存関係を守ります。

| 先行条件 | 後続タスク | 理由 |
| --- | --- | --- |
| `SITE-03` | `REL-02`、`REL-10` | 言語別URLと導入例を確定してmetadataへ反映するため |
| `SITE-06` | `REL-09`完了承認 | release前に利用者向けページが存在することを保証するため |
| `REL-01`〜`REL-08` | `REL-09` | 修正後の成果物をまとめて検証するため |
| `REL-09`、`REL-10` | `REL-11` | test、dry-run、版、変更履歴、Web同期後にだけタグを作るため |

### 7.4 リリース候補ゲート

`REL-11`へ進む前に、次を一つのrelease commitで確認します。

- [ ] `git status --short`が意図したrelease変更だけを示す。
- [ ] `VERSION`、manifest、source内versionの検査が成功する。
- [ ] 対応toolchainを利用できる全言語testが成功する。
- [ ] 全registry dry-run、package build、archive一覧検査が成功する。
- [ ] package単体で展開し、repository外の暗黙ファイルへ依存しない。
- [ ] README、license、homepage、repository、issues、言語別Web URLを確認した。
- [ ] `CHANGELOG.md`に`0.2.1`の変更と互換性を記録した。
- [ ] secret scanと不要ファイル検査が成功する。
- [ ] `SITE-06`が完了し、未公開パッケージが`planned`表示になっている。
- [ ] review Findingsがゼロになっている。

toolchainを導入できず未実行の検査は、成功扱いにしません。対象言語、理由、代替検査、実行予定者を記録し、release承認者が例外を明示的に判断します。

## 8. タグ作成規則

1. release commitのSHAを記録する。
2. annotatedな共通タグ`v0.2.1`を作る。
3. Goは同じcommitへモノレポ用タグ`go/v0.2.1`を作る。
4. 他のエコシステムで固有tag形式が必要な場合も、同じcommitを指すことを確認する。
5. localとremoteのtagが同じobjectを指すことを確認する。
6. tag push後は移動、上書き、再利用しない。
7. tag作成後に欠陥が判明した場合は公開を止め、修正版を次のpatch versionへ送る。

タグを監視する登録先に、未承認のタグを先に認識させないようにします。Git tagだけで配布する言語については、`v0.2.1`を不変sourceとします。

## 9. 公式パッケージ登録の実行順序

### 9.1 Wave A: タグ／source認識型

- Go Module Proxy／pkg.go.dev
- Swift Package Index

タグの形式、license検出、build matrixを確認します。公開済みページが存在するGoでは、初回掲載ではなく`0.2.1`の品質改善として扱います。

### 9.2 Wave B: upload型で準備が進んでいるもの

- PowerShell Gallery
- CPAN／PAUSE
- Hackage

APIキーや資格情報を環境変数または資格情報ストアから渡し、一件ずつuploadします。candidate機能がある場合は本番公開より先に使用します。

### 9.3 Wave C: PR／カタログ審査型

- Julia General Registry
- opam repository
- Nim package list
- Hare Project Library
- Quicklisp
- Crystalの選定済み検索インデックス

不変の`0.2.1` source URLとchecksumを確定してから申請します。複数の審査は並行できますが、各申請の状態とURLを個別に記録します。

### 9.4 Wave D: 構成・名前空間対応が大きいもの

- npmのJavaScript版とBun版
- JSRのDeno版
- DUBのD版
- Maven CentralのGroovy版
- LuaRocksのLua版
- CRANのR版
- Racket Package Catalog
- VPMのV版

scope、署名、モノレポ、ライセンス、policy対応を完了したものからWave BまたはCと同じ手順で公開します。Wave D内の全言語がそろうまで、準備済み言語を待たせる必要はありません。

### 9.5 すでに掲載済みのpackage

Rust、Ruby、Python、PHP、Elixirは初回掲載タスクを作りません。共通`0.2.1`の新versionを公開する場合はrelease更新として扱い、既存の掲載確認済みURLを維持します。GoとJuliaは`PARTIAL`改善runbookを使用します。

## 10. 1パッケージごとの公開トランザクション

各言語について、次の順序を崩しません。

1. `PUBLISH.md`の対象タスク、識別子、予定版、公開先を確認する。
2. release tagと配布物のchecksumまたは内容を確認する。
3. dry-runを同じtoolchainと設定で再実行する。
4. 人間が対象package、版、scope、公開先を最終確認する。
5. publish、upload、申請またはPR作成を一度だけ実行する。
6. timeout時は再実行せず、公開APIとpackage pageを確認する。
7. 公開サービスからクリーン環境へ導入する。
8. READMEと同じ最小masking例を実行する。
9. package pageの版、license、repository、finitefield.orgリンクを確認する。
10. Webページを`planned`から`published`へ切り替え、版と公式URLを設定する。
11. Webの生成テストを実行し、デプロイする。
12. `PUBLISH.md`の状態、公開URL、確認日、担当、残作業を更新する。

公開後の検証が失敗した場合は`DONE`にせず`PARTIAL`とし、他言語の公開を停止して共通原因の有無を確認します。

## 11. 登録フェーズの共通タスク

- [ ] **REG-01** `SITE-06`と`REL-09`〜`REL-11`の完了を確認し、本番レジストリ／カタログへの公開凍結を解除する。
- [ ] **REG-02** release commit、`v0.2.1`、固有tag、checksum、成果物一覧が記録済みで、remoteのtagが承認済みcommitを指すことを再確認する。
- [ ] **REG-03** Wave Aを一件ずつ公開・検証し、`PUBLISH.md`を更新する。
- [ ] **REG-04** Wave Bを一件ずつ公開・検証し、`PUBLISH.md`を更新する。
- [ ] **REG-05** Wave Cの申請を行い、review状態を追跡して採用後に検証する。
- [ ] **REG-06** Wave Dのblockerを言語単位で解消し、準備ができた順に公開・検証する。
- [ ] **REG-07** 掲載済みpackageの`0.2.1`更新を必要な登録先へ公開し、既存URLで最新版を確認する。
- [ ] **REG-08** 全25登録対象と11件の`N/A`を再集計し、公開URL、版、確認日、残件数を確定する。

## 12. 並行化と担当分離

安全に並行できる作業:

- 言語単位のWeb英語原稿作成
- 言語単位のmanifest、license、README、test修正
- 外部アカウントの申請と承認待ち
- 異なるレジストリ向けのdry-run
- 審査型カタログのreview対応

直列に行う作業:

- 共通versionの最終変更
- release commitの承認
- release tagの作成とpush
- 同一packageへのpublish再試行
- 本番レジストリへのupload
- 公開後のWeb状態切り替えと進捗確定

同じファイルや共通manifestを複数作業者が変更する場合は、先に担当範囲を分けます。特にルートの`VERSION`、`CHANGELOG.md`、`Makefile`、`Package.swift`、`composer.json`、`PUBLISH.md`はrelease調整担当が統合します。

## 13. 停止条件と復旧

次のいずれかが発生したら、新しいpackageの公開を停止します。

- 公開版とtagのsourceが一致しない。
- クリーン導入または最小例が失敗する。
- licenseが検出されず、文書や再配布が制限される。
- 別所有者の名前空間へ誤って公開した可能性がある。
- secretまたは不要なprivate fileが成果物に含まれる。
- 複数言語に影響するAPI動作差、version不一致、Web誤記が見つかる。

復旧時は、公開サービスの状態を先に確認し、同じpublish操作を盲目的に再実行しません。公開物を削除、yank、unlist、deprecateする必要がある場合は、利用不能、security、法的問題などの根拠と代替版を記録し、個別の明示承認を得ます。通常のmetadata修正は次のpatch versionで行います。

## 14. 完了条件

このロードマップは、次をすべて満たしたときに完了です。

1. 全36言語ページのインストール欄が、現在利用できる方法を示している。
2. 全ロケールで必須コンテンツがそろい、技術的なコマンド差分がない。
3. `0.2.1`のrelease commit、共通tag、必要な固有tagが不変で存在する。
4. 25件の登録対象がすべて`DONE`である。
5. 11件の`N/A`言語に、Git／sourceからの再現可能な導入方法がある。
6. 公開済みpackageは公式サービスからクリーン導入でき、最小例が成功する。
7. package pageとfinitefield.orgが相互に到達でき、版、識別子、状態が一致する。
8. `PUBLISH.md`の集計、マスター進捗表、runbookチェックボックスが最新である。
9. 未解決事項は、所有者、理由、再開条件を持つ個別タスクとして残っている。

外部審査待ちがある場合、登録プロジェクト全体は完了扱いにしません。ただし、内部作業がすべて完了し、申請URLと再開条件がある状態を中間マイルストーン「審査待ち」として明確に報告できます。

## 15. 実行記録テンプレート

言語ごとの結果は`PUBLISH.md`の該当runbookへ次の形式で記録します。

```text
言語:
担当者:
ゲート: S0 / S1 / S2 / S3 / S4 / S5
予定版:
release commit:
tag:
package識別子:
公式登録先:
dry-runと結果:
公開／申請操作:
申請または公開URL:
クリーン導入と結果:
最小例と結果:
license／repository／website確認:
Web状態: planned / published / git-only / source-only / unavailable
確認日時（JST）:
残作業と再開条件:
```
