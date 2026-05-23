#!/usr/bin/env bash
# =========================================================================
# sudo wrapper — コンテナ内 codex は NOPASSWD sudo を持つため、明示的に阻止
#                受講生本人が sudo したい場合はコンテナ外 (WSL) で実行
# =========================================================================
set -euo pipefail
# shellcheck source=guard-common.sh
source "$(dirname "${BASH_SOURCE[0]}")/guard-common.sh"

guard_reject "sudo" "コンテナ内での sudo は研修ハーネスで禁止 (権限昇格による全 guard 迂回防止)" "$@"
