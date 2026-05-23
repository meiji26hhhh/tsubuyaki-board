#!/usr/bin/env bash
# =========================================================================
# git wrapper — 破壊的サブコマンド/オプションを reject
#
# 許可:
#   git status / log / diff / show / fetch / pull / branch / switch / checkout (除く force)
#   git add / commit / push (force 除く)
#   git rm <file>          単一ファイルのインデックス削除
#   git restore <file>     未コミット変更の破棄 (受講生が意図して使う想定)
#   git stash push -u      安全な退避
# 拒否:
#   git push --force / -f / --force-with-lease (※main系のみ理想だが branch 判定が難しいため一律拒否)
#   git rm -rf / git rm -r <dir>     再帰削除
#   git clean -fd / -fdx              untracked 削除
#   git reset --hard                  作業ツリー破壊
#   git checkout -- .                 全変更破棄
# =========================================================================
set -euo pipefail
# shellcheck source=guard-common.sh
source "$(dirname "${BASH_SOURCE[0]}")/guard-common.sh"

REAL_GIT="$(guard_real_bin git)" || {
    echo "${GUARD_LOG_PREFIX} git の実体が見つかりません" >&2
    exit 127
}

if [[ $# -eq 0 ]]; then
    exec "${REAL_GIT}"
fi

# サブコマンドを取り出す (前置オプション -c foo=bar 等は飛ばす)
SUBCMD=""
for arg in "$@"; do
    case "${arg}" in
        -c|-C|--git-dir|--work-tree|--namespace|--exec-path|--bare|--no-replace-objects|--literal-pathspecs|--noglob-pathspecs|--glob-pathspecs|--icase-pathspecs|--no-optional-locks)
            continue
            ;;
        -*)
            continue
            ;;
        *)
            SUBCMD="${arg}"
            break
            ;;
    esac
done

case "${SUBCMD}" in
    push)
        for arg in "$@"; do
            case "${arg}" in
                -f|--force|--force-with-lease|--force-with-lease=*)
                    guard_reject "git push" "force push は研修ハーネスで一律禁止" "$@"
                    ;;
            esac
        done
        ;;
    rm)
        for arg in "$@"; do
            case "${arg}" in
                -r|-R|--recursive|-rf|-fr|-rfv|-vrf)
                    guard_reject "git rm" "git rm の再帰削除 (-r / -rf) は禁止" "$@"
                    ;;
            esac
        done
        # パスの破壊性チェック
        if guard_contains_dangerous_path "$@"; then
            guard_reject "git rm" "システム/機密パスの git rm は禁止" "$@"
        fi
        ;;
    clean)
        for arg in "$@"; do
            case "${arg}" in
                -f*|--force|-d|-dx|-fd|-fdx|-x|-X)
                    guard_reject "git clean" "untracked ファイルの破壊的削除 (git clean -fd 系) は禁止" "$@"
                    ;;
            esac
        done
        ;;
    reset)
        for arg in "$@"; do
            case "${arg}" in
                --hard|--merge|--keep)
                    if [[ "${arg}" == "--hard" ]]; then
                        guard_reject "git reset" "git reset --hard は禁止 (作業ツリーを破壊する)" "$@"
                    fi
                    ;;
            esac
        done
        ;;
    checkout)
        # 旧式の git checkout -- . (全変更破棄) を阻止
        local_saw_dashdash=0
        for arg in "$@"; do
            if [[ "${arg}" == "--" ]]; then
                local_saw_dashdash=1
                continue
            fi
            if (( local_saw_dashdash == 1 )); then
                case "${arg}" in
                    .|/|/workspace|/workspace/)
                        guard_reject "git checkout" "git checkout -- . / / は禁止 (git restore <file> を使うこと)" "$@"
                        ;;
                esac
            fi
        done
        ;;
    restore)
        # git restore . (全ファイル復元 = 全変更破棄) は受講生本人の判断で実行すべき。
        # Codex が走らせるのは禁止 (受講生承認なしで作業を消すリスク)。
        for arg in "$@"; do
            case "${arg}" in
                .|/|/workspace|/workspace/)
                    guard_reject "git restore" "git restore . (全変更破棄) は禁止 (受講生本人がコンテナ外で実行すること)" "$@"
                    ;;
            esac
        done
        ;;
    config)
        # 受講生のホスト ~/.gitconfig 改ざんを阻止 (--global / --system)
        for arg in "$@"; do
            case "${arg}" in
                --system)
                    guard_reject "git config" "git config --system は禁止 (システム設定改ざん)" "$@"
                    ;;
                --global)
                    guard_reject "git config" "git config --global は禁止 (ホストの ~/.gitconfig 改ざん。コンテナローカルのみ許可)" "$@"
                    ;;
            esac
        done
        ;;
    update-ref|gc|filter-branch|reflog)
        # 履歴改ざんになりうる強力コマンドは一律ブロック
        case "${SUBCMD}" in
            filter-branch)
                guard_reject "git filter-branch" "履歴改ざんは禁止" "$@"
                ;;
            update-ref)
                # delete だけ阻止
                for arg in "$@"; do
                    if [[ "${arg}" == "-d" || "${arg}" == "--delete" ]]; then
                        guard_reject "git update-ref" "ref の削除は禁止" "$@"
                    fi
                done
                ;;
        esac
        ;;
esac

exec "${REAL_GIT}" "$@"
