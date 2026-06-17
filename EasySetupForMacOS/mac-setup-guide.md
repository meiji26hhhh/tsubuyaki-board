# 受講生向けセットアップガイド（macOS / Apple Silicon 版）

AI 駆動開発研修 3 日コースで使う「社内つぶやきボード」演習リポジトリの、**Mac（Apple Silicon）向け**初期セットアップ手順です。
**研修 0-1 時間目で「アプリが空起動できる状態」にする**ことがゴール。

> 💻 **Windows をお使いの方はこのガイドではありません。** リポジトリ直下の `かんたんセットアップ` フォルダと [education/student-setup-guide.md](../education/student-setup-guide.md) を使ってください。

研修の進め方は [../education/ONBOARDING.md](../education/ONBOARDING.md)、つまずいたら [../education/TROUBLESHOOTING.md](../education/TROUBLESHOOTING.md) を参照してください（Windows 前提の記述は適宜読み替え）。

---

## 0. このガイドの読み方

- **コマンドは上から順に実行**。前ステップが成功してから次へ。
- 期待出力と違うものが出たら、即座に隣の人か講師に確認。**自己流に進めない**。
- **環境構築は `.command` ファイルをダブルクリックするだけ**で進みます。`EasySetupForMacOS` フォルダに番号順に並んでいます。
- macOS では `gvenzl/oracle-xe` イメージが Apple Silicon 非対応のため、**この研修の Mac 版はデータベースに H2（メモリ DB）のみを使います**。テスト・アプリ起動・Codex 開発はすべて H2 で完結するので、Oracle のセットアップはありません。
- 「**どこで操作するか**」を毎回示します。アイコン凡例：
  - 🖱️ **EasySetupForMacOS フォルダ**（Finder で開いて `.command` を**ダブルクリック**する）
  - 💻 **ターミナル**（macOS 標準の Terminal.app。`git clone` や `./mvnw`、`codex-shell` で使う。プロンプトは `ユーザ名@Mac名 ~ %` など）
  - 📦 **Codex コンテナ内**（`codex-shell` 実行後に入った状態。プロンプトが `codex@xxxxxxxx:/workspace$` 等になる）
  - 🌐 **ブラウザ**（GitHub の Web UI）

---

## 0.5. 用語ミニ辞書（初見の人向け）

| 用語 | ざっくり説明 |
|---|---|
| **ターミナル** | macOS 標準のコマンド入力ツール。`アプリケーション > ユーティリティ > ターミナル`、または Spotlight（⌘+Space）で `ターミナル` と検索して起動。既定のシェルは zsh。 |
| **Homebrew** | macOS のパッケージ管理ツール。JDK・Maven・podman などをコマンドで導入できる。「1_Macの準備」バッチが自動導入する。 |
| **コンテナ** | アプリ一式を箱詰めして実行する仕組み。本研修では Codex CLI 実行環境をコンテナで動かす。 |
| **Podman / podman machine** | コンテナを動かすツール（Docker と同等）。Apple Silicon では Linux の仮想マシン（**podman machine**）の上でコンテナが動く。「1_Macの準備」バッチが自動構築する。中身を理解する必要はない。 |
| **Codex CLI** | OpenAI の AI 開発エージェント。ターミナルから対話的に使う。本研修では Podman コンテナ内で動かす（`codex-shell` コマンドで起動）。**この CLI を使った開発こそが研修の本題**なので、起動はあえてバッチ化していない。 |
| **`.command` ファイル** | `EasySetupForMacOS` フォルダにある macOS 用のダブルクリック実行ファイル。Windows の `.bat` に相当。裏で Homebrew / podman を呼ぶが、受講生はその中身を知らなくてよい。 |
| **H2** | Java 製のメモリ内データベース。アプリ起動時に自動で立ち上がり、別途インストール・起動は不要。Mac 版ではこれを使う。 |
| **Organization** | GitHub の組織アカウント。講師が作成し、共有リポジトリを 1 つ用意する。受講生は招待されて参加する。 |
| **共有リポジトリ** | 全受講生が共通で使う 1 つのリポジトリ（`<org>/tsubuyaki-board`）。各自が clone し、自分専用の作業ブランチで作業する。`main` は配布時のまま温存し、誰も push しない。 |
| **作業ブランチ（`<github-id>`）** | あなた専用の作業ブランチ。自分の GitHub ユーザ名（小文字）を名前にして `main` から切り（§5 で作成）、研修中の全作業をこのブランチで行う。 |
| **Maven Wrapper (`./mvnw`)** | Maven 本体を別途インストールしなくても、リポジトリ同梱のスクリプトでビルドできる仕組み。ターミナルで実行する。 |
| **研修ハーネス (Codex Guard)** | Codex devbox コンテナ内で `rm -rf /`・`git reset --hard`・`.env` 読み取り等の破壊的操作を止める多層防御。詳細は [../AGENTS.md §7](../AGENTS.md)。 |

