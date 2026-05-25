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

# --- 再帰削除は生成物 allowlist のみに限定 -----------------------------------
RECURSIVE=0
OPERANDS=()
SAW_DASHDASH=0
for arg in "$@"; do
    if (( SAW_DASHDASH == 0 )); then
        case "${arg}" in
            --)
                SAW_DASHDASH=1
                continue
                ;;
            -r|-R|--recursive)
                RECURSIVE=1
                continue
                ;;
            -*)
                if [[ "${arg}" == *r* || "${arg}" == *R* ]]; then
                    RECURSIVE=1
                fi
                continue
                ;;
        esac
    fi
    OPERANDS+=("${arg}")
done

is_allowed_recursive_delete() {
    local target="$1"
    case "${target}" in
        target|target/|target/*|./target|./target/|./target/*|/workspace/target|/workspace/target/|/workspace/target/*|\
        build|build/|build/*|./build|./build/|./build/*|/workspace/build|/workspace/build/|/workspace/build/*|\
        node_modules|node_modules/|node_modules/*|./node_modules|./node_modules/|./node_modules/*|/workspace/node_modules|/workspace/node_modules/|/workspace/node_modules/*|\
        .cache|.cache/|.cache/*|./.cache|./.cache/|./.cache/*|/workspace/.cache|/workspace/.cache/|/workspace/.cache/*|\
        tmp|tmp/|tmp/*|./tmp|./tmp/|./tmp/*|/workspace/tmp|/workspace/tmp/|/workspace/tmp/*|\
        out|out/|out/*|./out|./out/|./out/*|/workspace/out|/workspace/out/|/workspace/out/*|\
        logs|logs/|logs/*|./logs|./logs/|./logs/*|/workspace/logs|/workspace/logs/|/workspace/logs/*)
            return 0
            ;;
    esac
    return 1
}

if (( RECURSIVE == 1 )); then
    if (( ${#OPERANDS[@]} == 0 )); then
        guard_reject rm "再帰削除の対象が不明です" "$@"
    fi
    for operand in "${OPERANDS[@]}"; do
        if ! is_allowed_recursive_delete "${operand}"; then
            guard_reject rm "再帰削除は生成物ディレクトリのみ許可 (target/build/node_modules/.cache/tmp/out/logs): ${operand}" "$@"
        fi
    done
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
        */src/test/java/com/example/tsubuyaki/sample|*/sample|\
        */src/test/java/com/example/tsubuyaki/sample/*)
            guard_reject rm "規範ファイル/不可削除パスは削除禁止: ${arg}" "$@"
            ;;
    esac
done

exec "${REAL_RM}" "$@"
