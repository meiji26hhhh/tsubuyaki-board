# TROUBLESHOOTING — 受講者向け FAQ

困ったらまず `bash scripts/doctor.sh` を実行。それでも分からなければ下記を参照。

## セットアップ

### Q1. `wsl --install` が「機能が無効です」で失敗する

```
管理者 PowerShell で:
  Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -All -NoRestart
  Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -All -NoRestart
PC 再起動 → wsl --install -d Ubuntu-22.04 --no-launch
```

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

### Q5. Codex が大量のファイルを書き換えはじめた

```bash
# Codex 側で Ctrl+C で中断
# シェルに戻ったら:
git status
git restore .              # 未コミットの変更を全て破棄
```

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

### Q9. `H2 vs Oracle` で CI だけ落ちる

- `SYSDATE` を使っていないか → `Instant.now()` に置き換える
- ID 採番が `IDENTITY` になっていないか → `@SequenceGenerator` に統一
- 予約語 (USER, DATE 等) をテーブル名・カラム名に使っていないか

## ビルド

### Q10. `./mvnw verify` が Checkstyle 警告で止まる

研修中はデフォルトで `failOnViolation=false` (警告のみ)。
もし fail で止まっている場合は `-Pstrict` を付けていないか確認。

### Q11. JaCoCo の閾値未達で fail

序盤 60%、中盤 70%、仕上げ 80% にスライドする（フェーズ「投稿一覧」「リファクタ＋カバレッジ80%到達」「仕上げ」で段階引き上げ）。CI もデフォルトは序盤 (60%) 設定。

```bash
./mvnw -B -Ph2 -Pcoverage-day2 verify   # 70% に上げる (プロファイル名は内部識別子)
```

## Git / GitHub

### Q12. PR を出したら CI が無限に走らない

- Actions タブで「Disable Actions」になっていないか
- fork でなく Template から作ったリポか (fork だと Actions がデフォルト無効)
- branch protection の status check 名が一致しているか

### Q13. CRLF / LF の差分が大量に出る

```bash
git config --global core.autocrlf input   # WSL / Mac
# Windows Git でも同じ
```

リポ内の `.gitattributes` で `* text=auto eol=lf` を強制しているので、
新規ファイルは LF になる。既存ファイルを直したい場合:

```bash
git rm --cached -r .
git reset --hard
git add -A
```

(未コミット変更がある場合は必ず一時退避 = `git stash`)

## 最後の手段

- 環境を破壊した気がする → `bash scripts/setup-wsl.sh --rollback` → 再セットアップ
- リポを壊した気がする → 自分のリポを Settings から delete → Template から再生成
- 何もかも分からない → 講師に「何を試して何が起きたか」を 3 行で報告する