---

## 1. 必要なアカウント・PC（前日までに準備）

### 1-0. 対象 Mac の前提

- **Apple Silicon（M1 / M2 / M3 / M4）** の Mac
- **macOS 13 (Ventura) 以降**（podman machine の安定動作のため。最新版を推奨）
- そのマシンの**管理者**として使えるアカウント（Homebrew 導入・JDK の cask 導入でパスワードを求められます）
- インターネット接続
- ディスクの空き容量 **15 GB 以上**（Homebrew / podman machine の VM / Codex イメージで消費します）

> 💡 Intel Mac でも動かないわけではありませんが、podman machine が重く、動作保証外です。

### 1-1. 必要なアカウント

| 項目 | 用途 | 確認方法 |
|---|---|---|
| GitHub アカウント | 共有リポへの push（自分の作業ブランチ） | https://github.com にログインできること |
| OpenAI アカウント | Codex CLI の認証 | API キー (`sk-...`) を発行済、課金（クレジット残高）あり |

> OpenAI API キーは研修運営から配布されます（`sk-` で始まる長い文字列）。
>
> GitHub の clone/push は HTTPS で行うため、Personal Access Token (classic) を §3-3 で取得します（パスワードの代わりに使用）。

---

## 2. 講師から受け取るもの

研修初日に講師から以下を受け取ります：

- **Organization への招待**（GitHub の登録メール宛に届く招待メール、または `https://github.com/<org>` から承認）
- **共有リポジトリの URL**（`https://github.com/<org>/tsubuyaki-board` 形式。clone に使う）
- **Organization 名**（`<org>`。clone URL や GitHub 上のパスに含まれます）

---

## 3. Organization への招待を受けて参加（🌐 ブラウザ）

本研修では、講師が作成した **Organization に 1 つだけ用意された共有リポジトリ**を全受講生で使います。あなたは Organization に招待され、共有リポを clone して、**自分専用の作業ブランチ**で作業します。

### 3-1. Organization の招待を承認（Accept）

1. 招待されると **GitHub の登録メールアドレス宛に招待メール**が届きます（件名は「You've been invited to join ...」）。
2. メール内の「**View invitation**」「**Join ...**」ボタン、または `https://github.com/orgs/<org>/invitation` を開きます。
3. **研修で使う GitHub アカウントで** Sign in。
4. 「**Join <org>**」ボタンで招待を承認します。

> 💡 招待メールが見当たらない場合は迷惑メールを確認するか、`https://github.com/<org>` を直接開いてください。

### 3-2. 共有リポジトリを開いて clone URL を取得

1. ブラウザで `https://github.com/<org>/tsubuyaki-board` を開きます（`<org>` は講師から共有された名前）。
2. ファイル一覧に `AGENTS.md`、`README.md`、`EXERCISES.md`、`pom.xml` などが見えれば OK。
3. 右上の緑の「**< > Code**」→「**HTTPS**」タブ → 表示される URL（`https://github.com/<org>/tsubuyaki-board.git`）をコピー。

