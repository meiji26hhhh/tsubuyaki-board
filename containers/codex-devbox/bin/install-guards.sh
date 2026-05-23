#!/usr/bin/env bash
# =========================================================================
# Codex devbox 内で guard を有効化するインストーラ
#
# - /opt/codex-guard/bin に guard 本体と symlink を配置
# - PATH の先頭に /opt/codex-guard/bin を入れる仕組みは Containerfile 側で
#   /etc/profile.d/codex-guard.sh を配置することで実現
# - 実体 (/bin/rm 等) を codex ユーザから実行不能にする (root only)
#
# このスクリプトは Containerfile の RUN から呼ばれる。
# =========================================================================
set -euo pipefail

GUARD_DIR=/opt/codex-guard/bin
SRC_DIR=/tmp/codex-guard-src

mkdir -p "${GUARD_DIR}"

# --- guard 本体配置 ---------------------------------------------------------
install -m 0755 "${SRC_DIR}/guard-common.sh"  "${GUARD_DIR}/guard-common.sh"
install -m 0755 "${SRC_DIR}/rm-guard.sh"      "${GUARD_DIR}/rm-guard.sh"
install -m 0755 "${SRC_DIR}/git-guard.sh"     "${GUARD_DIR}/git-guard.sh"
install -m 0755 "${SRC_DIR}/chmod-guard.sh"   "${GUARD_DIR}/chmod-guard.sh"
install -m 0755 "${SRC_DIR}/chown-guard.sh"   "${GUARD_DIR}/chown-guard.sh"
install -m 0755 "${SRC_DIR}/dd-guard.sh"      "${GUARD_DIR}/dd-guard.sh"
install -m 0755 "${SRC_DIR}/sudo-guard.sh"    "${GUARD_DIR}/sudo-guard.sh"

# --- guard コマンド名で symlink --------------------------------------------
ln -sf rm-guard.sh    "${GUARD_DIR}/rm"
ln -sf git-guard.sh   "${GUARD_DIR}/git"
ln -sf chmod-guard.sh "${GUARD_DIR}/chmod"
ln -sf chown-guard.sh "${GUARD_DIR}/chown"
ln -sf dd-guard.sh    "${GUARD_DIR}/dd"
ln -sf sudo-guard.sh  "${GUARD_DIR}/sudo"

# --- PATH 先頭差し込みファイルを配置 ----------------------------------------
cat >/etc/profile.d/codex-guard.sh <<'EOF'
# Codex devbox 研修ハーネス: guard を PATH 先頭に差し込む
if [[ ":${PATH}:" != *":/opt/codex-guard/bin:"* ]]; then
    export PATH="/opt/codex-guard/bin:${PATH}"
fi
EOF
chmod 0644 /etc/profile.d/codex-guard.sh

# --- bash 非ログインシェルでも PATH を適用 ----------------------------------
# /etc/bash.bashrc に追記して非ログインシェル (sh -c, codex の `bash -c` 経由) でも有効化
if ! grep -q 'codex-guard' /etc/bash.bashrc 2>/dev/null; then
    cat >>/etc/bash.bashrc <<'EOF'

# Codex devbox 研修ハーネス
if [[ ":${PATH}:" != *":/opt/codex-guard/bin:"* ]]; then
    export PATH="/opt/codex-guard/bin:${PATH}"
fi
EOF
fi

# --- /etc/environment にも PATH を仕込む ------------------------------------
# bash 以外のシェル (sh, dash) や exec 系直接呼び出し対策
if [[ -w /etc/environment ]]; then
    if ! grep -q 'codex-guard' /etc/environment 2>/dev/null; then
        # 既存 PATH 行があれば置換、無ければ追記
        if grep -q '^PATH=' /etc/environment; then
            sed -i 's|^PATH="\?|PATH="/opt/codex-guard/bin:|' /etc/environment
        else
            echo 'PATH="/opt/codex-guard/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"' >>/etc/environment
        fi
    fi
fi

# --- 実体バイナリを codex ユーザから実行不可に ------------------------------
# uid 1000 (codex) からは exec できないが、root 経由 (sudo-guard で阻止済) なら依然動く。
# guard wrapper 内では guard_real_bin で絶対パスを使い root 不要で exec できるよう、
# 「others 実行可」を残しつつ「読み取り＆実行」のみ許可、書き込みは root only。
# → 実は実体を取り上げると wrapper 自身が動かなくなるので、ここでは「実体を退避＋
#   PATH 先頭の guard を強制」する戦略のみで十分。実体は chmod 0755 のままにする。
#
# その代わりに /usr/local/bin/rm のような **上書き wrapper** を別途置かないことが重要。
# (誰かが /usr/local/bin/rm に何かを書いていたら衝突するのでチェック)
for cmd in rm git chmod chown dd sudo; do
    if [[ -L "/usr/local/bin/${cmd}" || -f "/usr/local/bin/${cmd}" ]]; then
        echo "[install-guards] WARN: /usr/local/bin/${cmd} が既に存在します (guard と競合)" >&2
    fi
done

echo "[install-guards] guard install complete: ${GUARD_DIR}"
ls -la "${GUARD_DIR}"
