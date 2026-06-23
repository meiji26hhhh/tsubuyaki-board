# 講師向けセットアップガイド

AI 駆動開発研修 3 日コースを開催する**講師が、研修開始の 1 週間前までに 1 回だけ実施する**作業手順です。

受講生向けは [../education/student-setup-guide.md](../education/student-setup-guide.md) を参照。

---

## 配布アーキテクチャ全体像

```
[基幹リポ (private)]          [公開リポ upstream]              [受講生ごとの fork]
TokyoItSchool-dev/            <owner>/tsubuyaki-board          <github-id>/tsubuyaki-board
tsubuyaki-board.git          (公開・main はロック)            (各自が Fork して作る)
     │                            │                                 │
     │  内容を 1 回 push          │   受講生が Fork (招待不要)       │
     │ ─────────────────►        │ ───────────────────────────────►│
     │  (講師がスターター用意)    │                                 │
     │                            │ ◄────────────────────────────── │
     │                            │   fork のブランチ → PR で提案    │
     │                            │   upstream main はロック         │
```

---

## 0. このガイドが扱うこと・扱わないこと

**扱う:**
- 研修リポを公開（public）リポジトリとして用意する手順（基幹リポの内容を 1 回 push）
- 受講生に Fork してもらう運用（招待は不要）
- upstream `main` をブランチ保護でロックする手順（+ Codex Guard）
- 講師自身のローカル環境キッティング
- 当日運営のリンク集（個別の運営要綱は [timetable.md](./timetable.md) と [rubric.md](./rubric.md)）

**扱わない:**
- 研修内容そのもの（→ [../EXERCISES.md](../EXERCISES.md)）
- 21 時間のタイムテーブル詳細（→ [../education/ONBOARDING.md](../education/ONBOARDING.md), [timetable.md](./timetable.md)）
- Codex への規範（→ [../AGENTS.md](../AGENTS.md)）

---

## 1. 前提アカウント・権限

| 項目 | 用途 | 確認方法 |
|---|---|---|
| GitHub アカウント | 全操作 | `gh auth status` で認証済 |
| 公開リポの所有者権限 | upstream リポの公開・ブランチ保護設定 | 個人アカウント、または Org 管理者として `<owner>/tsubuyaki-board` を作成・設定できる |
| 基幹リポへの read 権限 | 公開リポの初期化（`git clone` → push） | https://github.com/TokyoItSchool-dev/tsubuyaki-board にアクセス可 |
| OpenAI 課金済アカウント | 自分の Codex CLI 動作確認 | `OPENAI_API_KEY` 発行済、課金残高あり |
| `gh` CLI | スクリプト実行 | `gh --version` で 2.x 系 |
| ローカルマシン | 環境キッティング検証 | Windows 11 + WSL2 が動く |

---

## 2. 研修リポの所有者（owner）を決める

公開リポ `<owner>/tsubuyaki-board` を置く場所を決めます。Organization は**任意**です（fork モデルでは受講生の招待が不要なため、Org の請求・メンバー管理は要りません）。

| 選択肢 | `<owner>` | 補足 |
|---|---|---|
| 講師の個人アカウント | 講師の GitHub ユーザ名 | 最も手軽。公開リポなので誰でも Fork できる |
| 既存の Organization | Org 名 | すでに Org がある場合。Free プランで問題ない |
| 新規 Organization | 新 Org 名 | 必須ではない。作るなら https://github.com/account/organizations/new |

> 本研修では**採点・合否判定に GitHub Actions の CI を使いません**（受講生・講師ともローカル `./mvnw -B -Ph2 verify` で基本検証し、仕上げは `./mvnw -B -Ph2 -Pcoverage-day3 -Pstrict verify` で合否判定）。CI を使わないので、どの owner でも Free プランで足ります。
>
> **公開リポなら `main` のブランチ保護が Free で使えます**（§4）。受講生は各自の fork で作業し、upstream には直接 push できないため、`main` は二重に守られます。

> 💡 以降このガイドでは upstream リポを `<owner>/tsubuyaki-board` と表記します。配布時に実際の owner 名へ読み替えてください（受講生ガイドの `<owner>` と一致させる）。

---

## 3. 研修リポを公開（public）リポジトリとして用意

upstream となる**公開リポを 1 個**作り、基幹リポのスターター内容を 1 回 push します。受講生はこれを Fork して使うので、Classroom のような個人リポ自動生成や template 化は不要です。

### 3-1. 基幹リポをローカルに用意