### 3-3. Personal Access Token (classic) を取得

clone と push は HTTPS 経由で、GitHub はログインパスワードを使えないため、**Personal Access Token (classic)** を使います。

1. GitHub にログイン → 右上アバター → **Settings**
2. 左メニュー最下部 **Developer settings**
3. **Personal access tokens** → **Tokens (classic)**
4. **Generate new token** → **Generate new token (classic)**
5. **Note**: 識別名（例 `tsubuyaki-training`）
6. **Expiration**: **7 days**（研修期間に合わせる）
7. **Select scopes**: **`repo`** にチェック（private リポの読み書きに必須）
8. **Generate token** → 表示された `ghp_...` をコピー

> 📌 token は**この画面を離れると二度と表示されない**。必ずコピーしてメモ帳等に一時保管。
>
> ⚠️ token は秘密情報。コミット・チャットに貼らない。研修終了後は GitHub 側で **Delete** する。

---

## 4. Mac の準備（💻 ターミナル → 🖱️ ダブルクリック）

> このセクションは **リポジトリの clone →（初回だけ）実行許可の付与 → `.command` をダブルクリック** の流れです。Windows のような OS 再起動は不要です。

### 4-1. リポジトリをホーム配下に clone（💻 ターミナル）

⌘+Space で `ターミナル` と検索して起動し、以下を順に実行します（`<org>` は §3-2 の Organization 名に置換）：

```bash
# ホーム直下に作業用フォルダを作る（既にあれば何もしない）
mkdir -p ~/training
cd ~/training

# clone（§3-2 でコピーした共有リポの URL を使う）
git clone https://github.com/<org>/tsubuyaki-board.git
```

> ⚠️ **clone 先は必ずホーム（`~/`）配下にしてください**（例 `~/training/tsubuyaki-board`）。Mac の podman は仮想マシン経由でファイルを見るため、**ホーム配下に置いたフォルダしかコンテナから参照できません**。デスクトップ（`~/Desktop`）配下でも構いませんが、`/tmp` や `/opt` などホーム外に置くと Codex がリポを開けません。日本語やスペースを含まないパスを推奨します。
>
> 💡 `git: command not found` や「コマンドラインデベロッパツールが必要」と出たら、表示される案内に従って `xcode-select --install` を実行して git を入れてから clone し直してください（または §4-3 の「1_Macの準備」が Homebrew 版 git を入れます）。
>
> 💡 clone 時にユーザー名・パスワードを聞かれたら、**ユーザー名は GitHub ユーザー名**、**パスワードは §3-3 の token (`ghp_...`)** を貼り付けます。一度成功すると Mac のキーチェーンに保存され、以降は再入力不要です。

### 4-2. （初回だけ）実行許可を付与（💻 ターミナル）

clone 直後の `.command` は、ダブルクリックしても「実行できない／開発元を確認できない」と出ることがあります。**1 回だけ**次を実行して許可を与えます：

```bash
cd ~/training/tsubuyaki-board
chmod +x EasySetupForMacOS/*.command EasySetupForMacOS/bin/*.sh
xattr -dr com.apple.quarantine EasySetupForMacOS 2>/dev/null || true
```

> 💡 それでもダブルクリック時に「開発元を確認できないため開けません」と出たら、その `.command` を **Control を押しながらクリック →「開く」→「開く」** を選びます（初回のみ。2 回目以降は普通にダブルクリックできます）。

### 4-3. 「1_Macの準備」をダブルクリック（🖱️）

1. Finder で `~/training/tsubuyaki-board/EasySetupForMacOS` フォルダを開きます。
2. **`1_Macの準備.command`** をダブルクリックします（初回は §4-2 の通り Control+クリック →「開く」）。
3. ターミナルが開いて処理が進みます。途中で **Mac のログインパスワード**を聞かれたら入力してください（Homebrew 導入や JDK の cask 導入で必要。★入力中は画面に何も出ませんが入力されています）。
4. `手順1 が完了しました。` と表示されたら成功です。

