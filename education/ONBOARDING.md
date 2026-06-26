# ONBOARDING — 演習3日間の動き方

演習開始から成果まとめ終了まで 21 時間の行動指針。時間表記は「演習開始から N時間目」で統一する。
EXERCISES.md と一緒に読む。

## 演習タイムテーブル（N時間目表記）

| 時間目 | 物理日 | フェーズ名 | ゴール |
|---|---|---|---|
| 0h-1h | 1日目 | セットアップ確認 | Doctor 緑、`./mvnw -B -Ph2 verify` 緑、アプリ空起動成功 |
| 1h-2h | 1日目 | 仕様読解＋プロンプト準備 | EXERCISES の MUST を自分の言葉で再記述、TDD プロンプト雛形完成。プロンプトは` prompts-i-used.md`に書いていく。 |
| 2h-4h | 1日目 | 投稿一覧 (M1) | `GET /posts` が DB の行を表示、コミット & push |
| 4h-4.25h | 2日目 | ウォームアップ | 前日コミットのスモークと読み返し |
| 4.25h-6.5h | 2日目 | 投稿作成＋バリデーション (M2/M3) | フォームから投稿登録、異常系で再表示 |
| 6.5h-8h | 2日目 | 投稿詳細＋ヘルスチェック (M4/M5) | `GET /posts/{id}` が動き 404 ハンドリング、actuator/health 緑、`-Pcoverage-day2` (70%) 緑 |
| 8h-9.5h | 2日目 | リファクタ＋カバレッジ80%到達 | JaCoCo 80%、`-Pcoverage-day3 -Pstrict` 緑 |
| 9.5h-11.5h | 2日目 | いいね機能 (S1) | 詳細でいいね操作、冪等性、IP ハッシュ保存 |
| 11.5h-13h | 2日目 | キーワード検索 (S2) | `?q=` で本文 LIKE 検索、空文字フォールバック |
| 13h-13.25h | 3日目 | ウォームアップ | 前日コミットのスモークとセルフレビュー |
| 13.25h-14.5h | 3日目 | 投稿者拡張＋UX微調整 (S3) | アバター色、フォーム改善、エラーハンドラ |
| 14.5h-17h | 3日目 | COULD選択枠 | C1/C2/C3 から 1 つを選んで完了 |
| 17h-19h | 3日目 | 仕上げ＋ブランチ整流化＋プロンプトカタログ作成 | 自分のブランチの diff がレビュー可能状態、`docs/prompts-i-used.md` に 3 件以上記入 |
| 19h-20h | 3日目 | 相互レビュー | 隣の人のブランチ diff に 3 観点でコメント |
| 20h-21h | 3日目 | KPT＋講評＋自己採点 | KPT メモ、15 点ルーブリック自己採点 |

## セットアップ確認 (0-1時間目)

**詳細手順は [student-setup-guide.md](./student-setup-guide.md) を正本とする**。本セクションは「演習中に毎日確認する観点」をまとめたもの。

### Windows と WSL のパス対応（毎日の前提）

| Windows 側 | WSL Ubuntu 側 |
|---|---|
| `C:\workspace\<repo>` | `/mnt/c/workspace/<repo>` |
| `C:\Pleiades\eclipse\eclipse.exe` | （WSL からは直接実行しない） |
| Windows ユーザのホーム `C:\Users\<name>` | `/mnt/c/Users/<name>` |
| WSL ホーム（Ubuntu 内） | `~`（= `/home/<wsl-ユーザ名>`） |

**テスト・Codex・最終検証は WSL 側で実行**。Eclipse はコード編集に加え、アプリの起動・デバッグにも使える（[docs/eclipse-guide.md](../docs/eclipse-guide.md)）。

### 確認チェックリスト（朝一の動作確認）

毎朝 🐧 WSL Ubuntu のリポルートで以下 5 観点を確認する。**手順詳細は [student-setup-guide.md §8](./student-setup-guide.md) を正本とする**（順序もここに揃える）。

