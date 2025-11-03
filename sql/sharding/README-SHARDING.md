# Oracle Sharding Deployment Guide

## Architecture Overview

### Catalog Database (oracle-catalog)
- **Purpose**: Metadata repository only
- **Contains**: 
  - Shard routing metadata (`shard_routing_metadata` table)
  - Routing functions (`get_shard_for_user()`, `get_shard_for_region()`)
  - Shard connection information
- **Does NOT contain**: Application data (users, accounts, transactions)

### Shard Databases (oracle-shard1, oracle-shard2, oracle-shard3)
- **Purpose**: Store actual application data
- **Shard 1 (oracle-shard1)**: NA region data (user_id 1-10,000,000)
- **Shard 2 (oracle-shard2)**: EU region data (user_id 10,000,001-20,000,000)
- **Shard 3 (oracle-shard3)**: APAC region data (user_id 20,000,001-30,000,000)

## Deployment Steps

### 1. Setup Catalog (Metadata Only)
```bash
# Create metadata tables on catalog
docker exec -i oracle-catalog sqlplus bank_app/BankAppPass123@FREEPDB1 < sql/sharding/09-create-catalog-metadata.sql
```

### 2. Setup Each Shard
```bash
# Create tables on each shard
docker exec -i oracle-shard1 sqlplus bank_app/BankAppPass123@FREEPDB1 < sql/sharding/04-create-sharded-tables.sql
docker exec -i oracle-shard2 sqlplus bank_app/BankAppPass123@FREEPDB1 < sql/sharding/04-create-sharded-tables.sql
docker exec -i oracle-shard3 sqlplus bank_app/BankAppPass123@FREEPDB1 < sql/sharding/04-create-sharded-tables.sql

# Create procedures on each shard
docker exec -i oracle-shard1 sqlplus bank_app/BankAppPass123@FREEPDB1 < sql/sharding/06-create-procedures.sql
docker exec -i oracle-shard2 sqlplus bank_app/BankAppPass123@FREEPDB1 < sql/sharding/06-create-procedures.sql
docker exec -i oracle-shard3 sqlplus bank_app/BankAppPass123@FREEPDB1 < sql/sharding/06-create-procedures.sql
```

### 3. Insert Data to Correct Shards
```bash
# Insert NA region data on Shard 1
docker exec -i oracle-shard1 sqlplus bank_app/BankAppPass123@FREEPDB1 < sql/sharding/05-insert-sample-data-na.sql

# Insert EU region data on Shard 2
docker exec -i oracle-shard2 sqlplus bank_app/BankAppPass123@FREEPDB1 < sql/sharding/05-insert-sample-data-eu.sql

# Insert APAC region data on Shard 3
docker exec -i oracle-shard3 sqlplus bank_app/BankAppPass123@FREEPDB1 < sql/sharding/05-insert-sample-data-apac.sql
```

## Data Routing Rules

### Users
- **NA region** → Shard 1 (user_id: 1-10,000,000)
- **EU region** → Shard 2 (user_id: 10,000,001-20,000,000)
- **APAC region** → Shard 3 (user_id: 20,000,001-30,000,000)
- `user_id` is auto-generated based on region

### Accounts
- **Co-located with users** (same shard as user)
- Routing follows `user_id`, not `account_id`
- Account region must match user region

### Transactions
- **Co-located with source account** (same shard as `from_account_id`)
- For cross-shard transfers, transaction record created on source shard

## Querying Data

### Query All Shards via Catalog (UNION ALL Views)
The catalog provides UNION ALL views that aggregate data from all shards:

```bash
# Connect to catalog
docker exec -it oracle-catalog sqlplus bank_app/BankAppPass123@FREEPDB1

# Query all users from all shards
SELECT * FROM users_all;

# Query all accounts from all shards
SELECT * FROM accounts_all;

# Query all transactions from all shards
SELECT * FROM transactions_all;

# Account summary with user details from all shards
SELECT * FROM account_summary_all ORDER BY balance DESC;

# Regional statistics
SELECT * FROM regional_stats;

# Query specific region across all shards
SELECT * FROM users_all WHERE region = 'NA';
SELECT * FROM accounts_all WHERE region = 'EU';

# Filtered queries
SELECT * FROM accounts_all WHERE balance > 10000;
SELECT username, email, region, shard_location FROM users_all ORDER BY user_id;
```

### Query on Specific Shard (Direct Access)
```bash
# Query NA region data on Shard 1
docker exec -it oracle-shard1 sqlplus bank_app/BankAppPass123@FREEPDB1
SELECT * FROM users WHERE region = 'NA';
SELECT * FROM accounts WHERE region = 'NA';

# Query EU region data on Shard 2
docker exec -it oracle-shard2 sqlplus bank_app/BankAppPass123@FREEPDB1
SELECT * FROM users WHERE region = 'EU';
```

### Query Catalog Metadata
```bash
# View shard routing information
docker exec -it oracle-catalog sqlplus bank_app/BankAppPass123@FREEPDB1
SELECT * FROM shard_routing_view;
SELECT get_shard_for_user(5000000) FROM DUAL;  -- Returns 1 (Shard 1)
SELECT get_shard_for_region('NA') FROM DUAL;    -- Returns 1 (Shard 1)
```

### Available Union Views on Catalog
- `users_all`: All users from all shards (includes `shard_location` column)
- `accounts_all`: All accounts from all shards (includes `shard_location` column)
- `transactions_all`: All transactions from all shards (includes `shard_location` column)
- `account_summary_all`: Accounts joined with user details from all shards
- `regional_stats`: Aggregated statistics by region

## Cross-Shard Operations

For cross-shard operations (e.g., transfers between accounts on different shards):
1. Transaction record is stored on the source account's shard (`from_account_id`)
2. Both accounts are updated (source and destination)
3. Application layer handles distributed transaction coordination

## Important Notes

⚠️ **Catalog database should NEVER contain application data**
- Only metadata tables should exist on catalog
- All application data must be on shards only

⚠️ **Data must be inserted on correct shard**
- Use region-specific data insertion scripts
- Or use routing functions to determine correct shard before insert

⚠️ **Procedures must exist on all shards**
- Each shard has its own copy of stored procedures
- Queries execute locally on the shard containing the data

