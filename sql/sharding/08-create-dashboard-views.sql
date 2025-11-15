-- Create Dashboard Views for Statistics
-- Run as bank_app user

PROMPT ====================================
PROMPT Creating Dashboard Views
PROMPT ====================================

WHENEVER SQLERROR EXIT SQL.SQLCODE
WHENEVER OSERROR EXIT FAILURE

CONNECT bank_app/BankAppPass123@freepdb1

-- View for regional statistics
-- Uses union views to query data from all shards
-- user_id is globally unique (ranges: NA=1-10M, EU=10M+1-20M, APAC=20M+1-30M)
-- Transactions are stored on the from_account's shard (or to_account's shard for deposits)
CREATE OR REPLACE VIEW dashboard_regional_stats AS
WITH user_account_stats AS (
    SELECT 
        COALESCE(a.region, u.region) AS region,
        COUNT(DISTINCT u.user_id) AS total_users,  -- user_id is globally unique
        COUNT(DISTINCT a.account_number) AS total_accounts,  -- Use account_number (globally unique)
        COALESCE(SUM(a.balance), 0) AS total_balance,
        ROUND(AVG(a.balance), 2) AS avg_balance_per_account
    FROM users_all u
    LEFT JOIN accounts_all a ON u.user_id = a.user_id AND u.shard_location = a.shard_location
    GROUP BY COALESCE(a.region, u.region)
),
transaction_stats AS (
    -- Count transactions by region from transactions_all
    -- Each transaction appears once in transactions_all (on its own shard)
    -- Join to accounts_all to get region where transaction is stored
    -- Uses account_number (globally unique) instead of account_id (not globally unique)
    SELECT 
        acc.region,
        COUNT(*) AS total_transactions,
        COUNT(CASE WHEN t.transaction_type = 'DEPOSIT' THEN 1 END) AS deposits,
        COUNT(CASE WHEN t.transaction_type = 'WITHDRAWAL' THEN 1 END) AS withdrawals,
        COUNT(CASE WHEN t.transaction_type = 'TRANSFER' THEN 1 END) AS transfers,
        COALESCE(SUM(CASE WHEN t.transaction_type = 'DEPOSIT' THEN t.amount ELSE 0 END), 0) AS total_deposits,
        COALESCE(SUM(CASE WHEN t.transaction_type = 'WITHDRAWAL' THEN t.amount ELSE 0 END), 0) AS total_withdrawals,
        COALESCE(SUM(CASE WHEN t.transaction_type = 'TRANSFER' THEN t.amount ELSE 0 END), 0) AS total_transfers
    FROM transactions_all t
    JOIN accounts_all acc ON (
        -- For transfers/withdrawals: transaction is on from_account's shard
        -- For deposits: transaction is on to_account's shard
        -- Use account_number (globally unique) instead of account_id
        (t.from_account_number IS NOT NULL AND t.from_account_number = acc.account_number AND t.shard_location = acc.shard_location)
        OR
        (t.from_account_number IS NULL AND t.to_account_number IS NOT NULL AND t.to_account_number = acc.account_number AND t.shard_location = acc.shard_location)
    )
    GROUP BY acc.region
)
SELECT 
    COALESCE(uas.region, ts.region) AS region,
    COALESCE(uas.total_users, 0) AS total_users,
    COALESCE(uas.total_accounts, 0) AS total_accounts,
    COALESCE(ts.total_transactions, 0) AS total_transactions,
    COALESCE(uas.total_balance, 0) AS total_balance,
    COALESCE(uas.avg_balance_per_account, 0) AS avg_balance_per_account,
    COALESCE(ts.deposits, 0) AS deposits,
    COALESCE(ts.withdrawals, 0) AS withdrawals,
    COALESCE(ts.transfers, 0) AS transfers,
    COALESCE(ts.total_deposits, 0) AS total_deposits,
    COALESCE(ts.total_withdrawals, 0) AS total_withdrawals,
    COALESCE(ts.total_transfers, 0) AS total_transfers
FROM user_account_stats uas
FULL OUTER JOIN transaction_stats ts ON uas.region = ts.region
ORDER BY COALESCE(uas.region, ts.region);

