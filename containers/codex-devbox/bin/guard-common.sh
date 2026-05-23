#!/usr/bin/env bash
# =========================================================================
# Codex devbox 共通 guard ライブラリ
#   - 各 *-guard.sh から source される
#   - reject 時の終了コード・メッセージを統一する
# =========================================================================
# shellcheck shell=bash

GUARD_LOG_PREFIX="[codex-guard]"
GUARD_LOG_FILE="${GUARD_LOG_FILE:-/tmp/codex-guard.log}"
GUARD_REJECT_EXIT=126   # 慣例: 「実行権限あるが拒否された」

guard_reject() {
    # $1 = コマンド名, $2 = 理由, $3+ = 元の argv
    local cmd_name="$1"; shift
    local reason="$1"; shift
    local argv_dump="$*"

    printf '%s REJECTED %s :: %s :: argv=%s\n' \
        "$(date -Iseconds)" "${cmd_name}" "${reason}" "${argv_dump}" \
        >>"${GUARD_LOG_FILE}" 2>/dev/null || true

    cat >&2 <<EOF
${GUARD_LOG_PREFIX} ${cmd_name} は研修ハーネスでブロックされました。
理由: ${reason}
コマンド: ${cmd_name} ${argv_dump}

これは Codex devbox の保護機構です。本コマンドは研修中に必要のない
破壊的操作と判定されました。本当に必要な場合は受講生本人がコンテナ
外 (WSL Ubuntu) で実行してください。

詳細: education/TROUBLESHOOTING.md の「Codex ハーネス」セクション。
EOF
    exit ${GUARD_REJECT_EXIT}
}

guard_real_bin() {
    # /opt/codex-guard/bin 以外の最初のヒットを返す
    local name="$1"
    local candidate
    for candidate in /bin /usr/bin /usr/local/bin /sbin /usr/sbin; do
        if [[ -x "${candidate}/${name}" ]]; then
            printf '%s\n' "${candidate}/${name}"
            return 0
        fi
    done
    return 1
}

# 引数列に「危険パス」が含まれているか判定
guard_contains_dangerous_path() {
    local arg
    for arg in "$@"; do
        case "${arg}" in
            /|/*|~|~/*|..|../*|.|./*)
                # 完全削除リスク: ルート / ホーム / 親ディレクトリ / カレント丸ごと
                case "${arg}" in
                    /|/bin|/bin/*|/etc|/etc/*|/home|/home/*|/lib|/lib/*|/lib64|/lib64/*|\
/opt|/opt/*|/proc|/proc/*|/root|/root/*|/sbin|/sbin/*|/srv|/srv/*|/sys|/sys/*|\
/usr|/usr/*|/var|/var/*|/workspace|/workspace/.codex|/workspace/.codex/*|\
/workspace/.github|/workspace/.github/*|/workspace/AGENTS.md|\
/workspace/.git|/workspace/.git/*|\
~|~/*|~/.codex|~/.codex/*|~/.m2|~/.m2/*|\
..|../*|.)
                        return 0
                        ;;
                esac
                ;;
        esac
    done
    return 1
}
