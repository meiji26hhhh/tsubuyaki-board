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
  codex-cli, harness, openai, oracle, disk, eol, java-smoke
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
        # doctor は環境チェック.bat 等から非対話シェル (bash -c) 経由で起動される
        # ことがあり、その場合 /etc/profile.d/jdk.sh が読まれず JAVA_HOME が未設定に
        # 見える。受講生の対話シェル (~/.bashrc 経由) では設定済みなので、判定前に
        # 正本ファイルからフォールバック読込して実態に合わせる。
        if [[ -z "${JAVA_HOME:-}" && -f /etc/profile.d/jdk.sh ]]; then
            # shellcheck disable=SC1091
            source /etc/profile.d/jdk.sh 2>/dev/null || true
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

# --- 9.5. Codex training harness -----------------------------------------
if ! ${MODE_QUICK} && section "harness" "Codex 研修ハーネス"; then
    if ! command -v podman >/dev/null 2>&1; then
        warn "podman がないためハーネス実行検証をスキップ"
    elif ! podman image exists codex-devbox:latest 2>/dev/null; then
        warn "codex-devbox:latest 未ビルドのためハーネス実行検証をスキップ" "bash scripts/build-codex-image.sh"
    else
        HARNESS_TMP="$(mktemp -d)"
        mkdir -p "${HARNESS_TMP}/.codex" "${HARNESS_TMP}/instructor" "${HARNESS_TMP}/.github" "${HARNESS_TMP}/src" "${HARNESS_TMP}/target"
        printf 'harness test\n' > "${HARNESS_TMP}/AGENTS.md"
        printf '<project/>\n' > "${HARNESS_TMP}/pom.xml"
        printf 'approval_policy = "on-failure"\n' > "${HARNESS_TMP}/.codex/config.toml"
        printf 'ORACLE_APP_PWD=secret\n' > "${HARNESS_TMP}/.env"
        printf 'SECRET=secret\n' > "${HARNESS_TMP}/secret.txt"

        HARNESS_OUTPUT="$(
            podman run --rm \
                --userns=keep-id \
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
            ng "secret mask" "期待: env_mask=0 / 実際: ${HARNESS_OUTPUT:-(出力なし)}"
        fi
        if echo "${HARNESS_OUTPUT}" | grep -Eq 'ro=[1-9][0-9]*'; then
            ok "readonly mount" "AGENTS.md は書き込み不可"
        else
            ng "readonly mount" "期待: ro!=0 / 実際: ${HARNESS_OUTPUT:-(出力なし)}"
        fi
    fi
fi

# --- 10. OPENAI_API_KEY --------------------------------------------------
if section "openai" "OPENAI_API_KEY"; then
    # 非対話シェル (wsl -- bash -c) では ~/.bashrc が読まれず OPENAI_API_KEY が
    # 環境に無いため、setup-secrets.sh が ~/.bashrc に保存した値を拾う。
    if [[ -z "${OPENAI_API_KEY:-}" && -r "${HOME}/.bashrc" ]]; then
        OPENAI_API_KEY="$(sed -n "s/^export OPENAI_API_KEY='\(.*\)'\$/\1/p" "${HOME}/.bashrc" | tail -n1)"
    fi
    if [[ -n "${OPENAI_API_KEY:-}" ]]; then
        KEY_LEN=${#OPENAI_API_KEY}
        if [[ "${OPENAI_API_KEY}" == sk-* && ${KEY_LEN} -ge 20 ]]; then
            ok "OPENAI_API_KEY 設定済み" "値は表示しません"
        else
            warn "OPENAI_API_KEY の形式が怪しい" "値は表示しません"
        fi
    else
        ng "OPENAI_API_KEY が未設定"
    fi
fi

# --- 11. Oracle XE -------------------------------------------------------
if section "oracle" "Oracle XE"; then
    if podman ps --format '{{.Names}}' 2>/dev/null | grep -q '^tsubuyaki-oracle$'; then
        ok "tsubuyaki-oracle コンテナ起動中"
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
    if podman ps --format '{{.Names}}' 2>/dev/null | grep -q '^tsubuyaki-oracle$' \
        && [[ -x "${REPO_ROOT}/mvnw" ]]; then
        if "${REPO_ROOT}/mvnw" -B -q -Plocal -Dtest='*Smoke*' test >/dev/null 2>&1; then
            ok "smoke テスト成功"
        else
            warn "smoke テスト未定義 or 失敗 (受講生作成後に再実行)"
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
