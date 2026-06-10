#!/usr/bin/env bash
# =========================================================================
# chown wrapper — システム配下の所有者変更を reject
# =========================================================================
set -euo pipefail
# shellcheck source=guard-common.sh
source "$(dirname "${BASH_SOURCE[0]}")/guard-common.sh"

REAL_CHOWN="$(guard_real_bin chown)" || {
    echo "${GUARD_LOG_PREFIX} chown の実体が見つかりません" >&2
    exit 127
}

# 再帰 (-R) 付きの広範囲 chown も、対象パスが guard_contains_dangerous_path で
# 捕捉されるため個別のフラグ判定は持たない
if guard_contains_dangerous_path "$@"; then
    guard_reject "chown" "システム/機密パスの所有者変更は禁止" "$@"
fi

exec "${REAL_CHOWN}" "$@"
