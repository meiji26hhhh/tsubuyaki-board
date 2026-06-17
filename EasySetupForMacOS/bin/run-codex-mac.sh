#!/usr/bin/env bash
# =========================================================================
# Codex devbox コンテナを起動する標準ラッパ (macOS / Podman machine)
#
# - リポルートを /workspace に bind (cwd 非依存。.command ダブルクリックでも成立)
# - 研修専用 CODEX_HOME と ~/.m2 を Mac ホストと共有
# - OPENAI_API_KEY を環境変数経由で渡す (無ければ ~/.codex-training/openai_key)
#
# 既存 scripts/run-codex.sh の macOS 調整版。主な差分:
#   1. --userns=keep-id:uid=1000,gid=1000 (Mac ホストは uid 501、コンテナ codex は
#      uid 1000。素の keep-id では bind マウントに書けないため uid を明示マップ)
#   2. 「広すぎるパス」ガードを macOS 用に (/mnt/c を削除、/Users 等を追加)。
#      ~/ 配下のサブディレクトリは許可 (Mac は ~/ 配下に clone するのが自然)
#   3. OPENAI_API_KEY を専用キーファイルからフォールバック取得
#   4. 冒頭で Homebrew PATH 注入 + podman machine 自動起動
#
# 使い方:
#   bash bin/run-codex-mac.sh                 # 対話シェル
#   bash bin/run-codex-mac.sh codex           # コンテナ内で codex を直接起動
#   WORKSPACE_HOST=/path/to/repo bash bin/run-codex-mac.sh   # bind 元を上書き
# =========================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_common.sh
. "${SCRIPT_DIR}/_common.sh"

# Homebrew (podman) を PATH に載せる (.command 経由の最小 PATH 対策)
ensure_brew_path

IMAGE_TAG="${IMAGE_TAG:-codex-devbox:latest}"
# WORKSPACE_HOST 未指定なら「スクリプト位置基準のリポルート」を既定にする。
# これにより任意のディレクトリから codex-shell しても、.command ダブルクリックでも
# 常にリポルートが /workspace にマウントされる。
WORKSPACE_HOST="${WORKSPACE_HOST:-$(repo_root)}"
CODEX_HOME="${CODEX_HOME:-${HOME}/.codex-training/tsubuyaki-board}"
M2_HOME="${M2_HOME:-${HOME}/.m2}"
MACHINE_NAME="podman-machine-default"

if ! command -v podman >/dev/null 2>&1; then
    echo "podman が見つかりません。先に「1_Macの準備.command」を実行してください。" >&2
    exit 1
fi

# podman machine が止まっていたら起動する (起動が目的のラッパなので自動 start)
if ! podman machine inspect "${MACHINE_NAME}" >/dev/null 2>&1; then
    echo "podman machine が未作成です。先に「1_Macの準備.command」を実行してください。" >&2
    exit 1
fi
MACHINE_STATE="$(podman machine inspect "${MACHINE_NAME}" --format '{{.State}}' 2>/dev/null || echo '')"
if [[ "${MACHINE_STATE}" != "running" ]]; then
    echo "[codex-shell] podman machine を起動します..." >&2
    podman machine start >/dev/null 2>&1 || true
fi
# start 後も応答しなければ machine 起動失敗。後続の的外れなエラー
# (「イメージが見つかりません」等) を避けて、原因を明示して止める。
if ! podman info >/dev/null 2>&1; then
    echo "podman machine を起動できませんでした。'podman machine start' を手動で試してください。" >&2
    exit 1
fi

if ! podman image exists "${IMAGE_TAG}" 2>/dev/null; then
    echo "イメージ ${IMAGE_TAG} が見つかりません。" >&2
    echo "先に「1_Macの準備.command」(または bash scripts/build-codex-image.sh) を実行してください。" >&2
    exit 1
fi

# OPENAI_API_KEY: 環境変数 -> 専用キーファイル -> ~/.zshrc の順で取得
# (doctor-mac.sh の openai セクションと取得経路を揃え、doctor が緑なのに
#  起動だけ失敗する false-green を防ぐ)
if [[ -z "${OPENAI_API_KEY:-}" && -r "${HOME}/.codex-training/openai_key" ]]; then
    OPENAI_API_KEY="$(cat "${HOME}/.codex-training/openai_key")"
    export OPENAI_API_KEY
fi
if [[ -z "${OPENAI_API_KEY:-}" && -r "${HOME}/.zshrc" ]]; then
    OPENAI_API_KEY="$(sed -n "s/^export OPENAI_API_KEY='\(.*\)'\$/\1/p" "${HOME}/.zshrc" | tail -n1)"
    [[ -n "${OPENAI_API_KEY}" ]] && export OPENAI_API_KEY
fi
if [[ -z "${OPENAI_API_KEY:-}" ]]; then
    echo "OPENAI_API_KEY が未設定です。「2_APIキーとGit設定.command」を実行してください。" >&2
    exit 1
fi

