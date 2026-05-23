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
2. **Free プランは Actions の private リポ実行時間に上限あり**。受講生 10 名 × 3 日 = 累計 30 リポで CI を回すなら **Team プラン（または GitHub Education 経由）を推奨**。
3. Organization 名（例: `acme-training-2026q2`）と請求先メールを設定。

### 2-2. Actions の有効化

Organization の **Settings > Actions > General** で以下を設定：

- **Actions permissions**: 「Allow all actions and reusable workflows」
- **Workflow permissions**: 「Read and write permissions」（必要に応じて）
- **Allow GitHub Actions to create and approve pull requests**: チェック（任意）

### 2-3. Member seat 数の確認

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

## 4. CI 初回緑化とブランチ保護

ブランチ保護で `Build + Test (H2)` を required status check に指定するには、**CI 履歴に同名 check run が 1 回以上存在している必要**があります。順序が逆だと `422 Unprocessable Entity` で弾かれます。

### 4-1. CI を 1 回手動 push して緑化

通常は `git push --mirror` で main が push された時点で `.github/workflows/ci.yml` がトリガされます。ブラウザで `https://github.com/<org>/tsubuyaki-board/actions` を開き、`build-test` ジョブ（job 名: `Build + Test (H2)`）が緑になるまで待機。

### 4-2. main ブランチ保護を設定

CI が一度緑になったら：

```bash
gh api -X PUT "repos/<org>/tsubuyaki-board/branches/main/protection" \
    --input - <<EOF
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["Build + Test (H2)"]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": false,
    "require_code_owner_reviews": false,
    "required_approving_review_count": 0,
    "require_last_push_approval": false
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_conversation_resolution": true,
  "lock_branch": false,
  "required_linear_history": false
}
EOF
```

### 4-3. 受講生個人リポへの保護伝播について

**重要: branch protection は Classroom 生成リポへ自動伝播しません**。
受講生各自のリポ main 保護は、初日朝に全員に以下を 1 行実行してもらうのが現実的です。受講生ガイドの「9. 初回 push と CI 緑化」の前に挿入推奨：

```bash
gh api -X PUT "repos/$(gh api user --jq .login)/<assignment>-$(gh api user --jq .login)/branches/main/protection" \
    --input - <<EOF
{
  "required_status_checks": {"strict": true, "contexts": ["Build + Test (H2)"]},
  "enforce_admins": false,
  "required_pull_request_reviews": {"required_approving_review_count": 0},
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF
```

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
6. **Repository permission**: Admin（受講生に branch protection 設定もさせる場合）または Write
7. **Deadline**: 研修最終日の 21 時間目終了時刻
8. **Feedback pull request**: 任意（自動作成のフィードバック PR を作成する）

### 5-4. Assignment 招待 URL の取得

Assignment 作成完了画面に表示される **Invitation URL**（`https://classroom.github.com/a/xxxxxxxx`）をコピー。研修初日に受講生へ配布します。

### 5-5. 検証（テストアカウントでリハーサル）

別の GitHub アカウント（個人アカウントなど）で Assignment URL を踏み、自動生成された private リポを clone して `./mvnw -B -Ph2 verify` まで通るかを確認。詰まったら受講生ガイドに追記。

---

## 6. 講師自身のキッティング

受講生と同じ環境を講師マシンに構築します（質問対応・トラブル再現用）。

### 6-1. 講師リポを clone

```bash
cd /mnt/c/workspace
git clone https://github.com/<org>/tsubuyaki-board.git
cd tsubuyaki-board
```

### 6-2. Windows キッティング → 受講生ガイドと同手順

[../education/student-setup-guide.md §4](../education/student-setup-guide.md) の手順をそのまま実施。要約：

1. 🪟 管理者 PowerShell を起動
2. `Set-ExecutionPolicy -Scope Process Bypass; .\scripts\setup.ps1`
3. PC 再起動

**講師固有の差分**: 無し（同じ）。

### 6-3. WSL キッティング → 受講生ガイドと同手順

[../education/student-setup-guide.md §5](../education/student-setup-guide.md) の手順をそのまま実施。要約：

1. スタートメニュー → Ubuntu 起動 → 初回ユーザ・パスワード設定
2. `cd /mnt/c/workspace/tsubuyaki-board`
3. `bash scripts/setup-wsl.sh`

**講師固有の差分**: 無し（同じ）。

### 6-4. `OPENAI_API_KEY` 設定 → 受講生ガイドと同手順

[../education/student-setup-guide.md §7-2](../education/student-setup-guide.md) のとおり。

```bash
echo 'export OPENAI_API_KEY=sk-...' >> ~/.bashrc
source ~/.bashrc
```

**講師固有の差分**: 受講生に貸与する**予備キー**は **`~/.bashrc` に書かない**（誤って共有・公開しないため）。予備キーは 1Password / `pass` 等のシークレットマネージャに保管し、配布時のみ手動で渡す。

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

# Oracle 接続でアプリ起動 → /posts まで描画されること
SPRING_PROFILES_ACTIVE=local ./mvnw spring-boot:run
# 別タブで:
curl http://localhost:8080/actuator/health   # {"status":"UP"}
curl -I http://localhost:8080/posts          # 200 OK

