-- Create Bank Application User
-- Run on all databases (catalog and all shards)
-- This user will own the sharded tables

PROMPT ====================================
PROMPT Creating Bank Application User
PROMPT ====================================

WHENEVER SQLERROR EXIT SQL.SQLCODE
WHENEVER OSERROR EXIT FAILURE

-- Drop existing user to allow idempotent runs
DECLARE
    v_user_exists NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_user_exists FROM dba_users WHERE username = 'BANK_APP';
    IF v_user_exists > 0 THEN
        EXECUTE IMMEDIATE 'DROP USER bank_app CASCADE';
    END IF;
END;
/

-- Create bank application user
CREATE USER bank_app IDENTIFIED BY BankAppPass123;

-- Grant necessary privileges
GRANT CONNECT, RESOURCE TO bank_app;
GRANT CREATE SESSION TO bank_app;
GRANT CREATE TABLE TO bank_app;
GRANT CREATE SEQUENCE TO bank_app;
GRANT CREATE VIEW TO bank_app;
GRANT CREATE PROCEDURE TO bank_app;
GRANT CREATE TRIGGER TO bank_app;
GRANT CREATE MATERIALIZED VIEW TO bank_app;
GRANT CREATE DATABASE LINK TO bank_app;  -- Required for catalog to query shards

-- Ensure custom tablespace exists (optional, skip if already created)
DECLARE
    v_exists NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_exists
      FROM dba_tablespaces
     WHERE tablespace_name = 'BANK_DATA';

    IF v_exists = 0 THEN
        EXECUTE IMMEDIATE q'[
            CREATE TABLESPACE bank_data
            DATAFILE 'bank_data01.dbf'
            SIZE 100M AUTOEXTEND ON NEXT 50M MAXSIZE UNLIMITED
        ]';
    END IF;
END;
/

-- Grant for distributed transactions
GRANT EXECUTE ON DBMS_LOCK TO bank_app;

-- Grant dictionary access for monitoring
GRANT SELECT ON v_$session TO bank_app;
GRANT SELECT ON v_$database TO bank_app;

-- Set default tablespace for user (runs whether tablespace newly created or pre-existing)
ALTER USER bank_app DEFAULT TABLESPACE bank_data QUOTA UNLIMITED ON bank_data;

-- Also grant quota on USERS tablespace (for compatibility)
ALTER USER bank_app QUOTA UNLIMITED ON USERS;

SELECT 'Bank application user created successfully' AS status FROM DUAL;

PROMPT ====================================
PROMPT Bank app user: bank_app
PROMPT Password: BankAppPass123
PROMPT ====================================

