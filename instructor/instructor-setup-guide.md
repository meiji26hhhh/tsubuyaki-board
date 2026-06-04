# 講師向けセットアップガイド

AI 駆動開発研修 3 日コースを開催する**講師が、研修開始の 1 週間前までに 1 回だけ実施する**作業手順です。

受講生向けは [../education/student-setup-guide.md](../education/student-setup-guide.md) を参照。

---

## 配布アーキテクチャ全体像

```
[基幹リポ (private)]              [講師 Organization]              [受講生]
TokyoItSchool-dev/               <org>/tsubuyaki-board            全員が同じ共有リポを clone
tsubuyaki-board.git              (共有リポ・1 個だけ)            → 自分の作業ブランチ <github-id>
     │                                 │                               │
     │  内容を 1 回 push               │  Organization にメンバー招待  │
     │ ──────────────────────►         │ ────────────────────────────►│
     │  (講師がスターターを用意)       │  (受講生は招待を承認して参加) │
     │                                 │                               │
     │                                 │ ◄──────────────────────────── │
     │                                 │  自分のブランチへ push(PRなし)│
     │                                 │  共有 main は誰も触らない     │
```

---

## 0. このガイドが扱うこと・扱わないこと

**扱う:**
- 共有リポを Organization で初期化する手順（基幹リポの内容を 1 回 push）
- 受講生を Organization に招待する手順
- 共有 main を守る 4 層防御（規約／Codex Guard／CI 監視 Workflow／講師確認）の設定
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
| GitHub Organization 管理者権限 | Org への push、メンバー招待、リポ権限設定 | Org の Settings にアクセス可 |
| 基幹リポへの read 権限 | 共有リポの初期化（`git clone` → push） | https://github.com/TokyoItSchool-dev/tsubuyaki-board にアクセス可 |
| OpenAI 課金済アカウント | 自分の Codex CLI 動作確認 | `OPENAI_API_KEY` 発行済、課金残高あり |
| `gh` CLI | スクリプト実行 | `gh --version` で 2.x 系 |
| ローカルマシン | 環境キッティング検証 | Windows 11 + WSL2 が動く |

---

## 2. Organization 準備

### 2-1. Organization の新規作成 or 既存利用

新規作成する場合：

1. https://github.com/account/organizations/new で「Create a free organization」または有料プラン。
2. Organization 名（例: `acme-training-2026q2`）と請求先メールを設定。

> 本研修では**採点・合否判定に GitHub Actions の CI を使わない**方針（受講生・講師ともローカル `./mvnw -B -Ph2 verify` で基本検証し、仕上げは `./mvnw -B -Ph2 -Pcoverage-day3 -Pstrict verify` で合否判定する）。Organization のプランは Free で問題ない。
>
> ただし**共有 main を守る監視用に、軽量な GitHub Actions Workflow（`.github/workflows/protect-main.yml`）のみ**を 1 本だけ使う（§4 参照）。これは main への push を検知して講師へ通知するだけで、main への push 時しか起動しないため Free private の 2,000 分/月枠をほぼ消費しない。

### 2-2. Member seat 数の確認

Free プランは無制限ですが、Team プランは seat 課金。受講生人数分の seat が確保されているか **Settings > Billing** で確認。

---

## 3. 共有リポを Organization で初期化

全受講生が使う**共有リポを 1 個だけ** Organization に作り、基幹リポのスターター内容を 1 回 push します。Classroom のような個人リポ自動生成や template 化は不要です。

### 3-1. 基幹リポをローカルに用意

```bash
cd /tmp   # 作業用ディレクトリ、後で削除可
git clone https://github.com/TokyoItSchool-dev/tsubuyaki-board.git
cd tsubuyaki-board
```

> 💡 既に講師マシンに clone 済みの基幹リポがあればそれを使ってもよい。重要なのは「配布したい状態（main の最新）」が手元にあること。

### 3-2. Organization に共有リポ（private）を作成

```bash
gh auth status   # 認証済か確認

gh repo create <org>/tsubuyaki-board \
    --private \
    --description "AI 駆動開発研修 (Codex × Spring Boot) 演習リポジトリ（共有・受講生は各自ブランチで作業）"
```

### 3-3. スターター内容を共有リポへ push

配布したいのは「main の最新スナップショット」です。`--mirror` は使わず（基幹リポの全ブランチ・全履歴を受講生に見せる必要はない）、main を通常 push します。

