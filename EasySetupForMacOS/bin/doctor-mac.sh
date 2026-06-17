#!/usr/bin/env bash
# =========================================================================
# 社内つぶやきボード Doctor (macOS / Apple Silicon, H2 のみ)
#
# 既存 scripts/doctor.sh の macOS 版。WSL/Oracle 前提の検査を除去し、
# podman machine の状態検査を新設。DB は H2 のみのため Oracle 検査は無い。
#
# 使い方:
#   bash bin/doctor-mac.sh                  # 全件検査
#   bash bin/doctor-mac.sh --quick          # ネット疎通など重い検査をスキップ
#   bash bin/doctor-mac.sh --only jdk,podman
# =========================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EASYSET_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Homebrew (podman 等) を PATH に載せる (.command 経由の最小 PATH 対策)
if ! command -v brew >/dev/null 2>&1; then
    if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

LOG_DIR="${EASYSET_DIR}/logs"
mkdir -p "${LOG_DIR}"
LOG_FILE="${LOG_DIR}/doctor_$(date +%Y%m%d-%H%M%S).log"

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
        --quick) MODE_QUICK=true; shift ;;
        --only)
            ONLY_FILTER="${2:-}"
            if [[ -z "${ONLY_FILTER}" ]]; then
                echo "--only にはカテゴリをカンマ区切りで指定してください (例: --only podman,jdk)" >&2
                exit 1
            fi
            shift 2 ;;
        -h|--help)
            cat <<'EOF'
社内つぶやきボード Doctor (macOS 版)

使い方:
  bash bin/doctor-mac.sh
  bash bin/doctor-mac.sh --quick
  bash bin/doctor-mac.sh --only podman,jdk

カテゴリ:
  os, locale, network, git, jdk, maven, podman, podman-machine,
  codex-image, codex-cli, harness, openai, disk, eol
EOF
            exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# 画面には色付きで表示し、ログファイルには ANSI エスケープを除去して記録する
log() {
    printf '%b\n' "$*"
    printf '%b\n' "$*" | sed -e 's/\x1b\[[0-9;]*m//g' >> "${LOG_FILE}"
}
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
    if [[ "$(uname -s)" == "Darwin" ]]; then
        ok "macOS" "$(sw_vers -productVersion 2>/dev/null || echo '?')"
    else
        ng "macOS ではない" "$(uname -s)"
    fi
    ARCH="$(uname -m)"
    if [[ "${ARCH}" == "arm64" ]]; then
        ok "アーキテクチャ" "arm64 (Apple Silicon)"
    else
        warn "Apple Silicon (arm64) でない" "${ARCH}"
    fi
fi

# --- 2. ロケール / TZ ----------------------------------------------------
if section "locale" "ロケール / TZ"; then
    if [[ "${LANG:-}" == "ja_JP.UTF-8" ]]; then
        ok "LANG" "${LANG}"
    else
        warn "LANG が ja_JP.UTF-8 でない (macOS では空でも動作)" "${LANG:-(未設定)}"
    fi
    CURRENT_TZ="${TZ:-}"
    [[ -z "${CURRENT_TZ}" ]] && CURRENT_TZ="$(readlink /etc/localtime 2>/dev/null | sed 's#.*/zoneinfo/##' || true)"
    if [[ "${CURRENT_TZ}" == "Asia/Tokyo" ]]; then
        ok "TZ" "${CURRENT_TZ}"
    else
        warn "TZ が Asia/Tokyo でない (任意)" "${CURRENT_TZ:-(未設定)}"
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
    else
        ng "java コマンドが見つからない" "brew install --cask temurin@21 (1_Macの準備.command)"
    fi
    # macOS 定石: /usr/libexec/java_home -v 21 で JDK21 を解決
    if [[ -z "${JAVA_HOME:-}" ]]; then
        JAVA_HOME="$(/usr/libexec/java_home -v 21 2>/dev/null || true)"
    fi
    if [[ -n "${JAVA_HOME:-}" && -d "${JAVA_HOME}" ]]; then
        ok "JAVA_HOME (java_home -v 21)" "${JAVA_HOME}"
    else
        warn "JDK 21 を java_home で解決できない" "brew install --cask temurin@21"
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
            ok "podman info 成功"
        else
            ng "podman info が失敗 — podman machine が止まっている可能性" "podman machine start"
        fi
    else
        ng "podman が見つからない" "brew install podman"
    fi
fi