```bash
cd /tmp   # 作業用ディレクトリ、後で削除可
git clone https://github.com/TokyoItSchool-dev/tsubuyaki-board.git
cd tsubuyaki-board
```

> 💡 既に講師マシンに clone 済みの基幹リポがあればそれを使ってもよい。重要なのは「配布したい状態（main の最新）」が手元にあること。

### 3-2. 公開リポ（public）を作成

```bash
gh auth status   # 認証済か確認

gh repo create <owner>/tsubuyaki-board \
    --public \
    --description "AI 駆動開発研修 (Codex × Spring Boot) 演習リポジトリ（受講生は各自 Fork して作業）"
```

> 💡 既存のリポを後から公開へ切り替える場合は `gh repo edit <owner>/tsubuyaki-board --visibility public`（または Settings → 最下部 Danger Zone → Change visibility → Public）。

### 3-3. スターター内容を公開リポへ push

配布したいのは「main の最新スナップショット」です。`--mirror` は使わず（基幹リポの全ブランチ・全履歴を受講生に見せる必要はない）、main を通常 push します。

```bash
# 公開リポを remote として追加（origin は基幹リポなので別名 upstream にする）
git remote add upstream https://github.com/<owner>/tsubuyaki-board.git

# main を公開リポへ push
git push upstream main

# 配布したいタグがあれば一緒に（無ければ省略可）
# git push upstream --tags
```

> 💡 受講生に配るブランチは `main` 1 本で十分です。受講生は各自このリポを Fork し、自分の fork の `main` から `<github-id>` ブランチを切ります。

### 3-4. 検証

```bash
gh repo view <owner>/tsubuyaki-board --json visibility,defaultBranchRef
```

期待出力:

```json
{
  "visibility": "PUBLIC",
  "defaultBranchRef": {"name": "main"}
}
```

> 💡 `visibility` が `PUBLIC` であることが重要です（fork と Free のブランチ保護が使える前提）。`isTemplate` は不要（`false` のままで OK）。

---

## 4. upstream `main` をブランチ保護でロック（+ Codex Guard）

公開リポでは **branch protection が Free で使える**ため、upstream の `main` を「**誰も直接 push できない**」状態にできます。加えて受講生は各自の fork で作業し upstream への push 権限を持たないため、`main` は実質的に二重で守られます。

### 4-1. ブランチ保護で `main` をロック（手順）

GitHub の **Settings → Branches → Add branch protection rule**（または新しい **Rulesets**）で `main` を保護します。どこまで厳格にするかは**講師の裁量**ですが、最低限おすすめは次の設定です。

- **Branch name pattern**: `main`
- ☑ **Require a pull request before merging**（PR 必須 = 直接 push を禁止。承認数は 0 でも可）
- ☑ **Block force pushes**（force push 禁止。既定で含まれることが多い）
- ☑（任意）**Do not allow bypassing the above settings** / **Restrict deletions**

`gh` で設定する例（PR 必須＝直接 push 禁止の最小構成。JSON を `--input` で渡す）:

```bash
cat <<'JSON' | gh api -X PUT "repos/<owner>/tsubuyaki-board/branches/main/protection" --input -
{
  "required_status_checks": null,
  "enforce_admins": false,
  "required_pull_request_reviews": { "required_approving_review_count": 0 },
  "restrictions": null
}
JSON
```

> 💡 **厳格さは講師が選びます**。`enforce_admins` を `true` にすると講師自身も直接 push 不可（PR 必須）になります。線形履歴・削除禁止・必須レビュー数なども必要に応じて足してください。最小構成（PR 必須で直接 push を防ぐだけ）でも、受講生の事故 push をブロックする目的は果たせます。
>
> 💡 そもそも**受講生は upstream への push 権限を持たない**（fork で作業する）ので、ブランチ保護は「講師自身の誤操作」や「将来 collaborator を足した場合」への保険という位置づけです。

### 4-2. Codex Guard（コンテナ内 Codex 経路）

`containers/codex-devbox/bin/git-guard.sh` が、コンテナ内 Codex の `main` への push（fork の main 含む）と force push を exit 126 で拒否します。受講生が Codex に作業させても、`main` を直接汚す経路はコンテナ側でも塞がれています（詳細は [codex-guard-guide.md](./codex-guard-guide.md)）。

---

## 5. 受講生に Fork してもらう（招待は不要）

