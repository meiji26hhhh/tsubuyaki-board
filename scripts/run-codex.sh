#!/usr/bin/env bash
# Codex devbox コンテナを起動する標準ラッパ。
# - 現在のディレクトリ (リポルート想定) を /workspace に bind
# - ~/.codex (履歴) と ~/.m2 (Maven キャッシュ) を WSL ホストと共有
# - OPENAI_API_KEY を環境変数経由で渡す
#
# 使い方:
#   bash scripts/run-codex.sh                  # 対話シェル
#   bash scripts/run-codex.sh codex            # コンテナ内で codex を直接起動
#   WORKSPACE_HOST=/path/to/repo bash scripts/run-codex.sh   # bind 元を上書き
set -euo pipefail

IMAGE_TAG="${IMAGE_TAG:-codex-devbox:latest}"
WORKSPACE_HOST="${WORKSPACE_HOST:-$(pwd)}"
CODEX_HOME="${CODEX_HOME:-${HOME}/.codex}"
M2_HOME="${M2_HOME:-${HOME}/.m2}"

if ! command -v podman >/dev/null 2>&1; then
    echo "podman が見つかりません。setup-wsl.sh を先に実行してください。" >&2
    exit 1
fi

if ! podman image exists "${IMAGE_TAG}" 2>/dev/null; then
    echo "イメージ ${IMAGE_TAG} が見つかりません。" >&2
    echo "先に 'bash scripts/build-codex-image.sh' を実行してください。" >&2
    exit 1
fi

if [[ -z "${OPENAI_API_KEY:-}" ]]; then
    echo "OPENAI_API_KEY 環境変数を設定してから実行してください。" >&2
    echo "  例: export OPENAI_API_KEY=sk-xxxxxxxx" >&2
    exit 1
fi

if [[ ! -d "${WORKSPACE_HOST}" ]]; then
    echo "ワークスペース ${WORKSPACE_HOST} が存在しません。" >&2
    exit 1
fi

mkdir -p "${CODEX_HOME}" "${M2_HOME}"

# --- run options ----------------------------------------------------------
# --userns=keep-id : ホスト uid(1000) とコンテナ uid(1000) を揃え、bind マウント
#                    のファイル権限事故を避ける。
# --security-opt label=disable : SELinux ラベルが厳しい環境での回避。
RUN_OPTS=(
    --rm
    -it
    --name "codex-devbox-$$"
    --userns=keep-id
    --security-opt label=disable
    -e OPENAI_API_KEY
    -e "TZ=Asia/Tokyo"
    -e "LANG=ja_JP.UTF-8"
    -v "${WORKSPACE_HOST}:/workspace:rw"
    -v "${CODEX_HOME}:/home/codex/.codex:rw"
    -v "${M2_HOME}:/home/codex/.m2:rw"
    --workdir /workspace
)

# SPRING_PROFILES_ACTIVE は設定されていれば透過する
if [[ -n "${SPRING_PROFILES_ACTIVE:-}" ]]; then
    RUN_OPTS+=(-e SPRING_PROFILES_ACTIVE)
fi

exec podman run "${RUN_OPTS[@]}" "${IMAGE_TAG}" "$@"
