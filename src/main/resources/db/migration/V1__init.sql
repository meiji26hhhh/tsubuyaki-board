-- =========================================================================
-- 社内つぶやきボード V1: POSTS テーブル
-- Oracle XE 21c および H2(MODE=Oracle) の双方で動く DDL
-- =========================================================================

CREATE SEQUENCE posts_seq START WITH 1 INCREMENT BY 1 NOCACHE;

CREATE TABLE posts (
    id          NUMBER(19)         NOT NULL,
    author      VARCHAR2(30 CHAR)  NOT NULL,
    body        VARCHAR2(280 CHAR) NOT NULL,
    created_at  TIMESTAMP(6)       NOT NULL,
    CONSTRAINT posts_pk PRIMARY KEY (id)
);

CREATE INDEX posts_created_at_idx ON posts (created_at);
