#!/usr/bin/env bash
# =========================================================================
# chmod wrapper — 過剰権限・システム配下の権限変更を reject
#
# 許可: chmod +x script.sh          実行権限付与 (ローカル限定)
#       chmod 644 file              通常の権限変更
# 拒否: chmod -R 777 .              再帰的フル権限
#       chmod 777 / 等の システム配下
#       chmod -R /etc / /usr 等の システム配下再帰
# =========================================================================
set -euo pipefail
# shellcheck source=guard-common.sh
source "$(dirname "${BASH_SOURCE[0]}")/guard-common.sh"

REAL_CHMOD="$(guard_real_bin chmod)" || {
    echo "${GUARD_LOG_PREFIX} chmod の実体が見つかりません" >&2
    exit 127
}

RECURSIVE=0
MODE=""
for arg in "$@"; do
    case "${arg}" in
        --recursive)
            RECURSIVE=1
            ;;
        --*)
            ;;
        -*R*)
            # 結合フラグも再帰とみなす (-R, -Rv, -vR, -fR, -cfR 等)。
            # モード指定 (-x, a-w 等) に大文字 R は現れないため誤検知しない
            RECURSIVE=1
            ;;
        777|0777|a+rwx|a=rwx|ugo+rwx|ugo=rwx)
            MODE="${arg}"
            ;;
    esac
done

# 777 系の再帰適用は一律拒否
if (( RECURSIVE == 1 )) && [[ -n "${MODE}" ]]; then
    guard_reject "chmod" "chmod -R 777 (再帰フル権限) は禁止" "$@"
fi

# システム/機密パスへの chmod は拒否
if guard_contains_dangerous_path "$@"; then
    guard_reject "chmod" "システム/機密パスの権限変更は禁止" "$@"
fi

# 機密ファイル個別の chmod (パーミッション操作で読み取りを奪うのを防ぐ) は拒否
for arg in "$@"; do
    case "${arg}" in
        */.env|.env|*/.bashrc|.bashrc|*/AGENTS.md|AGENTS.md|*/.codex/*)
            guard_reject "chmod" "機密ファイル/規範ファイルの権限変更は禁止: ${arg}" "$@"
            ;;
    esac
done

exec "${REAL_CHMOD}" "$@"
