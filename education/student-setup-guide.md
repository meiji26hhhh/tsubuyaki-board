# 受講生向けセットアップガイド

AI 駆動開発研修 3 日コースで使う「社内つぶやきボード」演習リポジトリの初期セットアップ手順です。
**研修 0-1 時間目で「アプリが空起動できる状態」にする**ことがゴール。

詳細な進め方は [ONBOARDING.md](./ONBOARDING.md) を、つまずいたら [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) を参照してください。

---

## 0. このガイドの読み方

- **コマンドは上から順に実行**。前ステップが成功してから次へ。
- 期待出力と違うものが出たら、即座に隣の人か講師に確認。**自己流に進めない**。
- 詳細解説は本ガイドではしません。コマンドのみ。背景は ONBOARDING.md / README.md / TROUBLESHOOTING.md を読んでください。
- 「**どのターミナルで実行するか**」を毎回示します。アイコン凡例：
  - 🪟 **管理者 PowerShell**（Windows 側、UAC で承認したシェル）
  - 🐧 **WSL Ubuntu ターミナル**（Linux 側、プロンプトが `ユーザ名@PCの名前:~$` で終わる）
  - 📦 **Codex コンテナ内**（`codex-shell` 実行後に入った状態。プロンプトが `codex@xxxxxxxx:/workspace$` 等になる）
  - 🌐 **ブラウザ**（GitHub / GitHub Classroom の Web UI）

---

## 0.5. 用語ミニ辞書（初見の人向け）

| 用語 | ざっくり説明 |
|---|---|
| **PowerShell** | Windows 標準のコマンド入力ツール。本研修では「**管理者として実行**」した状態でキッティング用に使う。スタートメニューで `PowerShell` と検索 → 右クリック → 「管理者として実行」。 |
| **WSL2** | Windows 上で Linux を動かす仕組み。本研修では Ubuntu 22.04 を入れて使う。初回だけ Windows 機能の有効化と再起動が必要。 |
| **Ubuntu (WSL)** | WSL2 上で動く Linux ディストリビューション。スタートメニューから `Ubuntu` を起動するか、Windows Terminal の「Ubuntu」プロファイルを開くと入れる。 |
| **Windows Terminal** | Windows 標準の高機能ターミナル。PowerShell と Ubuntu をタブで切り替えられる。 `setup.ps1` が自動導入する。 |
| **コンテナ** | アプリケーション一式を箱詰めして配布・実行する仕組み。本研修では Oracle DB と Codex CLI 実行環境をコンテナで起動する。 |
| **Podman** | コンテナを動かすツール（Docker と同等）。`setup.ps1`／`setup-wsl.sh` で自動導入される。本研修では Podman を Docker の代わりに使う。 |
| **Codex CLI** | OpenAI の AI 開発エージェント。ターミナルから対話的に使う。本研修では Podman コンテナ内で動かす（`codex-shell` コマンドで起動）。 |
| **GitHub Classroom** | 教員が課題リポジトリの雛形を一括配布し、受講生ごとに個人リポジトリを自動生成する GitHub の仕組み。`https://classroom.github.com/a/xxxxxxxx` 形式の URL から参加する。 |
| **feature ブランチ** | 機能ごとに分けて作業する Git のブランチ。`feature/<your-name>-m1` のような名前で切る。main 直接 push は CI に拒否される。 |
| **Maven Wrapper (`./mvnw`)** | Maven 本体を別途インストールしなくても、リポジトリ同梱のスクリプトでビルドできる仕組み。WSL 側で実行する。 |
| **Pleiades** | 日本語化済み Eclipse 配布物。本研修ではエディタとしてのみ使い、**ビルドは WSL の `./mvnw`** で行う。 |
| **研修ハーネス (Codex Guard)** | Codex devbox コンテナ内で、`rm -rf /`・`git rm -r`・`git reset --hard`・`.env` 読み取り等の「研修中に必要のない破壊的操作」を **物理的にブロック**する仕組み。Codex がプロンプトインジェクション等で暴走しても被害を受けない。詳細は [TROUBLESHOOTING.md Q4-2/Q4-3](./TROUBLESHOOTING.md)、[AGENTS.md §7.3/§7.5](../AGENTS.md)。 |

