-- Create Shard Catalog User
-- Run on catalog database as SYS user
-- This user manages shard metadata

PROMPT ====================================
PROMPT Creating Shard Catalog User
PROMPT ====================================

-- Create shard catalog user
CREATE USER shard_catalog IDENTIFIED BY CatalogPass123;

-- Grant necessary privileges for sharding
GRANT CONNECT, RESOURCE, DBA TO shard_catalog;
GRANT CREATE SESSION TO shard_catalog;
GRANT CREATE DATABASE LINK TO shard_catalog;
GRANT CREATE TABLESPACE TO shard_catalog;
GRANT CREATE USER TO shard_catalog;
GRANT ALTER USER TO shard_catalog;
GRANT CREATE ROLE TO shard_catalog;
GRANT GRANT ANY ROLE TO shard_catalog;
GRANT CREATE PROCEDURE TO shard_catalog;
GRANT CREATE TRIGGER TO shard_catalog;
GRANT CREATE TYPE TO shard_catalog;
GRANT CREATE MATERIALIZED VIEW TO shard_catalog;
GRANT CREATE VIEW TO shard_catalog;
GRANT CREATE TABLE TO shard_catalog;
GRANT CREATE SEQUENCE TO shard_catalog;
GRANT SELECT ANY DICTIONARY TO shard_catalog;

-- Grant sharding-specific privileges (if available)
BEGIN
    EXECUTE IMMEDIATE 'GRANT GDS_CATALOG_SELECT TO shard_catalog';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -1919 THEN RAISE; END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'GRANT GDS_CATALOG_SELECT_ROLE TO shard_catalog';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -1919 THEN RAISE; END IF;
END;
/

SELECT 'Shard catalog user created successfully' AS status FROM DUAL;

PROMPT ====================================
PROMPT Shard catalog user: shard_catalog
PROMPT Password: CatalogPass123
PROMPT ====================================

