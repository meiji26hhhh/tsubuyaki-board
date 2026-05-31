# 完走判定ルーブリック (15 点満点・11 点で合格)

各項目 1 点。受講生が自己採点した上で、講師が受講生の作業ブランチ（`<github-id>`）を見て最終採点する。

## A. 機能要件 (6 点)

| # | 項目 | 採点ガイド |
|---|---|---|
| A1 | `GET /posts` がブラウザで開ける | DB に行があるとリストに出る |
| A2 | フォームから投稿が登録される | 投稿後に一覧に反映される |
| A3 | バリデーションエラーが画面に表示される | 空 body で再表示 + エラー文言 |
| A4 | `GET /posts/{id}` が動く | 404 ハンドリング含む |
| A5 | SHOULD 3 つすべて完了 (S1/S2/S3) | いいね / 検索 / 投稿者拡張 がそれぞれ動作 |
| A6 | COULD 選択枠 1 つ完了 (C1/C2/C3 のいずれか) | タグ / 論理削除 / REST API のいずれかが動作 |

## B. テスト網羅 (5 点)

| # | 項目 | 採点ガイド |
|---|---|---|
| B1 | Repository テスト 1 本以上 | `@DataJpaTest` を使っている |
| B2 | Service テスト 1 本以上 (異常系含む) | Mockito、`assertThatThrownBy` を使う |
| B3 | Controller テスト 1 本以上 | `@WebMvcTest`、`view().name()` と `model().attributeExists()` |
| B4 | 受講生ブランチで `./mvnw -B -Ph2 verify` が緑 | 受講生の `<github-id>` ブランチを `git fetch` → `git switch <github-id>` して基本検証が BUILD SUCCESS |
| B5 | 仕上げ品質ゲートが緑 | `./mvnw -B -Ph2 -Pcoverage-day3 -Pstrict verify` が BUILD SUCCESS。JaCoCo line coverage 80% 以上、Checkstyle / SpotBugs 警告なし |

## C. コミットの質 (3 点)

| # | 項目 | 採点ガイド |
|---|---|---|
| C1 | Conventional Commits に従っている | `feat(post): ...` 形式 |
| C2 | 1 コミット = 1 関心事 | テスト + 実装は同コミットで可、UI 微調整と機能追加は分離 |
| C3 | コミットメッセージと記録が整備されている | コミットが ONBOARDING の「コミット前セルフチェック」観点を押さえ、`docs/prompts-i-used.md` の「Codex に出した主要プロンプト」が空でない |

## D. AI 協働の作法 (1 点)

| # | 項目 | 採点ガイド |
|---|---|---|
| D1 | `docs/prompts-i-used.md` が提出されている | 少なくとも 3 つのプロンプトと「効いた / 効かなかった」のコメントが書かれている |

## 加点 (採点には影響しないが講評で取り上げる)

- COULD を 2 つ以上完了
- `MODE=Oracle` の落とし穴に 2 つ以上自力で気付いた
- Codex の生成コードを「ここはこう直しました」と言語化できる
- 相互レビューで他者のブランチ（Compare ビュー）に有意義なコメントを付けた

## 採点フォーマット (講師用)

```
受講生: <name> (GitHub: <github-id>)
ブランチ: <github-id>
Compare: https://github.com/<org>/tsubuyaki-board/compare/main...<github-id>

A. 機能 [_/6]  A1[ ] A2[ ] A3[ ] A4[ ] A5[ ] A6[ ]
B. テスト [_/5] B1[ ] B2[ ] B3[ ] B4[ ] B5[ ]
C. コミット [_/3] C1[ ] C2[ ] C3[ ]
D. AI 協働 [_/1] D1[ ]
合計: _/15   結果: ✅ 完走 / 🟡 部分達成 / 🔴 要フォロー

講評 (3 行):
1. 良かった点:
2. もう一押し:
3. 次の研修までに身につけたいこと:
```
