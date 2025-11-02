-- Create Dashboard Views for Statistics
-- Run as bank_app user

PROMPT ====================================
PROMPT Creating Dashboard Views
PROMPT ====================================

CONNECT bank_app/BankAppPass123@FREEPDB1

-- View for regional statistics
CREATE OR REPLACE VIEW dashboard_regional_stats AS
SELECT 
    COALESCE(a.region, u.region) AS region,
    COUNT(DISTINCT u.user_id) AS total_users,
    COUNT(DISTINCT a.account_id) AS total_accounts,
    COUNT(t.transaction_id) AS total_transactions,
    COALESCE(SUM(a.balance), 0) AS total_balance,
    ROUND(AVG(a.balance), 2) AS avg_balance_per_account,
    COUNT(CASE WHEN t.transaction_type = 'DEPOSIT' THEN 1 END) AS deposits,
    COUNT(CASE WHEN t.transaction_type = 'WITHDRAWAL' THEN 1 END) AS withdrawals,
    COUNT(CASE WHEN t.transaction_type = 'TRANSFER' THEN 1 END) AS transfers,
    COALESCE(SUM(CASE WHEN t.transaction_type = 'DEPOSIT' THEN t.amount ELSE 0 END), 0) AS total_deposits,
    COALESCE(SUM(CASE WHEN t.transaction_type = 'WITHDRAWAL' THEN t.amount ELSE 0 END), 0) AS total_withdrawals,
    COALESCE(SUM(CASE WHEN t.transaction_type = 'TRANSFER' THEN t.amount ELSE 0 END), 0) AS total_transfers
FROM users u
LEFT JOIN accounts a ON u.user_id = a.user_id
LEFT JOIN transactions t ON (a.account_id = t.from_account_id OR a.account_id = t.to_account_id)
GROUP BY COALESCE(a.region, u.region)
ORDER BY COALESCE(a.region, u.region);

-- View for overall statistics
CREATE OR REPLACE VIEW dashboard_overall_stats AS
SELECT 
    'TOTAL' AS metric,
    COUNT(DISTINCT u.user_id) AS total_users,
    COUNT(DISTINCT a.account_id) AS total_accounts,
    COUNT(t.transaction_id) AS total_transactions,
    SUM(a.balance) AS total_balance,
    ROUND(AVG(a.balance), 2) AS avg_balance_per_account,
    COUNT(CASE WHEN t.status = 'COMPLETED' THEN 1 END) AS completed_transactions,
    COUNT(CASE WHEN t.status = 'PENDING' THEN 1 END) AS pending_transactions,
    COUNT(CASE WHEN t.status = 'FAILED' THEN 1 END) AS failed_transactions,
    SUM(CASE WHEN t.transaction_type = 'DEPOSIT' THEN t.amount ELSE 0 END) AS total_deposits,
    SUM(CASE WHEN t.transaction_type = 'WITHDRAWAL' THEN t.amount ELSE 0 END) AS total_withdrawals,
    SUM(CASE WHEN t.transaction_type = 'TRANSFER' THEN t.amount ELSE 0 END) AS total_transfers
FROM users u
LEFT JOIN accounts a ON u.user_id = a.user_id
LEFT JOIN transactions t ON a.account_id = t.from_account_id OR a.account_id = t.to_account_id;

-- View for recent transactions
CREATE OR REPLACE VIEW dashboard_recent_transactions AS
SELECT 
    transaction_id,
    from_account_id,
    to_account_id,
    transaction_type,
    amount,
    status,
    transaction_date,
    description,
    (SELECT account_number FROM accounts WHERE account_id = t.from_account_id) AS from_account_number,
    (SELECT account_number FROM accounts WHERE account_id = t.to_account_id) AS to_account_number
FROM transactions t
ORDER BY transaction_date DESC
FETCH FIRST 20 ROWS ONLY;

-- View for account summary by region
CREATE OR REPLACE VIEW dashboard_accounts_by_region AS
SELECT 
    region,
    account_type,
    COUNT(*) AS account_count,
    SUM(balance) AS total_balance,
    ROUND(AVG(balance), 2) AS avg_balance,
    MIN(balance) AS min_balance,
    MAX(balance) AS max_balance
FROM accounts
GROUP BY region, account_type
ORDER BY region, account_type;

-- View for transaction volume by date
CREATE OR REPLACE VIEW dashboard_transactions_by_date AS
SELECT 
    TO_CHAR(transaction_date, 'YYYY-MM-DD') AS transaction_date,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_amount,
    COUNT(CASE WHEN transaction_type = 'DEPOSIT' THEN 1 END) AS deposits,
    COUNT(CASE WHEN transaction_type = 'WITHDRAWAL' THEN 1 END) AS withdrawals,
    COUNT(CASE WHEN transaction_type = 'TRANSFER' THEN 1 END) AS transfers
FROM transactions
WHERE transaction_date >= SYSDATE - 30
GROUP BY TO_CHAR(transaction_date, 'YYYY-MM-DD')
ORDER BY transaction_date DESC;

PROMPT ====================================
PROMPT Dashboard views created successfully!
PROMPT ====================================
PROMPT
PROMPT Views created:
PROMPT   - dashboard_regional_stats: Statistics by region
PROMPT   - dashboard_overall_stats: Overall totals
PROMPT   - dashboard_recent_transactions: Recent transaction list
PROMPT   - dashboard_accounts_by_region: Account breakdown by region
PROMPT   - dashboard_transactions_by_date: Transaction volume by date
PROMPT ====================================

