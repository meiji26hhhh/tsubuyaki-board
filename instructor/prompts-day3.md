# Codex プロンプト雛形 (フェーズ別)

各フェーズで受講生が Codex に与える指示の雛形。

「セットアップ確認」「投稿一覧」「投稿作成」までは雛形をそのまま配布、
「投稿詳細」以降は **受講生が自分で書く**ようにすると学習効果が高い。

---

## セットアップ確認 (0-1時間目)

(プロンプトは不要。`bash scripts/doctor.sh` と `bash scripts/start-oracle.sh` のみ)

---

## 投稿一覧 (M1) (2-4時間目)

```
タスク: 投稿一覧画面 (GET /posts) を TDD で実装してください。

要件:
  - Post エンティティは id:Long(SEQUENCE), author:String(NOT NULL, 1..30 文字),
    body:String(NOT NULL, 1..280 文字), createdAt:Instant を持つ
    (既に domain/Post.java にあるのでそのまま使う)。
  - PostRepository に findTop50ByOrderByCreatedAtDesc() を追加し、
    DataJpaTest で「createdAt 降順かつ最大 50 件」を検証する失敗テストを書く。
  - PostService.latest() を実装し、Repository を呼んで結果を返す。
  - PostController は GET /posts で posts/list.html をレンダリングし、
    model 属性 "posts" に List<Post> を積む。

順序:
  1. PostRepositoryTest を DataJpaTest で書き、createdAt 降順を検証する失敗テストを作る
  2. テストを通す最小実装を書く (Repository → Service)
  3. PostControllerTest を WebMvcTest で書き、model に "posts" 属性が積まれることを検証する
  4. Controller を実装 (Thymeleaf テンプレは既存のものを使う)
  5. ./mvnw -B -Ph2 test で全テストが緑になることを確認
  6. `feat(post): 投稿一覧 (GET /posts) を追加` でコミット

制約:
  - AGENTS.md と .codex/instructions.md を必ず参照
  - sample/ 配下のテストは削除しない
  - `th:utext` を使わない
```

---

## 投稿作成＋バリデーション (M2/M3) (4.25-6.5時間目)

```
タスク: 投稿登録 (GET/POST /posts) を TDD で追加してください。

要件:
  - PostForm は既存のものを使う (author 1..30 文字、body 1..280 文字、空白のみ NG)
  - POST 成功時は 302 で /posts へリダイレクト
  - POST 失敗時は 200 で posts/form.html を再表示しエラーを出す
  - サービス層 PostService.create(author, body) を追加し、Controller から呼ぶ

順序:
  1. PostControllerTest にバリデーション NG ケース (空 body) のテストを追加 (RED)
  2. ServiceTest で正常系・異常系を追加 (RED)
  3. 実装 (Service → Controller の順)
  4. 手動確認: ./mvnw -Plocal spring-boot:run で起動し、ブラウザで /posts/new
  5. `feat(post): 投稿作成フォームとバリデーションを追加` でコミット

制約:
  - Bean Validation アノテーションを使う。`if (x == null) throw ...` の手書きチェックは禁止
  - フォームには `_csrf` トークンを含める (Spring Security 適用後)
```

---

## 投稿詳細＋ヘルスチェック (M4/M5) (6.5-8時間目)

(受講生が自分で書く。雛形だけ提供)

```
タスク: 投稿詳細 (GET /posts/{id}) を TDD で実装し、投稿一覧／投稿作成をリファクタしてください。

受入基準:
  - <ここに受講生が自分で書く>

順序:
  1. ControllerTest で「存在する id → 200 + posts/detail ビュー」「存在しない id → 404」
  2. ...
```

---

## いいね機能 (S1) (9.5-11.5時間目)

```
タスク: 詳細画面で押せるいいねトグルを実装してください。

要件:
  - POST /posts/{id}/likes は同一 clientHash (= SHA-256(IP + UA + salt) の先頭 8 文字)
    が再度押したら解除 (冪等トグル)
  - PostLike テーブルを Flyway V2 で作成 (Oracle / H2(MODE=Oracle) 両対応 SQL)
  - 詳細画面にいいね数と Like ボタンを表示

TDD:
  1. PostLikeRepositoryTest (clientHash で existsByPostIdAndClientHash)
  2. PostLikeServiceTest (冪等性: 同一 clientHash の連続 POST で count が 0→1→0)
  3. ControllerTest (POST 後 302 で詳細にリダイレクト)
  4. 実装

セキュリティ:
  - IP は生で DB に保存しない
  - salt は @Value("${app.like.salt}") で application-*.yml から取る
  - .codex/prompts/review.md でセルフレビューする
```

---

## 仕上げ＋ブランチ整流化＋プロンプトカタログ作成 (17-19時間目)

```
タスク: ここまでの実装を本番に出せる品質に整えてください。

観点:
  1. エラーハンドラ (@ControllerAdvice) で 404 / 500 を整形
  2. README.md の「使い方」を実装に合わせて更新
  3. JaCoCo HTML レポートを生成し、カバレッジ 80% 以上か確認 + `docs/prompts-i-used.md` に 3 件以上のプロンプトを記入
  4. .codex/prompts/review.md で diff 全体を XSS / SQLi / ハードコード観点でセルフレビュー
  5. 自分のブランチへ push し、ONBOARDING の「コミット前セルフチェック」観点
     （実装した受入基準 / テスト結果 / 使ったプロンプト / ハマった点 / 次やるなら）を自己点検する

制約:
  - 新機能の追加は禁止 (品質向上だけ)
  - スコープ外のファイルは触らない
```

---

## 相互レビュー (19-20時間目)

(プロンプトは不要。受講生が Compare ビュー（`compare/main...<github-id>`）を画面共有して、口頭で議論)

レビュー観点:
- AGENTS.md のセキュリティ規約を守っているか
- テストの DisplayName が意味のある日本語か
- コミット粒度が適切か
- 「自分で書く部分」と「Codex に任せる部分」のバランス
