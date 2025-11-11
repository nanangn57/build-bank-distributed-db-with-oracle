-- Create Database Links and Union Views on Catalog
-- Run as bank_app user on CATALOG database
-- This allows querying all shards via catalog using UNION ALL views

PROMPT ====================================
PROMPT Creating Database Links to Shards
PROMPT This allows catalog to query data from all shards
PROMPT ====================================

WHENEVER SQLERROR EXIT SQL.SQLCODE
WHENEVER OSERROR EXIT FAILURE

CONNECT bank_app/BankAppPass123@freepdb1

-- Create database links to each shard
-- These links allow the catalog to access data on shards

PROMPT Creating database link to Shard 1 (NA region)...

-- Drop link if exists (for re-running script)
BEGIN
    EXECUTE IMMEDIATE 'DROP DATABASE LINK shard1_link';
    DBMS_OUTPUT.PUT_LINE('Dropped existing shard1_link');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -2024 THEN  -- Link does not exist
            NULL;  -- This is fine, continue
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

PROMPT Creating database link to Shard 2 (EU region)...

-- Drop link if exists
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

PROMPT Creating database link to Shard 3 (APAC region)...

-- Drop link if exists
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

PROMPT Testing database links...

SET SERVEROUTPUT ON;

-- Test database links with error handling
DECLARE
    v_test VARCHAR2(100);
BEGIN
    BEGIN
        SELECT 'Shard 1 connected' INTO v_test FROM DUAL@shard1_link;
        DBMS_OUTPUT.PUT_LINE('✅ Shard 1 link: Connected successfully');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('❌ Shard 1 link: ' || SQLERRM);
    END;
    
    BEGIN
        SELECT 'Shard 2 connected' INTO v_test FROM DUAL@shard2_link;
        DBMS_OUTPUT.PUT_LINE('✅ Shard 2 link: Connected successfully');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('❌ Shard 2 link: ' || SQLERRM);
    END;
    
    BEGIN
        SELECT 'Shard 3 connected' INTO v_test FROM DUAL@shard3_link;
        DBMS_OUTPUT.PUT_LINE('✅ Shard 3 link: Connected successfully');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('❌ Shard 3 link: ' || SQLERRM);
    END;
END;
/

PROMPT ====================================
PROMPT Database links created successfully!
PROMPT ====================================

