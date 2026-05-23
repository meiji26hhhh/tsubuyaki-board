#!/usr/bin/env bash
# =========================================================================
# GitHub Template Repository 作成 + ブランチ保護の一括設定
#
# 前提:
#   - gh CLI が認証済み (gh auth status)
#   - 本リポジトリで git init / commit / リモート設定が済んでいる
#
# 使い方:
#   bash scripts/github-setup.sh <owner> <repo-name>
#   例: bash scripts/github-setup.sh acme-corp butsubutsu-board-template
# =========================================================================
set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "使い方: bash scripts/github-setup.sh <owner> <repo-name>" >&2
    exit 1
fi

OWNER="$1"
REPO="$2"
FULL="${OWNER}/${REPO}"
DESCRIPTION="社内つぶやきボード — AI 駆動開発研修 (Codex × Spring Boot) のテンプレ"
DEFAULT_BRANCH="main"

# --- 1. gh CLI 認証チェック ---------------------------------------------
if ! command -v gh >/dev/null 2>&1; then
    echo "gh CLI が見つかりません。https://cli.github.com/ からインストールしてください。" >&2
    exit 1
fi
if ! gh auth status >/dev/null 2>&1; then
    echo "gh auth login で認証してください。" >&2
    exit 1
fi

# --- 2. 既存チェック ----------------------------------------------------
if gh repo view "${FULL}" >/dev/null 2>&1; then
    echo "リポジトリ ${FULL} は既に存在します。次のステップに進みます。"
else
    echo "==> リポジトリ ${FULL} を作成 (private + template)"
    gh repo create "${FULL}" \
        --private \
        --description "${DESCRIPTION}" \
        --disable-issues=false \
        --disable-wiki=true
fi

# --- 3. ローカル ⇄ リモート 紐づけ --------------------------------------
echo ""
echo "==> ローカル git の origin を設定"
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "本ディレクトリは git リポジトリではありません。先に git init してください。" >&2
    exit 1
fi
if git remote get-url origin >/dev/null 2>&1; then
    git remote set-url origin "https://github.com/${FULL}.git"
else
    git remote add origin "https://github.com/${FULL}.git"
fi

# --- 4. 初回 push --------------------------------------------------------
echo ""
echo "==> ${DEFAULT_BRANCH} に push"
git push -u origin "${DEFAULT_BRANCH}"

# --- 5. テンプレートリポとして登録 --------------------------------------
echo ""
echo "==> リポジトリをテンプレートとしてマーク"
gh api -X PATCH "repos/${FULL}" \
    -f is_template=true \
    -f default_branch="${DEFAULT_BRANCH}" \
    --silent

# --- 6. ブランチ保護 ----------------------------------------------------
echo ""
echo "==> ${DEFAULT_BRANCH} ブランチ保護を設定"
gh api -X PUT "repos/${FULL}/branches/${DEFAULT_BRANCH}/protection" \
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

echo ""
echo "==> 完了"
echo "  Template URL: https://github.com/${FULL}"
echo "  受講者向け案内: GitHub の 'Use this template' ボタンから個人リポを作成してもらう"
