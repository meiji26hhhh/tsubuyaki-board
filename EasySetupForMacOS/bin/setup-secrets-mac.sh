#!/usr/bin/env bash
# =========================================================================
# 社内つぶやきボード 秘密情報セットアップ (macOS)
#
# 受講生がコマンドを覚えなくて済むよう、OPENAI_API_KEY と Git のユーザー情報
# (user.name / user.email) を対話設定する。
#
# OPENAI_API_KEY は 2 か所に保存する:
#   1. ~/.zshrc (+ ~/.bash_profile): 対話シェルで codex-shell エイリアスを
#      使うときに環境変数として読まれる。
#   2. ~/.codex-training/openai_key (chmod 600): *.command をダブルクリックした
#      非対話経路では ~/.zshrc が読まれないため、run-codex-mac.sh /
#      doctor-mac.sh がこのファイルからフォールバックで読む。
#
# 注: DB は H2 のみのため .env は作らない (Spring Boot は .env を読まず、
#     Oracle も使わない)。
#
# 使い方:
#   bash bin/setup-secrets-mac.sh
# =========================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_common.sh
. "${SCRIPT_DIR}/_common.sh"

KEY_FILE="${HOME}/.codex-training/openai_key"

echo ""
echo "==> 1. OPENAI_API_KEY を設定"
echo "  Codex CLI が OpenAI に接続するための API キーを設定します。"
echo "  キーは sk- で始まる文字列です (例: sk-xxxxxxxx...)。"
echo "  ★貼り付けても画面には表示されませんが、ちゃんと入力されています。"
echo ""

# 既に保存済みのキーがあれば空 Enter で維持できるようにする
EXISTING_KEY=""
if [[ -r "${KEY_FILE}" ]]; then
    EXISTING_KEY="$(cat "${KEY_FILE}" 2>/dev/null || true)"
fi

KEY=""
ATTEMPT=0
while true; do
    ATTEMPT=$(( ATTEMPT + 1 ))
    if [[ -n "${EXISTING_KEY}" ]]; then
        read -rsp "  OPENAI_API_KEY を貼り付けて Enter (設定済みのため、空 Enter でいまのキーを維持): " KEY
    else
        read -rsp "  OPENAI_API_KEY を貼り付けて Enter (中止する場合は何も入れずに Enter): " KEY
    fi
    echo ""
    if [[ -z "${KEY}" ]]; then
        if [[ -n "${EXISTING_KEY}" ]]; then
            KEY="${EXISTING_KEY}"
            echo "  設定済みの OPENAI_API_KEY を維持します。"
            break
        fi
        echo "  入力が空のため中止しました。あとでもう一度実行してください。" >&2
        exit 1
    fi
    if [[ "${KEY}" == sk-* ]]; then
        break
    fi
    echo "  ⚠ sk- で始まっていません。もう一度入力してください。" >&2
    if (( ATTEMPT >= 3 )); then
        echo "  ⚠ 形式が正しくないキーですが、このまま設定します（後で修正できます）。" >&2
        break
    fi
done

# 保存先 1: 専用キーファイル (.command 非対話経路のフォールバック)
mkdir -p "$(dirname "${KEY_FILE}")"
printf '%s\n' "${KEY}" > "${KEY_FILE}"
chmod 600 "${KEY_FILE}"
echo "  ${KEY_FILE} に保存しました (パーミッション 600)。"

# 保存先 2: shell rc にマーカーブロックで export (対話シェル用)
MARKER_BEGIN="# >>> codex-training-secrets >>>"
MARKER_END="# <<< codex-training-secrets <<<"
# single-quote 囲みで書き出すため、KEY 内の ' を '\'' にエスケープする
# (貼り付けミスで ' が混入しても ~/.zshrc / ~/.bash_profile が壊れないように)
KEY_ESCAPED="${KEY//\'/\'\\\'\'}"
TMP_BLOCK="$(mktemp)"
cat > "${TMP_BLOCK}" <<EOF
${MARKER_BEGIN}
export OPENAI_API_KEY='${KEY_ESCAPED}'
${MARKER_END}
EOF
upsert_block "${HOME}/.zshrc" "${MARKER_BEGIN}" "${MARKER_END}" "${TMP_BLOCK}"
echo "  ~/.zshrc に OPENAI_API_KEY を保存しました。"
if [[ -f "${HOME}/.bash_profile" || "${SHELL}" == *bash* ]]; then
    upsert_block "${HOME}/.bash_profile" "${MARKER_BEGIN}" "${MARKER_END}" "${TMP_BLOCK}"
    echo "  ~/.bash_profile にも保存しました。"
fi
rm -f "${TMP_BLOCK}"

echo ""
echo "==> 2. Git のユーザー情報を設定"
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
        echo "  ⚠ 形式が正しくないようですが、このまま設定します。" >&2
        break
    fi
done

git config --global user.name "${GIT_NAME}"
git config --global user.email "${GIT_EMAIL}"
echo "  git config --global に user.name / user.email を設定しました。"

echo ""
echo "==> 秘密情報と Git の設定が完了しました"
echo "次は「3_環境チェック.command」をダブルクリックして、設定を確認してください。"