# Codex も必ず実機で 1 度動かす
codex-shell
# (コンテナ内) codex --help
```

すべて通れば講師キッティング完了。**受講生向けには H2 経路のみで OK**（Oracle はバックアップ）。

---

## 7. 当日運営フロー

詳細は [timetable.md](./timetable.md) と [rubric.md](./rubric.md) を参照。本ガイドではセットアップ観点のみ記述。

### 7-1. 0 時間目（受講生到着〜セットアップ開始）

- 受講生に [../education/student-setup-guide.md](../education/student-setup-guide.md) を案内（事前送付推奨）
- Classroom Assignment URL を配布（Slack / メール / ホワイトボード）
- Pleiades 配布媒体を回覧
- `OPENAI_API_KEY` 未発行の受講生がいれば即座に発行サポート

### 7-2. 0-1 時間目（セットアップ確認）

受講生ガイドの [§8 動作確認 5 点セット](../education/student-setup-guide.md) を全員クリアさせる。
講師は「詰まっている受講生」を回って [../education/TROUBLESHOOTING.md](../education/TROUBLESHOOTING.md) を一緒に追う。

### 7-3. PR レビューフロー（演習中）

受講生は自分の Classroom リポ内で：
1. `feature/...` ブランチで開発
2. 自分のリポに push
3. 自分のリポで PR 作成
4. self-merge

講師は各受講生のリポを Watch し、PR ごとに 1〜2 行のレビューコメントを残します。レビューポイントは [rubric.md](./rubric.md) の 15 点ルーブリックに沿って。

### 7-4. 相互レビュー（19-20 時間目）

[ONBOARDING.md](../education/ONBOARDING.md#相互レビュー-19-20時間目) を参照。

### 7-5. KPT＋自己採点（20-21 時間目）

[rubric.md](./rubric.md) を配布。

---

## 8. 権限プレイブック（トラブル時）

### 8-1. 受講生が Assignment を踏めない

- 症状: Classroom 画面で「You don't have access to this assignment」
- 原因: Organization の seat 不足、または受講生が SAML SSO 未認証
- 対処: Settings > Members で受講生を Pending invitation から Active に。SAML 必須 Org の場合は受講生に再認証を依頼

### 8-2. Actions が動かない

- 症状: 受講生個人リポで push しても workflow が起動しない
- 原因: Classroom 経由で生成されたリポは Actions がデフォルト無効の場合あり
- 対処: 受講生に **Settings > Actions > General** で「Allow all actions」を選択させる

### 8-3. 受講生の `OPENAI_API_KEY` が当日発行不能

- 症状: 個人カード未登録 / 残高不足 / 発行制限
- 対処: 講師が予備キー 1 本を保持しておき、当日のみ貸与（研修終了時に rotate）
- 予備キーの管理: 1Password / 環境変数で保持し、共有時は Slack DM 等の流出しにくい経路で渡す

### 8-4. branch protection 設定で 422 エラー

- 症状: `gh api PUT .../protection` が `422 Unprocessable Entity`
- 原因: `Build + Test (H2)` という名前の check run が CI 履歴に未登録
- 対処: 一度 main に空コミットを push し、CI を緑にしてから再実行（手順 4-1 を実施）

### 8-5. 受講生が main に直 push してしまった

- 症状: 受講生個人リポの main に feature を介さず push される
- 原因: 個人リポに branch protection が設定されていない
- 対処: 4-3 のコマンドで保護を有効化。push 済の不正コミットは `git revert` で戻す（force push は禁止）

---

## 9. 講師完了条件チェックリスト

研修開始前日までに以下が全て ✓ なら準備完了。

### Organization / リポ
- [ ] Organization 作成済、Actions 有効化済
- [ ] `<org>/tsubuyaki-board` が **private** かつ **isTemplate=true**
- [ ] Actions タブの初回 run が緑（`Build + Test (H2)`）
- [ ] main ブランチに保護設定（required status check, force push 禁止）

### Classroom
- [ ] Classroom 作成、Organization 紐付け済
- [ ] Assignment 作成（individual, private, template = `<org>/tsubuyaki-board`）
- [ ] Assignment 招待 URL を取得・共有準備完了
- [ ] テストアカウントで Assignment 参加 → clone → `./mvnw -B -Ph2 verify` 緑のリハーサル成功

### 講師マシン
- [ ] `setup.ps1` 完走、PC 再起動済
- [ ] `setup-wsl.sh` 完走
- [ ] `OPENAI_API_KEY` 設定済（`~/.bashrc`）
- [ ] `bash scripts/doctor.sh`（**全件**）緑
- [ ] `./mvnw -B -Plocal verify`（Oracle XE）緑
- [ ] `./mvnw -B -Ph2 verify`（H2）緑
- [ ] `codex-shell` → `codex --help` 表示

### 配布物
- [ ] Pleiades 配布媒体準備（USB / 共有ドライブ）
- [ ] Classroom Assignment URL を受講生案内に記載
- [ ] 予備 OPENAI_API_KEY を 1 本保持

すべて ✓ なら、研修当日は受講生対応に集中できます。

---

## 10. 次に読むもの

- [timetable.md](./timetable.md) — 当日のタイムテーブル
- [rubric.md](./rubric.md) — 15 点ルーブリック（自己採点・相互レビュー用）
- [prompts-day3.md](./prompts-day3.md) — Day 3 用プロンプト集
- [faq.md](./faq.md) — 講師 FAQ
- [../education/ONBOARDING.md](../education/ONBOARDING.md) — 受講生視点での 21 時間
- [../education/TROUBLESHOOTING.md](../education/TROUBLESHOOTING.md) — トラブル対処集
