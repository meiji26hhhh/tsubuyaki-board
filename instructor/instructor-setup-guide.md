# 講師向けセットアップガイド

AI 駆動開発研修 3 日コースを開催する**講師が、研修開始の 1 週間前までに 1 回だけ実施する**作業手順です。

受講生向けは [../education/student-setup-guide.md](../education/student-setup-guide.md) を参照。

---

## 配布アーキテクチャ全体像

```
[基幹リポ (private)]                [講師 Organization]                [受講生]
TokyoItSchool-dev/                  <org>/tsubuyaki-board               各自の private リポ
tsubuyaki-board.git                 (template 化)                       <org>/<assignment>-<id>
     │                                    │                                  │
     │  git clone --mirror                │                                  │
     │ ─────────────────────►             │                                  │
     │                                    │  GitHub Classroom Assignment     │
     │  git push --mirror                 │ ─────────────────────────────►   │
     │ ─────────────────────►             │  (受講生が URL を踏むと自動生成) │
                                          │                                  │
                                          │ ◄──────────────────────────────  │
                                          │   feature ブランチで PR / push   │
```

---

## 0. このガイドが扱うこと・扱わないこと

**扱う:**
- 基幹リポを Organization 内に複製する手順
- GitHub Classroom Assignment の作成
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
| GitHub Organization 管理者権限 | Org への push、Classroom 連携、template 化 | Org の Settings にアクセス可 |
| 基幹リポへの read 権限 | `git clone --mirror` | https://github.com/TokyoItSchool-dev/tsubuyaki-board にアクセス可 |
| OpenAI 課金済アカウント | 自分の Codex CLI 動作確認 | `OPENAI_API_KEY` 発行済、課金残高あり |
| `gh` CLI | スクリプト実行 | `gh --version` で 2.x 系 |
| ローカルマシン | 環境キッティング検証 | Windows 11 + WSL2 が動く |

---

## 2. Organization 準備

### 2-1. Organization の新規作成 or 既存利用

新規作成する場合：

1. https://github.com/account/organizations/new で「Create a free organization」または有料プラン。
2. Organization 名（例: `acme-training-2026q2`）と請求先メールを設定。

> 本研修では GitHub Actions による CI を使わない方針（受講生・講師ともローカル `./mvnw -B -Ph2 verify` で基本検証し、仕上げは `./mvnw -B -Ph2 -Pcoverage-day3 -Pstrict verify` で合否判定する）。Organization のプランは Free で問題ない。

### 2-2. Member seat 数の確認

Free プランは無制限ですが、Team プランは seat 課金。受講生人数分の seat が確保されているか **Settings > Billing** で確認。

---

## 3. 基幹リポを Organization に mirror 複製

### 3-1. 基幹リポを bare clone

```bash
cd /tmp   # 作業用ディレクトリ、後で削除可
git clone --mirror https://github.com/TokyoItSchool-dev/tsubuyaki-board.git
# → tsubuyaki-board.git/ という bare リポが作成される
```

### 3-2. Organization 内に空の private リポを作成

```bash
gh auth status   # 認証済か確認

gh repo create <org>/tsubuyaki-board \
    --private \
    --description "AI 駆動開発研修 (Codex × Spring Boot) 演習リポジトリ"
```

### 3-3. mirror push で全 ref を複製

```bash
cd tsubuyaki-board.git
git push --mirror git@github.com:<org>/tsubuyaki-board.git
# または HTTPS:
# git push --mirror https://github.com/<org>/tsubuyaki-board.git
```

