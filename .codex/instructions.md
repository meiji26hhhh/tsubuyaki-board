# Codex 補足指示 (instructions.md)

このファイルは AGENTS.md の補助。AGENTS.md と矛盾した場合は AGENTS.md が優先される。

## 重要な原則 (毎ターン参照すること)

1. **AGENTS.md を最優先で読む**。研修ルールはそこに集約されている。
2. **テストを先に書く** (TDD)。RED → GREEN → REFACTOR の順を守る。
3. **応答 / コミット / コメントはすべて日本語**。
4. **小さなコミット**。1 PR = 1 ユースケース。200 行超えは分割。
5. **不確実なら質問する**。推測で書かず、推測時は「推測:」と明示する。

## このリポの構造

| パス | 役割 |
|---|---|
| `src/main/java/com/example/butsubutsu/` | 業務コード本体 |
| `src/test/java/com/example/butsubutsu/` | テスト本体 |
| `src/test/java/com/example/butsubutsu/sample/` | TDD 雛形 (最後まで残す、削除禁止) |
| `src/main/resources/db/migration/` | Flyway マイグレーション (Oracle / H2 両対応) |
| `.codex/prompts/` | 共通プロンプト集 (TDD サイクル等) |
| `instructor/` | 講師資料 (受講生は読み取りのみ) |

## 触ってよいパス

凡例: ✅ 自由 / 🟡 受講生確認 / 🛑 物理ブロック (研修ハーネスで reject)

| パス | 読み取り | 書き込み | 削除 |
|---|---|---|---|
| `src/main/java/com/example/butsubutsu/**` | ✅ | ✅ | ✅ (個別ファイルのみ、ディレクトリ再帰削除は 🟡) |
| `src/test/java/com/example/butsubutsu/**` | ✅ | ✅ | ✅ (`sample/` 配下は 🛑) |
| `src/test/java/com/example/butsubutsu/sample/**` | ✅ | 🟡 (テスト雛形なので慎重に) | 🛑 |
| `src/main/resources/**` (templates / static / application*.yml) | ✅ | ✅ | ✅ |
| `src/main/resources/db/migration/**` | ✅ | ✅ (新規 V*.sql 追加) | 🟡 (既存マイグレーション削除は不可) |
| `pom.xml` | ✅ | ✅ (依存追加) | 🛑 (削除不可) |
| `compose.yaml`, `containers/**` | ✅ | 🟡 (要受講生確認) | 🛑 |
| `.github/workflows/**` | ✅ (ro マウント) | 🛑 (ハーネスで ro) | 🛑 |
| `AGENTS.md` | ✅ (ro マウント) | 🛑 | 🛑 |
| `.codex/**` (`.codex/sessions/` を除く) | ✅ (ro マウント) | 🛑 | 🛑 |
| `instructor/**` | ✅ (ro マウント) | 🛑 | 🛑 |
| `tasks/**` | ✅ | ✅ (todo / lessons) | 🟡 |
| `.env` / `.env.*` | 🛑 (`/dev/null` マウントで空) | 🛑 | 🛑 |
| `~/.bashrc` / `~/.bash_history` / `~/.gitconfig` / `~/.profile` | 🛑 (`/dev/null` マウント) | 🛑 | 🛑 |
| `~/.ssh/**` / `*.pem` / `*id_rsa*` | 🛑 (元々マウントされていない) | 🛑 | 🛑 |
| `/etc/**` / `/usr/**` / `/bin/**` / `/sbin/**` | ✅ (システム参照) | 🛑 | 🛑 |

## 研修ハーネス

詳細は [AGENTS.md §7.5](../AGENTS.md) を参照。要点：

- 破壊的コマンド (`rm -rf /`、`git rm -r`、`git reset --hard`、`git clean -fd`、
  `git push --force`、`dd`、`sudo` 等) は **コンテナ内 wrapper が物理 reject**
- 機密ファイル (`.env` 等) は **コンテナマウント層で `/dev/null` 上書き**
- 規範ファイル (`AGENTS.md`、`.codex/`、`instructor/`、`.github/`) は **ro マウント**
- ブロックされたら再試行せず代替手段を提案、受講生に判断を仰ぐ

## 困ったときの対処

- **ビルドが通らない**: `./mvnw -B -Ph2 verify` のエラー全文を読み、最初のエラーから順に対処する。
- **DB に接続できない**: `SPRING_PROFILES_ACTIVE=h2 ./mvnw spring-boot:run` で H2 に逃がしてから受講生と相談する。
- **テストが落ちている**: そのテスト 1 本だけ `./mvnw -Dtest=ClassName#methodName test` で再現させる。
- **何をすべきか分からない**: 受講生に「今のスコープ・受入基準・触ってよいファイルの 3 つを確認したい」と尋ねる。

## 共通プロンプト集

繰り返し使うプロンプトは `.codex/prompts/` 配下にある。

- `tdd-cycle.md`: TDD サイクル 1 回を回す標準フロー
- `controller-skeleton.md`: Controller + Service + Repository のスケルトン生成
- `jpa-entity.md`: JPA Entity + Repository + Flyway 生成
- `review.md`: PR 直前のセルフレビュー (XSS / SQLi / ハードコード)
