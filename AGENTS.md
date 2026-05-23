# AGENTS.md — 社内つぶやきボード Codex 規範

このリポジトリで作業する Codex CLI 向けの規範書。最優先で参照すること。
補足は `.codex/instructions.md` を参照。

## 1. このリポについて

### 1.1 目的とゴール

AI 駆動開発研修 (3 日間) の演習パート (計 21 時間) で、受講生が Codex CLI と協働して
「社内つぶやきボード」 (X風ミニ SNS) を完走させるためのテンプレ。
演習: 19 時間 (0-19 時間目)、成果まとめ: 2 時間 (19-21 時間目)。
完走条件: MUST 5 項目 + SHOULD 3 項目 + COULD 1 項目選択 がブラウザで動き、
CI が緑で、Repository / Service / Controller それぞれ 1 本以上のテストがあり、
JaCoCo カバレッジ 80% 以上、`docs/prompts-i-used.md` が提出されている状態。

### 1.2 技術スタック

| 領域 | 採用 |
|---|---|
| Language | Java 21 |
| Framework | Spring Boot 3.4.x |
| View | Thymeleaf |
| Persistence | Spring Data JPA + Flyway |
| DB (ローカル) | Oracle DB XE 21c (Podman / gvenzl/oracle-xe) |
| DB (CI / 軽量) | H2 メモリ (MODE=Oracle) |
| Build | Maven 3.9.x (Maven Wrapper) |
| Test | JUnit 5 + Mockito + AssertJ + MockMvc |
| Coverage | JaCoCo (序盤 60% → 中盤 70% → 仕上げ 80%、フェーズ「投稿一覧」「リファクタ＋カバレッジ80%到達」「仕上げ」で段階引き上げ) |
| Quality | Checkstyle + SpotBugs |

### 1.3 ディレクトリ地図

- `src/main/java/com/example/butsubutsu/` 業務コード
- `src/test/java/com/example/butsubutsu/sample/` TDD 雛形 (**削除禁止**)
- `src/main/resources/db/migration/` Flyway (Oracle / H2 両対応 SQL)
- `.codex/prompts/` 共通プロンプト
- `instructor/` 講師資料 (**読むだけ、書き込み禁止**)

## 2. コミュニケーション規約

### 2.1 応答言語

すべて日本語。エラーメッセージは原文 + 日本語要約で示す。

### 2.2 思考の出し方

提案 → 根拠 → 差分の順で示す。長文は箇条書きにする。
冗長な相槌や前置きは省く。

### 2.3 不確実性の扱い

推測のときは行頭に「推測:」と明示し、検証コマンドを併記する。
「たぶん」「だと思う」は避け、確認手段を提示する。

## 3. 開発フロー

### 3.1 TDD サイクル

**RED → GREEN → REFACTOR** を 1 PR 内で完結させる。

1. 失敗するテストを 1 本だけ書く (Red)
2. テストが通る最小実装を書く (Green)
3. 重複・命名・抽象度をリファクタリングする (Refactor)

失敗テストに `@Disabled` を貼って通すのは絶対禁止。

### 3.2 ブランチ戦略

- 作業は `feature/<課題番号>-<要約>` (例: `feature/m1-post-list`)
- `main` は常にグリーン
- `main` への直 push は不可。必ず PR 経由。

### 3.3 Conventional Commits

```
<type>(<scope>): <要約>

<本文 (任意)>
```

`type`: feat / fix / test / refactor / docs / chore / perf / ci
`scope` 例: `post`, `like`, `infra`, `ci`
本文は日本語可。72 文字で改行。

