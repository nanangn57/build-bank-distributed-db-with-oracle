-- Create Union Views on Catalog
-- Run as bank_app user on CATALOG database
-- These views UNION ALL data from all shards, allowing queries via catalog

PROMPT ====================================
PROMPT Creating Union Views for Cross-Shard Queries
PROMPT Query these views from catalog to get data from all shards
PROMPT ====================================

CONNECT bank_app/BankAppPass123@FREEPDB1

-- View that UNION ALL users from all shards
CREATE OR REPLACE VIEW users_all AS
SELECT user_id, username, email, full_name, phone, address, region, created_date, last_updated, 'SHARD1' AS shard_location
FROM users@shard1_link
UNION ALL
SELECT user_id, username, email, full_name, phone, address, region, created_date, last_updated, 'SHARD2' AS shard_location
FROM users@shard2_link
UNION ALL
SELECT user_id, username, email, full_name, phone, address, region, created_date, last_updated, 'SHARD3' AS shard_location
FROM users@shard3_link;

PROMPT Created view: users_all (UNION ALL from all shards)

-- View that UNION ALL accounts from all shards
CREATE OR REPLACE VIEW accounts_all AS
SELECT account_id, user_id, account_number, account_type, balance, currency, region, status, created_date, last_updated, 'SHARD1' AS shard_location
FROM accounts@shard1_link
UNION ALL
SELECT account_id, user_id, account_number, account_type, balance, currency, region, status, created_date, last_updated, 'SHARD2' AS shard_location
FROM accounts@shard2_link
UNION ALL
SELECT account_id, user_id, account_number, account_type, balance, currency, region, status, created_date, last_updated, 'SHARD3' AS shard_location
FROM accounts@shard3_link;

PROMPT Created view: accounts_all (UNION ALL from all shards)

-- View that UNION ALL transactions from all shards
CREATE OR REPLACE VIEW transactions_all AS
SELECT transaction_id, from_account_id, to_account_id, transaction_type, amount, currency, status, transaction_date, description, reference_number, 'SHARD1' AS shard_location
FROM transactions@shard1_link
UNION ALL
SELECT transaction_id, from_account_id, to_account_id, transaction_type, amount, currency, status, transaction_date, description, reference_number, 'SHARD2' AS shard_location
FROM transactions@shard2_link
UNION ALL
SELECT transaction_id, from_account_id, to_account_id, transaction_type, amount, currency, status, transaction_date, description, reference_number, 'SHARD3' AS shard_location
FROM transactions@shard3_link;

PROMPT Created view: transactions_all (UNION ALL from all shards)

-- Composite view: Accounts with User details from all shards
CREATE OR REPLACE VIEW account_summary_all AS
SELECT 
    a.account_id,
    a.account_number,
    a.user_id,
    u.username,
    u.full_name,
    u.email,
    a.account_type,
    a.balance,
    a.currency,
    a.region,
    a.status,
    a.created_date AS account_created,
    u.created_date AS user_created,
    a.shard_location
FROM accounts_all a
JOIN users_all u ON a.user_id = u.user_id AND a.shard_location = u.shard_location;

PROMPT Created view: account_summary_all (Accounts with user details from all shards)

-- View for regional statistics
CREATE OR REPLACE VIEW regional_stats AS
SELECT 
    region,
    COUNT(DISTINCT user_id) AS user_count,
    COUNT(DISTINCT account_id) AS account_count,
    COUNT(DISTINCT transaction_id) AS transaction_count,
    SUM(balance) AS total_balance,
    ROUND(AVG(balance), 2) AS avg_balance,
    MIN(balance) AS min_balance,
    MAX(balance) AS max_balance
FROM accounts_all
GROUP BY region;

PROMPT Created view: regional_stats (Aggregated statistics by region)

COMMIT;

PROMPT ====================================
PROMPT Union views created successfully!
PROMPT ====================================
PROMPT
PROMPT Available views on catalog:
PROMPT   - users_all: All users from all shards
PROMPT   - accounts_all: All accounts from all shards
PROMPT   - transactions_all: All transactions from all shards
PROMPT   - account_summary_all: Accounts with user details from all shards
PROMPT   - regional_stats: Aggregated statistics by region
PROMPT
PROMPT Example queries:
PROMPT   SELECT * FROM users_all;
PROMPT   SELECT * FROM accounts_all WHERE region = 'NA';
PROMPT   SELECT * FROM account_summary_all ORDER BY balance DESC;
PROMPT   SELECT * FROM regional_stats;
PROMPT ====================================