このバッチ（内部で `bin/setup-mac.sh` を実行）が以下を自動でやります：

- **Homebrew** の導入（未導入の場合）
- **Temurin JDK 21**（Java 21）/ **Maven** / **podman** / **git** の導入
- **podman machine** の作成・起動（コンテナを動かす Linux 仮想マシン）
- **Codex CLI 用 devbox コンテナイメージ**（`codex-devbox:latest`）のビルド
- `mvnw`（Maven Wrapper）の生成
- `~/.zshrc` に環境変数と **`codex-shell`** エイリアスを追加（後で §7-5 で使う）

**所要時間: 10〜20 分**（初回は VM イメージとコンテナのビルドで時間がかかります）。作業ログは `EasySetupForMacOS/logs/` に保存されます。

> 💡 完了後は**新しいターミナルのタブ／ウィンドウ**を開いてください。`codex-shell` エイリアスや `JAVA_HOME` は新しいシェルから有効になります。

---

## 5. 自分の作業ブランチを切る（💻 ターミナル）

共有 `main` は配布時のまま温存し、**誰も push しません**。あなたは**自分専用の作業ブランチ**を `main` から切り、研修中の全作業をこのブランチで行います。ブランチ名は**あなたの GitHub ユーザ名（小文字）**にします。

```bash
cd ~/training/tsubuyaki-board

# 現在のブランチを確認（clone 直後は main のはず）
git branch --show-current
# → main

# main から自分専用の作業ブランチを作って切り替える
# <github-id> はあなたの GitHub ユーザ名（小文字）に置き換える
git switch -c <github-id> origin/main

git branch --show-current
# → <github-id>
```

例: GitHub ユーザ名が `yamada` なら `git switch -c yamada origin/main`

> 📌 fork は不要です。push 先は共有リポ（origin）のあなたのブランチです。**共有 `main` には絶対に push しません**（詳細は [../AGENTS.md §3.2](../AGENTS.md)）。

---

## 6. API キーと Git 設定を登録（🖱️ 「2_APIキーとGit設定」）

Codex CLI が使う `OPENAI_API_KEY` と、コミットの作者情報（git の `user.name` / `user.email`）を、バッチが対話形式で登録します。

1. 講師から配布された自分用のキー（`sk-` で始まる長い文字列）を手元に用意します。
2. `EasySetupForMacOS` フォルダの **`2_APIキーとGit設定.command`** をダブルクリックします。
3. `OPENAI_API_KEY を貼り付けて Enter` と出たら、キーを貼り付けて Enter。
   - ★貼り付けても画面には表示されませんが、ちゃんと入力されています。
4. `ユーザー名` と `メールアドレス` を聞かれたら入力して Enter。
   - ユーザー名は **GitHub ユーザ名**（§5 のブランチ名と同じ）、メールアドレスは **GitHub に登録したもの**を推奨。
5. `秘密情報と Git の設定が完了しました` と表示されたら成功です。

このバッチ（内部で `bin/setup-secrets-mac.sh` を実行）が登録するもの：

| 登録先 | 内容 |
|---|---|
| `~/.zshrc`（ホーム） | `OPENAI_API_KEY`（対話シェルで毎回読まれる） |
| `~/.codex-training/openai_key` | `OPENAI_API_KEY`（`.command` ダブルクリック経路でも読めるようにする控え。パーミッション 600） |
| `~/.gitconfig`（ホーム） | git の `user.name` / `user.email`（コミットの作者情報） |

> 💡 Mac 版は H2 のみのため、Oracle 用の `.env` は作成しません。
>
> ⚠️ **API キーは絶対にコミットしないこと**。共有 PC では研修終了時に **キーを rotate**（OpenAI 側で発行し直し）してください。

---

## 7. 動作確認 4 点セット

