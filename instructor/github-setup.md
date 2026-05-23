# GitHub Template Repository セットアップ手順 (講師用)

研修開始前に 1 度だけ実施する。

## 前提

- GitHub アカウントが社内 Organization にあるか、個人で作る
- `gh` CLI がインストール済み (`gh --version`)
- 本テンプレ (template-repo/) がローカルで完成している

## 手順

### 1. git 初期化 + コミット

```bash
cd /mnt/c/workspace/butsubutsu-board-template   # template-repo/ をコピーした場所

git init -b main
git add -A
git commit -m "chore: 初期テンプレを追加

社内つぶやきボード AI 駆動開発研修 (3 日コース) 用テンプレ。
詳細は AGENTS.md と ONBOARDING.md。
"
```

### 2. gh CLI で認証

```bash
gh auth login
# Account: GitHub.com / HTTPS / Login with web browser
```

### 3. テンプレリポ作成 + ブランチ保護 (一括)

```bash
bash scripts/github-setup.sh <owner> <repo-name>
# 例:
bash scripts/github-setup.sh acme-corp butsubutsu-board-template
```

スクリプトの中身:
1. `gh repo create` で private リポを作成
2. `git remote add origin` + `git push -u origin main`
3. `gh api PATCH /repos/.../template` で `is_template = true` に設定
4. `gh api PUT /repos/.../branches/main/protection` でブランチ保護
   - PR 必須 (reviewers 0 でも require, conversation resolution 必須)
   - status check `Build + Test (H2)` 必須
   - force push 禁止 / 削除禁止

### 4. 受講者への案内

GitHub の URL とともに以下を共有:

```
1. https://github.com/<owner>/<repo-name>/generate を開く
2. Repository name: butsubutsu-board-<your-name>
3. "Include all branches" にチェック (任意)
4. 自分のアカウント配下に作成
5. clone して C:\workspace 配下に置く
   wsl
   cd /mnt/c/workspace
   git clone https://github.com/<you>/butsubutsu-board-<your-name>.git
```

## 注意

- **個人リポでも CI を有効にする**: テンプレ→個人リポ複製時、Actions がデフォルト無効のことがある。受講者に Settings > Actions > General で「Allow all actions」を選んでもらう。
- **branch protection は個人リポには伝播しない**: テンプレ生成後、受講者個人の main 保護は別途設定。簡略化のため、初日朝に全員に `gh api -X PUT ...` を 1 行実行してもらうのが現実的。

### 受講者個人リポの簡易保護 (任意)

```bash
gh api -X PUT "repos/$(gh api user --jq .login)/<repo-name>/branches/main/protection" \
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

## トラブル

- **`gh repo create` で 403**: Organization 配下に作る権限がない。`gh repo create <your-user>/<repo>` で個人アカウントに作ってから transfer する。
- **branch protection で 422**: status check `Build + Test (H2)` が CI 履歴に 1 度も存在しないと弾かれる。先に push → CI 1 回緑 → そのあと protection を設定する。`scripts/github-setup.sh` はその順で並んでいる。
