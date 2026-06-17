#!/usr/bin/env bash
# =========================================================================
# EasySetupForMacOS 共通ヘルパー (bash 3.2 互換 / source 専用)
#
# 受講生向け *.command は ASCII の薄いブートストラップにして、日本語 UI と
# ロジックはこの bin/*.sh 側に置く (Windows 版の .bat -> .ps1 と同じ構造)。
# かんたんセットアップ/bin/_common.ps1 の bash 移植。WSL 固有処理 (wslpath /
# Invoke-WslLogged / Distro) は macOS では不要なので持たない。
#
# 注意: このファイルは複数のスクリプトから source される。再 source しても
# 壊れないよう、変数は readonly にせず、副作用 (set -e 等) も持たせない。
# =========================================================================

# --- 色 (ANSI-C quoting。heredoc に出しても化けないよう実エスケープを格納) ---
C_RED=$'\033[0;31m'
C_GREEN=$'\033[0;32m'
C_YELLOW=$'\033[1;33m'
C_CYAN=$'\033[0;36m'
C_RESET=$'\033[0m'

# --- パス解決 ------------------------------------------------------------
# この _common.sh が置かれている bin ディレクトリ
_common_bin_dir() {
    cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
}

# EasySetupForMacOS ディレクトリ (bin の 1 つ上)
easyset_dir() {
    cd "$(_common_bin_dir)/.." && pwd
}

# リポジトリルート (bin の 2 つ上 = EasySetupForMacOS の 1 つ上)
repo_root() {
    cd "$(_common_bin_dir)/../.." && pwd
}

# --- Homebrew (Apple Silicon = /opt/homebrew) を PATH に載せる -------------
# Finder ダブルクリック実行では PATH が最小で brew が見えないことがあるため、
# 明示的に shellenv を eval する。Intel/旧環境の /usr/local もフォールバック。
ensure_brew_path() {
    if command -v brew >/dev/null 2>&1; then
        return 0
    fi
    if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
}

# --- 表示ヘルパー --------------------------------------------------------
# 罫線で囲んだ案内。色は環境変数 BANNER_COLOR で上書き可 (既定 cyan)。
print_banner() {
    local color="${BANNER_COLOR:-$C_CYAN}"
    local bar
    bar="$(printf '=%.0s' $(seq 1 60))"
    echo ""
    printf '%s%s%s\n' "${color}" "${bar}" "${C_RESET}"
    local line
    for line in "$@"; do
        printf '%s\n' "${line}"
    done
    printf '%s%s%s\n' "${color}" "${bar}" "${C_RESET}"
    echo ""
}

# 赤い失敗バナー。BANNER_COLOR を local で設定して print_banner を呼ぶ。
# `BANNER_COLOR=x print_banner` という前置代入は bash では関数 return 後も
# 残留するため、local 経由 (動的スコープで print_banner からも見える) にして
# 後続の通常バナーが赤くならないようにする。
print_error() {
    local BANNER_COLOR="${C_RED}"
    print_banner "$@"
}

# pause 相当。.command 経由でウィンドウが即閉じしないよう表示を読ませる。
wait_enter() {
    echo ""
    # 非対話 (パイプ等) では read が即 EOF になるので || true で握る
    read -r -p "Enter キーを押すと閉じます " _ || true
}

# EasySetupForMacOS/logs にタイムスタンプ付きログパスを生成して echo する。
new_log_path() {
    local prefix="$1"
    local log_dir
    log_dir="$(easyset_dir)/logs"
    mkdir -p "${log_dir}"
    printf '%s/%s_%s.log' "${log_dir}" "${prefix}" "$(date +%Y%m%d_%H%M%S)"
}

# --- shell rc のマーカーブロック操作 (setup-wsl.sh の awk 方式を流用) -------
# rc に冪等マーカーブロックを upsert する。
#   upsert_block <rc_path> <begin_marker> <end_marker> <block_file>
# - 正常ブロック (begin/end 両方あり) は中身を block_file で置換
# - end だけ消えた壊れブロックは begin 行を除去して末尾に追記
# - 無ければ末尾に追記
upsert_block() {
    local rc="$1" begin="$2" end="$3" block_file="$4"
    touch "${rc}"
    if grep -qF "${begin}" "${rc}" 2>/dev/null && grep -qF "${end}" "${rc}" 2>/dev/null; then
        awk -v begin="${begin}" -v end="${end}" -v block_file="${block_file}" '
            BEGIN { in_block = 0 }
            $0 ~ begin { in_block = 1
                         while ((getline line < block_file) > 0) print line
                         close(block_file); next }
            $0 ~ end   { in_block = 0; next }
            in_block == 0 { print }
        ' "${rc}" > "${rc}.tmp" && mv "${rc}.tmp" "${rc}"
    elif grep -qF "${begin}" "${rc}" 2>/dev/null; then
        grep -vF "${begin}" "${rc}" > "${rc}.tmp" && mv "${rc}.tmp" "${rc}"
        cat "${block_file}" >> "${rc}"
    else
        cat "${block_file}" >> "${rc}"
    fi
}

# rc からマーカーブロック (begin〜end) を丸ごと除去する。
#   remove_block <rc_path> <begin_marker> <end_marker>
remove_block() {
    local rc="$1" begin="$2" end="$3"
    [[ -f "${rc}" ]] || return 0
    awk -v begin="${begin}" -v end="${end}" '
        $0 ~ begin { in_block = 1; next }
        $0 ~ end   { in_block = 0; next }
        in_block != 1 { print }
    ' "${rc}" > "${rc}.tmp" && mv "${rc}.tmp" "${rc}"
}
