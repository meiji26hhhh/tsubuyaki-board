#!/usr/bin/env bash
# =========================================================================
# 社内つぶやきボード WSL Ubuntu 22.04 キッティング (idempotent)
#
# 使い方:
#   bash scripts/setup-wsl.sh                       # 通常実行
#   bash scripts/setup-wsl.sh --rollback            # apt purge + image rm
#   bash scripts/setup-wsl.sh --install-codex-host  # Codex CLI を WSL ホストに直接導入
# =========================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

MODE_ROLLBACK=false
MODE_HOST_CODEX=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --rollback)
            MODE_ROLLBACK=true
            shift
            ;;
        --install-codex-host)
            MODE_HOST_CODEX=true
            shift
            ;;
        -h|--help)
            cat <<'EOF'
使い方:
  bash scripts/setup-wsl.sh                          # 通常セットアップ
  bash scripts/setup-wsl.sh --rollback               # apt パッケージ purge
  bash scripts/setup-wsl.sh --install-codex-host     # Codex CLI を WSL ホストに直接導入
EOF
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

if [[ ${EUID} -ne 0 ]]; then
    SUDO="sudo"
else
    SUDO=""
fi

if ${MODE_ROLLBACK}; then
    echo "Rollback: apt purge + podman image rm"
    ${SUDO} apt-get purge -y \
        temurin-21-jdk maven podman podman-compose nodejs gh \
        ripgrep fd-find jq 2>/dev/null || true
    ${SUDO} apt-get autoremove -y || true
    podman image rm codex-devbox:latest 2>/dev/null || true
    echo "Rollback 完了"
    exit 0
fi

echo ""
echo "==> 1. apt update / 基本ツール"
${SUDO} apt-get update
${SUDO} apt-get install -y --no-install-recommends \
    git curl wget ca-certificates gnupg locales tzdata software-properties-common \
    jq unzip less vim-tiny sudo build-essential netcat-openbsd ripgrep fd-find file

echo ""
echo "==> 2. ロケール / TZ"
${SUDO} locale-gen ja_JP.UTF-8
${SUDO} update-locale LANG=ja_JP.UTF-8
${SUDO} ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
echo "Asia/Tokyo" | ${SUDO} tee /etc/timezone > /dev/null

echo ""
echo "==> 3. Eclipse Temurin 21"
if ! dpkg -s temurin-21-jdk >/dev/null 2>&1; then
    ${SUDO} mkdir -p /etc/apt/keyrings
    wget -qO- https://packages.adoptium.net/artifactory/api/gpg/key/public \
        | ${SUDO} gpg --dearmor -o /etc/apt/keyrings/adoptium.gpg
    CODENAME="$(awk -F= '/VERSION_CODENAME/ {print $2}' /etc/os-release)"
    echo "deb [signed-by=/etc/apt/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb ${CODENAME} main" \
        | ${SUDO} tee /etc/apt/sources.list.d/adoptium.list > /dev/null
    ${SUDO} apt-get update
    ${SUDO} apt-get install -y --no-install-recommends temurin-21-jdk
fi
${SUDO} tee /etc/profile.d/jdk.sh > /dev/null <<'EOF'
export JAVA_HOME=/usr/lib/jvm/temurin-21-jdk-amd64
export PATH="${JAVA_HOME}/bin:${PATH}"
EOF

echo ""
echo "==> 4. Maven"
if ! dpkg -s maven >/dev/null 2>&1; then
    ${SUDO} apt-get install -y --no-install-recommends maven
fi

echo ""
echo "==> 5. Podman / podman-compose"
# Ubuntu 22.04 で rootless podman を動かすのに必要なパッケージ:
#   - podman: コンテナランタイム本体
#   - uidmap: newuidmap/newgidmap (rootless 必須)
#   - slirp4netns: rootless ネットワーク
#   - fuse-overlayfs: rootless ストレージドライバ
${SUDO} apt-get install -y --no-install-recommends \
    podman uidmap slirp4netns fuse-overlayfs
# podman-compose は Ubuntu 22.04 jammy/universe には存在しないため pip 経由で導入
if ! command -v podman-compose >/dev/null 2>&1; then
    if ! command -v pip3 >/dev/null 2>&1; then
        ${SUDO} apt-get install -y --no-install-recommends python3-pip
    fi
    ${SUDO} pip3 install --break-system-packages podman-compose 2>/dev/null \
        || ${SUDO} pip3 install podman-compose
fi
USER_NAME="$(whoami)"
if ! grep -q "^${USER_NAME}:" /etc/subuid 2>/dev/null; then
    ${SUDO} usermod --add-subuids 100000-165535 --add-subgids 100000-165535 "${USER_NAME}" || true
fi