if [[ ! -d "${WORKSPACE_HOST}" ]]; then
    echo "ワークスペース ${WORKSPACE_HOST} が存在しません。" >&2
    exit 1
fi

WORKSPACE_HOST="$(cd "${WORKSPACE_HOST}" && pwd -P)"
HOME_REAL="$(cd "${HOME}" && pwd -P)"

# 広すぎるパスを /workspace にマウントさせない (macOS 版)。
# WSL の /mnt/c 系は不要。代わりに macOS のシステム/共有ディレクトリを禁止する。
case "${WORKSPACE_HOST}" in
    /|/Users|/System|/Library|/Applications|/tmp|/private|/private/tmp|/Volumes|/workspace)
        echo "ワークスペースとして広すぎるパスは指定できません: ${WORKSPACE_HOST}" >&2
        exit 1
        ;;
esac
# ホーム "直下そのもの" は不可。ただし ~/ 配下のサブディレクトリ
# (例: ~/training/tsubuyaki-board) は許可する (Mac の自然な clone 先)。
if [[ "${WORKSPACE_HOST}" == "${HOME_REAL}" ]]; then
    echo "ホーム直下全体を /workspace にマウントすることはできません: ${WORKSPACE_HOST}" >&2
    exit 1
fi
# ホーム直下の隠しディレクトリ (~/.ssh, ~/.codex-training 等の機密置き場) は拒否。
# ~/ 配下の通常サブディレクトリ (例 ~/training/tsubuyaki-board) は許可する。
case "${WORKSPACE_HOST}" in
    "${HOME_REAL}"/.*)
        echo "ホーム直下の隠しディレクトリ (~/.*) は /workspace に指定できません: ${WORKSPACE_HOST}" >&2
        exit 1
        ;;
esac

REQUIRED_MARKERS=("pom.xml" "AGENTS.md" ".codex/config.toml")
for marker in "${REQUIRED_MARKERS[@]}"; do
    if [[ ! -e "${WORKSPACE_HOST}/${marker}" ]]; then
        echo "ワークスペースが tsubuyaki-board のリポルートではありません (${marker} が見つかりません): ${WORKSPACE_HOST}" >&2
        exit 1
    fi
done

mkdir -p "${CODEX_HOME}" "${M2_HOME}"

# --- run options ----------------------------------------------------------
# --userns=keep-id:uid=1000,gid=1000 : Mac ホスト(uid 501)とコンテナの codex
#   (uid 1000) を揃え、bind マウントのファイル権限事故を避ける。素の keep-id だと
#   host 501 -> container 501 になり uid 1000 の codex がマウント先に書けない。
# --security-opt label=disable : SELinux ラベル回避 (podman machine の Linux では no-op)
# --security-opt no-new-privileges : sudo を持ち込んでも権限昇格できない
# --cap-drop=ALL : Linux capability を全削除
RUN_OPTS=(
    --rm
    --name "codex-devbox-$$"
    --userns=keep-id:uid=1000,gid=1000
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

# 対話シェルとして使うのが基本だが、非 TTY では -it が
# "input device is not a TTY" で失敗するため、TTY がある時だけ付ける
if [[ -t 0 ]]; then
    RUN_OPTS+=(-it)
fi

# --- 研修ハーネス: 機密ファイルを /dev/null 上書きマウント ----------------
# Mac ホストにも /dev/null は実在するので podman machine 越しでも機能する。
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
while IFS= read -r -d '' secret_path; do
    rel_path="${secret_path#"${WORKSPACE_HOST}"/}"
    # --mount はカンマ区切りでオプションを解釈するため、',' を含むパスは指定できない。
    # マスクを黙ってスキップすると機密が露出する (fail-open) ので、起動を中止する。
    if [[ "${rel_path}" == *,* ]]; then
        echo "機密ファイル名に ',' が含まれるためマスクできません: ${rel_path}" >&2
        echo "ファイル名を変更してから再実行してください。" >&2
        exit 1
    fi
    RUN_OPTS+=(--mount "type=bind,src=/dev/null,dst=/workspace/${rel_path},ro=true")
done < <(
    find "${WORKSPACE_HOST}" -path "${WORKSPACE_HOST}/.git" -prune -o \
        -path "${WORKSPACE_HOST}/target" -prune -o \
        -path "${WORKSPACE_HOST}/.codex/sessions" -prune -o \
        -type f \( \
            -name '.env' -o -name '.env.*' -o -name '*secret*' -o -name '*Secret*' -o \
            -name '*credentials*' -o -name '*Credentials*' -o -name '*.pem' -o \
            -name '*id_rsa*' -o -name '*id_ed25519*' \
        \) -print0
)

# --- 研修ハーネス: 規範ファイルを読み取り専用に -----------------------------
# AGENTS.md / .codex / instructor / .github は Codex に書き換えさせない。
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
echo "[codex-shell] 研修ハーネス有効 (rm/git/chmod/dd guard + .env マスク + 規範ファイル ro)" >&2

exec podman run "${RUN_OPTS[@]}" "${IMAGE_TAG}" "$@"
