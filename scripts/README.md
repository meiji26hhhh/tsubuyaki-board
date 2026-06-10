# scripts — セットアップ用の内部スクリプト

このフォルダは、研修環境のキッティング・診断（Doctor）・コンテナ起動ラッパなどの
**内部実装スクリプト**を置く場所です。普段はここを直接開く必要はありません。

> ⚠️ **受講生のみなさんへ**
>
> このフォルダの中身（`.ps1` / `.sh`）を**ダブルクリックしたり直接実行したりしないでください**。
>
> セットアップや環境チェックは、必ずリポジトリ直下の
> **「かんたんセットアップ」フォルダにあるバッチ（`.bat`）をダブルクリック**して行います。
> 中で何が動くかを覚える必要はありません。バッチが自動でこのフォルダのスクリプトを呼び出します。

## バッチ → 内部スクリプトの対応

「かんたんセットアップ」フォルダの各バッチは、裏でこのフォルダのスクリプトを実行します。

| かんたんセットアップ のバッチ | 裏で実行されるスクリプト |
|---|---|
| `セットアップ1_Windows準備.bat` | `scripts/setup.ps1` |
| `セットアップ2_Ubuntu準備.bat` | `scripts/setup-wsl.sh` |
| `セットアップ3_APIキー設定.bat` | `scripts/setup-secrets.sh` |
| `環境チェック.bat` | `scripts/doctor.sh --quick` |
| `Oracle起動.bat` | `scripts/start-oracle.sh` |
| `Oracle停止.bat` | `scripts/stop-oracle.sh` |
| `Oracle削除.bat` | `scripts/stop-oracle.sh --purge` |
| `研修終了_環境削除.bat` | （このフォルダのスクリプトは使わず `wsl --unregister Ubuntu-22.04` を実行） |

## 講師・開発者向け

上表以外のスクリプトの役割は次のとおりです。

- `scripts/doctor.ps1` — Windows 側（Pleiades / WSL / Podman Desktop / Git / `C:\workspace`）の診断。WSL 内部の検査は `scripts/doctor.sh` が担当。
- `scripts/build-codex-image.sh` — Codex devbox コンテナイメージ（`codex-devbox:latest`）のビルド。`setup-wsl.sh` から自動で呼ばれる。
- `scripts/run-codex.sh` — `codex-shell` エイリアスの実体。研修ハーネス（`.env` マスク・規範ファイル読み取り専用化など）を組み立ててコンテナを起動する。

手動で実行する場合の手順は、以下を参照してください。

- 受講生向け: `education/student-setup-guide.md`
- 講師向け: `instructor/instructor-setup-guide.md`
