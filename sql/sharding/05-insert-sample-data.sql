-- Insert Sample Data for Bank Transaction System
-- Run as bank_app user
-- Data will be automatically distributed to appropriate shards

PROMPT ====================================
PROMPT Inserting Sample Data
PROMPT ====================================

CONNECT bank_app/BankAppPass123@FREEPDB1

PROMPT Inserting users (replicated on all shards)...

-- Insert users (will be duplicated on all shards)
INSERT INTO users (user_id, username, email, full_name, region) 
VALUES (user_seq.NEXTVAL, 'john_doe', 'john.doe@example.com', 'John Doe', 'NA');
COMMIT;

INSERT INTO users (user_id, username, email, full_name, region) 
VALUES (user_seq.NEXTVAL, 'jane_smith', 'jane.smith@example.com', 'Jane Smith', 'EU');
COMMIT;

INSERT INTO users (user_id, username, email, full_name, region) 
VALUES (user_seq.NEXTVAL, 'lee_wong', 'lee.wong@example.com', 'Lee Wong', 'APAC');
COMMIT;

INSERT INTO users (user_id, username, email, full_name, region) 
VALUES (user_seq.NEXTVAL, 'maria_garcia', 'maria.garcia@example.com', 'Maria Garcia', 'NA');
COMMIT;

PROMPT Inserting accounts (distributed across shards based on account_id)...

-- Insert accounts - will be distributed to shards based on account_id hash
-- Shard 1 (North America): accounts 1-10M
INSERT INTO accounts (account_id, user_id, account_number, account_type, balance, region)
VALUES (1, 1, 'ACC001', 'CHECKING', 1000.00, 'NA');
COMMIT;

INSERT INTO accounts (account_id, user_id, account_number, account_type, balance, region)
VALUES (5000000, 1, 'ACC005M', 'SAVINGS', 50000.00, 'NA');
COMMIT;

INSERT INTO accounts (account_id, user_id, account_number, account_type, balance, region)
VALUES (500, 4, 'ACC500', 'CHECKING', 2500.00, 'NA');
COMMIT;

-- Shard 2 (Europe): accounts 10M-20M
INSERT INTO accounts (account_id, user_id, account_number, account_type, balance, region)
VALUES (15000000, 2, 'ACC015M', 'CHECKING', 7500.00, 'EU');
COMMIT;

INSERT INTO accounts (account_id, user_id, account_number, account_type, balance, region)
VALUES (12000000, 2, 'ACC012M', 'SAVINGS', 30000.00, 'EU');
COMMIT;

-- Shard 3 (Asia Pacific): accounts 20M-30M
INSERT INTO accounts (account_id, user_id, account_number, account_type, balance, region)
VALUES (25000000, 3, 'ACC025M', 'SAVINGS', 15000.00, 'APAC');
COMMIT;

INSERT INTO accounts (account_id, user_id, account_number, account_type, balance, region)
VALUES (21000000, 3, 'ACC021M', 'CHECKING', 5000.00, 'APAC');
COMMIT;

PROMPT Inserting transactions (co-located with accounts)...

-- Insert transactions - stored on same shard as from_account_id
INSERT INTO transactions (from_account_id, to_account_id, transaction_type, amount, status, description)
VALUES (NULL, 1, 'DEPOSIT', 1000.00, 'COMPLETED', 'Initial deposit');
COMMIT;

INSERT INTO transactions (from_account_id, to_account_id, transaction_type, amount, status, description)
VALUES (1, 5000000, 'TRANSFER', 500.00, 'COMPLETED', 'Transfer to savings');
COMMIT;

INSERT INTO transactions (from_account_id, to_account_id, transaction_type, amount, status, description)
VALUES (5000000, 15000000, 'TRANSFER', 250.00, 'COMPLETED', 'Cross-shard transfer demo');
COMMIT;

INSERT INTO transactions (from_account_id, to_account_id, transaction_type, amount, status, description)
VALUES (15000000, 25000000, 'TRANSFER', 100.00, 'COMPLETED', 'International transfer');
COMMIT;

PROMPT ====================================
PROMPT Sample data inserted successfully!
PROMPT ====================================
PROMPT
PROMPT Data distribution:
PROMPT   - Users: Replicated on all shards
PROMPT   - Accounts: Distributed across shards by account_id
PROMPT   - Transactions: Co-located with source accounts
PROMPT ====================================