以下 4 つが全て通れば 0-1 時間目完了です。§7-1 は 🖱️ **ダブルクリック**、§7-2〜§7-4 は 💻 **ターミナル**（リポルート `~/training/tsubuyaki-board` で実行）です。

### 7-1. 環境チェック（🖱️ 「3_環境チェック」）

`EasySetupForMacOS` フォルダの **`3_環境チェック.command`** をダブルクリックします（内部で `bin/doctor-mac.sh --quick`）。

期待出力（行頭の記号を確認）:

```
[ OK ] macOS ...
[ OK ] アーキテクチャ — arm64 (Apple Silicon)
[ OK ] java — ... 21 ...
[ OK ] mvnw 実行可能
[ OK ] podman ...
[ OK ] podman machine 起動中
[ OK ] codex-devbox:latest 存在 — arch=arm64
[ OK ] OPENAI_API_KEY 設定済み (値は表示しません)
...
```

判定:
- 全行が `[ OK ]` または `[WARN]` → 次へ
- 1 つでも `[ NG ]` → 表示と `EasySetupForMacOS/logs/` のログを確認、または講師に報告

> 💡 Mac 版に Oracle の項目はありません（H2 のみ）。

### 7-2. ビルド & テスト（H2 で）

```bash
cd ~/training/tsubuyaki-board
./mvnw -B -Ph2 verify
```

期待出力（最後の方）:

```
[INFO] BUILD SUCCESS
```

JUnit テストが全て緑（`Tests run: ... Failures: 0, Errors: 0`）、JaCoCo カバレッジレポートが `target/site/jacoco/index.html` に生成されます。

> 💡 初回は依存ライブラリの DL で 5〜10 分かかります。
> 💡 `BUILD FAILURE` が出たら [../education/TROUBLESHOOTING.md](../education/TROUBLESHOOTING.md) の Q10/Q11 を参照。

### 7-3. アプリ起動 & ヘルスチェック

ターミナルのタブを 2 つ使います（⌘+T で新規タブ）。

**タブ A**（アプリ起動。H2 メモリ DB で動くので Oracle は不要）:

```bash
cd ~/training/tsubuyaki-board
SPRING_PROFILES_ACTIVE=h2 ./mvnw spring-boot:run
```

`Started TsubuyakiApplication in X seconds` が出たら起動完了。**このタブは閉じずに残す**。

**タブ B**（ヘルスチェック）:

```bash
curl -s http://localhost:8080/actuator/health
```

期待出力:

```json
{"status":"UP"}
```

確認できたら、タブ A で **`Ctrl+C`** を押してアプリを停止します。

### 7-4. Codex CLI（💻 → 📦 コンテナ）

**Codex CLI の起動はあえてバッチ化していません**。`codex-shell` を自分でタイプするところから始めます（Codex を使った開発こそが研修の本題だからです）。

```bash
# 💻 ターミナル（新しいタブ推奨）で codex-shell エイリアスを実行
codex-shell
```

成功すると、プロンプトが **📦 Codex コンテナ内**に変わり、起動バナーが出ます：

```
codex@a3f5e7c2:/workspace$
```

コンテナの中で以下を実行：

```bash
codex --help
```

Codex CLI のヘルプが表示されれば §7-4 は合格です。抜けるには `exit`（または `Ctrl+D`）。

> 💡 `codex-shell: command not found` の場合は、`1_Macの準備` の完了後に**新しいターミナル**を開いていないだけのことが多いです。新しいタブを開いて再実行してください。それでもダメなら `bash ~/training/tsubuyaki-board/EasySetupForMacOS/bin/run-codex-mac.sh` を直接実行できます。
>
> 💡 ダブルクリック派は `EasySetupForMacOS/codex-shell.command` でも入れます。
>
> 💡 コンテナ内では `/workspace` がリポジトリのルートにマウントされ、`.env` や API キーは `/dev/null` でマスクされて Codex から見えません。`AGENTS.md` や `.codex/` は読み取り専用です。