> 💡 用語の詳細は ONBOARDING.md と AGENTS.md でも適宜出てきます。本ガイドではこれ以上深掘りしません。

---

## 1. 必要なアカウント（前日までに準備）

| 項目 | 用途 | 確認方法 |
|---|---|---|
| GitHub アカウント | Classroom リポへの push、PR | https://github.com にログインできること |
| OpenAI アカウント | Codex CLI の認証 | API キー (`sk-...`) を発行済、課金（クレジット残高）あり |

> OpenAI API キーは研修運営から配布されます。

---

## 2. 講師から受け取るもの

研修初日に講師から以下を受け取ります：

- **GitHub Classroom Assignment 招待 URL**（`https://classroom.github.com/a/xxxxxxxx` 形式）
- **Pleiades (Eclipse + 日本語パック) の配布媒体**（USB / 共有ドライブ）
- **Organization 名**（clone 時に URL に含まれます）

---

## 3. GitHub Classroom Assignment に参加

ここから**🌐 ブラウザ操作**です。普段使っているブラウザ（Chrome / Edge 等）を使ってください。

### 3-1. Classroom Assignment URL を開く

1. 講師から受け取った Classroom Assignment URL（`https://classroom.github.com/a/xxxxxxxx` 形式）をブラウザのアドレスバーに貼り付けて Enter。
2. GitHub にサインインしていない場合は、サインイン画面が出ます。**研修で使う GitHub アカウントで** Sign in。
3. 「**Authorize GitHub Classroom**」画面が出たら **Authorize** をクリック。

### 3-2. Assignment を Accept

1. 「**Accept this assignment**」という緑のボタンが画面中央付近にあるのでクリック。
2. クリック後、「**You're ready to go!**」または「**Your assignment repository has been created**」のような画面に切り替わります。
3. リポジトリ生成には **30 秒 〜 1 分**程度かかります。生成中はぐるぐるマークが回ります。

> 💡 1 分待っても画面が変わらない場合は、ブラウザをリロード（F5）。生成済みなら自分のリポへのリンクが表示されます。

### 3-3. 生成された自分のリポを開く

1. 画面に表示された自分のリポへのリンク、または以下の URL 形式で自分のリポを開く：
   - `https://github.com/<org>/<assignment-name>-<your-github-id>`
   - `<org>` は講師から事前に共有された Organization 名
   - `<assignment-name>` は講師が設定した課題名（例: `tsubuyaki-board`）
   - `<your-github-id>` はあなたの GitHub ユーザ名（小文字）
2. リポジトリのトップ画面で以下が見えれば OK：
   - リポジトリ名が右上に表示されている
   - ファイル一覧に `AGENTS.md`、`README.md`、`EXERCISES.md`、`pom.xml` などが見える
   - 左上の「Private」バッジが付いている
3. 右上の緑の「**< > Code**」ボタンをクリック → 「**HTTPS**」タブを選択 → 表示される URL（`https://github.com/<org>/<assignment-name>-<your-github-id>.git`）をコピー。

> 📌 この URL は次のステップ（§4）で clone に使います。コピーしたままにしておくか、メモ帳に貼り付けておくと楽です。
> 📌 「You don't have access to this assignment」と出たら → 講師に Organization の招待状況を確認してもらう（TROUBLESHOOTING のセットアップ§Q14）。

---

## 4. Windows キッティング（🪟 管理者 PowerShell）

> ⚠️ 本セクションは全て **🪟 管理者 PowerShell** で実行します。通常 PowerShell では権限不足で失敗します。

### 4-1. Pleiades を配置

配布媒体（USB / 共有ドライブ）から zip を取得し、エクスプローラで以下に解凍：

- 配置先: `C:\Pleiades`
- 中に `eclipse\eclipse.exe` が見える状態になっていれば OK

> 💡 zip の解凍は、配布媒体上ではなく**ローカルディスクに解凍してから移動**しても OK。長いパスの解凍エラーを避けたい時は、まず `C:\Pleiades` 直下に解凍するのが安全。

### 4-2. 管理者 PowerShell を起動

