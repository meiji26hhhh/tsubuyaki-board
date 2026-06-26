# Eclipse (Pleiades) でアプリを起動・操作するガイド

この文書は、WSL の `./mvnw spring-boot:run` と並ぶ **もう一つのアプリ起動手段**として、
Eclipse (Pleiades) からアプリを起動・デバッグする手順をまとめたものです。
初回セットアップは [受講生向けセットアップガイド](../education/student-setup-guide.md) を正本とし、
ここでは Pleiades が `C:\Pleiades` に配置済みの状態から先を扱います。

## 0. このガイドの位置づけ

本研修では、アプリの起動方法が 2 つあります。**どちらを使っても構いません**。

- **(A) WSL の `./mvnw spring-boot:run`** — ターミナルから起動する方法。CI と同じ条件で動かせます。
- **(B) Eclipse から起動** — GUI から起動する方法。**ブレークポイントを使ったデバッグ**が手軽にできます。

使い分けの目安は次の通りです。

- アプリを起動して動きを確認したい・コードをデバッグしたい → どちらでも可。Eclipse はデバッグが得意。
- テスト・カバレッジ・最終検証（`./mvnw -B -Ph2 verify`）→ **WSL の `./mvnw` を基本**とします（CI と条件を揃えるため）。

つまり Eclipse は「エディタ ＋ アプリの起動・デバッグ」に使い、仕上げの検証は WSL で行う、という分担です。

## 1. 前提

- Pleiades を `C:\Pleiades` に配置済み（[student-setup-guide §4](../education/student-setup-guide.md)）。
- Eclipse のワークスペースは `C:\workspace`。リポジトリは `C:\workspace\tsubuyaki-board`（= WSL の `/mnt/c/workspace/tsubuyaki-board` と同じ実体）。
- **Windows 側に別途 JDK をインストールする必要はありません**。Pleiades 同梱の JDK 21 をそのまま使います。
- WSL 側のセットアップ（`scripts/setup-wsl.sh`）が完了していること。

## 2. プロジェクトをインポートする

1. Eclipse を起動し、ワークスペースに `C:\workspace` を指定します。
2. メニュー `File > Import...` を開きます。
3. `Maven > Existing Maven Projects` を選び `Next`。
4. `Root Directory` に `C:\workspace\tsubuyaki-board` を指定し、`pom.xml` にチェックが入っていることを確認して `Finish`。

初回は依存ライブラリのダウンロードで数分かかります。完了するとパッケージエクスプローラに `tsubuyaki-board` が表示されます。

## 3. 文字コードを UTF-8 にする

1. `Window > Preferences > General > Workspace` を開きます。
2. `Text file encoding` を `Other > UTF-8` にします。

`.java` が文字化けする場合は [TROUBLESHOOTING.md の Q2](../education/TROUBLESHOOTING.md) を参照してください。

## 4. Build Automatically と「二重ビルド」の扱い

Eclipse の自動ビルドと WSL の `./mvnw` を**同時に**走らせると、出力先 `target/` が競合して壊れることがあります（[TROUBLESHOOTING.md の Q3](../education/TROUBLESHOOTING.md)）。次の方針で運用してください。

- **Eclipse からアプリを起動・デバッグするとき** — Eclipse がコンパイルを担うので、`Project > Build Automatically` は ON のままで構いません。
- **WSL で `./mvnw verify` を回すとき** — その間は Eclipse 側のビルドを走らせないようにします（`Project > Build Automatically` を一時的に OFF にするか、verify 中は Eclipse のビルド操作を控える）。
- 迷ったら「**片方ずつ使う**」のが安全です。Eclipse で起動・デバッグする時間帯と、WSL で `verify` する時間帯を分けてください。

## 5. アプリを起動する（H2 / Oracle 不要）

H2 はメモリ DB なので、Oracle を起動しなくても単体で動きます。**まずはこちらを推奨**します。

起動方法は環境により 2 通りあります。Pleiades に Spring Tools が含まれていれば方法A が手軽です。無ければ方法B を使います。

### 方法A: Spring Boot ダッシュボード（Spring Tools がある場合）

1. `Window > Show View > Other... > Spring > Boot Dashboard` を開きます。
2. 一覧に表示される `tsubuyaki-board`（`TsubuyakiApplication`）を選びます。
3. 起動構成を編集し、`Profile` に `h2` を指定します。
4. 起動ボタン（▶）でアプリを起動します。