実コマンド例（受講生向けの詳細な git ワークフローは [education/ONBOARDING.md の基本ループ](./education/ONBOARDING.md#git-操作の具体例) を参照）：

```bash
git add src/main/java/com/example/butsubutsu/controller/PostController.java
git commit -m "feat(post): GET /posts で最新50件を新着順に返す"
```

### 3.4 PR の単位

1 PR = 1 ユースケース。差分 200 行を超える場合は分割する。

## 4. テスト規約

### 4.1 カバレッジ閾値

- 「投稿一覧」完了時: 60% / 「リファクタ＋カバレッジ80%到達」完了時: 80% / 「仕上げ」完了時: 80% 維持 (行カバレッジ・JaCoCo)
- `./mvnw -B -Ph2 -Pcoverage-day3 verify` で 80% gate を有効化 (プロファイル名は内部識別子。意味は「仕上げ段階の 80% gate」)

### 4.2 テスト種別

| アノテーション | 用途 |
|---|---|
| `@DataJpaTest` | Repository。H2 起動、エンティティとクエリ |
| `@WebMvcTest` | Controller。Service をモック化、HTTP / ビュー検証 |
| `@SpringBootTest` | 統合。最小限。1 PR 内で増やしすぎない |
| 純 JUnit + Mockito | Service。Spring を起動しない |

### 4.3 テスト命名

`機能_状態_期待結果` 形式。例:

- `投稿一覧_DB空のとき_空配列をビューに渡す`
- `投稿作成_本文空文字_400を返しエラーを再表示する`

`@DisplayName` も日本語で。

## 5. セキュリティ規約

### 5.1 ハードコード禁止

接続情報・API キー・パスワードは `application-*.yml` か環境変数経由。

```java
// NG
String pwd = "Training#2026";

// OK
@Value("${app.admin.password}") String pwd;
```

### 5.2 SQL インジェクション保護

`@Query` での文字列連結は禁止。bind 変数を使う。

```java
// NG
@Query("SELECT p FROM Post p WHERE p.author = '" + name + "'")

// OK
@Query("SELECT p FROM Post p WHERE p.author = :name")
List<Post> findByAuthor(@Param("name") String name);
```

### 5.3 XSS 保護

Thymeleaf は **`th:text` を使う**。`th:utext` は禁止。

```html
<!-- NG -->
<p th:utext="${post.body}">…</p>

<!-- OK -->
<p th:text="${post.body}">…</p>
```

### 5.4 CSRF / 認証

Spring Security の CSRF は有効維持。フォームには `_csrf` トークンを必ず含める。

## 6. コード品質

### 6.1 静的解析

`./mvnw -B -Ph2 verify` で Checkstyle / SpotBugs が走る。
研修中は warning 表示。`-Pstrict` で error 扱い (PR レビュー時に推奨)。

### 6.2 命名規約

- クラス名: 名詞 (PascalCase)
- メソッド名: 動詞 + 名詞 (camelCase)
- 定数: UPPER_SNAKE_CASE
- パッケージ: 全小文字

### 6.3 例外設計

- チェック例外は最小限。ビジネス例外は専用クラスを作る。
- `catch (Exception e)` は禁止 (Checkstyle で警告)。
- スローしたまま握り潰さない。ログに残すか上位に伝搬する。

## 7. Codex 操作ルール

### 7.1 承認モード

`.codex/config.toml` の `approval_policy = "on-failure"`。
危険なコマンドは `on-request` に切り替える。

### 7.2 ネットワーク

許可: Maven Central / GitHub / api.openai.com のみ。
それ以外は受講生に確認する。

### 7.3 禁止コマンド

本リストは Codex devbox の研修ハーネス (`containers/codex-devbox/bin/*-guard.sh` +
`scripts/run-codex.sh` のマスクマウント) で**物理的にもブロック**されている。
ハーネスに頼らずプロンプト層でも遵守する。

#### 7.3.1 機密ファイル読み取り禁止

- `.env` / `.env.local` / `.env.*` (本リポ用の設定ファイル)
- `~/.bashrc` / `~/.bash_history` / `~/.profile` / `~/.gitconfig`
- `~/.ssh/**` / `*id_rsa*` / `*id_ed25519*` / `*.pem`
- `*credentials*` / `*secret*` を含むファイル名

> `/workspace/.env` は `/dev/null` 上書きマウントされており、Codex が読んでも空文字列が返る。
> 値を引き出そうと別経路 (printenv 等) を試行しないこと。

#### 7.3.2 破壊的ファイル操作禁止

- `rm -rf /` 系 (`/` / `~` / `.` / `..` / `/etc` / `/usr` / `/workspace` 等を対象に取るもの)
- `rm` で `.env` / `AGENTS.md` / `.codex/**` / `instructor/**` / `sample/**` を消す操作
- `git rm -r` / `git rm -rf` (再帰削除)
- `git clean -fd` / `git clean -fdx` (untracked 削除)
- `git reset --hard` (作業ツリー破壊)
- `git checkout -- .` / `git restore .` (全変更破棄。単発ファイルへの `git restore <file>` は許可)
- `dd` / `mkfs` / `fdisk` / `mount` / `umount`

#### 7.3.3 履歴・権限改ざん禁止 / guard 迂回禁止

- `git push --force` / `-f` / `--force-with-lease` (main 系・feature 系問わず一律)
- `git config --global` / `--system` (ホスト ~/.gitconfig 改ざん)
- `git filter-branch` / `git update-ref --delete` (履歴改ざん)
- `chmod -R 777` (再帰フル権限)
- `chmod` / `chown` をシステム配下 / 機密ファイルへ適用
- **絶対パスでの guard 迂回** — 例: `/bin/rm -rf /workspace`、`/usr/bin/git push --force` のように
  guard wrapper を経由せず `/bin/*` / `/usr/bin/*` を直接呼び出す行為。研修ハーネスの中核に
  対する明白な攻撃で、見つけ次第セッションを中断する。
- `bash -c "..."`、`eval`、`source` で guard 禁止コマンドを文字列経由で実行する迂回

#### 7.3.4 権限昇格・任意コード実行禁止

- `sudo` 全般 (コンテナ内 codex の NOPASSWD sudo は研修ハーネスで剥奪済)
- `curl URL | bash` / `wget URL | sh` (任意コードのリモート実行)
- 受講生の `~/.codex` 配下を書き換える操作

#### 7.3.5 DB 破壊禁止

- `DROP USER` / `DROP TABLE` / `DROP SCHEMA` (Flyway migration 内のロールバック相当は要相談)

### 7.4 自動化してよい範囲

- テスト実行 (`./mvnw test`)
- ビルド (`./mvnw -B -Ph2 verify`)
- フォーマット適用
- feature ブランチへのコミット
- 自分が作った PR ブランチへの push (force ではない通常 push のみ)
- `git rm <file>` の単発ファイル削除 (再帰削除 `-r` は不可)
- `git restore <file>` の単発ファイル変更破棄

### 7.5 ハーネスでブロックされたとき

研修ハーネス (`[codex-guard]` プレフィクス付きエラー、exit code 126) でコマンドが
拒否された場合、それは「研修中に必要のない破壊操作」と判定された結果。

#### あなた (Codex) の行動

1. **再試行しない**。同じコマンドを angle change しても同じ結果になる。
2. **代替手段を提案する**:
   - `git reset --hard` → `git stash push -u` を提案
   - `git clean -fd` → 個別 `rm <file>` を提案
   - `rm -rf <dir>` → ディレクトリ内の必要ファイルを残す形で個別削除を提案
3. **受講生に確認**: 「破壊操作が必要な場合は、研修進行を止めないため受講生本人が
   コンテナ外 (WSL) で実行することをお勧めします。実行してよろしいですか？」と尋ねる。
4. **強行突破しない**: PATH 操作 / `bash -c` / `eval` で wrapper を回避しようとしない。
   ハーネス迂回試行はすべて記録される (`/tmp/codex-guard.log`)。

## 8. 困ったとき

### 8.1 Doctor の使い方

環境異常を疑ったら `bash scripts/doctor.sh` を最初に実行する。

### 8.2 質問テンプレ

```
- 何をしようとしている?
- 何を試した?
- 何が起きた? (ログのどの行か)
- どのファイル / どの行か
```

### 8.3 良い指示 vs 悪い指示

```
NG: 「いい感じに作って」
OK: 「`GET /posts` を WebMvcTest で書いてから実装。受入基準は…」
```
