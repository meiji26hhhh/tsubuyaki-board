# TROUBLESHOOTING — 受講生向け FAQ

困ったらまず `bash scripts/doctor.sh` を実行。それでも分からなければ下記を参照。
緊急ではない Git 操作の安全策は本ページ末尾の[Git 操作の安全ガイド](#git-操作の安全ガイド)も参照。

## セットアップ

### Q1. `wsl --install` が「機能が無効です」で失敗する

🪟 管理者 PowerShell で：

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -All -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -All -NoRestart
```

PC 再起動 → 再度 🪟 管理者 PowerShell で：

```powershell
wsl --install -d Ubuntu-22.04 --no-launch
```

完了後にスタートメニューから「Ubuntu」を起動して初回ユーザ設定。

### Q2. Pleiades の文字化け (MS932 で `.java` が読めない)

`C:\Pleiades\eclipse\eclipse.ini` の末尾に追加して Eclipse 再起動:

```
-Dfile.encoding=UTF-8
```

Eclipse 内 Preferences > General > Workspace > Text file encoding = UTF-8 にする。

### Q3. Eclipse と Maven の二重ビルドで `target/` が壊れる

Eclipse の Project > Build Automatically をオフに。Eclipse はあくまでエディタとして使い、ビルドは WSL の `./mvnw` で。

## Codex

### Q4. `codex-shell` で `OPENAI_API_KEY` 未設定エラー

```bash
export OPENAI_API_KEY=sk-...
codex-shell
```

`~/.bashrc` に書いておくと毎回入れずに済む。

### Q4-2. Codex がコマンド実行で `[codex-guard]` と出して止まる

研修ハーネスがブロックした合図。**そのまま再試行しないこと**。ハーネスは「研修中に必要のない破壊的操作」を物理的に止める仕組み。

```
[codex-guard] rm は研修ハーネスでブロックされました。
理由: システム/機密パスの削除は禁止 (rm -rf /, rm -rf ~, rm -rf . など)
コマンド: rm -rf /workspace
```

このような出力が出たら、以下の順で対応：

1. **Codex に「代替案を出して」と返す**。ハーネスは Codex のためのレールで、迂回する必要はない。
2. それでも必要に見える操作（典型例: 大量のテンポラリファイルの一括削除）は **コンテナを抜けて** WSL 側で自分の手で実行する：
   ```bash
   exit                                          # 📦 コンテナを抜ける
   # 🐧 WSL 側で実行
   rm -rf /mnt/c/workspace/<repo>/target/
   ```
3. 履歴は `/tmp/codex-guard.log`（コンテナ内）で確認可能。何度も同じ拒否が出るなら、プロンプト設計を見直すサイン。

### Q4-3. Codex に `.env` の中身を聞いても答えない

仕様。`/workspace/.env` は研修ハーネスで `/dev/null` 上書きマウントされており、コンテナ内からは「空ファイル」に見える。これは `OPENAI_API_KEY` や DB パスワードが Codex のコンテキストに渡らないための保護機構。

API キーや DB パスワードを操作したい場合は、コンテナを抜けて WSL 側で `.env` を直接編集すること。

### Q5. Codex が大量のファイルを書き換えはじめた

**まず中断、次に状況確認、最後に破棄判断**の順で。

```bash
# 1. Codex 側で Ctrl+C で中断 (📦 コンテナ内、または codex プロセスを kill)

# 2. シェルに戻ったら、まず何が変わったか把握する
git status                 # 変更ファイル一覧
git diff                   # 内容を確認（量が多ければ git diff --stat で件数だけ）

# 3. (オプション) 一部を救いたい場合は退避してから戻す
git stash push -u -m "codex-runaway-$(date +%H%M%S)"
# 後で `git stash list` で確認、`git stash pop` で戻せる

# 4. それでも全部捨てたい場合だけ
git restore .              # 未コミットの変更 (tracked) を全て破棄
git clean -fd              # 新規生成ファイル (untracked) も削除する場合のみ
```

> ⚠️ `git restore .` は**確認ダイアログ無しで全変更を破棄**します。事前に `git status` / `git diff` で内容を必ず確認、惜しい部分があれば `git stash` で退避してから実行。
> ⚠️ `git clean -fd` は `.gitignore` 対象でないファイルが対象。`.env` などは `.gitignore` で除外済なので消えませんが、念のため `-n`（ドライラン）で確認推奨：`git clean -fdn`。

その後、AGENTS.md の「触ってよいパス」をプロンプトに添えて再依頼。

### Q6. Codex が `th:utext` を使ったテンプレートを生成した

AGENTS.md のセキュリティ規約違反。`.codex/prompts/review.md` をかぶせてセルフ修正させる:

```
.codex/prompts/review.md の内容を実行して、現在の diff を XSS / SQLi / ハードコード観点でレビューしてください。
```

## Oracle XE

### Q7. `bash scripts/start-oracle.sh` がタイムアウトする

```bash
podman logs butsubutsu-oracle | tail -n 50
```

`DATABASE IS READY TO USE!` が出ていれば healthcheck の遅れだけ。1 分待ってから:

```bash
podman exec butsubutsu-oracle healthcheck.sh
```

それでもダメなら **H2 に逃がす**:

```bash
SPRING_PROFILES_ACTIVE=h2 ./mvnw spring-boot:run
```

### Q8. 接続時に `ORA-01017: invalid username/password`

`.env` の `ORACLE_APP_PWD` と `application-local.yml` の参照名が一致しているか確認。
コンテナを作り直すと `.env` の値が再反映される:

```bash
podman compose down --volumes && bash scripts/start-oracle.sh
```

### Q9. `H2 vs Oracle` で `-Ph2 verify` だけ落ちる

- `SYSDATE` を使っていないか → `Instant.now()` に置き換える
- ID 採番が `IDENTITY` になっていないか → `@SequenceGenerator` に統一
- 予約語 (USER, DATE 等) をテーブル名・カラム名に使っていないか

## ビルド

### Q10. `./mvnw verify` が Checkstyle 警告で止まる

研修中はデフォルトで `failOnViolation=false` (警告のみ)。
もし fail で止まっている場合は `-Pstrict` を付けていないか確認。

### Q11. JaCoCo の閾値未達で fail

序盤 60%、中盤 70%、仕上げ 80% にスライドする（フェーズ「投稿一覧」「リファクタ＋カバレッジ80%到達」「仕上げ」で段階引き上げ）。デフォルトは序盤 (60%) 設定。

```bash
./mvnw -B -Ph2 -Pcoverage-day2 verify   # 70% に上げる (プロファイル名は内部識別子)
```

## Git / GitHub

### Q12. CRLF / LF の差分が大量に出る

通常は `setup.ps1` が `core.autocrlf=input` を自動設定するので発生しません。別マシンに環境を持ち込んだ場合のみ：

```bash
git config --global core.autocrlf input   # WSL / Mac でも同じ
```

リポ内の `.gitattributes` で `* text=auto eol=lf` を強制しているので、新規ファイルは LF になる。

既存ファイルを LF に揃え直したい場合（破壊操作のため手順厳守）：

```bash
# ⚠️ 危険: 以下は「未コミット変更を全消去」する操作。必ず順序を守る。

# 1. 未コミット変更があるか確認
git status

# 2. 未コミット変更があるなら、まず必ず stash で退避
git stash push -u -m "before-eol-normalize-$(date +%H%M%S)"

# 3. .gitattributes に従って再正規化
git rm --cached -r .       # インデックスを空に (作業ツリーは温存)
git reset --hard           # ⚠️ HEAD の状態に強制リセット (この時点で何も変更が残らないはず)
git add -A                 # 再 add で .gitattributes ルールが適用される
git commit -m "chore: normalize line endings to LF"

# 4. 退避していた場合は戻す
git stash pop              # コンフリクトしたら手動マージ
```

> ⚠️ `git reset --hard` は **作業ツリーとインデックスを HEAD に合わせて破棄**します。未コミットの修正は全て失われます。退避（`git stash`）を必ず先に。
> ⚠️ チームで作業中なら、本操作の前に `git fetch` で remote の状態を取得し、コンフリクトを最小化。研修中は自分専用リポなので影響は自分のみ。

### Q13. Classroom Assignment URL で「You don't have access」と出る

- 自分の GitHub アカウントが正しく Organization に招待されているか
- メールに届く Organization の招待を Accept したか（GitHub の Notifications で確認可能）
- SAML SSO 必須の Organization なら、ブラウザで Organization トップを開いて SSO 認証を済ませる
- それでもダメなら講師に **自分の GitHub ID** を伝えて、Organization 側で seat 状態を確認してもらう

---

## Git 操作の安全ガイド

「捨てる」「戻す」「退避する」の使い分けの早見表。**未コミット変更がある時は必ず `git status` で確認してから**。

### ケース別フロー

| やりたいこと | 推奨コマンド | 注意 |
|---|---|---|
| 今の変更を一時退避（後で戻したい） | `git stash push -u -m "<理由>"` | `-u` で新規ファイルも含む。後で `git stash pop` |
| 1 ファイルだけ変更を破棄 | `git restore <file>` | tracked ファイルのみ。新規ファイルは消えない |
| 全ファイルの未コミット変更を破棄 | `git restore .` | ⚠️ 戻せない。事前に `git diff` 確認 |
| ステージング（`git add`）を取り消す | `git restore --staged <file>` | 作業ツリーの変更は残る |
| 直前のコミットメッセージだけ修正 | `git commit --amend` | push 済みなら force 必要 → 避ける |
| 直前のコミットを取り消したい（変更は残す） | `git reset --soft HEAD^` | 変更は staging に残る |
| 直前のコミットを完全取り消し | `git reset --hard HEAD^` | ⚠️ 変更も消える。先に stash 推奨 |
| push 済みのコミットを打ち消す | `git revert <commit>` | 新規の打ち消しコミットを作る安全な方法 |
| 新規ファイル（untracked）も消したい | `git clean -fd` | ⚠️ 先に `git clean -fdn`（ドライラン）で確認 |
| ブランチごとなかったことにしたい | `git switch main && git branch -D feature/xxx` | ローカルだけ。push 済みは別操作 |

### 鉄則

1. **破壊操作の前に必ず `git status` と `git diff` で内容を確認**
2. **惜しい変更があれば必ず `git stash push -u` で退避**してから破壊操作
3. **`git push --force`（main 系）は禁止**（[AGENTS.md §7.3](../AGENTS.md)）
4. **完全に詰まったら、リポ自体を Template から再生成**したほうが安全（後述の「最後の手段」参照）

### stash の使い方クイック

```bash
git stash push -u -m "実験中-2026-05-24"   # 退避（-u で新規ファイルも含む）
git stash list                              # 退避一覧
git stash show -p stash@{0}                 # 中身を diff で見る
git stash pop                               # 最新の stash を戻す（同時に削除）
git stash apply stash@{1}                   # 戻すだけ（削除しない）
git stash drop stash@{0}                    # 退避を削除
```

---

## 最後の手段

- 環境を破壊した気がする → `bash scripts/setup-wsl.sh --rollback` → 再セットアップ
- リポを壊した気がする → 自分のリポを Settings から delete → Classroom Assignment URL を再度踏んで Template から再生成
- 何もかも分からない → 講師に「何を試して何が起きたか」を 3 行で報告する
