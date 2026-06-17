#!/usr/bin/env bash
# =========================================================================
# 社内つぶやきボード macOS (Apple Silicon) キッティング (idempotent)
#
# Windows 版の「セットアップ1 (WSL/Ubuntu/winget)」+「セットアップ2 (apt 一式)」
# を 1 本に集約したもの。macOS には WSL 層が無いため段を分ける必然がなく、
# 再起動も不要。
#
#   Homebrew -> Temurin 21 / Maven / podman / git -> podman machine ->
#   mvnw -> Codex devbox イメージ -> shell rc に codex-shell エイリアス
#
# DB は H2 のみ (Oracle XE は Apple Silicon 非対応)。Oracle 関連は何もしない。
#
# 使い方:
#   bash bin/setup-mac.sh
#   PODMAN_MACHINE_MEMORY=8192 bash bin/setup-mac.sh   # machine メモリ上書き
# =========================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_common.sh
. "${SCRIPT_DIR}/_common.sh"

REPO_ROOT="$(repo_root)"

# podman machine は既定名 podman-machine-default を使う
MACHINE_NAME="podman-machine-default"
MACHINE_CPUS="${PODMAN_MACHINE_CPUS:-4}"
MACHINE_MEMORY="${PODMAN_MACHINE_MEMORY:-4096}"
MACHINE_DISK="${PODMAN_MACHINE_DISK:-40}"

# --- 0. OS / アーキテクチャ ガード ---------------------------------------
if [[ "$(uname -s)" != "Darwin" ]]; then
    print_error " このスクリプトは macOS 専用です。"
    exit 1
fi
ARCH="$(uname -m)"
if [[ "${ARCH}" != "arm64" ]]; then
    print_banner " ⚠ Apple Silicon (arm64) を想定しています (検出: ${ARCH})。" \
                 " Intel Mac では podman machine が重く、動作保証外です。続行します。"
fi

print_banner " Mac の準備を始めます。" \
             " （Homebrew / JDK21 / Maven / podman / Codex 環境を入れます）" \
             " 途中でパスワードを聞かれたら、Mac のログインパスワードを入力してください。" \
             " ★入力中は画面に文字が出ませんが、ちゃんと入力されています。"

# --- 1. Homebrew ---------------------------------------------------------
echo ""
echo "==> 1. Homebrew"
ensure_brew_path
if ! command -v brew >/dev/null 2>&1; then
    echo "  Homebrew が無いので導入します（公式インストーラ）..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    ensure_brew_path
fi
if ! command -v brew >/dev/null 2>&1; then
    print_error " [失敗] Homebrew を導入できませんでした。" \
                 " ネットワークと https://brew.sh の案内をご確認ください。"
    exit 1
fi
echo "  brew: $(brew --version | head -n 1)"

# --- 2. JDK 21 / Maven / podman / git ------------------------------------
echo ""
echo "==> 2. JDK 21 / Maven / podman / git"
# Temurin 21 (cask): /Library/Java/JavaVirtualMachines に入り、
# /usr/libexec/java_home -v 21 が即認識する (formula の openjdk@21 は keg-only で
# symlink が要るため cask を採用)。管理者パスワードを求められることがある。
if ! /usr/libexec/java_home -v 21 >/dev/null 2>&1; then
    echo "  Temurin JDK 21 を導入します (管理者パスワードを求められることがあります)..."
    brew install --cask temurin@21
fi

brew_install_formula() {
    local f="$1"
    if brew list --formula "${f}" >/dev/null 2>&1; then
        echo "  ${f} は導入済み"
    else
        brew install "${f}"
    fi
}
brew_install_formula maven
brew_install_formula podman
brew_install_formula git

# --- 3. JAVA_HOME --------------------------------------------------------
echo ""
echo "==> 3. JAVA_HOME"
if JAVA_HOME="$(/usr/libexec/java_home -v 21 2>/dev/null)"; then
    export JAVA_HOME
    export PATH="${JAVA_HOME}/bin:${PATH}"
    echo "  JAVA_HOME=${JAVA_HOME}"
    java -version 2>&1 | head -n 1 | sed 's/^/  /'
else
    print_banner " ⚠ JDK 21 を /usr/libexec/java_home で検出できませんでした。" \
                 " 新しいターミナルを開いて java -version をご確認ください。"
fi

# --- 4. podman machine (Oracle なしで軽量) -------------------------------
echo ""
echo "==> 4. podman machine"
if ! podman machine inspect "${MACHINE_NAME}" >/dev/null 2>&1; then
    echo "  podman machine を作成します (cpus=${MACHINE_CPUS}, memory=${MACHINE_MEMORY}MB, disk=${MACHINE_DISK}GB)..."
    echo "  （初回は Linux VM イメージの取得で数分かかります）"
    podman machine init --cpus "${MACHINE_CPUS}" --memory "${MACHINE_MEMORY}" --disk-size "${MACHINE_DISK}"
