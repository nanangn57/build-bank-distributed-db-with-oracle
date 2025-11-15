-- Create Database Links on Each Shard for Cross-Shard Operations
-- Run as bank_app user on EACH SHARD
-- This allows shards to access each other for cross-shard transactions

PROMPT ====================================
PROMPT Creating Database Links on Shard
PROMPT Run this script on EACH SHARD
PROMPT ====================================

WHENEVER SQLERROR EXIT SQL.SQLCODE
WHENEVER OSERROR EXIT FAILURE

CONNECT bank_app/BankAppPass123@freepdb1

-- Grant CREATE DATABASE LINK privilege (if not already granted)
-- Note: This may need to be run as SYS user first
-- GRANT CREATE DATABASE LINK TO bank_app;

PROMPT Creating database links to other shards...

-- Create database link to Shard 1 (NA region)
BEGIN
    EXECUTE IMMEDIATE 'DROP DATABASE LINK shard1_link';
    DBMS_OUTPUT.PUT_LINE('Dropped existing shard1_link');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -2024 THEN  -- Link does not exist
            NULL;
        ELSE
            RAISE;
        END IF;
END;
/

CREATE DATABASE LINK shard1_link
CONNECT TO bank_app
IDENTIFIED BY BankAppPass123
USING '(DESCRIPTION=
    (ADDRESS=(PROTOCOL=TCP)(HOST=oracle-shard1)(PORT=1521))
    (CONNECT_DATA=(SERVICE_NAME=freepdb1))
)';

-- Create database link to Shard 2 (EU region)
BEGIN
    EXECUTE IMMEDIATE 'DROP DATABASE LINK shard2_link';
    DBMS_OUTPUT.PUT_LINE('Dropped existing shard2_link');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -2024 THEN
            NULL;
        ELSE
            RAISE;
        END IF;
END;
/

CREATE DATABASE LINK shard2_link
CONNECT TO bank_app
IDENTIFIED BY BankAppPass123
USING '(DESCRIPTION=
    (ADDRESS=(PROTOCOL=TCP)(HOST=oracle-shard2)(PORT=1521))
    (CONNECT_DATA=(SERVICE_NAME=freepdb1))
)';

-- Create database link to Shard 3 (APAC region)
BEGIN
    EXECUTE IMMEDIATE 'DROP DATABASE LINK shard3_link';
    DBMS_OUTPUT.PUT_LINE('Dropped existing shard3_link');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -2024 THEN
            NULL;
        ELSE
            RAISE;
        END IF;
END;
/

CREATE DATABASE LINK shard3_link
CONNECT TO bank_app
IDENTIFIED BY BankAppPass123
USING '(DESCRIPTION=
    (ADDRESS=(PROTOCOL=TCP)(HOST=oracle-shard3)(PORT=1521))
    (CONNECT_DATA=(SERVICE_NAME=freepdb1))
)';

COMMIT;

PROMPT ====================================
PROMPT Database links created on this shard!
PROMPT ====================================
PROMPT
PROMPT Links created:
PROMPT   - shard1_link (NA region)
PROMPT   - shard2_link (EU region)
PROMPT   - shard3_link (APAC region)
PROMPT
PROMPT These links allow cross-shard operations in stored procedures
PROMPT ====================================