```bash
# 共有リポを remote として追加（origin は基幹リポなので別名 org にする）
git remote add org https://github.com/<org>/tsubuyaki-board.git

# main を共有リポへ push
git push org main

# 配布したいタグがあれば一緒に（無ければ省略可）
# git push org --tags
```

> 💡 受講生に配るブランチは `main` 1 本で十分です。受講生は各自この `main` から自分の `<github-id>` ブランチを切ります。

### 3-4. 検証

```bash
gh repo view <org>/tsubuyaki-board --json visibility,defaultBranchRef
```

期待出力:

```json
{
  "visibility": "PRIVATE",
  "defaultBranchRef": {"name": "main"}
}
```

> 💡 共有リポなので `isTemplate` は不要（`false` のままで OK）。

---

## 4. 共有 main を守る 4 層防御

**重要な制約**: GitHub Free の private リポでは branch protection / ruleset が**強制されません**（設定しても "won't be enforced until you upgrade to Team" エラーになる）。つまり push を物理的に reject する手段が無いため、共有 main は次の 4 層で「汚さない／汚れても必ず戻せる」を担保します。

1. **規約**（AGENTS.md §3.2 / ONBOARDING.md 禁止事項 / student-setup-guide §6）— 「共有 main へは push しない。push 先は常に自分の `<github-id>` ブランチ」を初日キックオフで明示。

2. **Codex Guard**（`containers/codex-devbox/bin/git-guard.sh`）— コンテナ内 Codex が `main` へ push しようとすると exit 126 で拒否（force push 拒否は既存）。ただしコンテナ外の素の git は対象外。

3. **CI 監視 Workflow**（`.github/workflows/protect-main.yml`）— `main` への push を検知すると、push 主体（`github.actor`）が講師許可リスト外の場合に Issue を作成して講師へ通知（既定動作）。GitHub Actions は push 後に走るため事前ブロックはできないが、「誰が・いつ・どのコミットを」main に入れたかを即座に把握できる。許可リスト（講師アカウント）の設定箇所は当該ファイル冒頭のコメント参照。

4. **講師モニタリング** — CI 通知、または `git log --oneline origin/main` で違反を把握し、後述 §9-3 の手順で `git revert` して戻す。canonical なスターターは基幹リポ／講師手元に保持しておく。

> 受講生が自分の素の git（コンテナ外）で `git push origin main` する経路だけは技術的に塞げません。CI 検知 → 講師 `git revert` で是正する前提で運用します。事故時の手順は §9-3 を参照。
>
> 共有 main を**完全にロック**したい場合の選択肢: (a) リポを public 化すれば Free でも branch protection が使える、(b) GitHub Team / Education 特典で private のまま branch protection が使える。本研修は Free×private 前提で進めます。

---

## 5. 受講生を Organization に招待

Classroom の代わりに、受講生を共有リポへ **Write 権限**で招待します。受講生は自分の `<github-id>` ブランチへ push できればよいので、共有リポへの Write があれば十分です。

### 5-1. 受講生の GitHub ユーザ名を集める

事前に受講生全員の GitHub ユーザ名（小文字）を集めておきます（申込フォーム / 事前アンケートなど）。ブランチ名・採点時の識別に使うため、**正確な綴り**を確認します。

### 5-2. 共有リポへ Write 権限で招待（推奨: collaborator 追加）

最もシンプルで安全なのは、共有リポに各受講生を **collaborator（Write）として直接追加**する方法です（Org 全体の権限を緩めず、この 1 リポにだけ Write を与える）。受講生宛に招待メールが届き、承認するとアクセスできます。

```bash
# 受講生 1 人を共有リポに Write で招待
gh api -X PUT "repos/<org>/tsubuyaki-board/collaborators/<github-id>" -f permission=push
```

複数人をまとめて招待する例（ユーザ名を改行区切りで `students.txt` に用意）:

```bash
while read -r gh_id; do
  [ -z "$gh_id" ] && continue
  echo "inviting $gh_id ..."
  gh api -X PUT "repos/<org>/tsubuyaki-board/collaborators/$gh_id" -f permission=push
done < students.txt
```

