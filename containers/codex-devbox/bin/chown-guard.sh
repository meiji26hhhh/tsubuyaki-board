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

if guard_contains_dangerous_path "$@"; then
    guard_reject "chown" "システム/機密パスの所有者変更は禁止" "$@"
fi

# 再帰的に / / /workspace 等を chown するのは特に危険
for arg in "$@"; do
    case "${arg}" in
        -R|--recursive)
            # -R 付きで明らかに広範囲は guard_contains_dangerous_path で大半捕捉済
            :
            ;;
    esac
done

exec "${REAL_CHOWN}" "$@"