fork モデルでは**受講生の招待・collaborator 追加は一切不要**です。公開リポなので、受講生は自分で Fork するだけで作業を始められます。講師がやることは「リポ URL を伝える」「ブランチ名規約と PR 作成を伝える」だけです。

### 5-1. 受講生の GitHub ユーザ名（採点・識別用）

push 権限の付与には不要になりましたが、**採点・ブランチ識別のために GitHub ユーザ名（小文字）を集めておく**と便利です（申込フォーム / 事前アンケートなど）。当日でも、各自が作成する PR の作成者から把握できます。

### 5-2. 受講生への案内事項

研修初日に受講生へ次を伝えます（受講生ガイド §2・§3 と対応）:

- **研修リポ（upstream）URL** `https://github.com/<owner>/tsubuyaki-board`
- 「このリポを **Fork** して、自分の fork を clone すること」（招待・承認の手順は無い）
- 「clone 後は自分の GitHub ユーザ名で `git switch -c <github-id> origin/main`（fork の main 起点）してから作業すること」
- 「初回 push 後、fork のブランチ → upstream main へ **Draft PR** を 1 本作ること（講師レビュー用・マージしない）」

> 💡 招待メールの送付・承認待ち・collaborator 状況の確認といった作業が**すべて不要**になりました。受講生は到着後すぐ Fork できます。

### 5-3. リハーサル（テストアカウント検証）は §7 で実施

