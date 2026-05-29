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

if ${MODE_PURGE}; then
    echo "Purging Oracle XE (コンテナとデータを削除)..."
    "${COMPOSE_CMD[@]}" down --volumes || true
    podman volume rm tsubuyaki-oracle-data 2>/dev/null || true
    echo ""
    echo "削除しました。"
    echo "  - もう一度使うには start-oracle.sh で起動し直してください。"
    exit 0
fi

echo "Stopping Oracle XE..."
"${COMPOSE_CMD[@]}" stop oracle

echo ""
echo "停止しました。"
echo "  - データはボリューム tsubuyaki-oracle-data に保持されています。"
echo "  - データごと削除するには: stop-oracle.sh --purge"
