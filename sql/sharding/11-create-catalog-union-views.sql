-- Create Union Views on Catalog
-- Run as bank_app user on CATALOG database
-- These views UNION ALL data from all shards, allowing queries via catalog

PROMPT ====================================
PROMPT Creating Union Views for Cross-Shard Queries
PROMPT Query these views from catalog to get data from all shards
PROMPT ====================================

WHENEVER SQLERROR EXIT SQL.SQLCODE
WHENEVER OSERROR EXIT FAILURE

CONNECT bank_app/BankAppPass123@freepdb1

-- View that UNION ALL users from all shards
-- user_id is globally unique (ranges: NA=1-10M, EU=10M+1-20M, APAC=20M+1-30M)
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
-- user_id is globally unique (ranges: NA=1-10M, EU=10M+1-20M, APAC=20M+1-30M)
-- account_id is NOT globally unique (removed), account_number is globally unique
CREATE OR REPLACE VIEW accounts_all AS
SELECT user_id, account_number, account_type, balance, currency, region, status, created_date, last_updated, 'SHARD1' AS shard_location
FROM accounts@shard1_link
UNION ALL
SELECT user_id, account_number, account_type, balance, currency, region, status, created_date, last_updated, 'SHARD2' AS shard_location
FROM accounts@shard2_link
UNION ALL
SELECT user_id, account_number, account_type, balance, currency, region, status, created_date, last_updated, 'SHARD3' AS shard_location
FROM accounts@shard3_link;

PROMPT Created view: accounts_all (UNION ALL from all shards)

-- View that UNION ALL transactions from all shards
-- Removed transaction_id (not globally unique across shards)
-- Uses account_number directly (globally unique, stored in transactions table, always NOT NULL)
CREATE OR REPLACE VIEW transactions_all AS
SELECT 
    account_number,  -- Always NOT NULL, account where transaction is routed
    from_account_number,
    to_account_number,
    transaction_type, 
    amount, 
    currency, 
    status, 
    transaction_date, 
    description, 
    reference_number, 
    'SHARD1' AS shard_location
FROM transactions@shard1_link
UNION ALL
SELECT 
    account_number,
    from_account_number,
    to_account_number,
    transaction_type, 
    amount, 
    currency, 
    status, 
    transaction_date, 
    description, 
    reference_number, 
    'SHARD2' AS shard_location
FROM transactions@shard2_link
UNION ALL
SELECT 
    account_number,
    from_account_number,
    to_account_number,
    transaction_type, 
    amount, 
    currency, 
    status, 
    transaction_date, 
    description, 
    reference_number, 
    'SHARD3' AS shard_location
FROM transactions@shard3_link;

PROMPT Created view: transactions_all (UNION ALL from all shards)

-- Composite view: Accounts with User details from all shards
CREATE OR REPLACE VIEW account_summary_all AS
SELECT 
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
-- user_id is globally unique, transaction_id removed (not globally unique)
-- Uses account_number (globally unique) for joins
CREATE OR REPLACE VIEW regional_stats AS
SELECT 
    a.region,
    COUNT(DISTINCT u.user_id) AS user_count,  -- user_id is globally unique
    COUNT(DISTINCT a.account_number) AS account_count,  -- Use account_number (globally unique)
    COUNT(*) AS transaction_count,  -- Count all transactions (transaction_id removed)
    SUM(a.balance) AS total_balance,
    ROUND(AVG(a.balance), 2) AS avg_balance,
    MIN(a.balance) AS min_balance,
    MAX(a.balance) AS max_balance
FROM accounts_all a
LEFT JOIN users_all u ON a.user_id = u.user_id AND a.shard_location = u.shard_location
LEFT JOIN transactions_all t
  ON (a.account_number = t.from_account_number AND a.shard_location = t.shard_location)
  OR (a.account_number = t.to_account_number AND a.shard_location = t.shard_location)
GROUP BY a.region;

PROMPT Created view: regional_stats (Aggregated statistics by region)

COMMIT;

PROMPT ====================================
PROMPT Union views created successfully!
PROMPT ====================================
PROMPT
PROMPT Available views on catalog:
PROMPT   - users_all: All users from all shards (user_id is globally unique with ranges)
PROMPT   - accounts_all: All accounts from all shards (user_id globally unique, account_id removed, account_number globally unique)
PROMPT   - transactions_all: All transactions from all shards (removed transaction_id, from_account_id, to_account_id - only account_number globally unique)
PROMPT   - account_summary_all: Accounts with user details from all shards
PROMPT   - regional_stats: Aggregated statistics by region (user_id globally unique, transaction_id removed - uses account_number for joins)
PROMPT
PROMPT Example queries:
PROMPT   SELECT * FROM users_all;
PROMPT   SELECT * FROM accounts_all WHERE region = 'NA';
PROMPT   SELECT * FROM account_summary_all ORDER BY balance DESC;
PROMPT   SELECT * FROM regional_stats;
PROMPT ====================================

