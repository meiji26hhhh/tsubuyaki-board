#!/usr/bin/env bash
# 「Codex を起動」: Codex devbox コンテナに入る補助ランチャ。
# 研修の本番では Ubuntu/ターミナルから `codex-shell` エイリアスで入るのが基本だが、
# ターミナルに不慣れな受講生向けにダブルクリックでも入れるようにしたもの。
# 対話セッションなので exec でプロセスを置き換える (Enter 待ちは不要)。
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
exec bash "${HERE}/bin/run-codex-mac.sh"
