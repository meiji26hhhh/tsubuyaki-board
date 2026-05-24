#!/usr/bin/env bash
# =========================================================================
# 社内つぶやきボード Day0 Doctor (WSL2 / Linux 側)
#
# 使い方:
#   bash scripts/doctor.sh                       # 全件検査
#   bash scripts/doctor.sh --quick               # ネット疎通など重い検査をスキップ
#   bash scripts/doctor.sh --only network,jdk    # 特定カテゴリのみ
# =========================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LOG_FILE="/tmp/doctor-$(date +%Y%m%d-%H%M%S).log"

RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
CYAN=$'\033[0;36m'
RESET=$'\033[0m'

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0
MODE_QUICK=false
ONLY_FILTER=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --quick)
            MODE_QUICK=true
            shift
            ;;
        --only)
            ONLY_FILTER="$2"
            shift 2
            ;;
        -h|--help)
            cat <<'EOF'
社内つぶやきボード Doctor (Linux 側)

使い方:
  bash scripts/doctor.sh
  bash scripts/doctor.sh --quick
  bash scripts/doctor.sh --only network,jdk

カテゴリ:
  os, locale, network, git, jdk, maven, podman, codex-image,
  codex-cli, openai, oracle, disk, eol, java-smoke
EOF
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

log()  { printf '%b\n' "$*" | tee -a "${LOG_FILE}"; }
ok()   { PASS_COUNT=$((PASS_COUNT+1)); log "  ${GREEN}[ OK ]${RESET} $1${2:+ — $2}"; }
warn() { WARN_COUNT=$((WARN_COUNT+1)); log "  ${YELLOW}[WARN]${RESET} $1${2:+ — $2}"; }
ng()   { FAIL_COUNT=$((FAIL_COUNT+1)); log "  ${RED}[ NG ]${RESET} $1${2:+ — $2}"; }

section() {
    local id="$1" label="$2"
    if [[ -n "${ONLY_FILTER}" && ",${ONLY_FILTER}," != *",${id},"* ]]; then
        return 1
    fi
    log ""
    log "${CYAN}== ${label} ==${RESET}"
    return 0
}

