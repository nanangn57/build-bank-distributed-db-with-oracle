# Oracle Sharding Quick Reference Guide

## Architecture

### Components
- **Shard Catalog**: Central metadata repository (oracle-catalog)
- **Shard 1**: North America region (oracle-shard1)
- **Shard 2**: Europe region (oracle-shard2)
- **Shard 3**: Asia Pacific region (oracle-shard3)

### Table Strategy
- **Users**: DUPLICATED (exists on all shards)
- **Accounts**: SHARDED by account_id (consistent hash)
- **Transactions**: SHARDED, co-located with accounts

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

### User Accounts Across Shards
```sql
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

