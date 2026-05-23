-- =========================================================================
-- Oracle XE 起動時の初期化スクリプト
-- gvenzl/oracle-xe では /container-entrypoint-initdb.d 配下の *.sql が
-- APP_USER (butsubutsu) の PDB (XEPDB1) に対して自動実行される。
--
-- このファイルでは追加権限の付与と動作確認用 PROMPT のみを行う。
-- 業務テーブルの DDL は Flyway (src/main/resources/db/migration/V1__init.sql)
-- に任せる。
-- =========================================================================

PROMPT === butsubutsu schema init: granting extra privileges ===

-- Flyway のスキーマヒストリ表作成と、講師のデモ用シーケンス作成に必要
GRANT CREATE SEQUENCE TO butsubutsu;
GRANT CREATE PROCEDURE TO butsubutsu;
GRANT CREATE VIEW TO butsubutsu;
GRANT CREATE SYNONYM TO butsubutsu;

-- 日付フォーマットを ISO 形式に揃える (Flyway / アプリの両方に効かせる場合は
-- 各セッションで ALTER SESSION するか、JDBC 側で oracle.jdbc.timezoneAsRegion=false 等を設定)
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';

PROMPT === butsubutsu schema init: done ===
