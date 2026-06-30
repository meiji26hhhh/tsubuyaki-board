#!/usr/bin/env bash
# =========================================================================
# 社内つぶやきボード 秘密情報セットアップ (WSL Ubuntu 内で実行)
#
# 受講生がコマンドを覚えなくて済むよう、OPENAI_API_KEY・.env・Git のユーザー
# 情報 (user.name / user.email) を対話設定する。
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

# 既に保存済みのキーがあれば空 Enter で維持できるようにする (再実行時に再入力不要)
# ~/.bashrc 不在時に sed が非ゼロ終了しても set -e で中断しないよう || true で握る
EXISTING_KEY="$(sed -n "s/^export OPENAI_API_KEY='\(.*\)'\$/\1/p" "${HOME}/.bashrc" 2>/dev/null | tail -n1 || true)"

KEY=""
ATTEMPT=0
while true; do
    ATTEMPT=$(( ATTEMPT + 1 ))
    if [[ -n "${EXISTING_KEY}" ]]; then
        read -rp "  OPENAI_API_KEY を貼り付けて Enter (設定済みのため、空 Enter でいまのキーを維持): " KEY
    else
        read -rp "  OPENAI_API_KEY を貼り付けて Enter (中止する場合は何も入れずに Enter): " KEY
    fi
    echo ""
    if [[ -z "${KEY}" ]]; then
        if [[ -n "${EXISTING_KEY}" ]]; then
            KEY="${EXISTING_KEY}"
            echo "  設定済みの OPENAI_API_KEY を維持します。"
            break
        fi
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
if grep -qF "${MARKER_BEGIN}" "${BASHRC}" 2>/dev/null \
    && grep -qF "${MARKER_END}" "${BASHRC}" 2>/dev/null; then
    awk -v begin="${MARKER_BEGIN}" -v end="${MARKER_END}" -v block_file="${TMP_BLOCK}" '
        BEGIN { in_block = 0 }
        $0 ~ begin { in_block = 1
                     while ((getline line < block_file) > 0) print line
                     close(block_file); next }
        $0 ~ end   { in_block = 0; next }
        in_block == 0 { print }
    ' "${BASHRC}" > "${BASHRC}.tmp" && mv "${BASHRC}.tmp" "${BASHRC}"
elif grep -qF "${MARKER_BEGIN}" "${BASHRC}" 2>/dev/null; then
    # END マーカーだけ消えた壊れブロック: 上の awk だと BEGIN 以降の全行が
    # 消えてしまうため、BEGIN 行のみ除去して新ブロックを末尾に追記する。
    # (残骸の export 行は、あとに追記される新ブロックの export が後勝ちで上書きする)
    grep -vF "${MARKER_BEGIN}" "${BASHRC}" > "${BASHRC}.tmp" && mv "${BASHRC}.tmp" "${BASHRC}"
    cat "${TMP_BLOCK}" >> "${BASHRC}"
else
    cat "${TMP_BLOCK}" >> "${BASHRC}"
fi
rm -f "${TMP_BLOCK}"
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
EOF
    echo "  デフォルト値で .env を作成しました。"
fi

echo ""
echo "==> 3. Git のユーザー情報を設定"
echo "  コミットの作者として記録される名前とメールアドレスを設定します。"
echo "  (環境チェックの Git 項目で確認される設定です)"
echo ""

CURRENT_GIT_NAME="$(git config --global user.name 2>/dev/null || true)"
GIT_NAME=""
while true; do
    if [[ -n "${CURRENT_GIT_NAME}" ]]; then
        read -rp "  ユーザー名 [GitHub ユーザ名を推奨。空 Enter で現在の '${CURRENT_GIT_NAME}' を維持]: " GIT_NAME
        [[ -z "${GIT_NAME}" ]] && GIT_NAME="${CURRENT_GIT_NAME}"
    else
        read -rp "  ユーザー名 (GitHub ユーザ名を推奨): " GIT_NAME
    fi
    [[ -n "${GIT_NAME}" ]] && break
    echo "  ⚠ ユーザー名が空です。もう一度入力してください。" >&2
done

CURRENT_GIT_EMAIL="$(git config --global user.email 2>/dev/null || true)"
GIT_EMAIL=""
ATTEMPT=0
while true; do
    ATTEMPT=$(( ATTEMPT + 1 ))
    if [[ -n "${CURRENT_GIT_EMAIL}" ]]; then
        read -rp "  メールアドレス [GitHub 登録のものを推奨。空 Enter で現在の '${CURRENT_GIT_EMAIL}' を維持]: " GIT_EMAIL
        [[ -z "${GIT_EMAIL}" ]] && GIT_EMAIL="${CURRENT_GIT_EMAIL}"
    else
        read -rp "  メールアドレス (GitHub に登録したものを推奨): " GIT_EMAIL
    fi
    if [[ -z "${GIT_EMAIL}" ]]; then
        echo "  ⚠ メールアドレスが空です。もう一度入力してください。" >&2
        continue
    fi
    if [[ "${GIT_EMAIL}" == *@* ]]; then
        break
    fi
    echo "  ⚠ @ が含まれていません。もう一度入力してください。" >&2
    if (( ATTEMPT >= 3 )); then
        echo "  ⚠ 形式が正しくないようですが、このまま設定します（あとで git config --global user.email で修正できます）。" >&2
        break
    fi
done

git config --global user.name "${GIT_NAME}"
git config --global user.email "${GIT_EMAIL}"
echo "  git config --global に user.name / user.email を設定しました。"

echo ""
echo "==> 秘密情報と Git の設定が完了しました"
echo "次は「環境チェック.bat」をダブルクリックして、設定を確認してください。"
