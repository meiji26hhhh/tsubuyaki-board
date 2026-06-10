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
#   git push --force / -f / --force-with-lease / +<refspec> (※force は一律拒否)
#   git push (宛先が main) / --all / --mirror   共有 main 保護 (push 先は自分の <github-id> ブランチのみ)
#   git push (refspec なし / HEAD) で main を checkout 中   暗黙 push も同上
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

# サブコマンドを取り出す。
# `git -C /workspace reset --hard` のように値を消費する前置オプションがあるため、
# オプション名だけでなく次の値も確実にスキップする。
SUBCMD=""
ARGS=("$@")
idx=0
while (( idx < ${#ARGS[@]} )); do
    arg="${ARGS[$idx]}"
    case "${arg}" in
        -c|-C|--git-dir|--work-tree|--namespace|--exec-path)
            idx=$((idx + 2))
            continue
            ;;
        --git-dir=*|--work-tree=*|--namespace=*|--exec-path=*)
            idx=$((idx + 1))
            continue
            ;;
        --bare|--no-replace-objects|--literal-pathspecs|--noglob-pathspecs|--glob-pathspecs|--icase-pathspecs|--no-optional-locks)
            idx=$((idx + 1))
            continue
            ;;
        --)
            idx=$((idx + 1))
            continue
            ;;
        -*)
            idx=$((idx + 1))
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
                -f|--force|--force-with-lease|--force-with-lease=*|+*)
                    guard_reject "git push" "force push は研修ハーネスで一律禁止 (+<refspec> 形式の強制更新も含む)" "$@"
                    ;;
                --all|--mirror)
                    guard_reject "git push" "共有 main を含む一括 push (--all / --mirror) は禁止。自分の <github-id> ブランチのみ push すること" "$@"
                    ;;
                main|main:*|*:main|refs/heads/main|*:refs/heads/main)
                    guard_reject "git push" "共有 main への push は禁止。push 先は自分の <github-id> ブランチのみ" "$@"
                    ;;
            esac
        done
        # refspec を伴わない「暗黙 push」(git push / git push origin) は現在ブランチへ
        # 送られるため、main を checkout したままだと上の文字列一致では捕捉できずに
        # 共有 main へ届いてしまう。現在ブランチを解決して main なら拒否する。
        # `git push origin HEAD` (HEAD = 現在ブランチ) も同様に扱う。
        REFSPEC_COUNT=0
        SAW_PUSH=0
        BARE_HEAD=0
        for arg in "$@"; do
            if (( SAW_PUSH == 0 )); then
                [[ "${arg}" == "push" ]] && SAW_PUSH=1
                continue
            fi
            case "${arg}" in
                -*) ;;
                *)
                    REFSPEC_COUNT=$((REFSPEC_COUNT + 1))
                    [[ "${arg}" == "HEAD" ]] && BARE_HEAD=1
                    ;;
            esac
        done
        # 非オプション引数の 1 個目は remote 名。2 個目以降が refspec
        if (( REFSPEC_COUNT <= 1 || BARE_HEAD == 1 )); then
            CURRENT_BRANCH="$("${REAL_GIT}" symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
            if [[ "${CURRENT_BRANCH}" == "main" ]]; then
                guard_reject "git push" "main を checkout した状態の暗黙 push (refspec なし / HEAD) は共有 main に届くため禁止。自分の <github-id> ブランチへ switch してから push すること" "$@"
            fi
        fi
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
                --force)
                    guard_reject "git clean" "untracked ファイルの破壊的削除 (git clean -fd 系) は禁止" "$@"
                    ;;
                --*)
                    # その他の長形式 (--dry-run / --exclude= 等) は破壊しないので通す
                    ;;
                -*[fdxX]*)
                    # 短オプションは結合順を問わず f/d/x/X を含めば拒否 (-fd, -df, -dfx, -xdf 等)
                    guard_reject "git clean" "untracked ファイルの破壊的削除 (git clean -fd 系) は禁止" "$@"
                    ;;
            esac
        done
        ;;
    reset)
        # --hard のみ禁止。--merge / --keep は失われる変更があると git 自身が中断する
        for arg in "$@"; do
            if [[ "${arg}" == "--hard" ]]; then
                guard_reject "git reset" "git reset --hard は禁止 (作業ツリーを破壊する)" "$@"
            fi
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
    filter-branch)
        # 履歴改ざんは一律ブロック
        guard_reject "git filter-branch" "履歴改ざんは禁止" "$@"
        ;;
    update-ref)
        # delete だけ阻止 (gc / reflog 閲覧などの読み取り系は許可)
        for arg in "$@"; do
            if [[ "${arg}" == "-d" || "${arg}" == "--delete" ]]; then
                guard_reject "git update-ref" "ref の削除は禁止" "$@"
            fi
        done
        ;;
esac

exec "${REAL_GIT}" "$@"