### 方法B: Java アプリケーションとして起動（汎用）

1. パッケージエクスプローラで `src/main/java/com/example/tsubuyaki/TsubuyakiApplication.java` を右クリックします。
2. `Run As > Java Application` を選びます。

   > 💡 プロファイル未指定だと既定の `local` で起動し、Oracle を探しに行きます。Oracle 未起動なら一度失敗しますが、次の手順でプロファイルを `h2` に変えるので問題ありません。

3. メニュー `Run > Run Configurations...` を開き、左の `Java Application` 配下から先ほどの `TsubuyakiApplication` を選びます。
4. `Environment` タブで `Add...` を押し、次を追加します。

   - Name: `SPRING_PROFILES_ACTIVE`
   - Value: `h2`

   （`Arguments` タブの `VM arguments` に `-Dspring.profiles.active=h2` を書いても同じ効果です。）

5. `Run` で起動します。

起動成功のサインは、コンソールに `Started TsubuyakiApplication in X seconds` が出ることです。

## 6. アプリを起動する（Oracle XE / local プロファイル）

Oracle に接続して動かす場合の手順です。

1. **事前に WSL で Oracle を起動**します。

   ```bash
   # 🐧 WSL Ubuntu
   cd /mnt/c/workspace/tsubuyaki-board
   bash scripts/start-oracle.sh
   ```

   Oracle XE が `localhost:1521` で待ち受けます。WSL2 のポート転送により、**Windows の Eclipse からも `localhost` で届きます**。

2. プロファイルは `local`（既定）です。方法B の `Environment` で `SPRING_PROFILES_ACTIVE=local` を指定するか、未指定のままでも `application.yml` の既定が `local` なので Oracle に接続します。

3. **パスワードの注意点**:

   - `application-local.yml` は接続パスワードに `${ORACLE_APP_PWD:tsubuyaki_pw}` を使います（環境変数 `ORACLE_APP_PWD` があればそれ、無ければ既定値 `tsubuyaki_pw`）。
   - `.env` で `ORACLE_APP_PWD` を既定値から**変更している**場合は、Eclipse の `Run Configurations > Environment` にも同名・同値の `ORACLE_APP_PWD` を追加してください。設定しないと `ORA-01017`（認証失敗）になります。

4. `Run` で起動します。

## 7. ヘルスチェック

アプリ起動後、ブラウザで次を開きます。

```text
http://localhost:8080/actuator/health
```

次の表示が出れば起動成功です。

```json
{"status":"UP"}
```

## 8. 停止する

コンソールビュー右上の赤い停止ボタン（■）でアプリを停止します。

## 9. デバッグ実行（ブレークポイント）

Eclipse から起動する最大の利点は、ブレークポイントを使ったデバッグです。

1. 止めたい行の**行番号の左端**をダブルクリックしてブレークポイントを置きます。
2. `TsubuyakiApplication` を右クリック `> Debug As > Java Application`（プロファイルの指定方法は §5 と同じ）。
3. ブラウザや `curl` でリクエストを送ると、その行で実行が止まります。変数の値を見たり、ステップ実行（F6）したりできます。

## 10. テストを Eclipse から実行する

1. テストクラス（例: `SamplePostServiceTest`）を右クリック `> Run As > JUnit Test`。
2. テストは**常に H2 で動きます**（`src/test/resources` の設定で固定。プロファイル指定は不要）。

ただし、**カバレッジ閾値判定や静的解析を含む最終検証は WSL の `./mvnw -B -Ph2 verify` が正本**です。Eclipse の JUnit 実行は、書いたテストを素早く回す用途に使ってください。

## 11. 困ったとき

- **文字化け** → [TROUBLESHOOTING.md の Q2](../education/TROUBLESHOOTING.md)
- **`target/` 競合・二重ビルド** → [TROUBLESHOOTING.md の Q3](../education/TROUBLESHOOTING.md)
- **Oracle に接続できない** → まず WSL で `bash scripts/start-oracle.sh` を実行。それでもダメなら H2（§5）に切り替えれば進行を止めません。[TROUBLESHOOTING.md の Q7 / Q8](../education/TROUBLESHOOTING.md) も参照。
