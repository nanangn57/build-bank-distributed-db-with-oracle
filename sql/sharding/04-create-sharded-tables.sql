-- Create Distributed Tables for Bank Transaction System
-- Run as bank_app user on EACH SHARD (not catalog)
-- Tables are created on each shard independently
-- Catalog database should NOT have these application tables

PROMPT ====================================
PROMPT Creating Distributed Tables for Bank System
PROMPT Note: Run this script on EACH SHARD, not on catalog
PROMPT Catalog database should only contain metadata, not application data
PROMPT ====================================

WHENEVER SQLERROR EXIT SQL.SQLCODE
WHENEVER OSERROR EXIT FAILURE

CONNECT bank_app/BankAppPass123@freepdb1

PROMPT Creating Users Table (Sharded by region)...

-- Create users table - Sharded by user_id (region-based ID ranges)
-- Region-based ID ranges:
--   NA:   1 - 10,000,000 (Shard 1)
--   EU:   10,000,001 - 20,000,000 (Shard 2)
--   APAC: 20,000,001 - 30,000,000 (Shard 3)
-- Users are sharded based on their user_id, which is auto-generated based on region
CREATE TABLE users (
    user_id NUMBER PRIMARY KEY,
    username VARCHAR2(50) NOT NULL,
    email VARCHAR2(100) NOT NULL,
    full_name VARCHAR2(100),
    phone VARCHAR2(20),
    address VARCHAR2(200),
    region VARCHAR2(50) NOT NULL,  -- Region: 'NA', 'EU', 'APAC' - determines user_id range
    created_date DATE DEFAULT SYSDATE,
    last_updated DATE DEFAULT SYSDATE,
    CONSTRAINT chk_region CHECK (region IN ('NA', 'EU', 'APAC'))
);

-- Create sequences for each region
-- NA region: IDs 1-10M (Shard 1 only)
CREATE SEQUENCE user_seq_na START WITH 1 INCREMENT BY 1 MINVALUE 1 MAXVALUE 10000000 CYCLE;

-- EU region: IDs 10M-20M (Shard 2 only)
CREATE SEQUENCE user_seq_eu START WITH 10000001 INCREMENT BY 1 MINVALUE 10000001 MAXVALUE 20000000 CYCLE;

-- APAC region: IDs 20M-30M (Shard 3 only)
CREATE SEQUENCE user_seq_apac START WITH 20000001 INCREMENT BY 1 MINVALUE 20000001 MAXVALUE 30000000 CYCLE;

-- Function to get the next user ID based on region
CREATE OR REPLACE FUNCTION get_next_user_id(p_region VARCHAR2) RETURN NUMBER AS
    v_next_id NUMBER;
BEGIN
    CASE UPPER(p_region)
        WHEN 'NA' THEN
            SELECT user_seq_na.NEXTVAL INTO v_next_id FROM DUAL;
        WHEN 'EU' THEN
            SELECT user_seq_eu.NEXTVAL INTO v_next_id FROM DUAL;
        WHEN 'APAC' THEN
            SELECT user_seq_apac.NEXTVAL INTO v_next_id FROM DUAL;
        ELSE
            RAISE_APPLICATION_ERROR(-20001, 'Invalid region: ' || p_region || '. Must be NA, EU, or APAC');
    END CASE;
    RETURN v_next_id;
END;
/

-- Trigger to auto-generate user_id based on region before insert
CREATE OR REPLACE TRIGGER users_before_insert
BEFORE INSERT ON users
FOR EACH ROW
BEGIN
    IF :NEW.user_id IS NULL THEN
        :NEW.user_id := get_next_user_id(:NEW.region);
    ELSE
        -- Validate that provided ID matches region range
        CASE UPPER(:NEW.region)
            WHEN 'NA' THEN
                IF :NEW.user_id < 1 OR :NEW.user_id > 10000000 THEN
                    RAISE_APPLICATION_ERROR(-20002, 'User ID ' || :NEW.user_id || ' is out of range for NA region (1-10000000)');
                END IF;
            WHEN 'EU' THEN
                IF :NEW.user_id < 10000001 OR :NEW.user_id > 20000000 THEN
                    RAISE_APPLICATION_ERROR(-20002, 'User ID ' || :NEW.user_id || ' is out of range for EU region (10000001-20000000)');
                END IF;
            WHEN 'APAC' THEN
                IF :NEW.user_id < 20000001 OR :NEW.user_id > 30000000 THEN
                    RAISE_APPLICATION_ERROR(-20002, 'User ID ' || :NEW.user_id || ' is out of range for APAC region (20000001-30000000)');
                END IF;
            ELSE
                RAISE_APPLICATION_ERROR(-20001, 'Invalid region: ' || :NEW.region);
        END CASE;
    END IF;
END;
/

PROMPT Creating Accounts Table (Sharded with users by region)...

