#!/usr/bin/env bash
# Codex devbox entrypoint.
# 起動時に環境を検証し、対話シェルもしくは指定コマンドを起動する。
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

# --- 1. OPENAI_API_KEY 検査 ----------------------------------------------
if [[ -z "${OPENAI_API_KEY:-}" ]]; then
    echo -e "${RED}[codex-devbox] OPENAI_API_KEY が未設定です。${RESET}" >&2
    echo -e "${YELLOW}WSL 側で 'export OPENAI_API_KEY=sk-...' を実行してから run-codex.sh を呼んでください。${RESET}" >&2
    exit 1
fi

if [[ "${OPENAI_API_KEY}" != sk-* ]]; then
    echo -e "${YELLOW}[codex-devbox] WARN: OPENAI_API_KEY が 'sk-' で始まっていません。形式を再確認してください。${RESET}" >&2
fi

# --- 2. git safe.directory の保険登録 (uid 不一致対策) -------------------
# 注: PATH 先頭の codex-guard が git config --global を reject するため、
#     ここでは実体パスを直接呼ぶ。これは entrypoint (= 起動時の正規セットアップ)
#     なので、Codex が走り出す前に必要な操作。
REAL_GIT=/usr/bin/git
[[ -x "${REAL_GIT}" ]] || REAL_GIT=/bin/git
if [[ -x "${REAL_GIT}" ]]; then
    "${REAL_GIT}" config --global --add safe.directory /workspace >/dev/null 2>&1 || true
    "${REAL_GIT}" config --global --add safe.directory '/workspace/*' >/dev/null 2>&1 || true
fi

# --- 3. 起動バナー -------------------------------------------------------
KEY_LEN=${#OPENAI_API_KEY}
if (( KEY_LEN >= 12 )); then
    KEY_MASKED="${OPENAI_API_KEY:0:7}…${OPENAI_API_KEY: -4}"
else
    KEY_MASKED="(short)"
fi
CODEX_VERSION_INFO="$(codex --version 2>/dev/null || echo 'unknown')"
JAVA_LINE="$(java -version 2>&1 | head -n 1)"
MAVEN_LINE="$(mvn -v 2>/dev/null | head -n 1 || echo 'mvn not found')"

GUARD_STATUS="無効"
if [[ -x /opt/codex-guard/bin/rm ]]; then
    GUARD_STATUS="${GREEN}有効${RESET} (rm / git / chmod / chown / dd / sudo を wrapper で監査)"
fi

# .env が /dev/null マウントで上書きされているかを検査
ENV_STATUS="読み取り可"
if [[ -e /workspace/.env ]] && [[ ! -s /workspace/.env ]]; then
    # サイズ 0 = /dev/null overlay されている可能性大
    ENV_STATUS="${GREEN}/dev/null 上書きマウント済 (機密値は到達不能)${RESET}"
fi

cat <<EOF
${GREEN}╔══════════════════════════════════════════════════════════╗${RESET}
${GREEN}║  社内つぶやきボード Codex devbox                          ║${RESET}
${GREEN}╚══════════════════════════════════════════════════════════╝${RESET}
  ${CYAN}Codex CLI${RESET}    : ${CODEX_VERSION_INFO}
  ${CYAN}Java${RESET}         : ${JAVA_LINE}
  ${CYAN}Maven${RESET}        : ${MAVEN_LINE}
  ${CYAN}Workspace${RESET}    : $(pwd)
  ${CYAN}API Key${RESET}      : ${KEY_MASKED}
  ${CYAN}研修ハーネス${RESET} : ${GUARD_STATUS}
  ${CYAN}.env${RESET}         : ${ENV_STATUS}

EOF

# --- 4. コマンド実行 -----------------------------------------------------
if [[ $# -eq 0 ]]; then
    exec bash -l
else
    exec "$@"
fi