1. **Doctor** が `[ OK ]` または `[WARN]` のみ
2. **Oracle XE** が `tsubuyaki-oracle` で healthy
3. **`OPENAI_API_KEY`** が設定済み（値は表示しない）
4. **空アプリ起動 → `/actuator/health`** が `{"status":"UP"}`
5. **`./mvnw -B -Ph2 verify`** が BUILD SUCCESS

Eclipse (Pleiades) を使う場合は、ワークスペースを `C:\workspace\<repo>` にすること。WSL で `./mvnw verify` を回す間は `Project > Build Automatically` をオフにして二重ビルドを避ける（Eclipse からアプリを起動・デバッグする場合の運用は [docs/eclipse-guide.md](../docs/eclipse-guide.md)）。新たな PC でセットアップし直す場合も student-setup-guide §3〜§9 を再走すれば良い。

## 各日朝のウォームアップ (4-4.25時間目、13-13.25時間目)

```bash
bash scripts/doctor.sh --quick
./mvnw -B -Ph2 -Dtest='Sample*' test   # 前日成果のスモーク
git log --oneline -10                  # 前日コミットを読み返す
```

前日のコミットを 1 つ選び、Codex が書いたコードを 1 箇所だけ声に出して説明できるか自分でチェック。

## Codex との協働 (1-19時間目)

Codex CLI の起動、モデル / effort の使い分け、Plan Mode、resume、スラッシュコマンド、
`@` によるファイル指定、1 フェーズあたりの基本ループ、git 操作、セルフチェックは
[Codex CLI 基本操作ガイド](../docs/codex-cli-basics.md) を参照する。

演習中は、各フェーズで Codex に出した主要プロンプトと、その評価（効いた／効かなかった）を
`docs/prompts-i-used.md` に残す。仕上げフェーズで最低 3 件を確定させる。

## 成果まとめ — 相互レビュー＋KPT (19-21時間目)

### 相互レビュー (19-20時間目)

- 各人 5 分で自分の **PR の画面**（fork の `<github-id>` → upstream main）を画面共有
- 隣の人が 3 分でレビューコメント（機能・テスト・コミットの 3 観点）。コメントは PR の各コミット／各行に直接付けられる
- 講師が全体に 1 つだけ「ここ良い」をピックアップ

### KPT＋講評＋自己採点 (20-21時間目)

- KPT (Keep / Problem / Try) を 5 分で書き出す
- 15 点ルーブリック (instructor/rubric.md) で自己採点
- 「Codex を信用しすぎた / しなさすぎた」のハンドサインで距離感を言語化

## 3日完走のコツ

1. **MUST 5 個を 2日目午前までに終わらせる**。SHOULD は必達、COULD は選択必達。
2. **コミットを小さく**。1 機能 = 1 コミット。失敗したら戻し方は [TROUBLESHOOTING.md の Git 安全ガイド](./TROUBLESHOOTING.md#git-操作の安全ガイド) を参照（`git restore` は未コミット変更の破棄、戻したくない変更がある時は先に `git stash`）。
3. **Codex の出力を必ず読む**。理解できないコードはマージしない。
4. **詰まったら H2 に逃げる**。`SPRING_PROFILES_ACTIVE=h2 ./mvnw spring-boot:run`（または Eclipse で H2 起動 → [docs/eclipse-guide.md](../docs/eclipse-guide.md)）で進行は止めない。
5. **講師に質問するときは「何を試して何が起きたか」を最初に**。
6. **各日終わりに作業を push する**。翌日のウォームアップで自分のブランチの diff を読み返すと記憶が定着する。
7. **使ったプロンプトを `docs/prompts-i-used.md` に残す**。仕上げフェーズで整理する時間が短くて済む。

## 禁止事項

- AGENTS.md / .codex/ / instructor/ の編集
- upstream `main` への push（そもそも権限が無い）。fork の `main` への直接 push も避け、push 先は常に自分の `<github-id>` ブランチ
- 他の受講生の fork・ブランチへの push・削除
- `git push --force`（自分のブランチを含め研修中は一律禁止）
- 講師の許可なしに Codex を `--full-auto` に切り替えること
