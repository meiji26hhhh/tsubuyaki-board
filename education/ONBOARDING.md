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

**ビルド・テスト・Codex は全て WSL 側で実行**。Eclipse はエディタ用途のみ。

### 確認チェックリスト（朝一の動作確認）

毎朝 🐧 WSL Ubuntu のリポルートで以下 5 観点を確認する。**手順詳細は [student-setup-guide.md §8](./student-setup-guide.md) を正本とする**（順序もここに揃える）。

1. **Doctor** が `[ OK ]` または `[WARN]` のみ
2. **Oracle XE** が `tsubuyaki-oracle` で healthy
3. **`OPENAI_API_KEY`** が設定済み（値は表示しない）
4. **空アプリ起動 → `/actuator/health`** が `{"status":"UP"}`
5. **`./mvnw -B -Ph2 verify`** が BUILD SUCCESS

Eclipse (Pleiades) を使う場合は、ワークスペースを `C:\workspace\<repo>` にし `Project > Build Automatically` をオフにすること（ビルドは WSL の `./mvnw` 経由）。新たな PC でセットアップし直す場合も student-setup-guide §3〜§9 を再走すれば良い。

## 各日朝のウォームアップ (4-4.25時間目、13-13.25時間目)

```bash
bash scripts/doctor.sh --quick
./mvnw -B -Ph2 -Dtest='Sample*' test   # 前日成果のスモーク
git log --oneline -10                  # 前日コミットを読み返す
```

前日のコミットを 1 つ選び、Codex が書いたコードを 1 箇所だけ声に出して説明できるか自分でチェック。

## Codex との協働 (1-19時間目)

### 1 フェーズあたりの基本ループ

```
①  EXERCISES.md でこのフェーズの受入基準を読む
②  自分の作業ブランチ <github-id> にいることを確認 (git branch --show-current)
    ※ ブランチは student-setup-guide §6 で作成済み。課題ごとに分けたい人は
       任意で <github-id>/m1-post-list のようにサブブランチを切ってもよい
③  codex-shell でコンテナに入り、TDD プロンプトを投げる
    (.codex/prompts/tdd-cycle.md をコピペして埋める。codex 内では /tdd-cycle でも呼べる)
④  Codex がテスト → 実装を回す。生成されたコードを目で読む
⑤  受講生が ./mvnw -B -Ph2 test を回し、緑を確認
⑥  Codex に .codex/prompts/review.md を投げてセルフレビュー (codex 内では /review)
⑦  ローカルで ./mvnw -B -Ph2 verify が緑なことを確認
⑧  git add / commit (Conventional Commits) / push（自分の fork のブランチへ）
    → fork に push すると §9-4 で作った PR の差分が自動更新される。これで 1 ユースケース完了
       （PR は講師レビュー用。マージはしない / upstream main には取り込まない）
```

### git 操作の具体例

⑦〜⑧に対応。「Codex 任せにせず、自分の手で実行する」のが原則。コミット履歴は受講生自身の名前で残す。

```bash
# 🐧 Ubuntu (リポルートで)

# 1. 何が変わったか確認
git status
git diff                          # 内容を読んで「自分で説明できる」か自問

# 2. ステージング (ファイル単位)
git add src/main/java/com/example/tsubuyaki/controller/PostController.java
git add src/test/java/com/example/tsubuyaki/controller/PostControllerTest.java
# (まとめて: git add src/  でも可。ただし意図しないファイルを巻き込みやすい)

# 3. ステージ済みの内容を再確認
git diff --staged

# 4. Conventional Commits 形式でコミット (AGENTS.md §3.3)
git commit -m "feat(post): GET /posts で最新50件を新着順に返す"

# 5. push
git push                          # §9-2 で -u 済みなのでブランチ名省略可
```

#### push したら 1 ユースケース完了（⑧）

本研修では、**自分の fork のブランチに push した時点で 1 ユースケース完了**です。push すると、講師レビュー用の PR（student-setup-guide §9-4 で作成）の差分が自動更新されます。upstream の `main` には誰もマージしません（`main` はスターターのまま温存）。

```bash
# push 前にローカルで verify が緑であることを必ず確認
./mvnw -B -Ph2 verify

# 自分の fork のブランチへ push（§9-2 で -u 済みならブランチ名は省略可）
git push
```

#### コミット前 & PR セルフチェックの観点

各ユースケースを push する前（および PR の説明欄を更新するとき）に、以下の観点で自己点検します。仕上げ（17-19h）と相互レビュー（19-20h）でもこの観点を使います。

- **実装した MUST / SHOULD / COULD**: どの受入基準（M1〜／S1〜／C1〜）を満たしたか言えるか
- **テスト結果**: `./mvnw -B -Ph2 verify` が緑か、JaCoCo カバレッジは何 % か
- **Codex に出した主要プロンプト**: 効いた／効かなかったプロンプトを `docs/prompts-i-used.md` に控える
- **ハマったポイントと対処**: 例「H2 で `SYSDATE` が動かず `Instant.now()` に修正」
- **次やるなら何**: もう 1 日あれば取り組みたいことを 1〜3 行

#### 自分の変更を PR で見返す

§9-4 で作った PR を開くと、スターター（upstream の main）からの自分の全変更が「**Files changed**」タブに diff で出ます。相互レビュー（19-20h）ではこの **PR の画面**を共有し、各行・各コミットにコメントを付け合います。

> 💡 PR をまだ作っていない人は [student-setup-guide.md §9-4](./student-setup-guide.md) で作成してください。fork の `<github-id>` ブランチ → upstream main の Draft PR です。
>
> 💡 コミットメッセージや差分量の規約は AGENTS.md §3 を必ず参照。
>
> 💡 push 前に間違いに気づいた場合の戻し方は [TROUBLESHOOTING.md の Git 安全ガイド](./TROUBLESHOOTING.md#git-操作の安全ガイド) を参照。

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
4. **詰まったら H2 に逃げる**。`SPRING_PROFILES_ACTIVE=h2 ./mvnw spring-boot:run` で進行は止めない。
5. **講師に質問するときは「何を試して何が起きたか」を最初に**。
6. **各日終わりに作業を push する**。翌日のウォームアップで自分のブランチの diff を読み返すと記憶が定着する。
7. **使ったプロンプトを `docs/prompts-i-used.md` に残す**。仕上げフェーズで整理する時間が短くて済む。

## 禁止事項

- AGENTS.md / .codex/ / instructor/ の編集
- upstream `main` への push（そもそも権限が無い）。fork の `main` への直接 push も避け、push 先は常に自分の `<github-id>` ブランチ
- 他の受講生の fork・ブランチへの push・削除
- `git push --force`（自分のブランチを含め研修中は一律禁止）
- 講師の許可なしに Codex を `--full-auto` に切り替えること
