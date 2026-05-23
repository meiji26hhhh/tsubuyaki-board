# JPA Entity + Repository + DataJpaTest を生成

ドメイン名・カラム定義を与えたら、JPA Entity と Repository、@DataJpaTest、
Flyway マイグレーションを一式生成するプロンプト。

---

タスク: 以下の Entity 定義に基づいて JPA レイヤを生成してください。

エンティティ名: <<EntityName>>

カラム定義 (1 行 1 カラム):
- <<カラム1>> : <<型1>> : <<制約1>>
- <<カラム2>> : <<型2>> : <<制約2>>
- ...

生成するもの:
1. `@Entity` クラス (パッケージ: `com.example.butsubutsu.domain`)
2. `JpaRepository<EntityName, Long>` インタフェース
3. `@DataJpaTest` のテストクラス (正常系 1 本以上 + 異常系 1 本以上)
4. Flyway マイグレーション `V<n>__<entity>.sql` (Oracle / H2(MODE=Oracle) 両方で動く SQL)

制約:
- ID は `@GeneratedValue(strategy = GenerationType.SEQUENCE)` + `@SequenceGenerator(allocationSize = 1)` で統一。
- 日時カラムは `java.time.Instant` を使う。`java.util.Date` は禁止。
- 文字列カラムには `@Column(length = ..., nullable = ...)` を明示。
- DDL は `NUMBER(19)`, `VARCHAR2(... CHAR)`, `TIMESTAMP(6)` を使い、H2(MODE=Oracle) でも動くように書く。
- リポジトリのメソッド名は派生クエリ (`findTop50ByOrderByCreatedAtDesc`) を優先し、`@Query` を使うときは bind 変数を必ず使う (`?1` ではなく `:name` 推奨)。