-- Create accounts table - Sharded with users based on user_id (which determines region)
-- Accounts are co-located with users on the same shard (sharding follows user_id, not account_id)
-- Account IDs are auto-generated but don't need region-based ranges since sharding follows user_id
CREATE TABLE accounts (
    account_id NUMBER PRIMARY KEY,
    user_id NUMBER NOT NULL,
    account_number VARCHAR2(20) NOT NULL,
    account_type VARCHAR2(20) NOT NULL CHECK (account_type IN ('CHECKING', 'SAVINGS', 'BUSINESS')),
    balance NUMBER(15,2) DEFAULT 0 CHECK (balance >= 0),
    currency VARCHAR2(3) DEFAULT 'USD',
    region VARCHAR2(50) NOT NULL,  -- Geographic region (must match user's region)
    status VARCHAR2(10) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE', 'CLOSED', 'FROZEN')),
    created_date DATE DEFAULT SYSDATE,
    last_updated DATE DEFAULT SYSDATE,
    CONSTRAINT fk_account_user FOREIGN KEY (user_id) REFERENCES users(user_id),
    CONSTRAINT chk_account_region CHECK (region IN ('NA', 'EU', 'APAC'))
);

-- Create single sequence for accounts (sharding follows user_id, not account_id)
CREATE SEQUENCE account_seq START WITH 1 INCREMENT BY 1;

-- Trigger to auto-generate account_id, account_number and validate user_id region match
-- Accounts are sharded with users (co-located on same shard as user)
CREATE OR REPLACE TRIGGER accounts_before_insert
BEFORE INSERT ON accounts
FOR EACH ROW
DECLARE
    v_user_region VARCHAR2(50);
    v_account_id NUMBER;
BEGIN
    -- Get user's region to ensure account matches
    SELECT region INTO v_user_region
    FROM users
    WHERE user_id = :NEW.user_id;
    
    -- Ensure account region matches user region (co-location rule)
    IF UPPER(:NEW.region) != UPPER(v_user_region) THEN
        RAISE_APPLICATION_ERROR(-20003, 'Account region (' || :NEW.region || ') must match user region (' || v_user_region || ')');
    END IF;
    
    -- Auto-generate account_id if not provided
    IF :NEW.account_id IS NULL THEN
        SELECT account_seq.NEXTVAL INTO :NEW.account_id FROM DUAL;
    END IF;
    
    -- Store account_id for account_number generation
    v_account_id := :NEW.account_id;
    
    -- Auto-generate account_number if not provided
    -- Format: ACC-{account_id} (e.g., ACC-1, ACC-2, ACC-100)
    IF :NEW.account_number IS NULL THEN
        :NEW.account_number := 'ACC-' || TO_CHAR(v_account_id);
    END IF;
END;
/

PROMPT Creating Transactions Table (Co-located with accounts)...

-- Create transactions table - Distributed with accounts
-- Transactions stored on same shard as source account
CREATE TABLE transactions (
    transaction_id NUMBER GENERATED ALWAYS AS IDENTITY,
    from_account_id NUMBER,
    to_account_id NUMBER,
    transaction_type VARCHAR2(20) NOT NULL CHECK (transaction_type IN ('DEPOSIT', 'WITHDRAWAL', 'TRANSFER', 'FEE', 'INTEREST')),
    amount NUMBER(15,2) NOT NULL CHECK (amount > 0),
    currency VARCHAR2(3) DEFAULT 'USD',
    status VARCHAR2(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'COMPLETED', 'FAILED', 'CANCELLED', 'REVERSED')),
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    description VARCHAR2(200),
    reference_number VARCHAR2(50),
    CONSTRAINT fk_trans_from_account FOREIGN KEY (from_account_id) REFERENCES accounts(account_id),
    CONSTRAINT fk_trans_to_account FOREIGN KEY (to_account_id) REFERENCES accounts(account_id)
);

PROMPT Creating Indexes...

-- Create indexes on tables
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_region ON users(region);

CREATE INDEX idx_accounts_user ON accounts(user_id);
CREATE INDEX idx_accounts_number ON accounts(account_number);
CREATE INDEX idx_accounts_region ON accounts(region);
CREATE INDEX idx_accounts_status ON accounts(status);

CREATE INDEX idx_trans_from_account ON transactions(from_account_id);
CREATE INDEX idx_trans_to_account ON transactions(to_account_id);
CREATE INDEX idx_trans_date ON transactions(transaction_date);
CREATE INDEX idx_trans_status ON transactions(status);
CREATE INDEX idx_trans_ref ON transactions(reference_number);

PROMPT ====================================
PROMPT Distributed tables created successfully on this shard!
PROMPT ====================================
PROMPT
PROMPT Tables created:
PROMPT   - users (Sharded by region via user_id ranges)
PROMPT     * NA:    user_id 1 - 10,000,000 (Shard 1)
PROMPT     * EU:    user_id 10,000,001 - 20,000,000 (Shard 2)
PROMPT     * APAC:  user_id 20,000,001 - 30,000,000 (Shard 3)
PROMPT   - accounts (Sharded with users, co-located by user_id/region)
PROMPT   - transactions (Co-located with accounts, stored on same shard as source account)
PROMPT
PROMPT Note: This shard only stores data for its assigned region range
PROMPT ====================================
