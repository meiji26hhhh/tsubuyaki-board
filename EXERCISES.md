# EXERCISES — 社内つぶやきボード 機能要件と受入基準

演習 19 時間で実装する機能のリスト（成果まとめ 2 時間は別途）。
**MUST → SHOULD → COULD選択枠 の順で完走する**。
時間目はフェーズ開始から積み上げた相対時間。物理日との対応は education/ONBOARDING.md の表を参照。

## MUST (0-8時間目で必達)

### M1: 投稿一覧 `GET /posts`

> 前提アセット: `Post` entity (`src/main/java/com/example/tsubuyaki/domain/Post.java`) と V1 Flyway マイグレーション (`src/main/resources/db/migration/V1__init.sql`) は既に提供済。M1 ではこの上に Repository / Service / Controller を実装する。

- 新着順 (created_at DESC) で最大 50 件を返す
- ビュー: `posts/list.html`
- 0 件なら「まだ投稿はありません」を表示
- `model.posts` 属性に List<Post> を積む

受入基準:
- [ ] `PostRepository.findTop50ByOrderByCreatedAtDesc()` が定義され DataJpaTest で検証される
- [ ] `PostService.latest()` が Repository を呼んで結果を返す
- [ ] `PostController` が `GET /posts` で `posts/list` ビューを返す
- [ ] WebMvcTest で `model().attributeExists("posts")` を確認

### M2: 投稿作成フォーム `GET /posts/new`

- `posts/form.html` を表示
- フォームバインド用に `postForm` (PostForm) を model に積む

受入基準:
- [ ] フォームが描画される
- [ ] `_csrf` トークンを含む (Spring Security 適用後)

### M3: 投稿登録 `POST /posts`

- バリデーション: author 1..30 文字、body 1..280 文字、空白のみ NG
- 成功: 302 で `/posts` にリダイレクト
- 失敗: 200 で `posts/form` を再表示しエラー表示

受入基準:
- [ ] `PostService.create(author, body)` が `Post` を保存する
- [ ] WebMvcTest で異常系 (空 body) が 200 + エラー文字列で再表示されることを確認
- [ ] 正常系で DB に行が増える (DataJpaTest)

### M4: 投稿詳細 `GET /posts/{id}`

- `posts/detail.html` を表示
- 存在しない id は 404

受入基準:
- [ ] `PostService.findById(id)` が `Optional<Post>` を返す
- [ ] Controller で `Optional.isEmpty()` → 404

### M5: ヘルスチェック（回帰確認）

- `/actuator/health` が UP を返す（0-1h セットアップ確認時に既に通る想定。M4 までの実装で UP が壊れていないことを再確認する位置づけ）

受入基準:
- [ ] `./mvnw -B -Ph2 spring-boot:run` で起動した状態で `curl http://localhost:8080/actuator/health` が 200 を返す
- [ ] M4 完了時点で `{"status":"UP"}` が変わっていないこと（DataSource 等の破壊回帰が無い）

## SHOULD (9.5-13時間目で3つすべて必達)

> 8h-9.5h は「リファクタ＋カバレッジ80%到達」フェーズ（[ONBOARDING.md タイムテーブル](./education/ONBOARDING.md)参照）。SHOULD はその後の 9.5h から開始する。

3 つすべて (S1/S2/S3) を完走対象とする。順序は任意。

### S1: いいね

- `POST /posts/{id}/likes` で いいねトグル
- 同一 `clientHash` (= ハッシュ化された IP + UA、SHA-256 の先頭 8 文字) が再度押したら解除
- 詳細画面でいいね数と Like ボタン表示

受入基準:
- [ ] Flyway V2__likes.sql で `post_likes` テーブルを作る
- [ ] サービス層で「冪等性」をテスト (連続 POST で count が 0 → 1 → 0 と変わる)
- [ ] IP は **生で保存しない**。SHA-256 + アプリ内 salt でハッシュ化

### S2: キーワード検索

- `GET /posts?q=xxx` で本文 LIKE 検索
- 一覧画面を再利用 (検索ボックスを上部に追加)

受入基準:
- [ ] `@Query` の bind 変数を使う (文字列連結禁止)
- [ ] 空文字なら通常の最新 50 件にフォールバック

### S3: 投稿者名フィールド拡張

- 投稿者名を必須にし、フォームに任意のアバター色を選択させる (簡易)

受入基準:
- [ ] `posts` テーブルに `avatar_color` 相当の列を追加する Flyway migration がある
- [ ] `PostForm` で投稿者名 1..30 文字、アバター色は許可リスト内だけを受け付ける
- [ ] 一覧 / 詳細 / フォームで投稿者名とアバター色が表示・保持される
- [ ] Service または Controller テストで不正なアバター色が保存されないことを確認する

## COULD (14.5-17時間目で1つ選択して必達)

C1/C2/C3 から **1 つを選んで完了**。選択ガイドはフェーズ開始時に講師から提示。

### C1: タグ機能

本文中の `#tag` をパースして Tag テーブルに保存、`GET /tags/{name}` で関連投稿一覧。

受入基準:
- [ ] Flyway migration で `tags` と関連テーブルを追加する
- [ ] 投稿作成時に本文中の `#tag` を抽出し、重複タグを 1 つに正規化する
- [ ] `GET /tags/{name}` で対象タグの投稿だけを新着順に表示する
- [ ] Repository / Service のいずれかでタグ抽出と検索のテストがある

### C2: 投稿削除

論理削除 (`deleted_at` カラム)、論理削除済みは一覧で非表示。

受入基準:
- [ ] Flyway migration で `deleted_at` を追加し、既存投稿は未削除として扱う
- [ ] `POST /posts/{id}/delete` で論理削除し、成功時は `/posts` にリダイレクトする
- [ ] 一覧 / 検索 / 詳細で論理削除済み投稿を表示しない
- [ ] Service テストで削除済み投稿が検索結果に出ないことを確認する

### C3: REST API

`GET /api/posts` で JSON 返却、簡易 OpenAPI ドキュメント。

受入基準:
- [ ] `GET /api/posts` が最新 50 件を JSON 配列で返す
- [ ] JSON には `id`, `author`, `body`, `createdAt` を含め、内部 Entity を直接返さない
- [ ] MockMvc テストで status 200、JSON フィールド、件数上限を確認する
- [ ] `docs/api.md` にエンドポイント、レスポンス例、エラー時の扱いを記載する

## 意図的に外す機能

- ログイン / アカウント管理 (Spring Security の OAuth まで入れると 1 日では完走できない)
- 画像添付
- リプライツリー
- リアルタイム更新 (WebSocket / SSE)

これらを「やってみたい」と思った時点で **MUST が完了してから**。

## 完走判定 (15 点ルーブリック、11 点で合格)

詳細は `instructor/rubric.md`。要約:

- 機能要件 6 点 (各 MUST 1 点 + SHOULD 3 つ完了 1 点 + COULD 選択枠 1 つ完了 1 点)
- テスト網羅 5 点 (Repository / Service / Controller / `./mvnw -B -Ph2 verify` 緑 / `./mvnw -B -Ph2 -Pcoverage-day3 -Pstrict verify` 緑)
- コミットの質 3 点 (Conventional Commits / 1 関心事 1 コミット / コミットメッセージとセルフチェックの質)
- AI 協働の作法 1 点 (`docs/prompts-i-used.md` に 3 件以上のプロンプトと「効いた / 効かなかった」コメント)
