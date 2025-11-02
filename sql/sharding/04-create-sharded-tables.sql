-- Create Distributed Tables for Bank Transaction System (Fallback)
-- This uses regular tables instead of sharded tables for Oracle Free compatibility
-- Run as bank_app user on catalog database
-- Tables are created on each shard and accessed via database links

PROMPT ====================================
PROMPT Creating Distributed Tables for Bank System
PROMPT Note: Using regular tables with database links for Oracle Free compatibility
PROMPT ====================================

CONNECT bank_app/BankAppPass123@FREEPDB1

PROMPT Creating Users Table (Replicated across all shards)...

-- Create users table - Replicated on all shards
CREATE TABLE users (
    user_id NUMBER PRIMARY KEY,
    username VARCHAR2(50) NOT NULL,
    email VARCHAR2(100) NOT NULL,
    full_name VARCHAR2(100),
    phone VARCHAR2(20),
    address VARCHAR2(200),
    region VARCHAR2(50),  -- Routing key: 'NA', 'EU', 'APAC'
    created_date DATE DEFAULT SYSDATE,
    last_updated DATE DEFAULT SYSDATE
);

-- Create sequence for users
CREATE SEQUENCE user_seq START WITH 1 INCREMENT BY 1;

PROMPT Creating Accounts Table (Distributed across shards)...

-- Create accounts table - Distributed across shards by account_id range
-- Shard 1: 1-10M, Shard 2: 10M-20M, Shard 3: 20M-30M
CREATE TABLE accounts (
    account_id NUMBER PRIMARY KEY,
    user_id NUMBER NOT NULL,
    account_number VARCHAR2(20) NOT NULL,
    account_type VARCHAR2(20) NOT NULL CHECK (account_type IN ('CHECKING', 'SAVINGS', 'BUSINESS')),
    balance NUMBER(15,2) DEFAULT 0 CHECK (balance >= 0),
    currency VARCHAR2(3) DEFAULT 'USD',
    region VARCHAR2(50) NOT NULL,  -- Geographic region
    status VARCHAR2(10) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE', 'CLOSED', 'FROZEN')),
    created_date DATE DEFAULT SYSDATE,
    last_updated DATE DEFAULT SYSDATE,
    CONSTRAINT fk_account_user FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- Create sequence for accounts
CREATE SEQUENCE account_seq START WITH 1 INCREMENT BY 1;

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
PROMPT Distributed tables created successfully!
PROMPT ====================================
PROMPT
PROMPT Tables created:
PROMPT   - users (Replicated across all shards)
PROMPT   - accounts (Distributed by account_id range)
PROMPT   - transactions (Co-located with accounts)
PROMPT
PROMPT Note: These are regular tables. For full sharding features,
PROMPT configure Oracle Sharding with GSM and proper shard setup.
PROMPT ====================================

