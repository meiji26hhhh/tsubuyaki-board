# 講師用 FAQ — 当日詰まったときの即応集

受講生向け FAQ は `../education/TROUBLESHOOTING.md`。こちらは講師が即決するための判断材料。

## 環境系

### Q. 「セットアップ確認」の Doctor で 1 人だけ Podman が立ち上がらない

**即決**: 5 分待っても直らなければ、講師判断で一時的に `--install-codex-host` モードに切り替える。
このモードは Codex devbox ハーネスを通らないため、研修後に通常の `codex-shell` 経路へ戻す。

```bash
bash scripts/setup-wsl.sh --install-codex-host
```

WSL ホストに直 install した Codex CLI で進めさせ、破壊的 Git 操作や `.env` 読み取りをさせないよう講師が立ち会う。Podman の不調は休憩中に調査。

### Q. 1 人だけ Oracle XE が 5 分経っても ready にならない

**即決**: その受講生だけ `application-h2.yml` を default にして「投稿一覧」フェーズを始めさせる。

```bash
export SPRING_PROFILES_ACTIVE=h2
./mvnw spring-boot:run
```

Oracle 接続を確認するのは「リファクタ＋カバレッジ80%到達」フェーズで。

### Q. 全員が Maven Central に到達できない

**疑う**: 社内プロキシ。`~/.m2/settings.xml` にプロキシ設定が要る。

```xml
<settings>
  <proxies>
    <proxy>
      <id>company</id>
      <active>true</active>
      <protocol>http</protocol>
      <host>proxy.example.com</host>
      <port>8080</port>
    </proxy>
  </proxies>
</settings>
```

事前に IT 部門に確認すべき項目。

## Codex の暴走系

### Q. 1 人だけ Codex が `git push --force` しようとした

**即決**: AGENTS.md §7.3.3 の禁止コマンド一覧をその場で読ませる。コンテナ内 Codex の force push は Codex Guard（`git-guard.sh`）が exit 126 で拒否するが、コンテナ外の素の git は通る。Free×private のため GitHub branch protection は使えず（[instructor-setup-guide.md §4](./instructor-setup-guide.md)）、**事前の物理ブロックは無い**。

代わりに以下の手順で復旧：

1. 共有 `main` に入った不正コミットがあれば、講師が手元の clone で `git revert <SHA>` の打ち消しコミットを作り、`main` へ push して戻す（§4 の CI 監視 Workflow が通知してくれる）。canonical なスターターは基幹リポ／講師手元にあるので、最悪は `main` の強制復元も可能。
2. ローカルの作業ツリーは `git stash push -u` で退避し、必要な変更だけ自分の `<github-id>` ブランチに戻す。
3. force push による履歴書き換えは研修手順として許可しない。AGENTS.md §7.3.3「履歴・権限改ざん禁止」を全体に再共有。

### Q. Codex が `application-local.yml` のパスワードをハードコードで書き換えた

**即決**: `git restore src/main/resources/application-local.yml` で戻させ、
`.codex/prompts/review.md` を投げてセルフレビューさせる。
それでも繰り返すなら、その受講生の AGENTS.md にハードコード禁止の例を追記する案を提示。

### Q. Codex が `@Disabled` を貼って RED テストを GREEN に偽装した

**即決**: そのコミットを差し戻させ、AGENTS.md の「失敗テストに `@Disabled` を貼って通すのは絶対禁止」を引用。
当該テストの `@Disabled` を剥がしてやり直しさせる。

## 評価系

### Q. 機能は動いているけどテストがほぼ Codex 任せで本人が読めていない

**判断**: ルーブリック B (テスト網羅) の B2 (Service テスト) で減点。
KPT で「読めないコードはマージしない」を全体に再徹底。

### Q. SHOULD まで完走したが Conventional Commits が壊れている

**判断**: A は満点、B も満点、C で C1 を減点 → 14/15 で合格。
講評で「自動化された機械的な習慣 (commit 規約) は人間が押さえるべき」と伝える。

## トラブル外の判断

### Q. 集中力が切れた受講生が出てきた

**対応**: 各日の中盤 (例えば 6-7 時間目あたり、15 時間目あたり) に 5 分の休憩を強制的に挟む (タイムテーブルに含まれていなくても OK)。
後半に詰めすぎると「いいね機能」「キーワード検索」で品質が落ちる。

### Q. 早く終わった人がいる

**対応**: COULD (タグ機能 / REST API) に進ませる。
他の受講生のブランチ（Compare ビュー）のレビューを担当してもらうのもあり。

### Q. 想定より全体が遅い

**判断**: SHOULD 3 つのうち遅れている 1 つ (典型的には「キーワード検索」または「投稿者拡張」) を加点扱いに変更し、「リファクタ＋カバレッジ80%到達」を濃くする。
ルーブリックの A5 (SHOULD 3 つすべて完了) を「1 つ以上完了」に緩めて運用する案も提示。