テストアカウントを使った「Fork → clone → `<github-id>` ブランチ作成 → `./mvnw -B -Ph2 verify` → Draft PR」の確認は [§7 リハーサル](#7-リハーサルテストアカウントでの動作確認) で行います。**先に §6 で講師マシンを整備**（Temurin JDK 21 / Maven / Podman 導入）してからでないと、`./mvnw -B -Ph2 verify` が JDK 未導入で失敗します。

---

## 6. 講師自身のキッティング

受講生と同じ環境を講師マシンに構築します（質問対応・トラブル再現用）。順序は受講生ガイドと同じ「Windows キッティング → 再起動 → WSL → リポ clone」です。

### 6-1. 講師リポを clone（🪟 管理者 PowerShell）

WSL2 機能はまだ有効化されていないので、**Windows 側の PowerShell** で clone する（受講生ガイド §4-2 と同じ流れ）：

```powershell
New-Item -ItemType Directory -Force -Path "C:\workspace" | Out-Null
cd C:\workspace
git clone https://github.com/<owner>/tsubuyaki-board.git
cd tsubuyaki-board
```

> 💡 Git for Windows が未導入なら `winget install Git.Git` を先に。`setup.ps1` でも自動導入されるが、§6-1 で clone するには事前に Git が必要。

### 6-2. Windows キッティング → 受講生ガイドと同手順

[../education/student-setup-guide.md §4](../education/student-setup-guide.md) の手順をそのまま実施。受講生ガイドは**バッチをダブルクリックする経路**に統一されています。要約：

1. clone 済みリポジトリ内の `かんたんセットアップ` フォルダを開く
2. **`セットアップ1_Windows準備.bat`** をダブルクリック（UAC で「はい」→ 自動昇格で `scripts/setup.ps1` を実行）
3. PC 再起動

> 講師が内部挙動を直接確認したい場合は、🪟 管理者 PowerShell で `Set-ExecutionPolicy -Scope Process Bypass; .\scripts\setup.ps1` を実行しても同じです（バッチはこれを呼んでいるだけ）。

**講師固有の差分**:
- Pleiades は受講生に配布する媒体と**同じ zip** を `C:\Pleiades` に解凍してあること（配布媒体そのものの動作検証を兼ねる）。
- `setup.ps1` 完走後、🪟 PowerShell（管理者でも通常でも可）で Windows 側 Doctor を一度回し、緑揃いを確認:

  ```powershell
  .\scripts\doctor.ps1
  ```

  期待: `Pleiades` / `WSL2` / `Podman Desktop` / `Git for Windows` / `C:\workspace` の各セクションが `[ OK ]` または `[WARN]` で揃う。`[ NG ]` があれば §6-3 へ進む前に解消する。

### 6-3. WSL キッティング → 受講生ガイドと同手順 + Temurin JDK 21 検証

[../education/student-setup-guide.md §5](../education/student-setup-guide.md) の手順をそのまま実施。要約：

1. スタートメニュー → Ubuntu 起動 → 初回ユーザ・パスワード設定
2. `かんたんセットアップ` フォルダの **`セットアップ2_Ubuntu準備.bat`** をダブルクリック（`sudo` パスワードを 1 回入力）
3. 続けて **`セットアップ3_APIキー設定.bat`** で `OPENAI_API_KEY` / `.env` / Git ユーザー情報（`user.name` / `user.email`）を登録（§6-4 参照）

> バッチは内部で `scripts/setup-wsl.sh` を呼ぶだけです。講師が手動で確認したい場合は `cd /mnt/c/workspace/tsubuyaki-board && bash scripts/setup-wsl.sh`。

**講師固有の差分**: 無し（同じ）。ただし以降のリハーサル（§7）と Oracle 経路 verify（§6-5）が **Temurin JDK 21 に強く依存する**ため、`setup-wsl.sh` が何を入れるかを把握し、完了後に必ず検証する。

#### 6-3-1. `setup-wsl.sh` が自動で入れる Temurin JDK 21

`scripts/setup-wsl.sh` 内の `==> 3. Eclipse Temurin 21` ブロックが以下を自動実行する（手動操作不要）:

1. Adoptium の公開鍵を `/etc/apt/keyrings/adoptium.gpg` に登録
2. `/etc/apt/sources.list.d/adoptium.list` に `deb [signed-by=...] https://packages.adoptium.net/artifactory/deb <codename> main` を書き込み
3. `apt-get install -y temurin-21-jdk` で Java 21 を導入
4. `/etc/profile.d/jdk.sh` に以下を書き出し:
   ```sh
   export JAVA_HOME=/usr/lib/jvm/temurin-21-jdk-amd64
   export PATH="${JAVA_HOME}/bin:${PATH}"
   ```
5. `~/.bashrc` の `codex-training` ブロックから `jdk.sh` を `source` するよう追記

> 受講生・講師ともに **WSL Ubuntu 22.04 (jammy)** が前提（受講生ガイド §0.5 用語ミニ辞書）。他ディストロでは codename が一致せず apt 経路がエラーになる。

#### 6-3-2. Temurin JDK 21 の検証コマンド

`setup-wsl.sh` 完了後、新しいシェルを開く（または `source ~/.bashrc`）してから以下を順に実行:

```bash
# 1) java コマンドが 21 を返すこと
java --version
# → openjdk 21.0.x 202x-xx-xx
#    OpenJDK Runtime Environment Temurin-21.0.x+yy (build 21.0.x+yy)
#    OpenJDK 64-Bit Server VM Temurin-21.0.x+yy (build 21.0.x+yy, mixed mode, sharing)

# 2) JAVA_HOME が Temurin 21 を指していること
echo "$JAVA_HOME"
# → /usr/lib/jvm/temurin-21-jdk-amd64

# 3) Maven Wrapper がその JDK で動くこと（pom.xml がある場所で実行）
cd /mnt/c/workspace/tsubuyaki-board
./mvnw -v
# → Apache Maven 3.9.x ...
#    Java version: 21.0.x, vendor: Eclipse Adoptium, runtime: /usr/lib/jvm/temurin-21-jdk-amd64
```

3 つすべて期待出力どおりなら、§7 のリハーサルと §6-5 のフル動作確認に進める。

#### 6-3-3. JDK が見えない場合の救済

| 症状 | 原因の見当 | 対処 |
|---|---|---|
| `java: command not found` | 新シェルに `/etc/profile.d/jdk.sh` が読み込まれていない | `source /etc/profile.d/jdk.sh` を当該セッションで実行、または新しい Windows Terminal タブで Ubuntu を開き直す |
| `mvnw` で `JAVA_HOME is not defined correctly` | `JAVA_HOME` が空、または実体パスがズレている | `ls /usr/lib/jvm/` で実体ディレクトリ名を確認（Adoptium のアップデートで末尾が `temurin-21-jdk-amd64` 以外になる可能性）。ズレていれば `/etc/profile.d/jdk.sh` を編集 |
| `apt-get install temurin-21-jdk` が失敗 | apt source 行が壊れている、Adoptium のキー登録に失敗 | `bash scripts/setup-wsl.sh` を再実行（idempotent 設計で 2 回目以降も安全）。それでもダメなら `cat /etc/apt/sources.list.d/adoptium.list` で source 行を確認 |
| Ubuntu 22.04 以外で実行してしまった | codename が `jammy` でない | 本研修は Ubuntu 22.04 LTS 前提。他バージョンでの動作保証は無いため、受講生環境と揃えて再構築する |

### 6-4. `OPENAI_API_KEY`・Git 設定 → 受講生ガイドと同手順

手順本体は [../education/student-setup-guide.md §7](../education/student-setup-guide.md) を参照。受講生は **`セットアップ3_APIキー設定.bat`**（内部で `scripts/setup-secrets.sh`）で `OPENAI_API_KEY` を `~/.bashrc` に、`.env` をリポジトリ直下に登録し、続けて Git のユーザー情報（`user.name` / `user.email`）を `~/.gitconfig` に設定します（コミットの作者情報。環境チェックの Git 項目で確認される）。

**講師固有の差分**:
- **講師自身のキー** は `セットアップ3_APIキー設定.bat`（または手動の `~/.bashrc` 追記）で設定（普段使い用）
- **受講生へ貸与する予備キー** は **`~/.bashrc` には書かない**（誤って共有・公開しないため）
- 予備キーは 1Password / `pass` 等のシークレットマネージャに保管し、配布時のみ手動で渡す
- 配布経路は Slack DM など流出しにくい経路を選択
- 研修終了時に OpenAI ダッシュボードで rotate（発行し直し）

### 6-5. 動作確認（フル — 受講生より厳しめ）

受講生ガイド [§8](../education/student-setup-guide.md) の 5 点セットに加え、講師は **Oracle 経路と全件 doctor** も確認：

```bash
# 受講生は --quick だが、講師は全件
bash scripts/doctor.sh           # 全件

bash scripts/start-oracle.sh

# 受講生と同じ H2 経路 (テストは -P 指定に関わらず常に H2 で実行される)
./mvnw -B -Ph2 verify

# 仕上げ合否ゲート
./mvnw -B -Ph2 -Pcoverage-day3 -Pstrict verify

# Oracle 接続でアプリ起動 → /posts まで描画されること
# (起動時に Flyway 適用と JPA validate が Oracle XE に対して走るため、Oracle 経路の検証を兼ねる)
SPRING_PROFILES_ACTIVE=local ./mvnw spring-boot:run
# 別タブで:
curl http://localhost:8080/actuator/health   # {"status":"UP"}
curl -I http://localhost:8080/posts          # 200 OK

# Codex も必ず実機で 1 度動かす
codex-shell
# (コンテナ内) codex --help
```

`doctor.sh`（全件）の出力で以下が確実に揃うことを目視確認:

- `== JDK ==` セクション
  - `[ OK ] java — openjdk version "21..."`
  - `[ OK ] JAVA_HOME — /usr/lib/jvm/temurin-21-jdk-amd64`
- `== Maven Wrapper ==` セクション
  - `[ OK ] mvnw 実行可能`
  - `[ OK ] mvnw -v 成功`
- `== Podman ==` セクション
  - `[ OK ] podman info 成功 (rootless 含む)`
- `== Codex devbox image ==` セクション
  - `[ OK ] codex-devbox:latest 存在`

いずれかが `[WARN]` / `[ NG ]` であれば §6-3 の救済（JDK 系）または受講生ガイド §8、[../education/TROUBLESHOOTING.md](../education/TROUBLESHOOTING.md) を参照して解消する。

すべて通れば講師キッティング完了。次は §7 のリハーサル。**受講生向けには H2 経路のみで OK**（Oracle はバックアップ）。

---

## 7. リハーサル（テストアカウントでの動作確認）

受講生視点で、研修リポを Fork して clone し、自分のブランチで作業 → PR までを、**講師の業務 GitHub とは別のアカウント**で踏破して確認します。詰まったポイントは受講生ガイド / TROUBLESHOOTING への追記材料にします。

### 7-0. 前提条件

- §6 講師キッティングが完走し、自分のマシン上で `./mvnw -B -Ph2 verify` が **BUILD SUCCESS を返している**こと
- §3 で upstream リポが **public** で公開され、§4 で `main` のブランチ保護を設定済みであること
- WSL Ubuntu で `java --version` が `21`、`echo "$JAVA_HOME"` が `/usr/lib/jvm/temurin-21-jdk-amd64` を返すこと（§6-3-2 の検証済）

> ⚠️ §6 を飛ばして本節を実施すると、`./mvnw -B -Ph2 verify` が JDK 未導入で**確実に失敗**します。先に §6 を終わらせること。

### 7-1. テストアカウントを用意

- 講師の業務 GitHub アカウントとは別のアカウント（個人アカウントなど）を準備
- 公開リポなので、このアカウントへの招待や collaborator 追加は不要（Fork するだけ）

### 7-2. テストアカウントで Fork する

1. 🌐 ブラウザで GitHub からサインアウト → **テストアカウントで再サインイン**
2. 受講生ガイド §3 と同じく、upstream `https://github.com/<owner>/tsubuyaki-board` を開き、右上の「**Fork**」でテストアカウントのアカウントへ Fork する
3. Fork 後 `https://github.com/<test-account-id>/tsubuyaki-board` が開ける／ファイル一覧に `AGENTS.md` / `README.md` / `EXERCISES.md` / `pom.xml` が並ぶことを確認

### 7-3. 別ディレクトリへ clone（既存講師リポと衝突回避）して自分のブランチを切る

🐧 WSL Ubuntu で実施:

```bash
# リハーサル用の一時ディレクトリを作って clone する
mkdir -p /mnt/c/workspace/.rehearsal
cd /mnt/c/workspace/.rehearsal

# テストアカウントの fork を clone（受講生と同じ流れ。本番リポと名前が衝突しないよう別名で）
git clone https://github.com/<test-account-id>/tsubuyaki-board.git rehearsal-tsubuyaki
cd rehearsal-tsubuyaki

# 受講生と同じく、自分の作業ブランチを fork の main から切る
git switch -c <test-account-id> origin/main
```

> 💡 `.rehearsal/` は講師マシンのローカル作業ディレクトリ。本番の講師リポ（`/mnt/c/workspace/tsubuyaki-board`）と分離しておくと、後で `rm -rf` で安全に破棄できる。

### 7-4. 受講生と同じ経路で `./mvnw -B -Ph2 verify`

```bash
# 🐧 WSL Ubuntu — clone 直下で実行
./mvnw -B -Ph2 verify
```

期待出力:

```
[INFO] BUILD SUCCESS
[INFO] -----------------------------------
[INFO] Total time:  XX s
```

初回は依存ライブラリの DL で 5〜10 分かかる（受講生も同様）。

#### push と Draft PR、upstream main 直 push 不可の確認

受講生と同じく fork へ push し、PR を作り、upstream main へ直接 push できないことを確認します:

```bash
# fork（origin）の作業ブランチへ push
git push -u origin <test-account-id>

# Draft PR を作成（gh が auth 済みの場合。未認証ならブラウザで Compare & pull request）
gh pr create --repo <owner>/tsubuyaki-board \
  --base main --head <test-account-id>:<test-account-id> --draft --fill

# upstream main へ直接 push できないことを確認
git remote add upstream https://github.com/<owner>/tsubuyaki-board.git
git switch main
git commit --allow-empty -m "test: should be rejected"
git push upstream main   # → protected branch / 403 で拒否されれば OK
git switch <test-account-id>
```

> 💡 `git push upstream main` が拒否されれば（protected branch / 403）、ブランチ保護が正しく効いています。テストアカウントは upstream への push 権限も持たないため、いずれにせよ拒否されます。確認用の空コミットはリハーサルクローン内だけのものなので、§7-5 でクローンごと破棄すれば消えます。

#### 詰まったときの確認順

1. `java --version` が `21` を返すか → 違うなら §6-3 の Temurin 21 検証へ戻る
2. `echo "$JAVA_HOME"` が `/usr/lib/jvm/temurin-21-jdk-amd64` か → 違うなら §6-3-3 救済表へ
3. `bash scripts/doctor.sh --quick` で `[ NG ]` が無いか
4. ネットワーク（Maven Central 疎通）が `doctor.sh` の `== ネットワーク疎通 ==` で `[ OK ]` か（初回 verify は依存 DL のため Maven Central 必須）
5. すべて OK でも `BUILD FAILURE` になるなら **受講生ガイド／TROUBLESHOOTING に未記載のケース**。詰まったポイントをメモして [../education/student-setup-guide.md](../education/student-setup-guide.md) または [../education/TROUBLESHOOTING.md](../education/TROUBLESHOOTING.md) に追記する

### 7-5. 後片付け

リハーサル完了後:

```bash
# 元の講師リポへ戻る
cd /mnt/c/workspace/tsubuyaki-board

# リハーサル用 clone は破棄して構わない
rm -rf /mnt/c/workspace/.rehearsal/rehearsal-tsubuyaki
```

- テストアカウントの fork（`<test-account-id>/tsubuyaki-board`）は削除してよい（GitHub の fork ページ → Settings → 最下部 Danger Zone → Delete this repository）
- テストアカウントが作った Draft PR は close する（upstream の Pull requests タブから）
- 予備 `OPENAI_API_KEY` を Codex でも使ったなら、研修終了時に rotate（§6-4 参照）

---

## 8. 当日運営フロー

詳細は [timetable.md](./timetable.md) と [rubric.md](./rubric.md) を参照。本ガイドではセットアップ観点のみ記述。

### 8-1. 0 時間目（受講生到着〜セットアップ開始）

- 受講生に [../education/student-setup-guide.md](../education/student-setup-guide.md) を案内（事前送付推奨）
- 研修リポ（upstream）URL（`https://github.com/<owner>/tsubuyaki-board`）を配布（Slack / メール / ホワイトボード）。「各自 Fork して使う」ことを明示。招待・承認の作業は無い
- Pleiades 配布媒体を回覧
- `OPENAI_API_KEY` 未発行の受講生がいれば即座に発行サポート

### 8-2. 0-1 時間目（セットアップ確認）

受講生ガイドの [§8 動作確認 5 点セット](../education/student-setup-guide.md) を全員クリアさせる。
講師は「詰まっている受講生」を回って [../education/TROUBLESHOOTING.md](../education/TROUBLESHOOTING.md) を一緒に追う。

### 8-3. PR レビューフロー（演習中）

受講生は各自の fork 内で：
1. 自分の作業ブランチ `<github-id>` で開発
2. 自分の fork へ push（upstream main へ向けた Draft PR が自動更新される）

講師は upstream の **Pull requests タブ**で各受講生の PR を一覧し、各 PR の **Files changed** で差分を確認、コミット／行にコメントを残します。レビューポイントは [rubric.md](./rubric.md) の 15 点ルーブリックに沿って。

> 💡 ブランチ保護（§4）により upstream `main` への直接 push は事前にブロックされます。万一の異常は upstream の `main` 履歴（`git log --oneline upstream/main`）で確認できます。

### 8-4. 相互レビュー（19-20 時間目）

[ONBOARDING.md](../education/ONBOARDING.md#相互レビュー-19-20時間目) を参照。

### 8-5. KPT＋自己採点（20-21 時間目）

[rubric.md](./rubric.md) を配布。

---

## 9. 権限プレイブック（トラブル時）

### 9-1. 受講生が Fork / clone できない

- 症状: upstream を開けない、Fork できない、自分の fork を clone すると 404 / 認証エラー
- 原因: upstream が public になっていない、clone 先が upstream（`<owner>/...`）のまま、PAT のスコープ／失効
- 対処: §3-4 で upstream の `visibility` が `PUBLIC` か確認。受講生には「Fork してから**自分の fork**（`<github-id>/...`）を clone」「PAT は `public_repo` スコープ」を案内（受講生ガイド [Q13](../education/TROUBLESHOOTING.md)）

### 9-2. 受講生の `OPENAI_API_KEY` が当日発行不能

- 症状: 個人カード未登録 / 残高不足 / 発行制限
- 対処: 講師が予備キー 1 本を保持しておき、当日のみ貸与（研修終了時に rotate）
- 予備キーの管理・配布経路は [§6-4](#6-4-openai_api_key-設定--受講生ガイドと同手順) を参照

### 9-3. upstream `main` を保護できているか不安

- 症状: 「受講生が upstream main を汚さないか」が不安
- 原因/前提: fork モデルでは**受講生は upstream への push 権限を持たない**うえ、§4 のブランチ保護で `main` への直接 push は**事前にブロック**される（公開リポは Free でブランチ保護が効く）。旧来の「Free×private で物理ブロック不可」という制約は無くなった
- 対処: §4 のブランチ保護が有効か（Settings → Branches、または §7-4 の「直 push 不可の確認」）を点検するだけでよい。万一講師自身が誤って main を更新した場合は、手元の clone で `git revert` して打ち消す（canonical なスターターは基幹リポ／講師手元にある）

---

## 10. 講師完了条件チェックリスト

研修開始前日までに以下が全て ✓ なら準備完了。

### 公開リポ / ブランチ保護
- [ ] `<owner>/tsubuyaki-board` を **public** で作成済（§3）
- [ ] 基幹リポの main を公開リポへ push 済（スターターが見える）
- [ ] upstream `main` をブランチ保護でロック済（§4。PR 必須＝直接 push 禁止。厳格さは講師裁量）
- [ ] `main` 保護（ブランチ保護＋ Codex Guard の 2 層）を理解し、受講生周知（Fork → ブランチ → push → PR）の用意ができている

### 受講生案内・リハーサル
- [ ] 受講生の GitHub ユーザ名（小文字）を収集済（採点・識別用。push 権限付与には不要）
- [ ] 受講生案内（Fork → 自分の fork を clone → `<github-id>` ブランチ → push → Draft PR）を周知する用意ができている
- [ ] テストアカウントで Fork → clone → `<github-id>` ブランチ作成 → `./mvnw -B -Ph2 verify` 緑 → Draft PR → upstream main 直 push 不可、のリハーサル成功（[§7 リハーサル](#7-リハーサルテストアカウントでの動作確認) で実施）

### 講師マシン
- [ ] `セットアップ1_Windows準備.bat`（= `setup.ps1`）完走、PC 再起動済
- [ ] `セットアップ2_Ubuntu準備.bat`（= `setup-wsl.sh`）完走、`セットアップ3_APIキー設定.bat` 完走
- [ ] WSL Ubuntu 上で `java --version` が `21` を返す（Temurin 21）
- [ ] `echo "$JAVA_HOME"` が `/usr/lib/jvm/temurin-21-jdk-amd64`
- [ ] `./mvnw -v` で `Java version: 21.x.x, vendor: Eclipse Adoptium` が表示される
- [ ] `OPENAI_API_KEY` 設定済（`~/.bashrc`）
- [ ] `bash scripts/doctor.sh`（**全件**）緑
- [ ] `./mvnw -B -Ph2 verify`（基本検証。テストは常に H2 で実行される）緑
- [ ] `SPRING_PROFILES_ACTIVE=local ./mvnw spring-boot:run` で起動し `/actuator/health` が `UP`・`/posts` が 200（Oracle XE 経路の確認）
- [ ] `./mvnw -B -Ph2 -Pcoverage-day3 -Pstrict verify`（仕上げ合否ゲート）緑
- [ ] `codex-shell` → `codex --help` 表示

### 配布物
- [ ] Pleiades 配布媒体準備（USB / 共有ドライブ）
- [ ] 研修リポ（upstream）URL（`https://github.com/<owner>/tsubuyaki-board`）を受講生案内に記載（「各自 Fork」の旨も）
- [ ] 予備 OPENAI_API_KEY を 1 本保持

すべて ✓ なら、研修当日は受講生対応に集中できます。

---

## 10.5. 研修後のクリーンアップ

fork モデルでは受講生の成果は**各自の fork**にあり、upstream には PR として紐づくだけです。片付けは容易です。

- **PR を close し、upstream はそのまま次期研修へ再利用**: upstream の `main` は無傷なので、受講生の Draft PR を close するだけで次期研修にそのまま使えます。受講生の fork は各自の所有物なので、講師が消す必要はありません。

  ```bash
  # upstream に紐づく open PR を一覧
  gh pr list --repo <owner>/tsubuyaki-board --state open

  # 個別に close（マージはしない）
  gh pr close --repo <owner>/tsubuyaki-board <PR番号>
  ```

- **受講生に fork 削除を案内（任意）**: 残したくない受講生は各自の fork（`<github-id>/tsubuyaki-board`）を削除（Settings → 最下部 Danger Zone → Delete this repository）。講師側から他人の fork は削除できません。

- **upstream リポごと削除**: 次期研修で作り直す場合。

  ```bash
  gh repo delete <owner>/tsubuyaki-board --yes
  ```

> ⚠️ 削除前に、成果物（受講生の PR / fork）を保全する必要がないか確認してください。採点・記録が済んでから片付けます。受講生の fork は各自の所有物なので、講師が一括削除はできません（必要なら各自に依頼）。
>
> 💡 予備 `OPENAI_API_KEY` を配布・使用した場合は、OpenAI ダッシュボードで rotate（発行し直し）して締めます。

---

## 11. 次に読むもの

- [timetable.md](./timetable.md) — 当日のタイムテーブル
- [rubric.md](./rubric.md) — 15 点ルーブリック（自己採点・相互レビュー用）
- [prompts-day3.md](./prompts-day3.md) — Day 3 用プロンプト集
- [faq.md](./faq.md) — 講師 FAQ
- [../education/ONBOARDING.md](../education/ONBOARDING.md) — 受講生視点での 21 時間
- [../education/TROUBLESHOOTING.md](../education/TROUBLESHOOTING.md) — トラブル対処集
