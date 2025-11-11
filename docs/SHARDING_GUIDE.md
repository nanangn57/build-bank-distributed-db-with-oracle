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
This script handles catalog metadata, privileges, database links, shard schema, sample data, and catalog views in the correct order.

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

### Run Catalog Metadata + Views (manual)
```bash
docker exec -i oracle-catalog sqlplus bank_app/BankAppPass123@freepdb1 < sql/sharding/09-create-catalog-metadata.sql
docker exec -i oracle-catalog sqlplus sys/tuPDqNJWLr7QcA@freepdb1 as sysdba <<'EOF'
GRANT CREATE DATABASE LINK TO bank_app;
EXIT;
EOF
docker exec -i oracle-catalog sqlplus bank_app/BankAppPass123@freepdb1 < sql/sharding/10-create-catalog-database-links.sql
docker exec -i oracle-catalog sqlplus bank_app/BankAppPass123@freepdb1 < sql/sharding/11-create-catalog-union-views.sql
docker exec -i oracle-catalog sqlplus bank_app/BankAppPass123@freepdb1 < sql/sharding/08-create-dashboard-views.sql
```

## Connection Examples

### Connect to Catalog
```