`--mirror` は全ブランチ・全タグ・refs/* を完全複製します。Organization 側に同名 ref があれば**上書き**されます（クリーンな新規リポなので問題なし）。

### 3-4. Template 化

ブラウザで `https://github.com/<org>/tsubuyaki-board/settings` を開き、**Template repository** にチェック。

または CLI で：

```bash
gh api -X PATCH "repos/<org>/tsubuyaki-board" \
    -f is_template=true
```

### 3-5. 検証

```bash
gh repo view <org>/tsubuyaki-board --json visibility,isTemplate,defaultBranchRef
```

期待出力:

```json
{
  "visibility": "PRIVATE",
  "isTemplate": true,
  "defaultBranchRef": {"name": "main"}
}
```

---

## 4. main 直 push 禁止の運用方針

本研修では CI による物理ブロックは行わず、**規約遵守（AGENTS.md §3.2 / ONBOARDING.md 禁止事項）で main 直 push を禁止**します。受講生は必ず feature ブランチ + PR 経由で開発するよう、初日のキックオフで明示してください。

事故が起きた場合の対処は §9-3「受講生が main に直 push してしまった」を参照。

---

## 5. GitHub Classroom 設定

### 5-1. Classroom 作成

1. https://classroom.github.com にアクセス（GitHub アカウントでログイン）。
2. 「New classroom」をクリック。
3. Organization として 2 で準備した `<org>` を選択。
4. Classroom 名（例: `AI駆動開発研修-2026Q2`）を入力。
5. TA（補助講師）がいれば追加。

### 5-2. Roster 登録（任意）

受講生の本名と GitHub ID を紐付けたい場合は、Classroom 画面の **Students** タブで CSV インポート。匿名運用なら省略可。

### 5-3. Assignment 作成

1. Classroom 画面で「New assignment」→「Create an individual assignment」を選択（受講生ごとに別リポを生成）。
2. **Assignment title**: 例 `tsubuyaki-board`
3. **Assignment type**: Individual
4. **Repository visibility**: **Private**（必須）
5. **Starter code**: 3 で作成した `<org>/tsubuyaki-board` を選択（**template repository としてマーク済の必要あり**、これが 3-4 をやる理由）
6. **Repository permission**: Write（本研修では受講生に branch protection を設定させないため）
7. **Deadline**: 研修最終日の 21 時間目終了時刻
8. **Feedback pull request**: 任意（自動作成のフィードバック PR を作成する）

### 5-4. Assignment 招待 URL の取得

Assignment 作成完了画面に表示される **Invitation URL**（`https://classroom.github.com/a/xxxxxxxx`）をコピー。研修初日に受講生へ配布します。

### 5-5. リハーサル（テストアカウント検証）は §7 で実施

テストアカウントを使った Classroom Assignment の動作確認・`./mvnw -B -Ph2 verify` の通り確認は [§7 リハーサル](#7-リハーサルテストアカウントでの-assignment-動作確認) で行います。**先に §6 で講師マシンを整備**（Temurin JDK 21 / Maven / Podman 導入）してからでないと、`./mvnw -B -Ph2 verify` が JDK 未導入で失敗します。

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
3. 続けて **`セットアップ3_APIキー設定.bat`** で `OPENAI_API_KEY` と `.env` を登録（§6-4 参照）

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

### 6-4. `OPENAI_API_KEY` 設定 → 受講生ガイドと同手順

手順本体は [../education/student-setup-guide.md §7](../education/student-setup-guide.md) を参照。受講生は **`セットアップ3_APIキー設定.bat`**（内部で `scripts/setup-secrets.sh`）で `OPENAI_API_KEY` を `~/.bashrc` に、`.env` をリポジトリ直下に登録します。

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

## 7. リハーサル（テストアカウントでの Assignment 動作確認）

§5 で作成した Classroom Assignment が受講生視点でも正しく動くかを、**講師の業務 GitHub とは別のアカウント**で踏破して確認します。詰まったポイントは受講生ガイド / TROUBLESHOOTING への追記材料にします。

### 7-0. 前提条件

- §6 講師キッティングが完走し、自分のマシン上で `./mvnw -B -Ph2 verify` が **BUILD SUCCESS を返している**こと
- §5 で Classroom Assignment 作成・招待 URL の取得が完了していること
- WSL Ubuntu で `java --version` が `21`、`echo "$JAVA_HOME"` が `/usr/lib/jvm/temurin-21-jdk-amd64` を返すこと（§6-3-2 の検証済）

> ⚠️ §6 を飛ばして本節を実施すると、`./mvnw -B -Ph2 verify` が JDK 未導入で**確実に失敗**します。先に §6 を終わらせること。

### 7-1. テストアカウントを用意

- 講師の業務 GitHub アカウントとは別のアカウント（個人アカウントなど）を準備
- Organization の **seat が 1 つ消費される** 点に注意（Free プランは無制限、Team プランは課金）
- 当該アカウントを Organization に招待し、Settings > Members で **Active** になっていること

### 7-2. Assignment URL を踏んでリポ生成

1. 🌐 ブラウザで GitHub からサインアウト → **テストアカウントで再サインイン**
2. §5-4 で取得した Classroom 招待 URL（`https://classroom.github.com/a/xxxxxxxx`）を開く
3. **Authorize GitHub Classroom** → **Accept this assignment** をクリック
4. 30 秒〜 1 分待つと `<org>/<assignment>-<test-account-id>` という private リポが自動生成される
5. 受講生ガイド §3-3 と同じ画面遷移であること、ファイル一覧に `AGENTS.md` / `README.md` / `EXERCISES.md` / `pom.xml` が並ぶことを確認

### 7-3. 別ディレクトリへ clone（既存講師リポと衝突回避）

🐧 WSL Ubuntu で実施:

```bash
# リハーサル用の一時ディレクトリを作って clone する
mkdir -p /mnt/c/workspace/.rehearsal
cd /mnt/c/workspace/.rehearsal

# テストアカウントのリポを clone
git clone https://github.com/<org>/<assignment>-<test-account-id>.git
cd <assignment>-<test-account-id>
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
rm -rf /mnt/c/workspace/.rehearsal/<assignment>-<test-account-id>
```

- テストアカウントの GitHub リポ自体は研修期間後に削除（または `<org>` のリポ管理画面から手動 delete）
- テストアカウントの Organization seat は研修終了後に Settings > Members から外す
- 予備 `OPENAI_API_KEY` を Codex でも使ったなら、研修終了時に rotate（§6-4 参照）

---

## 8. 当日運営フロー

詳細は [timetable.md](./timetable.md) と [rubric.md](./rubric.md) を参照。本ガイドではセットアップ観点のみ記述。

### 8-1. 0 時間目（受講生到着〜セットアップ開始）

- 受講生に [../education/student-setup-guide.md](../education/student-setup-guide.md) を案内（事前送付推奨）
- Classroom Assignment URL を配布（Slack / メール / ホワイトボード）
- Pleiades 配布媒体を回覧
- `OPENAI_API_KEY` 未発行の受講生がいれば即座に発行サポート

### 8-2. 0-1 時間目（セットアップ確認）

受講生ガイドの [§8 動作確認 5 点セット](../education/student-setup-guide.md) を全員クリアさせる。
講師は「詰まっている受講生」を回って [../education/TROUBLESHOOTING.md](../education/TROUBLESHOOTING.md) を一緒に追う。

### 8-3. PR レビューフロー（演習中）

受講生は自分の Classroom リポ内で：
1. `feature/...` ブランチで開発
2. 自分のリポに push
3. 自分のリポで PR 作成
4. self-merge

講師は各受講生のリポを Watch し、PR ごとに 1〜2 行のレビューコメントを残します。レビューポイントは [rubric.md](./rubric.md) の 15 点ルーブリックに沿って。

### 8-4. 相互レビュー（19-20 時間目）

[ONBOARDING.md](../education/ONBOARDING.md#相互レビュー-19-20時間目) を参照。

### 8-5. KPT＋自己採点（20-21 時間目）

[rubric.md](./rubric.md) を配布。

---

## 9. 権限プレイブック（トラブル時）

### 9-1. 受講生が Assignment を踏めない

- 症状: Classroom 画面で「You don't have access to this assignment」
- 原因: Organization の seat 不足、または受講生が SAML SSO 未認証
- 対処: Settings > Members で受講生を Pending invitation から Active に。SAML 必須 Org の場合は受講生に再認証を依頼

### 9-2. 受講生の `OPENAI_API_KEY` が当日発行不能

- 症状: 個人カード未登録 / 残高不足 / 発行制限
- 対処: 講師が予備キー 1 本を保持しておき、当日のみ貸与（研修終了時に rotate）
- 予備キーの管理・配布経路は [§6-4](#6-4-openai_api_key-設定--受講生ガイドと同手順) を参照

### 9-3. 受講生が main に直 push してしまった

- 症状: 受講生個人リポの main に feature を介さず push される
- 原因: 規約違反（branch protection は本研修では設定しない方針）
- 対処: push 済の不正コミットは `git revert` で打ち消しコミットを作って戻す（force push は禁止）。再発防止として feature ブランチ + PR 経由の徹底を再度周知

---

## 10. 講師完了条件チェックリスト

研修開始前日までに以下が全て ✓ なら準備完了。

### Organization / リポ
- [ ] Organization 作成済
- [ ] `<org>/tsubuyaki-board` が **private** かつ **isTemplate=true**
- [ ] main 直 push 禁止規約を受講生に周知する用意ができている（CI による物理ブロックは行わない）

### Classroom
- [ ] Classroom 作成、Organization 紐付け済
- [ ] Assignment 作成（individual, private, template = `<org>/tsubuyaki-board`）
- [ ] Assignment 招待 URL を取得・共有準備完了
- [ ] テストアカウントで Assignment 参加 → clone → `./mvnw -B -Ph2 verify` 緑のリハーサル成功（[§7 リハーサル](#7-リハーサルテストアカウントでの-assignment-動作確認) で実施）

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
- [ ] Classroom Assignment URL を受講生案内に記載
- [ ] 予備 OPENAI_API_KEY を 1 本保持

すべて ✓ なら、研修当日は受講生対応に集中できます。

---

## 11. 次に読むもの

- [timetable.md](./timetable.md) — 当日のタイムテーブル
- [rubric.md](./rubric.md) — 15 点ルーブリック（自己採点・相互レビュー用）
- [prompts-day3.md](./prompts-day3.md) — Day 3 用プロンプト集
- [faq.md](./faq.md) — 講師 FAQ
- [../education/ONBOARDING.md](../education/ONBOARDING.md) — 受講生視点での 21 時間
- [../education/TROUBLESHOOTING.md](../education/TROUBLESHOOTING.md) — トラブル対処集
