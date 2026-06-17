#!/usr/bin/env bash
# 「Mac の準備」: Homebrew / JDK21 / Maven / podman / podman machine / Codex
# イメージをまとめて導入する。実ロジックは bin/setup-mac.sh。ここは Finder
# ダブルクリック用の薄い起動部 (cwd が不定なので自身の位置から解決する)。
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Finder ダブルクリックは PATH が最小なので Homebrew を明示的に載せる
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
. "${HERE}/bin/_common.sh"

LOG="$(new_log_path setup-mac)"
# setup-mac.sh は bash の対話 read を使わない (sudo/brew は端末に直結) ため
# tee でログを取りつつ実行できる。
bash "${HERE}/bin/setup-mac.sh" 2>&1 | tee "${LOG}"
status="${PIPESTATUS[0]}"
echo ""
echo "（作業の記録: ${LOG}）"
read -r -p "Enter キーを押すと閉じます " _ || true
exit "${status}"