1. キーボードの **Windows キー**を押す（スタートメニューが開く）。
2. `PowerShell` と入力（検索結果に「Windows PowerShell」が出る）。
3. 検索結果の「Windows PowerShell」を**右クリック** → 「**管理者として実行**」をクリック。
4. ユーザーアカウント制御（UAC）のダイアログ「このアプリがデバイスに変更を加えることを許可しますか？」が出るので「**はい**」をクリック。
5. 青いウィンドウで `PS C:\WINDOWS\system32>` のようなプロンプトが出れば OK。タイトルバーに「**管理者**」と表示されていることを確認。

> 📌 タイトルバーに「管理者」が無い場合は通常 PowerShell。閉じて 4-2 をやり直してください。

### 4-3. リポジトリを `C:\workspace` 配下に clone

🪟 管理者 PowerShell で以下を順に実行（`<org>` と `<assignment-name>-<your-github-id>` は §3-3 で確認したものに置換）：

```powershell
# C:\workspace が無ければ作成（既にあれば何もしない）
New-Item -ItemType Directory -Force -Path "C:\workspace" | Out-Null

# 移動
cd C:\workspace

# clone（§3-3 でコピーした URL を使う）
git clone https://github.com/<org>/<assignment-name>-<your-github-id>.git

# リポジトリ内に移動
cd <assignment-name>-<your-github-id>
```

> 💡 `git` コマンドが「コマンドが見つかりません」と出る場合は、Git for Windows が未導入。後続の `setup.ps1` を先に走らせる必要があるため、いったん別シェルから `winget install Git.Git` するか、講師に確認してください。
> 💡 clone 時に GitHub の認証画面（ブラウザ）が開くことがあります。指示に従ってサインインしてください。

### 4-4. キッティングスクリプトを実行

引き続き 🪟 管理者 PowerShell（カレントディレクトリは clone したリポの中）で：

```powershell
# このセッション内だけ実行ポリシーを Bypass にする
# (これをしないと .ps1 がブロックされる。Process スコープなので
# ターミナルを閉じれば元に戻る — 永続的な変更ではない)
Set-ExecutionPolicy -Scope Process Bypass

# キッティング本体を実行
.\scripts\setup.ps1
```

このスクリプトが以下を自動でやります：

- WSL2 機能（VirtualMachinePlatform / WSL）の有効化
- Ubuntu 22.04 ディストロの導入（初回ログインはまだしない）
- `winget` で：Git for Windows / Podman Desktop / Windows Terminal
- `git config --global core.autocrlf input` の設定（改行コードの混乱回避）
- `C:\workspace` の作成（既存ならスキップ）
- `C:\Pleiades` の存在確認

**所要時間: 5〜15 分**。実行ログは `C:\workspace\.kitting\setup-YYYYMMDD-HHMMSS.log` に保存されます。

### 4-5. PC を再起動

スクリプトが終わったら、画面に再起動が必要な旨が表示されます。**PC を再起動**してください（スタートメニュー → 電源 → 再起動）。

> 📌 WSL 機能の有効化は再起動が必要。再起動せずに次のステップに進むと「カーネルが見つからない」エラーになります。
> 📌 詳細な対処は [TROUBLESHOOTING.md の Q1](./TROUBLESHOOTING.md) を参照。

---

## 5. WSL キッティング（🐧 Ubuntu）

再起動後の手順。**ここから操作するターミナルが WSL Ubuntu に変わります**。PowerShell ではありません。

### 5-1. Ubuntu の初回起動（ユーザ名・パスワード設定）

1. **Windows キー**を押す → `Ubuntu` と入力 → 「**Ubuntu 22.04 LTS**」（または `Ubuntu`）をクリックして起動。
2. 黒いウィンドウが開き、「**Installing, this may take a few minutes...**」と表示される。**初回のみ 1〜3 分待つ**。
3. `Enter new UNIX username:` と聞かれたら、半角英小文字のユーザ名を入力（Windows のユーザ名とは別物で OK。例: `kensuke`）。
4. `New password:` と聞かれたらパスワードを入力（**画面には何も表示されないが、ちゃんと入力されている**）。確認用にもう一度同じパスワードを入れる。
5. プロンプトが `ユーザ名@PCの名前:~$` の形になれば、Ubuntu のセットアップ完了。

> 💡 ここで設定したパスワードは、後続の `sudo` で必要になります。**忘れないようにメモ**。
> 💡 パスワード入力中に「何も表示されない」のは Linux の仕様（隠して安全のため）。落ち着いてタイプして Enter してください。

