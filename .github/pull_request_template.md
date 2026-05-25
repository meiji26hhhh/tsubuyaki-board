## 実装した MUST / SHOULD

- [ ] M1: 投稿一覧 `GET /posts`
- [ ] M2: 投稿フォーム `GET /posts/new`
- [ ] M3: 投稿登録 `POST /posts`
- [ ] M4: 投稿詳細 `GET /posts/{id}`
- [ ] M5: ヘルスチェック `GET /actuator/health`
- [ ] S1: いいね
- [ ] S2: キーワード検索
- [ ] S3: 投稿者名フィールド

## テスト結果

- ローカル `./mvnw -B -Ph2 verify` … <!-- 緑 / 赤 -->
- カバレッジ (JaCoCo) … <!-- XX% -->

ログまたはスクショを貼ってください (target/site/jacoco/index.html の数値で OK)。

## Codex に出した主要プロンプト (最大 3 つ)

```
1.
```

```
2.
```

```
3.
```

## ハマったポイントと対処

<!--
例: H2 で `SYSDATE` が動かなかった → `Instant.now()` を使うように修正
例: Thymeleaf で `th:utext` を書いていた → `th:text` に修正
-->

## 次やるなら何

<!--
このスコープを超えて、もう 1 日あれば取り組みたいことを 1〜3 行で。
-->