> 💡 `permission=push` が「Write（push 可能）」を意味します。受講生は自分のブランチを push できますが、Free×private では共有 main を技術的にロックできない点は §4 のとおり（規約＋CI 監視で担保）。
>
> 💡 Org の **Settings > Member privileges > Base permissions** を `Read`（または None）のままにしておけば、collaborator 追加したこの共有リポ以外に受講生はアクセスできません（最小権限）。

### 5-3. 招待状況の確認

```bash
# 招待承認待ち（pending）の一覧
gh api "repos/<org>/tsubuyaki-board/invitations" --jq '.[].invitee.login'

# 承認済み collaborator の一覧
gh api "repos/<org>/tsubuyaki-board/collaborators" --jq '.[].login'
```

受講生が招待メールを承認すると pending から消え、collaborators 側に現れます。当日までに全員が承認済みになっているか確認します。

### 5-4. 受講生への案内事項

研修初日に受講生へ次を伝えます（受講生ガイド §2・§3 と対応）:

- **Organization 名** `<org>` と **共有リポ URL** `https://github.com/<org>/tsubuyaki-board`
- 「招待メール（または `https://github.com/<org>`）から参加を承認すること」
- 「clone 後は自分の GitHub ユーザ名で `git switch -c <github-id> origin/main` してから作業すること」

### 5-5. リハーサル（テストアカウント検証）は §7 で実施

