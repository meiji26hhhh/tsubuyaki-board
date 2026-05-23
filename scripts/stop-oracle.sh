#!/usr/bin/env bash
# Oracle XE コンテナを停止する。データボリュームは残す。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${REPO_ROOT}"

if command -v podman-compose >/dev/null 2>&1; then
    COMPOSE_CMD=(podman-compose)
elif podman compose version >/dev/null 2>&1; then
    COMPOSE_CMD=(podman compose)
else
    echo "podman-compose / podman compose のいずれも利用できません。" >&2
    exit 1
fi

echo "Stopping Oracle XE..."
"${COMPOSE_CMD[@]}" stop oracle

echo ""
echo "停止しました。"
echo "  - データはボリューム butsubutsu-oracle-data に保持されています。"
echo "  - データごと削除するには: ${COMPOSE_CMD[*]} down --volumes"
