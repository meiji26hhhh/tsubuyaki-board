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
| `instructor/` | 講師資料 (受講者は読み取りのみ) |

## 触ってよいパス

| パス | 動作 |
|---|---|
| `src/main/java/com/example/butsubutsu/**` | 自由に編集 |
| `src/test/java/com/example/butsubutsu/**` | 自由に編集 (sample/ は削除しない) |
| `src/main/resources/**` (templates / static / db/migration / application*.yml) | 自由に編集 |
| `pom.xml` | 依存追加は OK、プラグイン削除は要確認 |
| `compose.yaml`, `containers/**` | 編集前に必ず受講者に確認 |
| `.github/workflows/**` | 編集前に必ず受講者に確認 |
| `AGENTS.md`, `.codex/**`, `instructor/**` | 編集禁止 |

## 困ったときの対処

- **ビルドが通らない**: `./mvnw -B -Ph2 verify` のエラー全文を読み、最初のエラーから順に対処する。
- **DB に接続できない**: `SPRING_PROFILES_ACTIVE=h2 ./mvnw spring-boot:run` で H2 に逃がしてから受講者と相談する。
- **テストが落ちている**: そのテスト 1 本だけ `./mvnw -Dtest=ClassName#methodName test` で再現させる。
- **何をすべきか分からない**: 受講者に「今のスコープ・受入基準・触ってよいファイルの 3 つを確認したい」と尋ねる。

## 共通プロンプト集

繰り返し使うプロンプトは `.codex/prompts/` 配下にある。

- `tdd-cycle.md`: TDD サイクル 1 回を回す標準フロー
- `controller-skeleton.md`: Controller + Service + Repository のスケルトン生成
- `jpa-entity.md`: JPA Entity + Repository + Flyway 生成
- `review.md`: PR 直前のセルフレビュー (XSS / SQLi / ハードコード)
