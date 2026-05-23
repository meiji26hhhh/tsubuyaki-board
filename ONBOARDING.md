# ONBOARDING — 演習3日間の動き方

演習開始から成果まとめ終了まで 21 時間の行動指針。時間表記は「演習開始から N時間目」で統一する。
EXERCISES.md と一緒に読む。

## 演習タイムテーブル（N時間目表記）

| 時間目 | 物理日 | フェーズ名 | ゴール |
|---|---|---|---|
| 0h-1h | 1日目 | セットアップ確認 | Doctor 緑、CI 初回緑、アプリ空起動成功 |
| 1h-2h | 1日目 | 仕様読解＋プロンプト準備 | EXERCISES の MUST を自分の言葉で再記述、TDD プロンプト雛形完成 |
| 2h-4h | 1日目 | 投稿一覧 (M1) | `GET /posts` が DB の行を表示、PR 作成 |
| 4h-4.25h | 2日目 | ウォームアップ | 前日 PR のスモークと読み返し |
| 4.25h-6.5h | 2日目 | 投稿作成＋バリデーション (M2/M3) | フォームから投稿登録、異常系で再表示 |
| 6.5h-8h | 2日目 | 投稿詳細＋ヘルスチェック (M4/M5) | `GET /posts/{id}` が動き 404 ハンドリング、actuator/health 緑 |
| 8h-9.5h | 2日目 | リファクタ＋カバレッジ80%到達 | JaCoCo 80%、`-Pcoverage-day3` 緑 |
| 9.5h-11.5h | 2日目 | いいね機能 (S1) | 詳細でいいね操作、冪等性、IP ハッシュ保存 |
| 11.5h-13h | 2日目 | キーワード検索 (S2) | `?q=` で本文 LIKE 検索、空文字フォールバック |
| 13h-13.25h | 3日目 | ウォームアップ | 前日 PR のスモークとセルフレビュー |
| 13.25h-14.5h | 3日目 | 投稿者拡張＋UX微調整 (S3) | アバター色、フォーム改善、エラーハンドラ |
| 14.5h-17h | 3日目 | COULD選択枠 | C1/C2/C3 から 1 つを選んで完了 |
| 17h-19h | 3日目 | 仕上げ＋PR整流化＋プロンプトカタログ作成 | PR がレビュー可能状態、`docs/prompts-i-used.md` に 3 件以上記入 |
| 19h-20h | 3日目 | 相互レビュー | 隣の人の PR に 3 観点でコメント |
| 20h-21h | 3日目 | KPT＋講評＋自己採点 | KPT メモ、15 点ルーブリック自己採点 |

## セットアップ確認 (0-1時間目)

1. **Eclipse (Pleiades) を起動** … ワークスペースは `C:\workspace\<repo>`
2. **Eclipse のビルドを停止** … Project > Build Automatically をオフ
3. **WSL ターミナルを開く** … `cd /mnt/c/workspace/<repo>`
4. **Doctor 実行** …
   ```bash
   bash scripts/doctor.sh
   ```
   すべて `[ OK ]` か `[WARN]` で `[ NG ]` がないこと。NG があれば TROUBLESHOOTING.md。
5. **Oracle XE 起動** …
   ```bash
   bash scripts/start-oracle.sh
   ```
6. **OPENAI_API_KEY** … `export OPENAI_API_KEY=sk-...` (`~/.bashrc` に書いておくと楽)
7. **空アプリ起動** …
   ```bash
   ./mvnw -B -Ph2 spring-boot:run    # H2 ですぐ動く
   # 別ターミナルで:
   curl -s http://localhost:8080/actuator/health
   ```
8. **初回 CI 緑** … `git push` して GitHub の Actions タブで CI が緑になることを確認

## 各日朝のウォームアップ (4-4.25時間目、13-13.25時間目)

```bash
bash scripts/doctor.sh --quick
./mvnw -B -Ph2 -Dtest='Sample*' test   # 前日成果のスモーク
git log --oneline -10                  # 前日コミットを読み返す
```

前日 PR を 1 つ開き、Codex が書いたコードを 1 箇所だけ声に出して説明できるか自分でチェック。

## Codex との協働 (1-19時間目)

### 1 フェーズあたりの基本ループ

```
①  EXERCISES.md でこのフェーズの受入基準を読む
②  feature ブランチを切る  (git switch -c feature/m1-post-list)
③  codex-shell でコンテナに入り、TDD プロンプトを投げる
    (.codex/prompts/tdd-cycle.md をコピペして埋める)
④  Codex がテスト → 実装を回す。生成されたコードを目で読む
⑤  受講者が ./mvnw -B -Ph2 test を回し、緑を確認
⑥  Codex に .codex/prompts/review.md を投げてセルフレビュー
⑦  git add / commit (Conventional Commits) / push
⑧  GitHub で PR を作成し、CI 緑を待つ
⑨  self-merge して main に取り込む
```

### Codex への良い指示の作り方

```
NG: 「いい感じに作って」
NG: 「テストも書いて」
OK: 「`GET /posts` の Controller を、最新 50 件を新着順で返す要件で、
     PostControllerTest を @WebMvcTest で書いて RED → 実装で GREEN → リファクタの順で。
     model 属性は "posts" にする。`th:utext` は使わない。」
```

### 使ったプロンプトの記録 (17-19時間目で整備)

各フェーズで Codex に出した主要なプロンプトと、その評価（効いた／効かなかった）を
`docs/prompts-i-used.md` に残す。仕上げフェーズで最低 3 件を確定させる。

## 成果まとめ — 相互レビュー＋KPT (19-21時間目)

### 相互レビュー (19-20時間目)

- 各人 5 分で PR を画面共有
- 隣の人が 3 分でレビューコメント (機能・テスト・コミットの 3 観点)
- 講師が全体に 1 つだけ「ここ良い」をピックアップ

### KPT＋講評＋自己採点 (20-21時間目)

- KPT (Keep / Problem / Try) を 5 分で書き出す
- 15 点ルーブリック (instructor/rubric.md) で自己採点
- 「Codex を信用しすぎた / しなさすぎた」のハンドサインで距離感を言語化

## 3日完走のコツ

1. **MUST 5 個を 2日目午前までに終わらせる**。SHOULD は必達、COULD は選択必達。
2. **コミットを小さく**。1 機能 = 1 コミット。失敗したら `git restore .` で戻す。
3. **Codex の出力を必ず読む**。理解できないコードはマージしない。
4. **詰まったら H2 に逃げる**。`SPRING_PROFILES_ACTIVE=h2 ./mvnw spring-boot:run` で進行は止めない。
5. **講師に質問するときは「何を試して何が起きたか」を最初に**。
6. **各日終わりに PR を 1 本作る**。翌日のウォームアップで自分の PR を読み返すと記憶が定着する。
7. **使ったプロンプトを `docs/prompts-i-used.md` に残す**。仕上げフェーズで整理する時間が短くて済む。

## 禁止事項

- AGENTS.md / .codex/ / instructor/ の編集
- `main` ブランチへの直 push (CI で拒否)
- `git push --force` (main 系)
- 講師の許可なしに Codex を `--full-auto` に切り替えること
