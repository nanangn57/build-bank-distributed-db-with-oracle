# Oracle Sharding Quick Reference Guide

## Architecture

### Components
- **Shard Catalog**: Central metadata repository (oracle-catalog)
- **Shard 1**: North America region (oracle-shard1)
- **Shard 2**: Europe region (oracle-shard2)
- **Shard 3**: Asia Pacific region (oracle-shard3)

### Table Strategy
- **Users**: SHARDED by region (user_id auto-generated based on region)
  - NA region: user_id 1 - 10,000,000 (Shard 1)
  - EU region: user_id 10,000,001 - 20,000,000 (Shard 2)
  - APAC region: user_id 20,000,001 - 30,000,000 (Shard 3)
- **Accounts**: SHARDED with users (co-located on same shard as user, account_id auto-generated based on region)
- **Transactions**: SHARDED, co-located with source account (same shard as from_account_id)

### Key Features
- **Auto-Generated IDs**: user_id and account_id are automatically generated based on region
- **Region-Based Sharding**: Users and accounts are distributed by geographic region
- **Co-Location**: Accounts are always on the same shard as their user
- **Transaction Co-Location**: Transactions stored on same shard as source account

## Quick Commands

### Start Infrastructure
```bash
./docker/start-sharding.sh
```

### Setup Sharding
```bash
./scripts/setup-sharding.sh
```

### Test Setup
```bash
./scripts/test-sharding.sh
```

### Run Use Cases
```bash
./scripts/run-use-cases.sh
```

### Stop Infrastructure
```bash
./docker/stop-sharding.sh
```

## Connection Examples

### Connect to Catalog
```bash
docker exec -it oracle-catalog sqlplus bank_app/BankAppPass123@FREEPDB1
```

### Connect to Shard 1
```bash
docker exec -it oracle-shard1 sqlplus bank_app/BankAppPass123@FREEPDB1
```

### Run SQL File
```bash
docker exec -i oracle-catalog sqlplus bank_app/BankAppPass123@FREEPDB1 < sql/sharding/07-use-cases.sql
```

## Common Queries

### Create User (Auto-Generated ID)
```sql
-- user_id is auto-generated based on region (do not specify)
EXEC create_user('john_doe', 'john@example.com', 'John Doe', NULL, NULL, 'NA');
-- Or use direct INSERT (user_id will be auto-generated)
INSERT INTO users (username, email, full_name, region) 
VALUES ('jane_smith', 'jane@example.com', 'Jane Smith', 'EU');
```

### Create Account (Auto-Generated ID)
```sql
-- account_id is auto-generated based on user's region
EXEC create_account(1, 'ACC001', 'CHECKING', 1000.00);
-- Or use direct INSERT (account_id will be auto-generated, region matches user)
INSERT INTO accounts (user_id, account_number, account_type, balance, region)
VALUES (1, 'ACC002', 'SAVINGS', 5000.00, 'NA');
```

### Query Account (Auto-routed)
```sql
SELECT * FROM accounts WHERE account_id = 5000000;
```

### Cross-Shard Transfer
```sql
EXEC transfer_money(5000000, 15000000, 250.00, 'Transfer demo');
```

### Multi-Shard Aggregation
```sql
SELECT region, COUNT(*), SUM(balance) 
FROM accounts 
GROUP BY region;
```

### User Accounts (Same Shard)
```sql
-- All accounts for a user are on the same shard
SELECT a.*, u.username 
FROM accounts a 
JOIN users u ON a.user_id = u.user_id 
WHERE u.user_id = 1;
```

## Monitoring

### Check Container Status
```bash
docker-compose -f docker-compose-sharding.yml ps
```

### View Logs
```bash
docker logs -f oracle-catalog
docker logs -f oracle-shard1
```

### Web Interfaces
- Catalog: https://localhost:5500/em
- Shard 1: https://localhost:5501/em
- Shard 2: https://localhost:5502/em
- Shard 3: https://localhost:5503/em

## Use Cases Demonstrated

1. **Automatic Shard Routing**: Single-account queries
2. **Cross-Shard Transactions**: Money transfers between shards
3. **Multi-Shard Aggregation**: Analytics across all shards
4. **High-Volume Processing**: Parallel transaction processing
5. **Real-Time Analytics**: Cross-shard reporting
6. **Geographic Distribution**: Region-based data storage