### 5-2. Windows Terminal で Ubuntu を開く（推奨）

`setup.ps1` が **Windows Terminal** も導入しているので、以降は Windows Terminal の Ubuntu タブを使う方が快適です。

1. **Windows キー** → `Terminal` または `Windows Terminal` で検索 → 起動。
2. タイトルバーの **下向き矢印 `∨`** をクリック → ドロップダウンから「**Ubuntu**」「**Ubuntu-22.04**」のような項目をクリック。
3. プロンプトが `ユーザ名@PCの名前:~$` になれば OK。

> 💡 これ以降「🐧 WSL ターミナルで実行」と書かれている箇所は、この Windows Terminal の Ubuntu タブで実行します。

### 5-3. PowerShell と Ubuntu の見分け方

混乱しやすいので明示：

| ターミナル | プロンプト例 | 用途 |
|---|---|---|
| 🪟 PowerShell | `PS C:\workspace>` | Windows 側のキッティング（§4 のみ） |
| 🐧 Ubuntu (WSL) | `kensuke@DESKTOP-XYZ:~$` | 以降のほぼ全ての作業 |
| 📦 Codex コンテナ | `codex@a3f5...:/workspace$` | Codex CLI を使う時のみ |

§4 が終わった後は **基本的に Ubuntu** で作業すると覚えてください。

### 5-4. リポジトリへ移動

🐧 Ubuntu で以下を実行：

```bash
# Windows の C:\workspace は WSL からは /mnt/c/workspace で見える
cd /mnt/c/workspace/<assignment-name>-<your-github-id>

# 念のため、リポジトリ内にいるか確認
pwd
ls
# 出力例:
#   /mnt/c/workspace/tsubuyaki-board-kensuke
#   AGENTS.md  EXERCISES.md  README.md  pom.xml  scripts/  ...
```

> 💡 Windows の `C:\workspace\foo` は WSL からは `/mnt/c/workspace/foo` として参照します（パスの読み替え）。逆向きは Windows のエクスプローラで `\\wsl$\Ubuntu-22.04\home\<ユーザ名>` でアクセス可能。
> 💡 タブ補完（Tab キー）が効きます。長いディレクトリ名は数文字入力して Tab。

### 5-5. WSL 側のキッティングスクリプトを実行

```bash
bash scripts/setup-wsl.sh
```

途中で `sudo` のパスワードを 1 回聞かれます（§5-1 で設定したパスワード）。

このスクリプトが以下を `apt` で導入します：

- Eclipse Temurin JDK 21（Java 21）
- Maven
- Podman + podman-compose（コンテナ実行）
- Codex CLI 用 devbox コンテナイメージ（`codex-devbox:latest`）のビルド
- `gh` CLI、ripgrep、fd-find、jq などの便利ツール
- `~/.bashrc` に **`codex-shell`** エイリアスを追加（後で §8-5 で使う）

**所要時間: 5〜10 分**。

### 5-6. 完了後の確認

スクリプトが終わったら、新しいシェルを開き直して反映：

```bash
# .bashrc を読み直す（あるいはターミナルを開き直す）
source ~/.bashrc

# Java と Maven が入ったか確認
java --version       # → openjdk 21 ...
mvn --version        # → Apache Maven 3.9.x ...
podman --version     # → podman version 4.x ...
```

> 📌 1 つでも「コマンドが見つかりません」になったら、[TROUBLESHOOTING.md](./TROUBLESHOOTING.md) を参照、または `bash scripts/setup-wsl.sh` をもう一度走らせる。

---

## 6. feature ブランチを切る（🐧 Ubuntu）

main 直 push は CI のブランチ保護で拒否されます。**必ず feature ブランチで開発**します。

```bash
# 現在のブランチを確認（最初は main のはず）
git branch --show-current
# → main

# feature ブランチを「作って・切り替える」
git switch -c feature/<your-name>-m1

# 切り替わったか確認
git branch --show-current
# → feature/<your-name>-m1
```

例: `git switch -c feature/yamada-m1`

> 💡 `git switch -c <名前>` は「ブランチを新規作成して、そこに切り替える」操作です。`-c` 無しの `git switch <名前>` は既存ブランチへの切替のみ。
> 📌 fork は不要です。push 先は自分の Classroom リポジトリ（origin）です。
> 📌 ブランチ名規約は [AGENTS.md §3.2](../AGENTS.md) を参照。例: `feature/m1-post-list` のように `<課題番号>-<要約>` 形式でも OK。

