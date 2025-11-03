-- Example Queries Using Catalog Union Views
-- Run as bank_app user on CATALOG database
-- These queries demonstrate querying all shards via catalog

PROMPT ====================================
PROMPT Example Queries via Catalog Union Views
PROMPT Query all shards through oracle-catalog
PROMPT ====================================

CONNECT bank_app/BankAppPass123@FREEPDB1

PROMPT
PROMPT ====================================
PROMPT Example 1: Query all users from all shards
PROMPT ====================================

SELECT 
    shard_location,
    COUNT(*) AS user_count,
    LISTAGG(username, ', ') WITHIN GROUP (ORDER BY user_id) AS users
FROM users_all
GROUP BY shard_location
ORDER BY shard_location;

PROMPT
PROMPT ====================================
PROMPT Example 2: Query all accounts from all shards
PROMPT ====================================

SELECT 
    region,
    shard_location,
    COUNT(*) AS account_count,
    SUM(balance) AS total_balance,
    ROUND(AVG(balance), 2) AS avg_balance
FROM accounts_all
GROUP BY region, shard_location
ORDER BY region, shard_location;

PROMPT
PROMPT ====================================
PROMPT Example 3: Query specific region across shards
PROMPT ====================================

SELECT 
    user_id,
    username,
    email,
    region,
    shard_location
FROM users_all
WHERE region = 'NA'
ORDER BY user_id;

PROMPT
PROMPT ====================================
PROMPT Example 4: Account summary with user details from all shards
PROMPT ====================================

SELECT 
    a.account_id,
    a.account_number,
    u.username,
    u.full_name,
    a.account_type,
    a.balance,
    a.region,
    a.shard_location
FROM accounts_all a
JOIN users_all u ON a.user_id = u.user_id AND a.shard_location = u.shard_location
ORDER BY a.balance DESC;

PROMPT
PROMPT ====================================
PROMPT Example 5: Regional statistics from all shards
PROMPT ====================================

SELECT * FROM regional_stats
ORDER BY region;

PROMPT
PROMPT ====================================
PROMPT Example 6: Find user by username across all shards
PROMPT ====================================

SELECT 
    user_id,
    username,
    email,
    full_name,
    region,
    shard_location
FROM users_all
WHERE username = 'john_doe';

PROMPT
PROMPT ====================================
PROMPT Example 7: All transactions from all shards
PROMPT ====================================

SELECT 
    shard_location,
    transaction_type,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_amount,
    ROUND(AVG(amount), 2) AS avg_amount
FROM transactions_all
GROUP BY shard_location, transaction_type
ORDER BY shard_location, transaction_type;

PROMPT
PROMPT ====================================
PROMPT Example 8: Cross-shard query - accounts by balance range
PROMPT ====================================

SELECT 
    region,
    shard_location,
    CASE 
        WHEN balance < 1000 THEN 'Low'
        WHEN balance < 10000 THEN 'Medium'
        ELSE 'High'
    END AS balance_category,
    COUNT(*) AS account_count
FROM accounts_all
GROUP BY region, shard_location,
    CASE 
        WHEN balance < 1000 THEN 'Low'
        WHEN balance < 10000 THEN 'Medium'
        ELSE 'High'
    END
ORDER BY region, shard_location, balance_category;

PROMPT
PROMPT ====================================
PROMPT Example queries complete!
PROMPT ====================================
PROMPT
PROMPT All queries above query data from all shards via catalog union views
PROMPT ====================================

