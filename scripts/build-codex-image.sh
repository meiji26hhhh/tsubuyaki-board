#!/usr/bin/env bash
# Codex devbox イメージをビルドする。
# 使い方:
#   bash scripts/build-codex-image.sh
#   CODEX_VERSION=0.x.y bash scripts/build-codex-image.sh   # バージョン固定
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CONTEXT_DIR="${REPO_ROOT}/containers/codex-devbox"
IMAGE_TAG="${IMAGE_TAG:-codex-devbox:latest}"
CODEX_VERSION="${CODEX_VERSION:-latest}"

if ! command -v podman >/dev/null 2>&1; then
    echo "podman が見つかりません。setup-wsl.sh を先に実行してください。" >&2
    exit 1
fi

if [[ ! -f "${CONTEXT_DIR}/Containerfile" ]]; then
    echo "Containerfile が見つかりません: ${CONTEXT_DIR}/Containerfile" >&2
    exit 1
fi

echo "Building Codex devbox image"
echo "  - Image tag      : ${IMAGE_TAG}"
echo "  - Codex version  : ${CODEX_VERSION}"
echo "  - Context        : ${CONTEXT_DIR}"
echo ""

podman build \
    --tag "${IMAGE_TAG}" \
    --build-arg CODEX_VERSION="${CODEX_VERSION}" \
    --file "${CONTEXT_DIR}/Containerfile" \
    "${CONTEXT_DIR}"

echo ""
echo "Build complete:"
podman images "${IMAGE_TAG}"