---

## 7. `.env` と `OPENAI_API_KEY` を設定（🐧 Ubuntu）

「`.env`」と「`~/.bashrc`」の **2 箇所**に値を入れます。役割が違います：

| ファイル | 用途 | 編集対象キー |
|---|---|---|
| `.env`（リポジトリ直下） | Oracle DB コンテナ起動時のパスワード等 | `ORACLE_PWD` / `ORACLE_APP_PWD` |
| `~/.bashrc`（ホーム） | シェル起動時に毎回読まれる環境変数 | `OPENAI_API_KEY` |

### 7-1. `.env` を雛形からコピー

```bash
# リポルートにいることを確認
pwd
# → /mnt/c/workspace/<assignment-name>-<your-github-id>

# 雛形をコピー（同名ファイルが既にあれば上書きせず注意表示）
cp -i dotenv.example .env

# 中身を確認
cat .env
```

`.env` の中身：

```dotenv
OPENAI_API_KEY=sk-your-key-here       # ← ここは §7-2 で別ファイルに書くので、ここは触らなくて良い
ORACLE_PWD=Training#2026              # ← デフォルト値そのままで OK
ORACLE_APP_PWD=butsubutsu_pw          # ← デフォルト値そのままで OK
SPRING_PROFILES_ACTIVE=local          # ← デフォルト値そのままで OK
```

**研修ではデフォルト値のまま**で動作します。本番運用するなら必ず変更してください。

> 💡 `.env` は `.gitignore` で除外済。コミットされません。
> 💡 `.env` 内の `OPENAI_API_KEY` 行は無視されます（次の §7-2 で `~/.bashrc` 経由で設定するため）。

### 7-2. `OPENAI_API_KEY` を `~/.bashrc` に追記

講師から配布された自分用のキー（`sk-` で始まる長い文字列）を、シェルが毎回読む `~/.bashrc` に書き込みます。

```bash
# 自分のキーに置換して実行（sk-xxxx の部分を書き換える）
echo 'export OPENAI_API_KEY=sk-xxxx-your-actual-key' >> ~/.bashrc

# 反映
source ~/.bashrc

# 設定されたか確認（先頭 7 文字だけ表示して安全に確認）
echo "${OPENAI_API_KEY:0:7}..."
# → sk-xxxx...
```

> ⚠️ **キーは絶対にコミットしないこと**。`git add ~/.bashrc` のような事故は避ける（`~/.bashrc` はリポ外なので通常は起きない）。
> ⚠️ ターミナル履歴（`~/.bash_history`）には残ります。共有 PC では研修終了時に **キーを rotate**（OpenAI 側で発行し直し）してください。

### 7-3. （補足）エディタで直接編集したい場合

`echo` ではなくエディタで開きたい場合：

```bash
# nano (シンプル、初学者向け。保存 = Ctrl+O Enter / 終了 = Ctrl+X)
nano ~/.bashrc

# vim-tiny / vi (慣れている人向け)
vi ~/.bashrc
```

ファイル末尾に `export OPENAI_API_KEY=sk-xxxx` を 1 行追記して保存。

---

## 8. 動作確認 5 点セット（🐧 Ubuntu）

以下 5 つが全て通れば 0-1 時間目完了です。**全て 🐧 Ubuntu で**、リポルート（`/mnt/c/workspace/<assignment-name>-<your-github-id>`）にいる状態で実行します。

### 8-1. Doctor（環境チェック）

```bash
bash scripts/doctor.sh --quick
```

期待出力（行頭の記号を確認）:

```
[ OK ] Java 21 ...
[ OK ] Maven 3.9.x ...
[ OK ] Podman 4.x ...
[WARN] Oracle container は未起動  ← この時点では未起動なので WARN で OK
[ OK ] codex-devbox:latest イメージあり
[ OK ] OPENAI_API_KEY 設定済 (先頭 sk-)
...
```

判定:
- 全行が `[ OK ]` または `[WARN]` → 次へ
- 1 つでも `[ NG ]` → [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) で該当項目を参照、または講師に報告

### 8-2. Oracle XE 起動

```bash
bash scripts/start-oracle.sh
```