テストアカウントを使った「招待承認 → 共有リポ clone → `<github-id>` ブランチ作成 → `./mvnw -B -Ph2 verify`」の確認は [§7 リハーサル](#7-リハーサルテストアカウントでの動作確認) で行います。**先に §6 で講師マシンを整備**（Temurin JDK 21 / Maven / Podman 導入）してからでないと、`./mvnw -B -Ph2 verify` が JDK 未導入で失敗します。

---

## 6. 講師自身のキッティング

受講生と同じ環境を講師マシンに構築します（質問対応・トラブル再現用）。順序は受講生ガイドと同じ「Windows キッティング → 再起動 → WSL → リポ clone」です。

### 6-1. 講師リポを clone（🪟 管理者 PowerShell）

WSL2 機能はまだ有効化されていないので、**Windows 側の PowerShell** で clone する（受講生ガイド §4-2 と同じ流れ）：

```powershell
New-Item -ItemType Directory -Force -Path "C:\workspace" | Out-Null
cd C:\workspace
git clone https://github.com/<org>/tsubuyaki-board.git
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

# Oracle XE 経路でも verify が通ること（受講生は H2 のみで OK）
./mvnw -B -Plocal verify

# 受講生と同じ H2 経路
./mvnw -B -Ph2 verify

# 仕上げ合否ゲート
./mvnw -B -Ph2 -Pcoverage-day3 -Pstrict verify

# Oracle 接続でアプリ起動 → /posts まで描画されること
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

§5 で招待した受講生視点で、共有リポを clone して自分のブランチで作業できるかを、**講師の業務 GitHub とは別のアカウント**で踏破して確認します。詰まったポイントは受講生ガイド / TROUBLESHOOTING への追記材料にします。

### 7-0. 前提条件

- §6 講師キッティングが完走し、自分のマシン上で `./mvnw -B -Ph2 verify` が **BUILD SUCCESS を返している**こと
- §5 で共有リポへの受講生招待（テストアカウント分を含む）が完了していること
- WSL Ubuntu で `java --version` が `21`、`echo "$JAVA_HOME"` が `/usr/lib/jvm/temurin-21-jdk-amd64` を返すこと（§6-3-2 の検証済）

> ⚠️ §6 を飛ばして本節を実施すると、`./mvnw -B -Ph2 verify` が JDK 未導入で**確実に失敗**します。先に §6 を終わらせること。

### 7-1. テストアカウントを用意

- 講師の業務 GitHub アカウントとは別のアカウント（個人アカウントなど）を準備
- 当該アカウントを §5-2 と同じ手順で共有リポに collaborator（Write）として招待し、承認しておく

### 7-2. 招待を承認して共有リポにアクセス

1. 🌐 ブラウザで GitHub からサインアウト → **テストアカウントで再サインイン**
2. 共有リポへの招待メール（または `https://github.com/<org>/tsubuyaki-board`）を開き、招待を承認する
3. 受講生ガイド §3 と同じく、共有リポ `https://github.com/<org>/tsubuyaki-board` を開ける／ファイル一覧に `AGENTS.md` / `README.md` / `EXERCISES.md` / `pom.xml` が並ぶことを確認

### 7-3. 別ディレクトリへ clone（既存講師リポと衝突回避）して自分のブランチを切る

🐧 WSL Ubuntu で実施:

```bash
# リハーサル用の一時ディレクトリを作って clone する
mkdir -p /mnt/c/workspace/.rehearsal
cd /mnt/c/workspace/.rehearsal

# 共有リポを clone（受講生と同じ URL。本番リポと名前が衝突しないよう別名で）
git clone https://github.com/<org>/tsubuyaki-board.git rehearsal-tsubuyaki
cd rehearsal-tsubuyaki

# 受講生と同じく、自分の作業ブランチを main から切る
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

- 共有リポに push してしまったテスト用ブランチがあれば削除: `git push <共有リポ> --delete <test-account-id>`（または GitHub の branches タブから削除）
- テストアカウントの collaborator 権限は研修開始前に Settings > Collaborators から外す（本番受講生と混在させない）
- 予備 `OPENAI_API_KEY` を Codex でも使ったなら、研修終了時に rotate（§6-4 参照）

---

## 8. 当日運営フロー

詳細は [timetable.md](./timetable.md) と [rubric.md](./rubric.md) を参照。本ガイドではセットアップ観点のみ記述。

### 8-1. 0 時間目（受講生到着〜セットアップ開始）

- 受講生に [../education/student-setup-guide.md](../education/student-setup-guide.md) を案内（事前送付推奨）
- 共有リポ URL（`https://github.com/<org>/tsubuyaki-board`）と Organization 名を配布（Slack / メール / ホワイトボード）。Organization への招待は前日までに送り、当日までに全員承認済みが理想
- Pleiades 配布媒体を回覧
- `OPENAI_API_KEY` 未発行の受講生がいれば即座に発行サポート

### 8-2. 0-1 時間目（セットアップ確認）

受講生ガイドの [§8 動作確認 5 点セット](../education/student-setup-guide.md) を全員クリアさせる。
講師は「詰まっている受講生」を回って [../education/TROUBLESHOOTING.md](../education/TROUBLESHOOTING.md) を一緒に追う。

### 8-3. ブランチレビューフロー（演習中）

受講生は共有リポ内で：
1. 自分の作業ブランチ `<github-id>` で開発（PR は作らない）
2. 自分のブランチへ push

講師は共有リポの **branches タブ**で各受講生ブランチの更新を一覧し、`https://github.com/<org>/tsubuyaki-board/compare/main...<github-id>` の **Compare ビュー**で差分を確認、コミット／行にコメントを残します。レビューポイントは [rubric.md](./rubric.md) の 15 点ルーブリックに沿って。

> 💡 共有 `main` に想定外の push が無いか（§4 の CI 監視 Workflow 通知、または `git log --oneline origin/main`）も時々確認します。違反があれば §9-3 で是正。

### 8-4. 相互レビュー（19-20 時間目）

[ONBOARDING.md](../education/ONBOARDING.md#相互レビュー-19-20時間目) を参照。

### 8-5. KPT＋自己採点（20-21 時間目）

[rubric.md](./rubric.md) を配布。

---

## 9. 権限プレイブック（トラブル時）

### 9-1. 受講生が共有リポにアクセスできない

- 症状: 共有リポを開くと 404、または clone が `Repository not found` / 認証エラー
- 原因: 招待メール未承認、招待先 GitHub ユーザ名の綴り誤り、または SAML SSO 未認証
- 対処: §5-3 の `gh api .../invitations` で pending を確認。未承認なら本人に承認を依頼。ユーザ名が違っていれば §5-2 で正しい ID に招待し直す。SAML 必須 Org の場合は受講生に再認証を依頼

### 9-2. 受講生の `OPENAI_API_KEY` が当日発行不能

- 症状: 個人カード未登録 / 残高不足 / 発行制限
- 対処: 講師が予備キー 1 本を保持しておき、当日のみ貸与（研修終了時に rotate）
- 予備キーの管理・配布経路は [§6-4](#6-4-openai_api_key-設定--受講生ガイドと同手順) を参照

### 9-3. 受講生が共有 main に直 push してしまった

- 症状: 共有リポの `main` に、受講生のコミットが直接 push される（§4 の CI 監視 Workflow が Issue で通知、または `git log origin/main` で発覚）
- 原因: 規約違反（Free×private のため branch protection は使えず、技術的な事前ブロックは無い）
- 対処: 講師が手元の clone で当該コミットを `git revert` し、`main` へ push して打ち消す（force push は禁止）。canonical なスターターは基幹リポ／講師手元にあるので、最悪は `main` の強制復元も可能。本人へは「push 先は自分の `<github-id>` ブランチ」を再周知

---

## 10. 講師完了条件チェックリスト

研修開始前日までに以下が全て ✓ なら準備完了。

### Organization / リポ
- [ ] Organization 作成済
- [ ] `<org>/tsubuyaki-board` が **private**（共有リポ。template 化は不要）
- [ ] 基幹リポの main を共有リポへ push 済（スターターが見える）
- [ ] `.github/workflows/protect-main.yml` を配置し、講師アカウントを許可リストに設定済（§4 の CI 監視）
- [ ] 共有 main 保護の 4 層（規約／Codex Guard／CI 監視／講師確認）を理解し、受講生周知の用意ができている

### 受講生招待
- [ ] 受講生全員の GitHub ユーザ名（小文字）を収集済
- [ ] 共有リポへ collaborator（Write）として招待済（§5-2）。当日までに承認状況を §5-3 で確認
- [ ] テストアカウントで 招待承認 → clone → `<github-id>` ブランチ作成 → `./mvnw -B -Ph2 verify` 緑のリハーサル成功（[§7 リハーサル](#7-リハーサルテストアカウントでの動作確認) で実施）

### 講師マシン
- [ ] `セットアップ1_Windows準備.bat`（= `setup.ps1`）完走、PC 再起動済
- [ ] `セットアップ2_Ubuntu準備.bat`（= `setup-wsl.sh`）完走、`セットアップ3_APIキー設定.bat` 完走
- [ ] WSL Ubuntu 上で `java --version` が `21` を返す（Temurin 21）
- [ ] `echo "$JAVA_HOME"` が `/usr/lib/jvm/temurin-21-jdk-amd64`
- [ ] `./mvnw -v` で `Java version: 21.x.x, vendor: Eclipse Adoptium` が表示される
- [ ] `OPENAI_API_KEY` 設定済（`~/.bashrc`）
- [ ] `bash scripts/doctor.sh`（**全件**）緑
- [ ] `./mvnw -B -Plocal verify`（Oracle XE）緑
- [ ] `./mvnw -B -Ph2 verify`（H2 基本検証）緑
- [ ] `./mvnw -B -Ph2 -Pcoverage-day3 -Pstrict verify`（仕上げ合否ゲート）緑
- [ ] `codex-shell` → `codex --help` 表示

### 配布物
- [ ] Pleiades 配布媒体準備（USB / 共有ドライブ）
- [ ] 共有リポ URL（`https://github.com/<org>/tsubuyaki-board`）と Organization 名を受講生案内に記載
- [ ] 予備 OPENAI_API_KEY を 1 本保持

すべて ✓ なら、研修当日は受講生対応に集中できます。

---

## 10.5. 研修後のクリーンアップ

研修終了後、Organization を片付けます。共有リポ 1 個に集約されているため片付けは容易です。**いずれか**を選びます。

- **受講生ブランチだけ削除してスターターを次期研修に再利用**: 共有 `main` は無傷のまま、各受講生ブランチを削除する。

  ```bash
  # 受講生ブランチを一覧（main 以外）
  git ls-remote --heads https://github.com/<org>/tsubuyaki-board.git \
    | awk '{print $2}' | sed 's#refs/heads/##' | grep -v '^main$'

  # 個別に削除
  git push https://github.com/<org>/tsubuyaki-board.git --delete <github-id>
  ```

  GitHub の branches タブから手動削除も可。`main` は残るので、次回はまた §5（招待）から再開できる。

- **共有リポごと削除**: 次期研修で作り直す場合。

  ```bash
  gh repo delete <org>/tsubuyaki-board --yes
  ```

- **Organization ごと削除**: その Organization を二度と使わない場合。Settings の最下部「Delete this organization」から。collaborator・リポ・全ブランチが一括で消える。

> ⚠️ 削除前に、成果物（受講生の各ブランチ）を保全する必要がないか確認してください。採点・記録が済んでから片付けます。
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
