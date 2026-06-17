#!/usr/bin/env bash
# 「API キーと Git 設定」: OPENAI_API_KEY と git の user.name / user.email を
# 対話設定する。実ロジックは bin/setup-secrets-mac.sh。
# read による秘匿入力があるため tee はしない (プロンプトが隠れるのを防ぐ)。
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
bash "${HERE}/bin/setup-secrets-mac.sh"
status=$?
echo ""
read -r -p "Enter キーを押すと閉じます " _ || true
exit "${status}"
