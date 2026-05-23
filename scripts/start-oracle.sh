#!/usr/bin/env bash
# Oracle XE コンテナを起動し、healthcheck が ready になるまで待つ。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${REPO_ROOT}"

# .env があれば読み込む (ORACLE_PWD / ORACLE_APP_PWD)
if [[ -f .env ]]; then
    set -a
    # shellcheck disable=SC1091
    source .env
    set +a
fi

# podman-compose / podman compose のどちらでも動かす
if command -v podman-compose >/dev/null 2>&1; then
    COMPOSE_CMD=(podman-compose)
elif podman compose version >/dev/null 2>&1; then
    COMPOSE_CMD=(podman compose)
else
    echo "podman-compose / podman compose のいずれも利用できません。" >&2
    echo "setup-wsl.sh を再実行してください。" >&2
    exit 1
fi

echo "Starting Oracle XE (${COMPOSE_CMD[*]} up -d oracle)..."
"${COMPOSE_CMD[@]}" up -d oracle

echo ""
echo "起動完了を待機します (初回は最大 3 分かかります)..."
TIMEOUT=300
ELAPSED=0
INTERVAL=10

while (( ELAPSED < TIMEOUT )); do
    if podman exec butsubutsu-oracle healthcheck.sh >/dev/null 2>&1; then
        echo ""
        echo "✅ Oracle XE is ready."
        echo ""
        echo "接続情報:"
        echo "  URL      : jdbc:oracle:thin:@//localhost:1521/XEPDB1"
        echo "  User     : butsubutsu"
        echo "  Password : \$ORACLE_APP_PWD (デフォルト butsubutsu_pw)"
        exit 0
    fi
    sleep "${INTERVAL}"
    ELAPSED=$(( ELAPSED + INTERVAL ))
    echo "  ...waiting (${ELAPSED}s / ${TIMEOUT}s)"
done

echo "" >&2
echo "❌ Oracle XE がタイムアウト ${TIMEOUT}s 以内に ready になりませんでした。" >&2
echo "   ログ確認: podman logs butsubutsu-oracle" >&2
exit 1
