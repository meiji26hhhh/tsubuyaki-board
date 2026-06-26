# 社内つぶやきボード

AI 駆動開発研修 (3 日) の演習パート (19h + 成果まとめ 2h) で使う、Codex CLI と協働して
「社内つぶやきボード」を完走させる Spring Boot 演習リポジトリです。

## TL;DR

セットアップの**正本は [education/student-setup-guide.md](./education/student-setup-guide.md)**（受講生・講師ともこれを読む）。本 README には超圧縮版のみ置く。

```bash
# 1. TokyoItSchool-dev/tsubuyaki-board を Fork し、自分の fork <github-id>/tsubuyaki-board を clone (C:\workspace 配下)
# 2. 🪟 管理者 PowerShell:  Set-ExecutionPolicy -Scope Process Bypass; .\scripts\setup.ps1
# 3. PC 再起動 → スタートメニューで Ubuntu 初回ログイン
# 4. 🐧 Ubuntu:  cd /mnt/c/workspace/tsubuyaki-board && bash scripts/setup-wsl.sh
# 5. 🐧 Ubuntu:  git switch -c <github-id> origin/main  # 自分の作業ブランチ（fork の main にも upstream にも直接 push しない）
# 6. 🐧 Ubuntu:  OPENAI_API_KEY を ~/.bashrc に設定（値は画面表示しない）
# 7. 🐧 Ubuntu:  bash scripts/start-oracle.sh && ./mvnw -B -Ph2 verify
# 8. 🐧 Ubuntu:  codex-shell    # Codex devbox コンテナへ
# 9. 🌐 fork の <github-id> ブランチ → upstream main へ Draft PR を作成（講師レビュー用・マージしない）
```

詳細手順、つまずきポイント、用語ミニ辞書は [education/student-setup-guide.md](./education/student-setup-guide.md) を参照。

## 全体像

- **題材**: 「社内つぶやきボード」 (X風ミニ SNS) — `education/EXERCISES.md` を参照
- **スタック**: Spring Boot 3.4.1 + Thymeleaf + Spring Data JPA + Maven, JDK 21
- **DB (ローカル)**: Oracle DB XE 21c (Podman / `gvenzl/oracle-xe`)
- **DB (軽量・テスト用)**: H2 メモリ (`MODE=Oracle`)
- **AI エージェント**: Codex CLI (`@openai/codex`) を WSL + Podman 上で起動

## 主要ファイル

| ファイル | 役割 |
|---|---|
| `AGENTS.md` | Codex への規範書 (最優先で読まれる) |
| `.codex/config.toml` | Codex CLI の動作既定 |
| `.codex/prompts/` | 共通プロンプト (TDD サイクル等) |
| `education/EXERCISES.md` | 機能要件と受入基準 (MUST / SHOULD / COULD) |
| `education/student-setup-guide.md` | 受講生向けセットアップガイド |
| `education/ONBOARDING.md` | 演習 3 日間の動き方（N 時間目表記） |
| `education/TROUBLESHOOTING.md` | よくあるエラーと対処 |
| `docs/eclipse-guide.md` | Eclipse からアプリを起動・デバッグする手順 |
| `instructor/instructor-setup-guide.md` | 講師向けセットアップガイド |
| `pom.xml` | Spring Boot + 静的解析 + JaCoCo |
| `compose.yaml` | Oracle XE 起動定義 |
| `containers/codex-devbox/` | Codex 用 Podman コンテナ定義 |
| `scripts/` | キッティング / Doctor / 起動ラッパ |

## ディレクトリ

```
src/
├── main/
│   ├── java/com/example/tsubuyaki/
│   │   ├── TsubuyakiApplication.java      エントリポイント
│   │   ├── controller/PostController.java 投稿 Controller (TODO 多め)
│   │   ├── domain/Post.java               JPA Entity
│   │   ├── repository/PostRepository.java
│   │   ├── service/PostService.java
│   │   └── web/dto/PostForm.java
│   └── resources/
│       ├── application.yml
│       ├── application-local.yml          Oracle XE 接続
│       ├── application-h2.yml             軽量・テスト用
│       ├── templates/posts/*.html         Thymeleaf
│       ├── static/css/app.css
│       └── db/migration/V1__init.sql      Flyway
└── test/
    └── java/com/example/tsubuyaki/sample/
        SamplePostRepositoryTest.java      (削除禁止)
        SamplePostServiceTest.java         (削除禁止)
        SamplePostControllerTest.java      (削除禁止)
```

## よく使うコマンド

```bash
# 検査
bash scripts/doctor.sh                   # 全件
bash scripts/doctor.sh --quick           # 軽量

# DB
bash scripts/start-oracle.sh
bash scripts/stop-oracle.sh

# ビルド・テスト (テストは常に H2 で実行される)
./mvnw -B -Ph2 verify                    # 基本検証

# アプリ起動 (Eclipse から起動・デバッグする場合は docs/eclipse-guide.md を参照)
./mvnw -Plocal spring-boot:run           # Oracle XE 接続 (既定)
./mvnw -Ph2 spring-boot:run              # H2 で起動 (Oracle 不要)

# 1 本だけテストを動かす
./mvnw -B -Ph2 -Dtest='SamplePostControllerTest' test

# Codex
codex-shell                              # devbox に入る
# (コンテナ内) codex --help

# カバレッジ閾値の切替
./mvnw -B -Ph2 -Pcoverage-day3 -Pstrict verify  # 仕上げ合否判定 (80% + 警告→エラー)
```

## OpenAI API キーの渡し方

正本は [education/student-setup-guide.md §7](./education/student-setup-guide.md)。要点のみ：

- `OPENAI_API_KEY` は **WSL 側 `~/.bashrc` に書く**（Windows 環境変数は WSL に伝搬しない）
- `.env` は Oracle 接続用（`ORACLE_PWD` / `ORACLE_APP_PWD`）として使う — API キーは入れない
- Doctor や起動バナーはキーの先頭文字も表示しない。「設定済み」だけ確認する

## 次に読むもの

1. **受講生** → `education/student-setup-guide.md` で初日のセットアップを完了
2. **講師** → `instructor/instructor-setup-guide.md` で研修開始前の準備を完了
3. `AGENTS.md` — Codex に何をさせるか・させないか
4. `education/ONBOARDING.md` — 当日の流れ
5. `education/EXERCISES.md` — 何を作るか
6. 困ったら `education/TROUBLESHOOTING.md` → `bash scripts/doctor.sh`