---

## 8. 初回 push とローカル verify 緑化（💻 ターミナル → 🌐 ブラウザ）

本研修では合否判定に CI を使わず、**ローカルで `./mvnw -B -Ph2 verify` が BUILD SUCCESS すること**を確認します。

### 8-1. 状態確認 → push

```bash
git branch --show-current      # → <github-id> であること
git status                     # → nothing to commit, working tree clean

git push -u origin <github-id>
```

`-u origin <github-id>` で以降は `git push` だけで OK。push されるのは**あなたのブランチだけ**で、共有 `main` には影響しません。

> 💡 認証を求められたら、ユーザー名は GitHub ユーザー名、パスワードは §3-3 の token (`ghp_...`)。
> 📌 push が失敗する場合、Organization メンバー権限の反映に数分かかることがあります。3 分待って再 push、それでもダメなら講師へ。

---

## 9. 次に読むもの

1. **[../education/ONBOARDING.md](../education/ONBOARDING.md)** — 演習 3 日間の動き方（Windows 前提の記述は Mac に読み替え）
2. **[../EXERCISES.md](../EXERCISES.md)** — 機能要件（MUST / SHOULD / COULD）と受入基準
3. **[../AGENTS.md](../AGENTS.md)** — Codex への規範書
4. 詰まったら **[../education/TROUBLESHOOTING.md](../education/TROUBLESHOOTING.md)** → `3_環境チェック.command`（または `bash EasySetupForMacOS/bin/doctor-mac.sh`）

---

## 完了条件チェックリスト

研修 0-1 時間目終了時点で、以下が全て ✓ なら OK。

- [ ] Organization の招待を承認し、共有リポにアクセスできる
- [ ] Personal Access Token (classic) を取得済（7 days・`repo` スコープ）
- [ ] `git clone` 成功、**`~/` 配下**（例 `~/training/tsubuyaki-board`）に配置
- [ ] `chmod +x` で `.command` に実行許可を付与
- [ ] `1_Macの準備.command` 完走（Homebrew / JDK21 / Maven / podman machine / Codex イメージ）
- [ ] 自分の作業ブランチ `<github-id>` を `main` から作成
- [ ] `2_APIキーとGit設定.command` で `OPENAI_API_KEY` と git の `user.name` / `user.email` を登録
- [ ] `3_環境チェック.command` 全行 `[ OK ]` か `[WARN]`（`[ NG ]` なし）
- [ ] `./mvnw -B -Ph2 verify` BUILD SUCCESS
- [ ] `curl http://localhost:8080/actuator/health` が `{"status":"UP"}`
- [ ] `codex-shell` → `codex --help` 表示
- [ ] 初回 push 完了（自分の `<github-id>` ブランチが origin に上がっている）

すべて ✓ になったら `ONBOARDING.md` の **1-2 時間目** に進んでください。

---

## 研修が終わったら（環境の片付け・最終日のみ）

Mac をきれいな状態へ戻したいときだけ使います。`EasySetupForMacOS` フォルダの **`研修終了_環境削除.command`** をダブルクリックすると、研修環境を撤去します。

| 削除するもの | 残すもの |
|---|---|
| podman machine（コンテナ用の仮想マシン）/ `codex-devbox` イメージ / `~/.zshrc`・`~/.bash_profile` の研修設定 / `~/.codex-training`（研修用 API キー） | Homebrew 本体 / JDK / Maven / git / リポジトリのソース |

> ⚠️ 実行すると確認のため半角で `delete` と入力するよう求められます。**元に戻せません。**
> ⚠️ 削除前に、**push し忘れた変更が無いか**必ず確認してください。
> ⚠️ Homebrew や JDK も完全に消したい場合は、案内に従って `brew uninstall ...` を手動で実行してください。
> ⚠️ 共有 Mac では、研修終了時に **API キーを rotate**（OpenAI 側で発行し直し）してください。
