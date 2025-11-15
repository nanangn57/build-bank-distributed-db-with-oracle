-- Remove Foreign Key Constraint for to_account_number
-- This allows cross-shard transfers where to_account may be on a different shard
-- Run as bank_app user on EACH SHARD

PROMPT ====================================
PROMPT Removing to_account_number Foreign Key
PROMPT Run this script on EACH SHARD
PROMPT ====================================

WHENEVER SQLERROR EXIT SQL.SQLCODE
WHENEVER OSERROR EXIT FAILURE

CONNECT bank_app/BankAppPass123@freepdb1

-- Drop foreign key constraint for to_account_number
-- This is needed because to_account may be on a different shard in cross-shard transfers
PROMPT Dropping FK_TRANS_TO_ACCOUNT_NUMBER constraint...

BEGIN
    EXECUTE IMMEDIATE 'ALTER TABLE transactions DROP CONSTRAINT fk_trans_to_account_number';
    DBMS_OUTPUT.PUT_LINE('Dropped fk_trans_to_account_number constraint');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -2443 THEN  -- ORA-02443: Cannot drop constraint - does not exist
            DBMS_OUTPUT.PUT_LINE('Constraint fk_trans_to_account_number does not exist (already removed)');
        ELSE
            RAISE;
        END IF;
END;
/

COMMIT;

PROMPT ====================================
PROMPT Foreign key constraint removed!
PROMPT ====================================
PROMPT
PROMPT Note: to_account_number foreign key removed to allow cross-shard transfers
PROMPT Foreign keys for account_number and from_account_number remain (always on same shard)
PROMPT ====================================