# --- 1. OS / シェル ------------------------------------------------------
if section "os" "OS / シェル"; then
    if [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
        ok "WSL ディストリ" "${WSL_DISTRO_NAME}"
    elif uname -a | grep -qi microsoft; then
        warn "WSL らしいが WSL_DISTRO_NAME が空"
    else
        ng "Linux/WSL ではない可能性"
    fi
    ok "kernel" "$(uname -r)"
fi

# --- 2. ロケール / TZ ----------------------------------------------------
if section "locale" "ロケール / TZ"; then
    if [[ "${LANG:-}" == "ja_JP.UTF-8" ]]; then
        ok "LANG" "${LANG}"
    else
        warn "LANG が ja_JP.UTF-8 でない" "${LANG:-(未設定)}"
    fi
    CURRENT_TZ="$(timedatectl 2>/dev/null | awk -F': *' '/Time zone/ {print $2}' | awk '{print $1}')"
    [[ -z "${CURRENT_TZ}" ]] && CURRENT_TZ="${TZ:-}"
    # WSL では timedatectl が systemd 未起動で空を返すため、/etc/timezone を最終フォールバックにする
    [[ -z "${CURRENT_TZ}" && -r /etc/timezone ]] && CURRENT_TZ="$(cat /etc/timezone)"
    if [[ "${CURRENT_TZ}" == "Asia/Tokyo" ]]; then
        ok "TZ" "${CURRENT_TZ}"
    else
        warn "TZ が Asia/Tokyo でない" "${CURRENT_TZ:-(未設定)}"
    fi
fi

# --- 3. ネットワーク疎通 -------------------------------------------------
if ! ${MODE_QUICK} && section "network" "ネットワーク疎通"; then
    if curl -sI -o /dev/null -w '%{http_code}' --max-time 10 https://repo.maven.apache.org/maven2/ | grep -q '200'; then
        ok "Maven Central 疎通"
    else
        ng "Maven Central に到達できない"
    fi
    HTTP_CODE=$(curl -sI -o /dev/null -w '%{http_code}' --max-time 10 -H 'Authorization: Bearer invalid' https://api.openai.com/v1/models)
    if [[ "${HTTP_CODE}" == "401" || "${HTTP_CODE}" == "200" ]]; then
        ok "api.openai.com 疎通" "HTTP ${HTTP_CODE}"
    else
        warn "api.openai.com 疎通異常" "HTTP ${HTTP_CODE}"
    fi
    if curl -sI -o /dev/null -w '%{http_code}' --max-time 10 https://github.com/ | grep -q '200\|301\|302'; then
        ok "github.com 疎通"
    else
        warn "github.com 疎通異常"
    fi
fi

# --- 4. Git --------------------------------------------------------------
if section "git" "Git"; then
    if command -v git >/dev/null 2>&1; then
        ok "git" "$(git --version)"
        if [[ -n "$(git config --global user.name 2>/dev/null)" ]]; then
            ok "git user.name 設定済み" "$(git config --global user.name)"
        else
            ng "git config --global user.name が未設定"
        fi
        if [[ -n "$(git config --global user.email 2>/dev/null)" ]]; then
            ok "git user.email 設定済み"
        else
            ng "git config --global user.email が未設定"
        fi
    else
        ng "git が見つからない"
    fi
fi

# --- 5. JDK --------------------------------------------------------------
if section "jdk" "JDK"; then
    if command -v java >/dev/null 2>&1; then
        JAVA_VERSION_LINE=$(java -version 2>&1 | head -n 1)
        if echo "${JAVA_VERSION_LINE}" | grep -qE '"21(\.|$)|"21\.0'; then
            ok "java" "${JAVA_VERSION_LINE}"
        else
            warn "java は見つかったが Java 21 でない可能性" "${JAVA_VERSION_LINE}"
        fi
        if [[ -n "${JAVA_HOME:-}" && -d "${JAVA_HOME}" ]]; then
            ok "JAVA_HOME" "${JAVA_HOME}"
        else
            warn "JAVA_HOME 未設定 or 不在" "${JAVA_HOME:-(未設定)}"
        fi
    else
        ng "java コマンドが見つからない"
    fi
fi

# --- 6. Maven Wrapper ----------------------------------------------------
if section "maven" "Maven Wrapper"; then
    if [[ -x "${REPO_ROOT}/mvnw" ]]; then
        ok "mvnw 実行可能"
        if "${REPO_ROOT}/mvnw" -v >/dev/null 2>&1; then
            ok "mvnw -v 成功"
        else
            ng "mvnw -v が失敗"
        fi
    elif command -v mvn >/dev/null 2>&1; then
        warn "mvnw 未生成 (mvn はある)" "$(mvn -v 2>/dev/null | head -n 1)"
    else
        ng "mvnw も mvn も見つからない"
    fi
fi

# --- 7. Podman -----------------------------------------------------------
if section "podman" "Podman"; then
    if command -v podman >/dev/null 2>&1; then
        ok "podman" "$(podman --version)"
        if podman info >/dev/null 2>&1; then
            ok "podman info 成功 (rootless 含む)"
        else
            ng "podman info が失敗 — Podman Desktop / podman machine が止まっている可能性"
        fi
    else
        ng "podman が見つからない"
    fi
fi

# --- 8. Codex devbox image -----------------------------------------------
if section "codex-image" "Codex devbox image"; then
    if podman image exists codex-devbox:latest 2>/dev/null; then
        ok "codex-devbox:latest 存在"
    else
        warn "codex-devbox:latest 未ビルド" "bash scripts/build-codex-image.sh"
    fi
fi

# --- 9. Codex CLI (コンテナ内バージョン取得) ----------------------------
if ! ${MODE_QUICK} && section "codex-cli" "codex CLI"; then
    if podman image exists codex-devbox:latest 2>/dev/null; then
        # entrypoint.sh は OPENAI_API_KEY 未設定で exit 1 するため、
        # バージョン取得時は --entrypoint codex で entrypoint を素通りさせる
        CODEX_VER=$(podman run --rm --entrypoint codex codex-devbox:latest --version 2>/dev/null | head -n 1 || echo "")
        if [[ -n "${CODEX_VER}" ]]; then
            ok "codex CLI" "${CODEX_VER}"
        else
            warn "codex CLI のバージョン取得失敗"
        fi
    else
        warn "image 未ビルドのためスキップ"
    fi
fi

# --- 10. OPENAI_API_KEY --------------------------------------------------
if section "openai" "OPENAI_API_KEY"; then
    if [[ -n "${OPENAI_API_KEY:-}" ]]; then
        KEY_LEN=${#OPENAI_API_KEY}
        if (( KEY_LEN >= 12 )); then
            KEY_MASK="${OPENAI_API_KEY:0:7}…${OPENAI_API_KEY: -4}"
        else
            KEY_MASK="(short)"
        fi
        if [[ "${OPENAI_API_KEY}" == sk-* && ${KEY_LEN} -ge 20 ]]; then
            ok "OPENAI_API_KEY 設定済み" "${KEY_MASK} (${KEY_LEN} chars)"
        else
            warn "OPENAI_API_KEY の形式が怪しい" "${KEY_MASK}"
        fi
    else
        ng "OPENAI_API_KEY が未設定"
    fi
fi

# --- 11. Oracle XE -------------------------------------------------------
if section "oracle" "Oracle XE"; then
    if podman ps --format '{{.Names}}' 2>/dev/null | grep -q '^butsubutsu-oracle$'; then
        ok "butsubutsu-oracle コンテナ起動中"
        if (echo > /dev/tcp/localhost/1521) >/dev/null 2>&1; then
            ok "localhost:1521 疎通"
        elif command -v nc >/dev/null 2>&1 && nc -z localhost 1521 2>/dev/null; then
            ok "localhost:1521 疎通 (nc)"
        else
            warn "1521 に疎通しない (起動直後の場合は数十秒待つ)"
        fi
    else
        warn "Oracle XE コンテナが起動していない" "bash scripts/start-oracle.sh"
    fi
fi

# --- 12. ディスク空き ----------------------------------------------------
if section "disk" "ディスク空き"; then
    AVAIL_ROOT_KB=$(df -k / | awk 'NR==2 {print $4}')
    AVAIL_MNT_KB=$(df -k /mnt/c 2>/dev/null | awk 'NR==2 {print $4}' || echo "0")
    if (( AVAIL_ROOT_KB > 10*1024*1024 )); then
        ok "/ 空き" "$((AVAIL_ROOT_KB/1024/1024)) GB"
    else
        warn "/ 空きが 10GB 未満" "$((AVAIL_ROOT_KB/1024/1024)) GB"
    fi
    if [[ "${AVAIL_MNT_KB}" != "0" && -n "${AVAIL_MNT_KB}" ]]; then
        if (( AVAIL_MNT_KB > 10*1024*1024 )); then
            ok "/mnt/c 空き" "$((AVAIL_MNT_KB/1024/1024)) GB"
        else
            warn "/mnt/c 空きが 10GB 未満" "$((AVAIL_MNT_KB/1024/1024)) GB"
        fi
    fi
fi

# --- 13. 改行コード ------------------------------------------------------
if section "eol" "改行コード (LF)"; then
    if command -v file >/dev/null 2>&1; then
        BAD_FILES=$(find "${REPO_ROOT}/scripts" "${REPO_ROOT}/containers" -name '*.sh' \
                    -exec file {} \; 2>/dev/null | grep CRLF || true)
        if [[ -z "${BAD_FILES}" ]]; then
            ok "scripts/*.sh と containers/**/*.sh はすべて LF"
        else
            ng "CRLF の sh ファイルあり" "$(echo "${BAD_FILES}" | head -n 3)"
        fi
    else
        warn "file コマンドがないためスキップ"
    fi
fi

# --- 14. Java から XE への smoke 接続 (オプション) -----------------------
if ! ${MODE_QUICK} && section "java-smoke" "Java からの XE smoke 接続"; then
    if podman ps --format '{{.Names}}' 2>/dev/null | grep -q '^butsubutsu-oracle$' \
        && [[ -x "${REPO_ROOT}/mvnw" ]]; then
        if "${REPO_ROOT}/mvnw" -B -q -Plocal -Dtest='*Smoke*' test >/dev/null 2>&1; then
            ok "smoke テスト成功"
        else
            warn "smoke テスト未定義 or 失敗 (受講者作成後に再実行)"
        fi
    else
        warn "Oracle 未起動 or mvnw 未生成のためスキップ"
    fi
fi

# === サマリ ==============================================================
log ""
log "${CYAN}=== Doctor Summary ===${RESET}"
log "  PASS: ${GREEN}${PASS_COUNT}${RESET}    WARN: ${YELLOW}${WARN_COUNT}${RESET}    FAIL: ${RED}${FAIL_COUNT}${RESET}"
log "  詳細ログ: ${LOG_FILE}"

if (( FAIL_COUNT > 0 )); then
    exit 1
fi
exit 0