# --- 8. podman machine (macOS 固有) --------------------------------------
if section "podman-machine" "podman machine"; then
    if ! command -v podman >/dev/null 2>&1; then
        ng "podman が無いため machine を確認できない"
    elif podman machine inspect podman-machine-default >/dev/null 2>&1; then
        STATE="$(podman machine inspect podman-machine-default --format '{{.State}}' 2>/dev/null || echo '')"
        if [[ "${STATE}" == "running" ]]; then
            ok "podman machine 起動中" "podman-machine-default"
        else
            ng "podman machine が起動していない (${STATE:-unknown})" "podman machine start"
        fi
    else
        ng "podman machine が未作成" "「1_Macの準備.command」を実行"
    fi
fi

# --- 9. Codex devbox image -----------------------------------------------
if section "codex-image" "Codex devbox image"; then
    if ! command -v podman >/dev/null 2>&1; then
        warn "podman がないためスキップ"
    elif podman image exists codex-devbox:latest 2>/dev/null; then
        ARCH_INFO="$(podman image inspect codex-devbox:latest --format '{{.Architecture}}' 2>/dev/null || echo '?')"
        ok "codex-devbox:latest 存在" "arch=${ARCH_INFO}"
    else
        warn "codex-devbox:latest 未ビルド" "「1_Macの準備.command」を実行"
    fi
fi

# --- 10. Codex CLI (コンテナ内バージョン取得) ----------------------------
if ! ${MODE_QUICK} && section "codex-cli" "codex CLI"; then
    if podman image exists codex-devbox:latest 2>/dev/null; then
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

# --- 11. Codex training harness ------------------------------------------
# 注: scripts/run-codex.sh ではなく bin/run-codex-mac.sh の実マウント構成
# (keep-id:uid=1000,gid=1000) を手書きで再現したフィクスチャ。run-codex-mac.sh の
# マスク条件・マウント構成を変えたら、ここも必ず追従させること (自動同期はされない)。
# macOS の podman machine は $HOME のみ virtiofs 共有するため、一時ディレクトリは
# TMPDIR (/var/folders/...) ではなく $HOME 配下に作る必要がある。
if ! ${MODE_QUICK} && section "harness" "Codex 研修ハーネス"; then
    if ! command -v podman >/dev/null 2>&1; then
        warn "podman がないためハーネス実行検証をスキップ"
    elif ! podman image exists codex-devbox:latest 2>/dev/null; then
        warn "codex-devbox:latest 未ビルドのためスキップ" "「1_Macの準備.command」を実行"
    else
        HARNESS_BASE="${HOME}/.codex-training"
        mkdir -p "${HARNESS_BASE}"
        HARNESS_TMP="$(mktemp -d "${HARNESS_BASE}/harness-test.XXXXXX")"
        mkdir -p "${HARNESS_TMP}/.codex" "${HARNESS_TMP}/src" "${HARNESS_TMP}/target"
        printf 'harness test\n' > "${HARNESS_TMP}/AGENTS.md"
        printf '<project/>\n' > "${HARNESS_TMP}/pom.xml"
        printf 'approval_policy = "on-request"\n' > "${HARNESS_TMP}/.codex/config.toml"
        printf 'ORACLE_APP_PWD=secret\n' > "${HARNESS_TMP}/.env"
        printf 'SECRET=secret\n' > "${HARNESS_TMP}/secret.txt"

        HARNESS_OUTPUT="$(
            podman run --rm \
                --userns=keep-id:uid=1000,gid=1000 \
                --security-opt label=disable \
                --security-opt no-new-privileges \
                --cap-drop=ALL \
                -v "${HARNESS_TMP}:/workspace:rw" \
                --mount "type=bind,src=/dev/null,dst=/workspace/.env,ro=true" \
                --mount "type=bind,src=/dev/null,dst=/workspace/secret.txt,ro=true" \
                --mount "type=bind,src=${HARNESS_TMP}/AGENTS.md,dst=/workspace/AGENTS.md,ro=true" \
                --mount "type=bind,src=${HARNESS_TMP}/.codex,dst=/workspace/.codex,ro=true" \
                --workdir /workspace \
                --entrypoint bash \
                codex-devbox:latest -lc '
                    set +e
                    git init -q /workspace >/dev/null 2>&1

                    git -C /workspace reset --hard >/tmp/harness-git.log 2>&1
                    git_rc=$?

                    rm -rf src >/tmp/harness-rm-src.log 2>&1
                    rm_src_rc=$?

                    mkdir -p target
                    rm -rf target >/tmp/harness-rm-target.log 2>&1
                    rm_target_rc=$?

                    env_mask=1
                    [[ -e /workspace/.env && ! -s /workspace/.env && -e /workspace/secret.txt && ! -s /workspace/secret.txt ]] && env_mask=0

                    echo "mutate" >> /workspace/AGENTS.md 2>/tmp/harness-ro.log
                    ro_rc=$?

                    printf "git=%s rm_src=%s rm_target=%s env_mask=%s ro=%s\n" \
                        "${git_rc}" "${rm_src_rc}" "${rm_target_rc}" "${env_mask}" "${ro_rc}"
                ' 2>/dev/null || true
        )"
        rm -rf "${HARNESS_TMP}"

        if echo "${HARNESS_OUTPUT}" | grep -q 'git=126'; then
            ok "git guard" "git -C /workspace reset --hard を拒否"
        else
            ng "git guard" "期待: git=126 / 実際: ${HARNESS_OUTPUT:-(出力なし)}"
        fi
        if echo "${HARNESS_OUTPUT}" | grep -q 'rm_src=126'; then
            ok "rm guard" "rm -rf src を拒否"
        else
            ng "rm guard" "期待: rm_src=126 / 実際: ${HARNESS_OUTPUT:-(出力なし)}"
        fi
        if echo "${HARNESS_OUTPUT}" | grep -q 'rm_target=0'; then
            ok "rm allowlist" "rm -rf target は許可"
        else
            ng "rm allowlist" "期待: rm_target=0 / 実際: ${HARNESS_OUTPUT:-(出力なし)}"
        fi
        if echo "${HARNESS_OUTPUT}" | grep -q 'env_mask=0'; then
            ok "secret mask" ".env と secret.txt は空マウント"
        else
            ng "secret mask" "期待: env_mask=0 / 実際: ${HARNESS_OUTPUT:-(出力なし)} (Mac は \$HOME 配下のみ bind 可)"
        fi
        if echo "${HARNESS_OUTPUT}" | grep -Eq 'ro=[1-9][0-9]*'; then
            ok "readonly mount" "AGENTS.md は書き込み不可"
        else
            ng "readonly mount" "期待: ro!=0 / 実際: ${HARNESS_OUTPUT:-(出力なし)}"
        fi
    fi
