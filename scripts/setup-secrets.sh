#!/usr/bin/env bash
# =========================================================================
# 社内つぶやきボード 秘密情報セットアップ (WSL Ubuntu 内で実行)
#
# 受講生がコマンドを覚えなくて済むよう、OPENAI_API_KEY と .env を対話設定する。
# 秘密情報は WSL 内で完結させ、Windows のコマンドラインには一切載せない
# (プロセス一覧からの漏えいを防ぐ)。
#
# 使い方:
#   bash scripts/setup-secrets.sh
# =========================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo ""
echo "==> 1. OPENAI_API_KEY を設定"
echo "  Codex CLI が OpenAI に接続するための API キーを設定します。"
echo "  キーは sk- で始まる文字列です (例: sk-xxxxxxxx...)。"
echo "  ★貼り付けても画面には表示されませんが、ちゃんと入力されています。"
echo ""

KEY=""
ATTEMPT=0
while true; do
    ATTEMPT=$(( ATTEMPT + 1 ))
    read -rsp "  OPENAI_API_KEY を貼り付けて Enter (中止する場合は何も入れずに Enter): " KEY
    echo ""
    if [[ -z "${KEY}" ]]; then
        echo "  入力が空のため中止しました。あとでもう一度このバッチを実行してください。" >&2
        exit 1
    fi
    if [[ "${KEY}" == sk-* ]]; then
        break
    fi
    echo "  ⚠ sk- で始まっていません。もう一度入力してください。" >&2
    if (( ATTEMPT >= 3 )); then
        echo "  ⚠ 形式が正しくないキーですが、このまま設定します（後で ~/.bashrc を直接修正できます）。" >&2
        break
    fi
done

# ~/.bashrc に冪等なマーカーブロックで書き込む (再実行しても重複しない)
MARKER_BEGIN="# >>> codex-training-secrets >>>"
MARKER_END="# <<< codex-training-secrets <<<"
BASHRC="${HOME}/.bashrc"
TMP_BLOCK="$(mktemp)"
cat > "${TMP_BLOCK}" <<EOF
${MARKER_BEGIN}
export OPENAI_API_KEY='${KEY}'
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
# このプロセス以降でも使えるようにエクスポート
export OPENAI_API_KEY="${KEY}"
echo "  ~/.bashrc に OPENAI_API_KEY を保存しました。"

echo ""
echo "==> 2. .env を用意"
ENV_FILE="${REPO_ROOT}/.env"
EXAMPLE_FILE="${REPO_ROOT}/dotenv.example"
if [[ -f "${ENV_FILE}" ]]; then
    echo "  .env は既にあります (上書きしません)。"
elif [[ -f "${EXAMPLE_FILE}" ]]; then
    cp "${EXAMPLE_FILE}" "${ENV_FILE}"
    echo "  dotenv.example から .env を作成しました。"
else
    cat > "${ENV_FILE}" <<'EOF'
# 自動生成された .env (dotenv.example が見つからなかったためデフォルト値で生成)
ORACLE_PWD=Training#2026
ORACLE_APP_PWD=tsubuyaki_pw
SPRING_PROFILES_ACTIVE=local
EOF
    echo "  デフォルト値で .env を作成しました。"
fi

echo ""
echo "==> 秘密情報の設定が完了しました"
echo "次は「環境チェック.bat」をダブルクリックして、設定を確認してください。"
