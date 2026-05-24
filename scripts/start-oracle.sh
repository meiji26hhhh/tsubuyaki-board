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

# Ubuntu 22.04 (podman 3.4.4 + containernetworking-plugins 0.9.1) では、
# podman-compose が cniVersion=1.0.0 の conflist を書くと、起動の度に
#   "plugin firewall does not support config version 1.0.0"
# という warning が出る。動作には影響しないが受講生が混乱するので、
# 既存の conflist を 0.4.0 に書き換えて警告を抑制する。
fix_cni_conflist() {
    local cni_dir="${HOME}/.config/cni/net.d"
    if [[ -d "${cni_dir}" ]]; then
        find "${cni_dir}" -name '*.conflist' -exec \
            sed -i 's/"cniVersion": *"1\.0\.0"/"cniVersion": "0.4.0"/g' {} + 2>/dev/null || true
    fi
}
fix_cni_conflist

echo "Starting Oracle XE (${COMPOSE_CMD[*]} up -d oracle)..."
# WSL2 では systemd が動いていないため、podman 3.4.4 が healthcheck を systemd
# timer で起動しようとして以下の error を出すが動作には影響しないので抑制する:
#   "unable to get systemd connection to (add|start) healthchecks: ..."
# (start-oracle.sh は後段で podman exec healthcheck.sh を直接呼んで疎通確認する)
"${COMPOSE_CMD[@]}" up -d oracle 2>&1 \
    | grep -vE 'unable to get systemd connection to (add|start) healthchecks' || true
COMPOSE_RC=${PIPESTATUS[0]}
if [[ ${COMPOSE_RC} -ne 0 ]]; then
    echo "podman-compose up が失敗しました (exit=${COMPOSE_RC})" >&2
    exit "${COMPOSE_RC}"
fi

# compose が新規に conflist を書き出した場合に備えてもう一度書き換え
# (次回以降の起動で警告が出ないようにする)
fix_cni_conflist

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