-- View for overall statistics
-- Uses union views to query data from all shards
-- user_id is globally unique (ranges: NA=1-10M, EU=10M+1-20M, APAC=20M+1-30M)
CREATE OR REPLACE VIEW dashboard_overall_stats AS
WITH account_stats AS (
    SELECT 
        COUNT(DISTINCT u.user_id) AS total_users,  -- user_id is globally unique
        COUNT(DISTINCT a.account_number) AS total_accounts,  -- Use account_number (globally unique)
        COALESCE(SUM(a.balance), 0) AS total_balance,
        ROUND(AVG(a.balance), 2) AS avg_balance_per_account
    FROM users_all u
    LEFT JOIN accounts_all a ON u.user_id = a.user_id AND u.shard_location = a.shard_location
),
transaction_stats AS (
    -- Simply count all transactions from transactions_all
    -- transactions_all is a UNION of all shards, so this gives us the total count
    SELECT 
        COUNT(*) AS total_transactions,
        COUNT(CASE WHEN t.status = 'COMPLETED' THEN 1 END) AS completed_transactions,
        COUNT(CASE WHEN t.status = 'PENDING' THEN 1 END) AS pending_transactions,
        COUNT(CASE WHEN t.status = 'FAILED' THEN 1 END) AS failed_transactions,
        COALESCE(SUM(CASE WHEN t.transaction_type = 'DEPOSIT' THEN t.amount ELSE 0 END), 0) AS total_deposits,
        COALESCE(SUM(CASE WHEN t.transaction_type = 'WITHDRAWAL' THEN t.amount ELSE 0 END), 0) AS total_withdrawals,
        COALESCE(SUM(CASE WHEN t.transaction_type = 'TRANSFER' THEN t.amount ELSE 0 END), 0) AS total_transfers
    FROM transactions_all t
)
SELECT 
    'TOTAL' AS metric,
    ac.total_users,
    ac.total_accounts,
    tx.total_transactions,
    ac.total_balance,
    ac.avg_balance_per_account,
    tx.completed_transactions,
    tx.pending_transactions,
    tx.failed_transactions,
    tx.total_deposits,
    tx.total_withdrawals,
    tx.total_transfers
FROM account_stats ac
CROSS JOIN transaction_stats tx;

-- View for recent transactions
-- Uses union views to query data from all shards
-- Removed transaction_id, from_account_id, to_account_id (not globally unique)
-- Only includes account_number (globally unique identifier)
CREATE OR REPLACE VIEW dashboard_recent_transactions AS
SELECT 
    from_account_number,
    to_account_number,
    transaction_type,
    amount,
    status,
    transaction_date,
    description,
    reference_number,
    shard_location
FROM transactions_all
ORDER BY transaction_date DESC
FETCH FIRST 20 ROWS ONLY;

-- View for account summary by region
-- Uses union views to query data from all shards
CREATE OR REPLACE VIEW dashboard_accounts_by_region AS
SELECT 
    region,
    account_type,
    COUNT(*) AS account_count,
    COALESCE(SUM(balance), 0) AS total_balance,
    ROUND(AVG(balance), 2) AS avg_balance,
    MIN(balance) AS min_balance,
    MAX(balance) AS max_balance
FROM accounts_all
GROUP BY region, account_type
ORDER BY region, account_type;

-- View for transaction volume by date
-- Uses union views to query data from all shards
CREATE OR REPLACE VIEW dashboard_transactions_by_date AS
SELECT 
    TO_CHAR(transaction_date, 'YYYY-MM-DD') AS transaction_date,
    COUNT(*) AS transaction_count,
    COALESCE(SUM(amount), 0) AS total_amount,
    COUNT(CASE WHEN transaction_type = 'DEPOSIT' THEN 1 END) AS deposits,
    COUNT(CASE WHEN transaction_type = 'WITHDRAWAL' THEN 1 END) AS withdrawals,
    COUNT(CASE WHEN transaction_type = 'TRANSFER' THEN 1 END) AS transfers
FROM transactions_all
WHERE transaction_date >= SYSDATE - 30
GROUP BY TO_CHAR(transaction_date, 'YYYY-MM-DD')
ORDER BY transaction_date DESC;

PROMPT ====================================
PROMPT Dashboard views created successfully!
PROMPT ====================================
PROMPT
PROMPT Views created:
PROMPT   - dashboard_regional_stats: Statistics by region (from all shards)
PROMPT   - dashboard_overall_stats: Overall totals (from all shards)
PROMPT   - dashboard_recent_transactions: Recent transaction list (from all shards)
PROMPT   - dashboard_accounts_by_region: Account breakdown by region (from all shards)
PROMPT   - dashboard_transactions_by_date: Transaction volume by date (from all shards)
PROMPT
PROMPT Note: These views query data from all shards via union views
PROMPT ====================================

