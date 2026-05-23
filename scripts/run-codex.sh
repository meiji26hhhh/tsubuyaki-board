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
# --security-opt no-new-privileges : sudo を持ち込んでも setuid 系で権限昇格できない
# --read-only : ルートファイルシステムを読み取り専用にしたいが、
#               /tmp や Maven のキャッシュで書き込み必要なので tmpfs と writable_roots
#               で開ける必要があり、今回は採用見送り。
# --cap-drop=ALL : Linux capability を全削除 (network 等は podman の network で別途)
RUN_OPTS=(
    --rm
    -it
    --name "codex-devbox-$$"
    --userns=keep-id
    --security-opt label=disable
    --security-opt no-new-privileges
    --cap-drop=ALL
    -e OPENAI_API_KEY
    -e "TZ=Asia/Tokyo"
    -e "LANG=ja_JP.UTF-8"
    -v "${WORKSPACE_HOST}:/workspace:rw"
    -v "${CODEX_HOME}:/home/codex/.codex:rw"
    -v "${M2_HOME}:/home/codex/.m2:rw"
    --workdir /workspace
)

# --- 研修ハーネス: 機密ファイルを /dev/null 上書きマウント ----------------
# Codex がリポルートを読んでも、以下のファイルは「空」として返るようにする。
#
# 仕組み:
#   1. /home/codex/ 配下の dotfile は Containerfile で空ファイル作成済 (常時マスク)
#   2. /workspace/ 配下の機密ファイル (.env 等) はホスト側に存在する場合のみマスク
#      - ホストに無い場合は bind 元 (/dev/null) も dst も無いケースで podman が
#        失敗するため、存在チェックで分岐
#   3. ホストに .env が無いケースは初期状態であり、そもそも機密値が無いので
#      マスク不要 (= マウントしないだけで安全)

# 常時マスク (コンテナ内 dotfile)
HARNESS_ALWAYS_MASK=(
    "/home/codex/.bashrc"
    "/home/codex/.bash_history"
    "/home/codex/.profile"
    "/home/codex/.gitconfig"
)
for mask_path in "${HARNESS_ALWAYS_MASK[@]}"; do
    RUN_OPTS+=(--mount "type=bind,src=/dev/null,dst=${mask_path},ro=true")
done

# ホスト側に存在する場合のみマスク (/workspace 配下の機密)
HARNESS_WORKSPACE_MASK=(
    ".env"
    ".env.local"
    ".env.production"
    ".env.development"
)
for rel_path in "${HARNESS_WORKSPACE_MASK[@]}"; do
    if [[ -f "${WORKSPACE_HOST}/${rel_path}" ]]; then
        RUN_OPTS+=(--mount "type=bind,src=/dev/null,dst=/workspace/${rel_path},ro=true")
    fi
done

# --- 研修ハーネス: 規範ファイルを読み取り専用に -----------------------------
# AGENTS.md / .codex / instructor / .github は Codex に書き換えさせない。
# bind マウントを :ro で重ねがけして物理的に書き込み禁止。
HARNESS_READONLY_PATHS=(
    "AGENTS.md"
    ".codex"
    "instructor"
    ".github"
)
for ro_path in "${HARNESS_READONLY_PATHS[@]}"; do
    if [[ -e "${WORKSPACE_HOST}/${ro_path}" ]]; then
        RUN_OPTS+=(--mount "type=bind,src=${WORKSPACE_HOST}/${ro_path},dst=/workspace/${ro_path},ro=true")
    fi
done

# SPRING_PROFILES_ACTIVE は設定されていれば透過する
if [[ -n "${SPRING_PROFILES_ACTIVE:-}" ]]; then
    RUN_OPTS+=(-e SPRING_PROFILES_ACTIVE)
fi

# --- 起動 -------------------------------------------------------------------
# 受講生に「ハーネスが有効である」ことを認知させるため、起動前に 1 行表示
echo "[codex-shell] 研修ハーネス有効 (rm/git/chmod/dd guard + .env マスク + 規範ファイル ro)" >&2

exec podman run "${RUN_OPTS[@]}" "${IMAGE_TAG}" "$@"