fi

# --- 12. OPENAI_API_KEY --------------------------------------------------
if section "openai" "OPENAI_API_KEY"; then
    # 環境変数 -> 専用キーファイル -> ~/.zshrc の順でフォールバック取得
    if [[ -z "${OPENAI_API_KEY:-}" && -r "${HOME}/.codex-training/openai_key" ]]; then
        OPENAI_API_KEY="$(cat "${HOME}/.codex-training/openai_key" 2>/dev/null || true)"
    fi
    if [[ -z "${OPENAI_API_KEY:-}" && -r "${HOME}/.zshrc" ]]; then
        OPENAI_API_KEY="$(sed -n "s/^export OPENAI_API_KEY='\(.*\)'\$/\1/p" "${HOME}/.zshrc" | tail -n1)"
    fi
    if [[ -n "${OPENAI_API_KEY:-}" ]]; then
        KEY_LEN=${#OPENAI_API_KEY}
        if [[ "${OPENAI_API_KEY}" == sk-* && ${KEY_LEN} -ge 20 ]]; then
            ok "OPENAI_API_KEY 設定済み" "値は表示しません"
        else
            warn "OPENAI_API_KEY の形式が怪しい" "値は表示しません"
        fi
    else
        ng "OPENAI_API_KEY が未設定" "「2_APIキーとGit設定.command」を実行"
    fi
fi

# --- 13. ディスク空き ----------------------------------------------------
if section "disk" "ディスク空き"; then
    AVAIL_ROOT_KB=$(df -k / | awk 'NR==2 {print $4}')
    if [[ -n "${AVAIL_ROOT_KB}" ]] && (( AVAIL_ROOT_KB > 15*1024*1024 )); then
        ok "/ 空き" "$((AVAIL_ROOT_KB/1024/1024)) GB"
    else
        warn "/ 空きが 15GB 未満" "$((AVAIL_ROOT_KB/1024/1024)) GB"
    fi
fi

# --- 14. 改行コード ------------------------------------------------------
if section "eol" "改行コード (LF)"; then
    if command -v file >/dev/null 2>&1; then
        BAD_FILES=$(find "${EASYSET_DIR}" \( -name '*.sh' -o -name '*.command' \) \
                    -exec file {} \; 2>/dev/null | grep CRLF || true)
        if [[ -z "${BAD_FILES}" ]]; then
            ok "EasySetupForMacOS の *.sh / *.command はすべて LF"
        else
            ng "CRLF のファイルあり (shebang が壊れます)" "$(echo "${BAD_FILES}" | head -n 3)"
        fi
    else
        warn "file コマンドがないためスキップ"
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
