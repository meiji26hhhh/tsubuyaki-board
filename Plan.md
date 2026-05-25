# tsubuyaki-board 教材・Codexハーネス安全化 実装ハンドオフ

## Objective

Codex 初学者向け教材として、ハーネスの実効性、秘密情報保護、教材内の安全ルール一貫性、要件と品質ゲートの明確さを改善する。

## Scope

- Codex devbox ハーネス: `scripts/run-codex.sh`, `scripts/doctor.sh`, `containers/codex-devbox/bin/*`
- Codex 設定と教材: `.codex/config.toml`, `README.md`, `dotenv.example`, `education/**`, `instructor/**`, `EXERCISES.md`, `AGENTS.md`
- タスク管理: `tasks/todo.md`, `tasks/lessons.md`

## Constraints

- 変更は教材・ハーネスに限定し、アプリ機能実装には踏み込まない。
- `.env` や個人の `~/.codex` に秘密情報を残す導線を減らす。
- 研修内で禁止している破壊操作を、通常手順や講師 FAQ で例外的に推奨しない。
- 完全なネットワーク egress 制限は今回の範囲外。物理制限がないことを明記する。

## Implementation Steps

1. `git-guard.sh` のサブコマンド検出を、値を消費する Git グローバルオプション対応に修正する。
2. `rm-guard.sh` で再帰削除を `target/`, `build/`, `node_modules/`, `.cache/`, `tmp/` などの生成物に限定し、主要ディレクトリを拒否する。
3. `run-codex.sh` に workspace root marker 検証と広範囲マウント拒否を追加し、secret 名パターンを `/dev/null` マスク対象にする。
4. `doctor.sh` に `harness` カテゴリを追加し、guard reject、ro mount、secret mask を確認する。
5. `dotenv.example` と受講生ガイドから `.env` への API キー導線を削除し、キー断片表示を「設定済み」表示へ寄せる。
6. `.codex/config.toml` と起動スクリプトで、受講生ホームの `~/.codex` 共有を既定から外し、研修専用 CODEX_HOME を使う。
7. 教材内の `reset --hard`, `clean -fd`, `restore .`, `force-with-lease` の通常推奨を削除または講師立会いの最後の手段へ隔離する。
8. `EXERCISES.md` に S3 / C1 / C2 / C3 の受入基準を追加し、品質ゲート表現を `-Pcoverage-day3 -Pstrict` に揃える。
9. 検証結果を `tasks/todo.md` と `tasks/lessons.md` に記録する。

## Test And Verification Strategy

- Shell: `bash -n scripts/run-codex.sh scripts/doctor.sh containers/codex-devbox/bin/*.sh`
- Static scan: `rg -n "OPENAI_API_KEY|cat \\.env|git reset --hard|git clean -fd|force-with-lease|git restore \\." README.md AGENTS.md education instructor .codex scripts containers`
- Harness: `bash scripts/doctor.sh --only harness` in WSL/devbox-capable environment
- Java: `./mvnw -B -Ph2 verify` and `./mvnw -B -Ph2 -Pcoverage-day3 -Pstrict verify` in WSL Java 21 environment

## Open Questions Or Assumptions

- Current execution environment may not have WSL initialized or Java 21 on Windows, so Maven verification may need to be recorded as blocked locally.
- Podman-level network allowlist is not implemented here; future work can add proxy/firewall or explicit offline mode.

## Handoff Notes For ClaudeCode

ClaudeCode should continue from this `Plan.md` and update `tasks/todo.md` as it completes each item. Do not reintroduce API key examples into `.env`, and do not document force push or whole-tree destructive restore as normal recovery paths.
