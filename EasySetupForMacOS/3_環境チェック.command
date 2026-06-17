#!/usr/bin/env bash
# 「環境チェック」: 準備ができているか診断する。実ロジックは bin/doctor-mac.sh。
# doctor 自身が EasySetupForMacOS/logs にログを書くため、ここでは tee しない。
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
bash "${HERE}/bin/doctor-mac.sh" --quick
status=$?
echo ""
read -r -p "Enter キーを押すと閉じます " _ || true
exit "${status}"
