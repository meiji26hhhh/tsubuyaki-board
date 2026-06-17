#!/usr/bin/env bash
# 「研修終了_環境削除」: 研修環境 (podman machine / Codex イメージ / シェル設定 /
# 研修用 API キー) を撤去する。実ロジックは bin/uninstall-mac.sh。
# delete の対話確認があるため tee はしない。
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
bash "${HERE}/bin/uninstall-mac.sh"
status=$?
echo ""
read -r -p "Enter キーを押すと閉じます " _ || true
exit "${status}"
