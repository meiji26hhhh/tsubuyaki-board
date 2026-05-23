# Spring MVC Controller スケルトン生成

ユースケースを与えたら、Controller / Service / Repository のスケルトンと
@WebMvcTest による失敗テストを生成するためのプロンプト。

---

タスク: 以下のユースケースに対する Spring MVC のスケルトンを生成してください。

ユースケース: <<ユースケース説明>>

生成するもの:
1. `@WebMvcTest` を用いた Controller テスト 1 本 (最初は失敗する状態)
2. Controller クラス (Bean Validation + リダイレクト / ビュー名のみ実装)
3. Service クラス (まずは throw new UnsupportedOperationException で OK)
4. Repository (必要なメソッドのシグネチャのみ)
5. Thymeleaf テンプレート (必要なら)

制約:
- 入力検証は Bean Validation アノテーションを使う。`if (x == null) throw ...` のような手書きチェックは使わない。
- HTML テンプレートでは必ず `th:text` を使う。`th:utext` は禁止 (XSS 保護)。
- フォームには `_csrf` トークンを含める (Spring Security 適用後)。
- テストには `@DisplayName` を日本語で付ける (例: `投稿一覧_空のとき_空配列をビューに渡す`)。
- パスは `/posts`, `/posts/new`, `/posts/{id}` の REST 風に統一。
