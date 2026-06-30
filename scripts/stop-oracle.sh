#!/usr/bin/env bash
# Oracle XE コンテナを停止する。
#   引数なし : 停止のみ (データボリュームは残す)
#   --purge  : コンテナとデータボリュームを完全削除する
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${REPO_ROOT}"

MODE_PURGE=false
case "${1:-}" in
    --purge) MODE_PURGE=true ;;
    "")      ;;
    *)
        echo "Unknown option: $1" >&2
        echo "使い方: stop-oracle.sh [--purge]" >&2
        exit 1
        ;;
esac

if command -v podman-compose >/dev/null 2>&1; then
    COMPOSE_CMD=(podman-compose)
elif podman compose version >/dev/null 2>&1; then
    COMPOSE_CMD=(podman compose)
else
    echo "podman-compose / podman compose のいずれも利用できません。" >&2
    exit 1
fi

# compose.yaml で publish しているポート (ホスト側)
ORACLE_PORT=1521

# rootless podman では、コンテナ停止後もポート転送プロセス (rootlessport 等) が
# 残り、ポート 1521 を握り続けて次回 start-oracle.sh が "address already in use"
# で失敗することがある。停止後にまだリッスン状態なら、占有プロセスを終了して解放する。
# (誰もリッスンしていなければ何もしない冪等処理)
free_oracle_port() {
    local port="${ORACLE_PORT}"

    if ! command -v ss >/dev/null 2>&1; then
        # ss が無い環境ではポート解放確認を行わない (通常は iproute2 で同梱)
        return 0
    fi

    # まだ誰もリッスンしていなければ解放済み
    if ! ss -ltn "sport = :${port}" 2>/dev/null | grep -q LISTEN; then
        return 0
    fi

    echo ""
    echo "ポート ${port} がまだ使用中です。占有プロセスを終了して解放します..."

    # ss の出力 (users:(("rootlessport",pid=12345,fd=10))) から PID を抽出する
    local pids
    pids="$(ss -ltnp "sport = :${port}" 2>/dev/null \
        | grep -oE 'pid=[0-9]+' | cut -d= -f2 | sort -u || true)"

    if [[ -z "${pids}" ]]; then
        echo "  - 占有プロセスを特定できませんでした (権限不足の可能性があります)。" >&2
        echo "    手動で確認してください: ss -ltnp 'sport = :${port}'" >&2
        return 0
    fi

    # まず TERM で穏やかに終了を促し、残っていれば KILL で確実に終了させる
    local pid
    for pid in ${pids}; do
        kill "${pid}" 2>/dev/null || true
    done
    sleep 2
    for pid in ${pids}; do
        if kill -0 "${pid}" 2>/dev/null; then
            kill -9 "${pid}" 2>/dev/null || true
        fi
    done

    if ss -ltn "sport = :${port}" 2>/dev/null | grep -q LISTEN; then
        echo "  - ポート ${port} をまだ解放できませんでした。手動確認が必要です:" >&2
        echo "    ss -ltnp 'sport = :${port}'" >&2
    else
        echo "  - ポート ${port} を解放しました。"
    fi
}

if ${MODE_PURGE}; then
    echo "Purging Oracle XE (コンテナとデータを削除)..."
    "${COMPOSE_CMD[@]}" down --volumes || true
    podman volume rm tsubuyaki-oracle-data 2>/dev/null || true
    free_oracle_port
    echo ""
    echo "削除しました。"
    echo "  - もう一度使うには start-oracle.sh で起動し直してください。"
    exit 0
fi

# コンテナ未作成の状態 (一度も起動していない / 削除済み) で compose stop を呼ぶと
# set -e により生エラーで終了してしまうため、先に存在を確認して冪等にする
if ! podman ps -a --format '{{.Names}}' 2>/dev/null | grep -qx 'tsubuyaki-oracle'; then
    echo "Oracle XE コンテナは存在しません (停止済み、または未起動)。"
    echo "  - 起動するには: start-oracle.sh"
    exit 0
fi

echo "Stopping Oracle XE..."
"${COMPOSE_CMD[@]}" stop oracle

free_oracle_port

echo ""
echo "停止しました。"
echo "  - データはボリューム tsubuyaki-oracle-data に保持されています。"
echo "  - データごと削除するには: stop-oracle.sh --purge"