このスクリプトは:
1. `compose.yaml` を使って Oracle XE コンテナを起動
2. healthcheck が `healthy` になるまで待機

期待出力（最終行）:

```
✓ Oracle XE (container butsubutsu-oracle) is healthy.
```

**初回は 5〜10 分かかります**（イメージ pull とスキーマ初期化）。2 回目以降は数十秒。

進捗確認したい場合は、別タブで `podman ps` を実行：

```bash
podman ps
# CONTAINER ID  IMAGE                                     STATUS               PORTS                  NAMES
# abc123def456  docker.io/gvenzl/oracle-xe:21.3.0-slim... Up 5 minutes (healthy)  0.0.0.0:1521->1521/tcp butsubutsu-oracle
```

`STATUS` が `(healthy)` で確定。

> 💡 `start-oracle.sh` で問題が出た場合は [TROUBLESHOOTING.md の Q7](./TROUBLESHOOTING.md) を参照。

### 8-3. ビルド & テスト（H2 で）

```bash
./mvnw -B -Ph2 verify
```

`-Ph2` は「H2 メモリ DB プロファイルを有効化」の意味。Oracle に依存せず軽量に動かせるので、まず H2 で確認。

期待出力（最後の方）:

```
[INFO] BUILD SUCCESS
[INFO] -----------------------------------
[INFO] Total time:  XX s
```

JUnit テストが全て緑、JaCoCo カバレッジレポートが `target/site/jacoco/index.html` に生成されます。

