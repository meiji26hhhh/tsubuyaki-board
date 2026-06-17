#!/usr/bin/env bash
# =========================================================================
# 社内つぶやきボード 研修環境の後片付け (macOS)
#
# Windows 版の「研修終了_環境削除.bat」(wsl --unregister) に相当。macOS には
# WSL ディストロが無いので、代わりに以下を撤去する:
#   - podman machine (podman-machine-default)
#   - codex-devbox:latest イメージ
#   - ~/.zshrc / ~/.bash_profile の codex-training マーカーブロック
#   - ~/.codex-training (研修用 CODEX_HOME と API キーファイル)
#
# Homebrew 本体・JDK・Maven・git は他で使う可能性があるため削除しない (案内のみ)。
#
# 使い方:
#   bash bin/uninstall-mac.sh
# =========================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_common.sh
. "${SCRIPT_DIR}/_common.sh"

ensure_brew_path

print_banner " 研修環境をお片付けします。" \
             " 削除対象: podman machine / codex-devbox イメージ / シェル設定 / 研修用 API キー" \
             " ★ Homebrew 本体・JDK・Maven・git は残します (他で使う可能性があるため)。" \
             " ★ push し忘れた変更が無いか、先に確認してください (元に戻せません)。"

read -r -p "本当に削除する場合は、半角で delete と入力して Enter: " ANSWER
if [[ "${ANSWER}" != "delete" ]]; then
    echo "中止しました。何も削除していません。"
    exit 0
fi

# --- 1. Codex devbox イメージ (machine 稼働中に削除する) ------------------
echo ""
echo "==> 1. codex-devbox イメージを削除"
if command -v podman >/dev/null 2>&1; then
    # イメージ削除には machine が動いている必要があるため、必要なら一時起動
    MACHINE_STATE="$(podman machine inspect podman-machine-default --format '{{.State}}' 2>/dev/null || echo '')"
    if [[ -n "${MACHINE_STATE}" && "${MACHINE_STATE}" != "running" ]]; then
        podman machine start >/dev/null 2>&1 || true
    fi
    podman image rm -f codex-devbox:latest >/dev/null 2>&1 && echo "  削除しました" || echo "  (イメージは存在しませんでした)"
else
    echo "  podman が無いためスキップ"
fi

# --- 2. podman machine -------------------------------------------------
echo ""
echo "==> 2. podman machine を削除"
if command -v podman >/dev/null 2>&1 && podman machine inspect podman-machine-default >/dev/null 2>&1; then
    podman machine stop >/dev/null 2>&1 || true
    podman machine rm -f podman-machine-default >/dev/null 2>&1 && echo "  削除しました" || echo "  削除に失敗 (手動で podman machine rm を試してください)"
else
    echo "  podman machine は存在しませんでした"
fi

# --- 3. シェル設定のマーカーブロックを除去 -------------------------------
echo ""
echo "==> 3. シェル設定 (~/.zshrc / ~/.bash_profile) のマーカーブロックを除去"
for rc in "${HOME}/.zshrc" "${HOME}/.bash_profile"; do
    [[ -f "${rc}" ]] || continue
    remove_block "${rc}" "# >>> codex-training >>>" "# <<< codex-training <<<"
    remove_block "${rc}" "# >>> codex-training-secrets >>>" "# <<< codex-training-secrets <<<"
    echo "  ${rc} を整理しました"
done

# --- 4. 研修用 CODEX_HOME / API キーを削除 ------------------------------
echo ""
echo "==> 4. ~/.codex-training を削除 (研修用 Codex 設定と API キー)"
rm -rf "${HOME}/.codex-training" && echo "  削除しました"

print_banner " お片付けが完了しました。" \
             " 残っているもの: Homebrew / JDK / Maven / git / リポジトリのソース。" \
             " 完全に消したい場合は brew uninstall などを手動で実行してください。" \
             " もう一度使うには「1_Macの準備.command」からやり直してください。"
