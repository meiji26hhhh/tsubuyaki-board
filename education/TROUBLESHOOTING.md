# TROUBLESHOOTING — 受講生向け FAQ

困ったらまず `bash scripts/doctor.sh` を実行。それでも分からなければ下記を参照。
緊急ではない Git 操作の安全策は本ページ末尾の[Git 操作の安全ガイド](#git-操作の安全ガイド)も参照。

## セットアップ

### Q1-1. `wsl --install` が「機能が無効です」で失敗する

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

### Q1-2. Pleiades の文字化け (MS932 で `.java` が読めない)

`C:\Pleiades\eclipse\eclipse.ini` の末尾に追加して Eclipse 再起動:

```
-Dfile.encoding=UTF-8
```

Eclipse 内 Preferences > General > Workspace > Text file encoding = UTF-8 にする。

### Q1-3. Eclipse と Maven の二重ビルドで `target/` が壊れる

WSL で `./mvnw verify` を回す間は Eclipse の `Project > Build Automatically` をオフにして二重ビルドを避ける。Eclipse からアプリを起動・デバッグする運用は [docs/eclipse-guide.md](../docs/eclipse-guide.md) を参照（その場合は Build Automatically を ON のままで構わない）。

### Q1-4. ./mvnw ~ のコマンドで「permitted系のエラー」になる

ユーザー権限が足りずにエラーになっています。コマンドをsudoで実行してください。
その他のubuntuコマンドでも「permitted」のエラーがでたら、sudoを試してください。

```bash
sudo ./mvnw -B -Ph2 verify
# 初回はパスワードを求められます。
```

### Q1-5. セットアップ1でwingetに失敗する

何らかの理由でwingetコマンドが実行できない場合があります。その場合は、wingetでインストール予定のソフトウェアを個別に手動インストールします。
下記、公式サイトからそれぞれインストーラーをDLし、インストールしてください(すべてデフォルト設定でOK)。

- [Git](https://git-scm.com/)
- [Podman Desktop](https://podman-desktop.io/downloads)
- [Windows ターミナルのインストール | Microsoft Learn](https://learn.microsoft.com/ja-jp/windows/terminal/install)


## Codex

### Q2-1. `codex-shell` で `OPENAI_API_KEY` 未設定エラー

```bash
read -rsp 'OPENAI_API_KEY: ' OPENAI_API_KEY
printf '\nexport OPENAI_API_KEY=%q\n' "$OPENAI_API_KEY" >> ~/.bashrc
source ~/.bashrc
codex-shell
```

値は画面や履歴に表示しない。`~/.bashrc` に書いておくと毎回入れずに済む。

コンテナ起動時に entrypoint が `OPENAI_API_KEY` から Codex の認証ファイル（`auth.json`）を自動生成する（現行の Codex CLI は環境変数を直接は認証に使わないため）。キーを差し替えた場合も `codex-shell` に入り直せば反映される。起動バナーの「Codex 認証」が「失敗」のときは、コンテナ内で `printenv OPENAI_API_KEY | codex login --with-api-key` を実行する。

### Q2-2. Codex がコマンド実行で `[codex-guard]` と出して止まる

研修ハーネスがブロックした合図。**そのまま再試行しないこと**。ハーネスは「研修中に必要のない破壊的操作」を止める多層防御です。

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

### Q2-3. Codex に `.env` の中身を聞いても答えない

仕様。`/workspace/.env` は研修ハーネスで `/dev/null` 上書きマウントされており、コンテナ内からは「空ファイル」に見える。これは `OPENAI_API_KEY` や DB パスワードが Codex のコンテキストに渡らないための保護機構。

API キーや DB パスワードを操作したい場合は、コンテナを抜けて WSL 側で `.env` を直接編集すること。

### Q2-4. Codex が大量のファイルを書き換えはじめた

**まず中断、次に状況確認、最後に破棄判断**の順で。

```bash
# 1. Codex 側で Ctrl+C で中断 (📦 コンテナ内、または codex プロセスを kill)

# 2. シェルに戻ったら、まず何が変わったか把握する
git status                 # 変更ファイル一覧
git diff                   # 内容を確認（量が多ければ git diff --stat で件数だけ）

# 3. (オプション) 一部を救いたい場合は退避してから戻す
git stash push -u -m "codex-runaway-$(date +%H%M%S)"
# 後で `git stash list` で確認、`git stash pop` で戻せる

# 4. 戻す対象をファイル単位で決める
git restore src/main/java/com/example/tsubuyaki/controller/PostController.java
# 新規ファイルを消す場合も、git status で確認した上で個別に rm <file>
```

> ⚠️ 全変更の一括破棄や untracked の一括削除は、研修中の通常手順では使いません。必要に見える場合は講師に相談し、まず `git stash push -u` で退避してください。

その後、AGENTS.md の「触ってよいパス」をプロンプトに添えて再依頼。

### Q2-5. Codex が `th:utext` を使ったテンプレートを生成した

AGENTS.md のセキュリティ規約違反。`.codex/prompts/review.md` をかぶせてセルフ修正させる:

```
.codex/prompts/review.md の内容を実行して、現在の diff を XSS / SQLi / ハードコード観点でレビューしてください。
```

## Oracle XE

### Q3-1. `bash scripts/start-oracle.sh` がタイムアウトする

```bash
podman logs tsubuyaki-oracle | tail -n 50
```

`DATABASE IS READY TO USE!` が出ていれば healthcheck の遅れだけ。1 分待ってから:

```bash
podman exec tsubuyaki-oracle healthcheck.sh
```

それでもダメなら **H2 に逃がす**:

```bash
SPRING_PROFILES_ACTIVE=h2 ./mvnw spring-boot:run
```

> Eclipse から H2 で起動する場合は [docs/eclipse-guide.md](../docs/eclipse-guide.md) §5。

### Q3-2. 接続時に `ORA-01017: invalid username/password`

`.env` の `ORACLE_APP_PWD` と `application-local.yml` の参照名が一致しているか確認。
コンテナを作り直すと `.env` の値が再反映される:

```bash
# ⚠️ Oracle のデータボリューム (作成した表とデータ) も削除されます
bash scripts/stop-oracle.sh --purge && bash scripts/start-oracle.sh
```

### Q3-3. `H2 vs Oracle` で `-Ph2 verify` だけ落ちる

- `SYSDATE` を使っていないか → `Instant.now()` に置き換える
- ID 採番が `IDENTITY` になっていないか → `@SequenceGenerator` に統一
- 予約語 (USER, DATE 等) をテーブル名・カラム名に使っていないか

## ビルド

### Q4-1. `./mvnw verify` が Checkstyle 警告で止まる

研修中はデフォルトで `failOnViolation=false` (警告のみ)。
もし fail で止まっている場合は `-Pstrict` を付けていないか確認。

### Q4-2. JaCoCo の閾値未達で fail

序盤 60%、中盤 70%、仕上げ 80% にスライドする（フェーズ「投稿一覧」「リファクタ＋カバレッジ80%到達」「仕上げ」で段階引き上げ）。デフォルトは序盤 (60%) 設定。

```bash
./mvnw -B -Ph2 -Pcoverage-day2 verify   # 70% に上げる (プロファイル名は内部識別子)
```

## Git / GitHub

### Q5-1. CRLF / LF の差分が大量に出る

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
git add --renormalize .    # 作業ツリーを破壊せず、改行コードの正規化差分を作る
git commit -m "chore: normalize line endings to LF"

# 4. 退避していた場合は戻す
git stash pop              # コンフリクトしたら手動マージ
```

> ⚠️ 改行コードの正規化で一括破棄コマンドは使いません。差分を `git diff --staged` で確認してから commit してください。

### Q5-2. Fork できない / 自分の fork が見つからない / PR が作れない

**Fork できない・自分の fork が見当たらない:**

- ブラウザで研修リポ（upstream `https://github.com/TokyoItSchool-dev/tsubuyaki-board`）を開き、右上の「**Fork**」を押したか。公開リポなので招待は不要
- Fork 後の URL は `https://github.com/<github-id>/tsubuyaki-board`。自分のアバター →「Your repositories」にも出る
- 「You already have a fork」と出る場合はすでに Fork 済み。その既存 fork をそのまま使えばよい（再 Fork 不要）

**自分の fork を clone できない（404 / 認証エラー）:**

- clone 先が **自分の fork（`<github-id>/...`）** の URL か（upstream `TokyoItSchool-dev/...` ではない）。`git remote -v` で確認
- ユーザ名は GitHub ユーザ名、パスワードは PAT（`ghp_...`）か（[student-setup-guide §3-3](./student-setup-guide.md)。`public_repo` スコープ・未失効を確認）

**PR が作れない / 向きがおかしい:**

- PR の **base** が `TokyoItSchool-dev/tsubuyaki-board` の `main`、**compare** が `<github-id>/tsubuyaki-board` の `<github-id>` ブランチになっているか（[student-setup-guide §9-4](./student-setup-guide.md)）
- 先に fork へ push してあるか（push 済みのブランチでないと PR の compare に出ない）
- それでもダメなら講師に **自分の GitHub ID と fork の URL** を伝えて確認してもらう

### Q5-3. 環境チェックで `git config --global user.name が未設定` の NG が出る

コミットの作者情報（`user.name` / `user.email`）が WSL 側に未設定の状態。`セットアップ3_APIキー設定.bat` をもう一度ダブルクリックすれば対話形式で設定できます（設定済みの API キーは空 Enter でそのまま維持されます）。

手動で設定する場合は 🐧 Ubuntu で：

```bash
git config --global user.name "<github-id>"          # GitHub ユーザ名を推奨
git config --global user.email "<メールアドレス>"     # GitHub に登録したものを推奨
```

---

## Git 操作の安全ガイド

「捨てる」「戻す」「退避する」の使い分けの早見表。**未コミット変更がある時は必ず `git status` で確認してから**。

### ケース別フロー

| やりたいこと | 推奨コマンド | 注意 |
|---|---|---|
| 今の変更を一時退避（後で戻したい） | `git stash push -u -m "<理由>"` | `-u` で新規ファイルも含む。後で `git stash pop` |
| 1 ファイルだけ変更を破棄 | `git restore <file>` | tracked ファイルのみ。新規ファイルは消えない |
| 複数ファイルの変更を退避 | `git stash push -u -m "<理由>"` | 戻す可能性がある場合の第一選択 |
| ステージング（`git add`）を取り消す | `git restore --staged <file>` | 作業ツリーの変更は残る |
| 直前のコミットメッセージだけ修正 | `git commit --amend` | push 済みなら force 必要 → 避ける |
| 直前のコミットを取り消したい（変更は残す） | `git reset --soft HEAD^` | 変更は staging に残る |
| 直前のコミットを打ち消す | `git revert HEAD` | push 済みでも安全。履歴を書き換えない |
| push 済みのコミットを打ち消す | `git revert <commit>` | 新規の打ち消しコミットを作る安全な方法 |
| 新規ファイル（untracked）を消したい | `rm <file>` | `git status` で確認したファイルを個別に消す |
| 実験用サブブランチを捨てたい | `git switch <github-id> && git branch -D <github-id>/実験` | ローカルだけ。自分の名前空間のブランチに対してのみ。push 済みは別操作 |

### 鉄則

1. **変更を捨てる前に必ず `git status` と `git diff` で内容を確認**
2. **惜しい変更があれば必ず `git stash push -u` で退避**
3. **`git push --force` は禁止**（自分のブランチを含め一律。[AGENTS.md §7.3](../AGENTS.md)）。**`main`（fork の main も upstream も）への直接 push も禁止**（push 先は常に自分の `<github-id>` ブランチ。upstream には push 権限も無い）
4. **完全に詰まったら、自分のブランチを `main` から切り直す**のが安全（後述の「最後の手段」参照）

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

- 環境を破壊した気がする → `bash scripts/setup-wsl.sh --rollback`（JDK / Maven / Podman / codex-devbox イメージを削除する。git リポジトリと自分のコードには影響しない）→ `セットアップ2_Ubuntu準備.bat` から再セットアップ
- 自分のブランチを壊した気がする → `git switch main` → `git switch -c <github-id>-retry origin/main` で fork の `main` から作業ブランチを切り直す（fork や `main` は消さない）。ローカル clone ごと作り直したい場合は、フォルダを消して [student-setup-guide §4-2](./student-setup-guide.md) から**自分の fork**を clone し直す
- 何もかも分からない → 講師に「何を試して何が起きたか」を 3 行で報告する

## 仮想環境セットアップの最後の手段

- 仮想環境での構築を諦めて、Codex CLI または Codex Desktop をローカルインストールして使用します。
- インストール方法は講師に相談してください。
- この場合、仮想環境によるハーネスがなくなってしまうため、コマンド実行の承認には十分に注意してください。

⚠ 「Codexの承認方法」で、フルアクセスは使用禁止です。必ず「承認を依頼」を選択します。