> 💡 初回は依存ライブラリの DL で 5〜10 分かかります。
> 💡 `BUILD FAILURE` が出たら [TROUBLESHOOTING.md Q10/Q11](./TROUBLESHOOTING.md#ビルド) を参照。

### 8-4. アプリ起動 & ヘルスチェック

**ここから 🐧 Ubuntu のターミナルを 2 つ使います。**

#### 8-4-1. アプリ起動（タブ A）

現在のターミナル（タブ A とする）でアプリを起動：

```bash
SPRING_PROFILES_ACTIVE=h2 ./mvnw spring-boot:run
```

`Started ButsubutsuApplication in X seconds` の行が出たら起動完了。**このターミナルはアプリのログを表示し続けるので、閉じずに残しておく**。

#### 8-4-2. ヘルスチェック（タブ B — 新規タブ）

別の Ubuntu タブを開きます。Windows Terminal なら：

- ショートカット: `Ctrl + Shift + T` で新規タブ → タイトルバーの `∨` → 「Ubuntu」を選択
- または `Ctrl + Shift + 1` 〜 `9` のような既定ショートカットが効く環境もあります

新しいタブ（タブ B）で以下を実行：

```bash
# ホスト OS 自身のポート 8080 にアクセスする (WSL 内からも localhost で届く)
curl -s http://localhost:8080/actuator/health
```

期待出力:

```json
{"status":"UP"}
```

#### 8-4-3. アプリを停止

確認が終わったら、タブ A に戻って **`Ctrl+C`** を押してアプリを停止。タブ B はそのまま開いたままで OK（次の §8-5 で使う）。

> 💡 「タブ A と B どっち？」を毎回意識してください。アプリを起動したタブで `curl` を打つと、アプリが Ctrl+C 待ち状態なので動きません。
> 💡 タブを増やせない環境では、`tmux` で画面分割するか、`./mvnw spring-boot:run &` でバックグラウンド起動 → `kill %1` で停止、でも代替可能（中級者向け）。

### 8-5. Codex CLI（📦 コンテナ）

```bash
# 🐧 Ubuntu で codex-shell エイリアスを実行
codex-shell
```

成功すると、プロンプトが Ubuntu から **📦 Codex コンテナ内**に変わります：

```
codex@a3f5e7c2:/workspace$
```

コンテナの中で以下を実行：

```bash
# Codex CLI のヘルプ表示
codex --help
```

期待出力: Codex CLI のヘルプメッセージ（使えるサブコマンド一覧）が表示されること。

コンテナから抜けるには:

```bash
exit
# または Ctrl+D
```

プロンプトが元の Ubuntu（`ユーザ名@PCの名前:~$`）に戻れば OK。

> 💡 `codex-shell` 内では `/workspace` がリポジトリのルートにマウントされます。コンテナ内の変更はホストのリポにそのまま反映されます。
> 💡 「`OPENAI_API_KEY` が見つかりません」と言われたら → §7-2 が未完了。コンテナを抜けて再設定。

---

## 9. 初回 push と CI 緑化（🐧 Ubuntu → 🌐 ブラウザ）

ここまで完了したら、初回 push で GitHub Actions が動くか確認します。

### 9-1. 状態確認（push 前）

```bash
# 自分が今どのブランチにいるか
git branch --show-current
# → feature/<your-name>-m1   ← §6 で作ったブランチ名であること

# 変更ファイルが無いことを確認（このタイミングではセットアップだけで未編集のはず）
git status
# → nothing to commit, working tree clean
```

> 💡 もし `.env` や生成物が `Untracked files` に出ていても、それらは `.gitignore` で除外されている設計です。心配なら `cat .gitignore` で確認。

### 9-2. push

```bash
git push -u origin feature/<your-name>-m1
```

`-u origin <branch>` は「以降この feature ブランチは origin（自分の Classroom リポ）を追跡する」設定。次回からは `git push` だけで OK。

#### 認証が要求された場合

初回 push 時にユーザ名・パスワード（または PAT）を聞かれることがあります。Git for Windows 経由なら、ブラウザが開いて GitHub の OAuth 認証が走ります。指示に従ってサインインしてください。

> 💡 `gh` CLI で先に `gh auth login` を済ませてあるとスムーズです。

### 9-3. Actions タブで CI を確認

1. 🌐 ブラウザで自分のリポジトリを開く（§3-3 で確認した URL）。
2. 上部のタブ「**Actions**」をクリック。
3. 最新の workflow run（タイトルは初回コミットメッセージのもの）が表示される。
4. クリックしてジョブ詳細を開く → **Build + Test (H2)** ジョブが回り、緑のチェックマーク `✓` で完了することを確認。
5. 所要時間は 3〜5 分程度。

> 📌 push が失敗する場合: Classroom リポへの書き込み権限が反映されるまで数分かかることがあります。3 分ほど待ってから再 push、それでもダメなら講師へ連絡。
> 📌 CI が起動しない場合: 自分のリポの **Settings → Actions → General** で「Allow all actions and reusable workflows」が選択されているか確認。Classroom 経由のリポは Actions がデフォルト無効のことがあります。
> 📌 ジョブが赤（×）になった場合: クリックして失敗したステップのログを読む。よくあるのは「テスト失敗」「`./mvnw verify` の依存解決失敗」。[TROUBLESHOOTING.md](./TROUBLESHOOTING.md) を参照。

---

## 10. 次に読むもの

ここまで通ったら、以下の順で読み進めてください：

1. **[ONBOARDING.md](./ONBOARDING.md)** — 演習 3 日間の動き方（21 時間のタイムテーブル、Codex 協働ループ、禁止事項）
2. **[../EXERCISES.md](../EXERCISES.md)** — 機能要件（MUST / SHOULD / COULD）と受入基準
3. **[../AGENTS.md](../AGENTS.md)** — Codex への規範書（Codex が最優先で読むファイル）
4. 詰まったら **[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)** → `bash scripts/doctor.sh`

---

## 完了条件チェックリスト

研修 0-1 時間目終了時点で、以下が全て ✓ なら OK。

- [ ] Classroom Assignment URL から自分の private リポを生成済
- [ ] `git clone` 成功、`C:\workspace\<repo-name>` に配置
- [ ] `setup.ps1` → `setup-wsl.sh` 完走
- [ ] `feature/<your-name>-m1` ブランチを作成
- [ ] `OPENAI_API_KEY` を `~/.bashrc` に設定
- [ ] `bash scripts/start-oracle.sh` で `butsubutsu-oracle` が healthy（§8-2）
- [ ] `doctor.sh --quick` 全行 `[ OK ]` か `[WARN]`
- [ ] `./mvnw -B -Ph2 verify` BUILD SUCCESS
- [ ] `curl /actuator/health` が `{"status":"UP"}`
- [ ] `codex-shell` → `codex --help` 表示
- [ ] 初回 push で Actions タブの `Build + Test (H2)` が緑

すべて ✓ になったら、`ONBOARDING.md` の **1-2 時間目（仕様読解＋プロンプト準備）** に進んでください。
