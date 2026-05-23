# 社内つぶやきボード

AI 駆動開発研修 (3 日) の演習パート (19h + 成果まとめ 2h) で使う、Codex CLI と協働して
「社内つぶやきボード」を完走させる Spring Boot 演習リポジトリです。

## TL;DR

```bash
# 1. テンプレから自分のリポを作って clone
#    GitHub の「Use this template」ボタンから自分のアカウントにリポを作成し、
#    C:\workspace 配下に clone する。

# 2. キッティング (講師が事前に終わっている場合は省略可)
.\scripts\setup.ps1                 # 管理者 PowerShell
wsl bash scripts/setup-wsl.sh       # WSL Ubuntu

# 3. API キーを設定 (各自で取得)
export OPENAI_API_KEY=sk-...

# 4. Oracle XE を起動
bash scripts/start-oracle.sh

# 5. ビルドとテスト (H2 で)
./mvnw -B -Ph2 verify

# 6. アプリ起動
SPRING_PROFILES_ACTIVE=local ./mvnw spring-boot:run
# http://localhost:8080/posts

# 7. Codex に入る
codex-shell                         # podman 経由で Codex devbox に入る
```

## 全体像

- **題材**: 「社内つぶやきボード」 (X風ミニ SNS) — `EXERCISES.md` を参照
- **スタック**: Spring Boot 3.4.x + Thymeleaf + Spring Data JPA + Maven, JDK 21
- **DB (ローカル)**: Oracle DB XE 21c (Podman / `gvenzl/oracle-xe`)
- **DB (CI)**: H2 メモリ (`MODE=Oracle`)
- **AI エージェント**: Codex CLI (`@openai/codex`) を WSL + Podman 上で起動
- **CI**: GitHub Actions で Maven build + JUnit + Checkstyle + SpotBugs + JaCoCo

## 主要ファイル

| ファイル | 役割 |
|---|---|
| `AGENTS.md` | Codex への規範書 (最優先で読まれる) |
| `.codex/config.toml` | Codex CLI の動作既定 |
| `.codex/prompts/` | 共通プロンプト (TDD サイクル等) |
| `EXERCISES.md` | 機能要件と受入基準 (MUST / SHOULD / COULD) |
| `ONBOARDING.md` | 演習 3 日間の動き方（N 時間目表記） |
| `TROUBLESHOOTING.md` | よくあるエラーと対処 |
| `pom.xml` | Spring Boot + 静的解析 + JaCoCo |
| `compose.yaml` | Oracle XE 起動定義 |
| `containers/codex-devbox/` | Codex 用 Podman コンテナ定義 |
| `scripts/` | キッティング / Doctor / 起動ラッパ |

## ディレクトリ

```
src/
├── main/
│   ├── java/com/example/butsubutsu/
│   │   ├── ButsubutsuApplication.java     エントリポイント
│   │   ├── controller/PostController.java 投稿 Controller (TODO 多め)
│   │   ├── domain/Post.java               JPA Entity
│   │   ├── repository/PostRepository.java
│   │   ├── service/PostService.java
│   │   └── web/dto/PostForm.java
│   └── resources/
│       ├── application.yml
│       ├── application-local.yml          Oracle XE 接続
│       ├── application-h2.yml             CI / 軽量
│       ├── templates/posts/*.html         Thymeleaf
│       ├── static/css/app.css
│       └── db/migration/V1__init.sql      Flyway
└── test/
    └── java/com/example/butsubutsu/sample/
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

# ビルド・テスト
./mvnw -B -Ph2 verify                    # CI と同等 (H2)
./mvnw -B -Plocal verify                 # ローカル Oracle XE

# 1 本だけテストを動かす
./mvnw -B -Ph2 -Dtest='SamplePostControllerTest' test

# Codex
codex-shell                              # devbox に入る
# (コンテナ内) codex --help

# カバレッジ閾値の切替
./mvnw -B -Ph2 -Pcoverage-day3 verify    # 仕上げ段階 (80%) ※プロファイル名は内部識別子
./mvnw -B -Ph2 -Pcoverage-day3 -Pstrict verify  # 警告→エラー化
```

## OpenAI API キーの渡し方

```bash
# WSL の ~/.bashrc の最後に追記 (個人マシン専用):
export OPENAI_API_KEY=sk-...

# 1 セッションだけ:
export OPENAI_API_KEY=sk-... ; codex-shell

# .env ファイル経由 (compose.yaml の Oracle パスワード等と一緒に):
cp dotenv.example .env && vi .env
```

## 次に読むもの

1. `AGENTS.md` — Codex に何をさせるか・させないか
2. `ONBOARDING.md` — 当日の流れ
3. `EXERCISES.md` — 何を作るか
4. 困ったら `TROUBLESHOOTING.md` → `bash scripts/doctor.sh`
