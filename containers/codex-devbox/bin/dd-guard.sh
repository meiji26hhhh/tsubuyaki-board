#!/usr/bin/env bash
# =========================================================================
# dd wrapper — 研修中に dd を使う正当な理由はないため一律拒否
# =========================================================================
set -euo pipefail
# shellcheck source=guard-common.sh
source "$(dirname "${BASH_SOURCE[0]}")/guard-common.sh"

guard_reject "dd" "dd は研修ハーネスで一律禁止 (ディスク破壊リスク)" "$@"
