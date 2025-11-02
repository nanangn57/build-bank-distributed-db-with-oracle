-- Create Bank Application User
-- Run on all databases (catalog and all shards)
-- This user will own the sharded tables

PROMPT ====================================
PROMPT Creating Bank Application User
PROMPT ====================================

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

-- Grant for distributed transactions
GRANT EXECUTE ON DBMS_LOCK TO bank_app;

-- Grant dictionary access for monitoring
GRANT SELECT ON v_$session TO bank_app;
GRANT SELECT ON v_$database TO bank_app;

-- Create default tablespace
CREATE TABLESPACE bank_data
DATAFILE '/opt/oracle/oradata/FREEPDB1/bank_data01.dbf'
SIZE 100M AUTOEXTEND ON NEXT 50M MAXSIZE UNLIMITED;

-- Set default tablespace for user
ALTER USER bank_app DEFAULT TABLESPACE bank_data QUOTA UNLIMITED ON bank_data;

-- Also grant quota on USERS tablespace (for compatibility)
ALTER USER bank_app QUOTA UNLIMITED ON USERS;

SELECT 'Bank application user created successfully' AS status FROM DUAL;

PROMPT ====================================
PROMPT Bank app user: bank_app
PROMPT Password: BankAppPass123
PROMPT ====================================

