# codex-guard-guide 図版

`instructor/codex-guard-guide.md` の Mermaid 図を画像化したもの。`.md` は GitHub 上で Mermaid をネイティブ描画するが、pandoc 変換後の HTML 等 Mermaid 非対応ビューア向けに PNG を併置している。

| ファイル | 対応する図 |
|---|---|
| `01-defense-in-depth.png` | §1-4 多層防御の全体像（flowchart） |
| `02-guard-flow.png` | §2-2 guard wrapper の判定フロー（flowchart） |
| `03-startup-sequence.png` | §2-6 起動の流れ（sequenceDiagram） |

`*.mmd` が各図のソース。**Mermaid 図を直したら `.mmd` を更新し、下記コマンドで PNG を再生成すること**（`.md` 本文の Mermaid ブロックも同時に合わせる）。

## 再生成

mermaid-cli（`mmdc`）は本リポジトリに同梱していない。Node.js を用意して取得する。

```bash
# 任意の作業ディレクトリで mermaid-cli を導入（Chromium も自動取得）
npm install @mermaid-js/mermaid-cli

# このフォルダに cd して各図を再生成
mmdc -i 01-defense-in-depth.mmd  -o 01-defense-in-depth.png  -c mermaid-config.json -p puppeteer-config.json -b white -s 3
mmdc -i 02-guard-flow.mmd        -o 02-guard-flow.png        -c mermaid-config.json -p puppeteer-config.json -b white -s 3
mmdc -i 03-startup-sequence.mmd  -o 03-startup-sequence.png  -c mermaid-config.json -p puppeteer-config.json -b white -s 3
```

- `mermaid-config.json` … 日本語フォント（Yu Gothic / Meiryo / Segoe UI Emoji）と図の既定を指定
- `puppeteer-config.json` … `--no-sandbox`（CI / コンテナ環境向け）
- `-b white` … 白背景、`-s 3` … 3倍解像度