# rootless podman のストレージドライバを overlay + fuse-overlayfs に固定。
# Ubuntu 22.04 + WSL2 では何も指定しないと vfs にフォールバックすることがあり、
# その場合 "graph driver \"vfs\" from database" の警告が以降ずっと出続ける。
USER_CONTAINERS_DIR="${HOME}/.config/containers"
mkdir -p "${USER_CONTAINERS_DIR}"
if [[ ! -f "${USER_CONTAINERS_DIR}/storage.conf" ]]; then
    cat > "${USER_CONTAINERS_DIR}/storage.conf" <<'EOF'
[storage]
driver = "overlay"

[storage.options.overlay]
mount_program = "/usr/bin/fuse-overlayfs"
EOF
fi
# 既に vfs で初期化されていて、ローカルイメージがまだ無ければ
# storage を一度だけリセットして overlay で再初期化する (初回セットアップ救済)
CURRENT_DRIVER="$(podman info --format '{{.Store.GraphDriverName}}' 2>/dev/null | tail -n 1 || true)"
if [[ "${CURRENT_DRIVER}" == "vfs" ]] && [[ -z "$(podman images -q 2>/dev/null)" ]]; then
    podman system reset --force >/dev/null 2>&1 || true
fi

echo ""
echo "==> 6. mvnw 生成 (script-only)"
if [[ ! -x "${REPO_ROOT}/mvnw" ]]; then
    # shellcheck disable=SC1091
    source /etc/profile.d/jdk.sh
    (cd "${REPO_ROOT}" && mvn -q -N wrapper:wrapper -Dtype=script -Dmaven=3.9.9) || \
        echo "  mvnw 生成に失敗。pom.xml と Maven のバージョンを確認してください。"
    if [[ -f "${REPO_ROOT}/mvnw" ]]; then
        chmod +x "${REPO_ROOT}/mvnw"
        echo "  mvnw を生成しました"
    fi
fi

echo ""
echo "==> 7. Codex devbox イメージ"
if ! ${MODE_HOST_CODEX}; then
    if ! podman image exists codex-devbox:latest 2>/dev/null; then
        bash "${REPO_ROOT}/scripts/build-codex-image.sh"
    else
        echo "  codex-devbox:latest はビルド済み"
    fi
else
    echo "  --install-codex-host: Node + Codex CLI を WSL ホストに直接導入"
    if ! command -v node >/dev/null 2>&1; then
        curl -fsSL https://deb.nodesource.com/setup_20.x | ${SUDO} bash -
        ${SUDO} apt-get install -y --no-install-recommends nodejs
    fi
    ${SUDO} npm install -g @openai/codex@latest
fi

echo ""
echo "==> 8. ~/.bashrc にエイリアスを追加"
MARKER_BEGIN="# >>> codex-training >>>"
MARKER_END="# <<< codex-training <<<"
BASHRC="${HOME}/.bashrc"
TMP_BLOCK="$(mktemp)"
cat > "${TMP_BLOCK}" <<EOF
${MARKER_BEGIN}
export LANG=ja_JP.UTF-8
export TZ=Asia/Tokyo
[ -f /etc/profile.d/jdk.sh ] && source /etc/profile.d/jdk.sh
alias codex-shell='bash ${REPO_ROOT}/scripts/run-codex.sh'
${MARKER_END}
EOF
if grep -qF "${MARKER_BEGIN}" "${BASHRC}" 2>/dev/null; then
    awk -v begin="${MARKER_BEGIN}" -v end="${MARKER_END}" -v block_file="${TMP_BLOCK}" '
        BEGIN { in_block = 0 }
        $0 ~ begin { in_block = 1
                     while ((getline line < block_file) > 0) print line
                     close(block_file); next }
        $0 ~ end   { in_block = 0; next }
        in_block == 0 { print }
    ' "${BASHRC}" > "${BASHRC}.tmp" && mv "${BASHRC}.tmp" "${BASHRC}"
else
    cat "${TMP_BLOCK}" >> "${BASHRC}"
fi
rm -f "${TMP_BLOCK}"

echo ""
echo "==> 9. Doctor (quick)"
# 直前に書き込んだ /etc/profile.d/jdk.sh と TZ を当該プロセスにも反映させる
# (新シェルでは bashrc/profile から自動的に読まれるため、ここの補完はセットアップ完了時の表示用)
# shellcheck disable=SC1091
source /etc/profile.d/jdk.sh 2>/dev/null || true
export TZ="${TZ:-Asia/Tokyo}"
bash "${REPO_ROOT}/scripts/doctor.sh" --quick || true

echo ""
echo "==> WSL セットアップ完了"
echo "次のステップ ('かんたんセットアップ' フォルダのバッチをダブルクリック):"
echo "  1. セットアップ3_APIキー設定.bat   # OPENAI_API_KEY と .env を設定"
echo "  2. 環境チェック.bat                # 準備ができているか診断"
echo "  3. Oracle起動.bat                  # データベースを起動"
echo ""
echo "（上級者向け）手動で行う場合:"
echo "  bash scripts/setup-secrets.sh      # OPENAI_API_KEY と .env を設定"
echo "  bash scripts/start-oracle.sh"
echo "  codex-shell                        # コンテナに入って codex を起動"