fi
# running 以外なら start (running 時に start するとエラーになるため必ず事前判定)
MACHINE_STATE="$(podman machine inspect "${MACHINE_NAME}" --format '{{.State}}' 2>/dev/null || echo '')"
if [[ "${MACHINE_STATE}" != "running" ]]; then
    echo "  podman machine を起動します..."
    # 既に starting/running の競合で start が非ゼロを返しても setup を止めない。
    # 起動可否は直後の `podman info` で最終判定する。
    podman machine start || true
fi
if ! podman info >/dev/null 2>&1; then
    print_error " [失敗] podman が応答しません。" \
                 " 'podman machine start' を手動で試し、解決しなければ講師にご相談ください。"
    exit 1
fi
echo "  podman: $(podman --version)"

# --- 5. Maven Wrapper (mvnw) ---------------------------------------------
echo ""
echo "==> 5. Maven Wrapper (mvnw)"
if [[ ! -x "${REPO_ROOT}/mvnw" ]]; then
    if ( cd "${REPO_ROOT}" && mvn -q -N wrapper:wrapper -Dtype=script -Dmaven=3.9.9 ); then
        echo "  mvnw を生成しました"
    else
        echo "  ⚠ mvnw 生成に失敗。pom.xml と Maven のバージョンを確認してください。"
    fi
    # 生成成否に関わらず、mvnw があれば実行ビットを立てる
    # (clone や zip 展開で +x が落ちていた場合の self-heal)
    [[ -f "${REPO_ROOT}/mvnw" ]] && chmod +x "${REPO_ROOT}/mvnw"
else
    echo "  mvnw は生成済み"
fi

# --- 6. Codex devbox イメージ --------------------------------------------
echo ""
echo "==> 6. Codex devbox イメージ"
if podman image exists codex-devbox:latest 2>/dev/null; then
    echo "  codex-devbox:latest はビルド済み"
else
    # 既存の共有スクリプトを無変更で呼ぶ (arm64 ネイティブビルド)
    bash "${REPO_ROOT}/scripts/build-codex-image.sh"
fi

# --- 7. shell rc に環境変数と codex-shell エイリアスを追加 -----------------
echo ""
echo "==> 7. シェル設定 (~/.zshrc / ~/.bash_profile)"
MARKER_BEGIN="# >>> codex-training >>>"
MARKER_END="# <<< codex-training <<<"
RUN_CODEX="${SCRIPT_DIR}/run-codex-mac.sh"
TMP_BLOCK="$(mktemp)"
# heredoc 内: 実行時に確定させたいもの (RUN_CODEX) はそのまま展開、
# シェル起動のたびに評価したいもの (brew shellenv / java_home) は \ でエスケープ。
cat > "${TMP_BLOCK}" <<EOF
${MARKER_BEGIN}
[ -x /opt/homebrew/bin/brew ] && eval "\$(/opt/homebrew/bin/brew shellenv)"
export LANG=ja_JP.UTF-8
export TZ=Asia/Tokyo
export JAVA_HOME="\$(/usr/libexec/java_home -v 21 2>/dev/null)"
[ -n "\${JAVA_HOME}" ] && export PATH="\${JAVA_HOME}/bin:\${PATH}"
alias codex-shell='bash "${RUN_CODEX}"'
${MARKER_END}
EOF

# macOS の既定対話シェルは zsh。必ず ~/.zshrc に書く。
upsert_block "${HOME}/.zshrc" "${MARKER_BEGIN}" "${MARKER_END}" "${TMP_BLOCK}"
echo "  ~/.zshrc を更新しました"
# bash 併用者向け。macOS の bash ログインシェルは ~/.bashrc ではなく ~/.bash_profile を読む。
if [[ -f "${HOME}/.bash_profile" || "${SHELL}" == *bash* ]]; then
    upsert_block "${HOME}/.bash_profile" "${MARKER_BEGIN}" "${MARKER_END}" "${TMP_BLOCK}"
    echo "  ~/.bash_profile を更新しました"
fi
rm -f "${TMP_BLOCK}"

# --- 8. Doctor (quick) ---------------------------------------------------
echo ""
echo "==> 8. 環境チェック (quick)"
bash "${SCRIPT_DIR}/doctor-mac.sh" --quick || true

print_banner " 手順1 が完了しました。" \
             " 次は「2_APIキーとGit設定.command」をダブルクリックしてください。" \
             " （新しいターミナルを開くと codex-shell エイリアスが使えるようになります）"
