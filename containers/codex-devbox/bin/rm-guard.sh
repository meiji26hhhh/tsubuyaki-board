#!/usr/bin/env bash
# =========================================================================
# rm wrapper — 破壊的引数を reject
#
# 許可: rm <file>         単一ファイル削除
#       rm -r build/      ビルド成果物の再帰削除
#       rm -rf node_modules/  プロジェクト内ローカルディレクトリの削除
# 拒否: rm -rf /          ルート丸ごと
#       rm -rf ~          ホーム丸ごと
#       rm -rf .          カレント丸ごと
#       rm -rf ..         親ディレクトリ
#       rm -rf /etc 等の システム配下
#       rm -rf ~/.ssh 等の 機密配下
#       rm /workspace/.env 等の 機密ファイル個別削除
# =========================================================================
set -euo pipefail
# shellcheck source=guard-common.sh
source "$(dirname "${BASH_SOURCE[0]}")/guard-common.sh"

REAL_RM="$(guard_real_bin rm)" || {
    echo "${GUARD_LOG_PREFIX} rm の実体が見つかりません" >&2
    exit 127
}

# --- 危険引数チェック --------------------------------------------------------
if guard_contains_dangerous_path "$@"; then
    guard_reject rm "システム/機密パスの削除は禁止 (rm -rf /, rm -rf ~, rm -rf . など)" "$@"
fi

# --- 機密ファイル個別削除のブロック ----------------------------------------
for arg in "$@"; do
    case "${arg}" in
        */.env|.env|/workspace/.env|\
        */.env.local|.env.local|\
        */.bashrc|.bashrc|~/.bashrc|\
        */.bash_history|.bash_history|~/.bash_history|\
        *id_rsa*|*id_ed25519*|*credentials*|*.pem)
            guard_reject rm "機密ファイルの削除は禁止: ${arg}" "$@"
            ;;
    esac
done

# --- AGENTS.md 等の規範ファイル削除のブロック ------------------------------
for arg in "$@"; do
    case "${arg}" in
        */AGENTS.md|AGENTS.md|\
        */.codex|.codex|*/.codex/*|\
        */instructor|instructor|*/instructor/*|\
        */src/test/java/com/example/butsubutsu/sample|*/sample|\
        */src/test/java/com/example/butsubutsu/sample/*)
            guard_reject rm "規範ファイル/不可削除パスは削除禁止: ${arg}" "$@"
            ;;
    esac
done

exec "${REAL_RM}" "$@"
