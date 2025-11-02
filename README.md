# Build Bank Distributed Database with Oracle Sharding

Project to build a distributed database supporting transactions for banks using Oracle Sharding.

## Overview

This project implements Oracle Sharding for a bank transaction system, demonstrating:
- **Distributed Data Storage**: Accounts and transactions sharded across multiple database instances
- **Cross-Shard Transactions**: Money transfers between accounts on different shards
- **Automatic Routing**: Queries automatically routed to correct shards
- **High Availability**: Data distributed across 3 shards for scalability
- **Real-Time Analytics**: Aggregation queries across all shards

## Architecture

### Sharding Configuration

```
┌─────────────────────────────────────────┐
│      Shard Catalog (Central Metadata)   │
│         oracle-catalog:1521              │
└─────────────────────────────────────────┘
           │        │        │
    ┌──────┘        │        └──────┐
    │               │               │
┌───▼───┐      ┌───▼───┐      ┌───▼───┐
│Shard 1│      │Shard 2│      │Shard 3│
│ (NA)  │      │ (EU)  │      │(APAC) │
│1522   │      │1523   │      │1524   │
└───────┘      └───────┘      └───────┘
```

### Table Distribution Strategy

1. **Users Table**: DUPLICATED across all shards (for local joins)
2. **Accounts Table**: SHARDED by `account_id` using consistent hash
3. **Transactions Table**: SHARDED and co-located with accounts (stored on same shard as source account)

### Shard Distribution

- **Shard 1 (North America)**: Handles accounts and transactions for NA region
- **Shard 2 (Europe)**: Handles accounts and transactions for EU region
- **Shard 3 (Asia Pacific)**: Handles accounts and transactions for APAC region

## Prerequisites

- Docker Desktop installed and running
- Oracle Container Registry account (free)
- At least 16GB RAM available for containers (4GB per database)
- Oracle Database Free image pulled

## Quick Start

### 1. Setup Environment

```bash
# Create .env file from template (if not exists)
cp .env.example .env

# Edit .env file with your passwords
nano .env
```

### 2. Start Sharding Infrastructure

```bash
# Make scripts executable
chmod +x docker/*.sh scripts/*.sh

# Start all containers (catalog + 3 shards)
./docker/start-sharding.sh
```

**Wait 2-5 minutes** for all databases to initialize.

### 3. Verify Containers

```bash
# Check container status
docker-compose -f docker-compose-sharding.yml ps

# Check logs
docker-compose -f docker-compose-sharding.yml logs -f
```

### 4. Setup Sharding

```bash
# Run complete sharding setup
./scripts/setup-sharding.sh
```

This script will:
- Enable sharding on all databases
- Create shard catalog user
- Create bank application user
- Create sharded tables
- Insert sample data
- Create stored procedures

### 5. Test Sharding

```bash
# Run tests
./scripts/test-sharding.sh

# Run use case demonstrations
./scripts/run-use-cases.sh
```

## Use Cases Demonstrated

### 1. Automatic Shard Routing
Queries automatically route to the correct shard based on sharding key (account_id)

```sql
SELECT * FROM accounts WHERE account_id = 5000000;
-- Automatically routes to correct shard
```

### 2. Cross-Shard Money Transfer
Transfer money between accounts on different shards with ACID guarantees

```sql
EXEC transfer_money(5000000, 15000000, 250.00, 'Cross-shard transfer');
```

### 3. Multi-Shard Aggregation
Query and aggregate data from all shards automatically

```sql
SELECT region, COUNT(*), SUM(balance) 
FROM accounts 
GROUP BY region;
```

### 4. High-Volume Transaction Processing
Process thousands of transactions in parallel across shards

### 5. Real-Time Analytics
Cross-shard analytics queries for business intelligence

### 6. Geographic Data Distribution
Data stored close to where it's accessed (region-based sharding)

## Project Structure

```
build-bank-distributed-db-with-oracle/
├── docker-compose-sharding.yml    # Multi-instance Docker setup
├── docker/
│   ├── start-sharding.sh         # Start all shards
│   ├── stop-sharding.sh          # Stop all shards
│   └── ...
├── sql/
│   └── sharding/
│       ├── 01-enable-sharding.sql          # Enable sharding
│       ├── 02-create-shard-catalog-user.sql # Catalog user
│       ├── 03-create-bank-app-user.sql      # Application user
│       ├── 04-create-sharded-tables.sql     # Sharded tables
│       ├── 05-insert-sample-data.sql       # Sample data
│       ├── 06-create-procedures.sql        # Stored procedures
│       └── 07-use-cases.sql                # Use case demos
├── scripts/
│   ├── setup-sharding.sh          # Complete setup script
│   ├── test-sharding.sh           # Test sharding setup
│   └── run-use-cases.sh           # Run use cases
└── README.md
```

## Database Schema

### Users Table (DUPLICATED)
- `user_id`: Primary key
- `username`, `email`, `full_name`
- `region`: Routing key ('NA', 'EU', 'APAC')

### Accounts Table (SHARDED)
- `account_id`: Primary key (sharding key)
- `user_id`: Foreign key to users
- `account_number`, `account_type`
- `balance`: Account balance
- `region`: Geographic region

### Transactions Table (SHARDED)
- `transaction_id`: Primary key
- `from_account_id`, `to_account_id`: Foreign keys
- `transaction_type`: DEPOSIT, WITHDRAWAL, TRANSFER, FEE
- `amount`: Transaction amount
- `status`: PENDING, COMPLETED, FAILED
- Co-located with accounts table

## Connection Details

### Catalog Database
- **Host**: `localhost` (or `oracle-catalog` from within network)
- **Port**: `1521`
- **Service**: `FREEPDB1`
- **Users**: 
  - `sys` / (from .env ORACLE_PWD)
  - `bank_app` / (from .env BANK_APP_PASSWORD)

### Shard Databases
- **Shard 1**: `localhost:1522`
- **Shard 2**: `localhost:1523`
- **Shard 3**: `localhost:1524`

### JDBC Connection Strings
```properties
JDBC_URL_CATALOG=jdbc:oracle:thin:@localhost:1521/FREEPDB1
JDBC_URL_SHARD1=jdbc:oracle:thin:@localhost:1522/FREEPDB1
JDBC_URL_SHARD2=jdbc:oracle:thin:@localhost:1523/FREEPDB1
JDBC_URL_SHARD3=jdbc:oracle:thin:@localhost:1524/FREEPDB1
```

## Web Interfaces

Access Oracle Enterprise Manager Express:

- **Catalog**: https://localhost:5500/em
- **Shard 1**: https://localhost:5501/em
- **Shard 2**: https://localhost:5502/em
- **Shard 3**: https://localhost:5503/em

Login:
- Username: `sys`
- Password: (from .env file ORACLE_PWD)
- Login as: `SYSDBA`

## Manual SQL Access

```bash
# Connect to catalog
docker exec -it oracle-catalog sqlplus bank_app/BankAppPass123@FREEPDB1

# Connect to shard 1
docker exec -it oracle-shard1 sqlplus bank_app/BankAppPass123@FREEPDB1

# Connect as sys
docker exec -it oracle-catalog sqlplus sys/tuPDqNJWLr7QcA@FREEPDB1 as sysdba
```

## Stored Procedures

### `transfer_money(from_account_id, to_account_id, amount, description)`
Transfer money between accounts (handles cross-shard automatically)

### `deposit_money(to_account_id, amount, description)`
Deposit money to an account

### `withdraw_money(from_account_id, amount, description)`
Withdraw money from an account

### `get_account_balance(account_id)`
Get current account balance

## Management Commands

### Start All Shards
```bash
./docker/start-sharding.sh
# or
docker-compose -f docker-compose-sharding.yml up -d
```

### Stop All Shards
```bash
./docker/stop-sharding.sh
# or
docker-compose -f docker-compose-sharding.yml stop
```

### View Logs
```bash
# All containers
docker-compose -f docker-compose-sharding.yml logs -f

# Specific container
docker logs -f oracle-catalog
docker logs -f oracle-shard1
```

### Remove Containers
```bash
# Stop and remove containers (keeps data)
docker-compose -f docker-compose-sharding.yml down

# Remove containers and volumes (deletes data!)
docker-compose -f docker-compose-sharding.yml down -v
```

## Troubleshooting

### Containers Won't Start
- Ensure Docker Desktop is running
- Check available memory (need ~16GB total)
- Verify ports are not in use
- Check logs: `docker-compose -f docker-compose-sharding.yml logs`

### Database Connection Errors
- Wait 2-5 minutes after container start for initialization
- Check logs for "DATABASE IS READY TO USE!" message
- Verify passwords in .env file match container environment

### Sharding Setup Fails
- Ensure all databases are fully initialized before running setup
- Check that sharding packages are available (DBMS_GSM_*)
- Verify network connectivity between containers
- Check container logs for errors

### ARM Mac Issues
- Oracle Database runs via x86_64 emulation on ARM Macs
- Use `--cap-add=CAP_SYS_NICE` (already configured)
- May be slower than native x86_64

## Features Demonstrated

✅ **Automatic Shard Routing**: Queries route to correct shard automatically  
✅ **Cross-Shard Transactions**: ACID-compliant transactions across shards  
✅ **Multi-Shard Aggregation**: Query data from all shards simultaneously  
✅ **Co-located Data**: Transactions stored on same shard as accounts  
✅ **Duplicated Tables**: Users table duplicated for local joins  
✅ **High Scalability**: Horizontal scaling across multiple shards  
✅ **Real-Time Analytics**: Cross-shard analytics queries  

## Next Steps

1. **Add More Shards**: Scale horizontally by adding more shard instances
2. **Configure Replication**: Set up shard replicas for high availability
3. **Optimize Sharding Keys**: Adjust distribution based on access patterns
4. **Monitor Performance**: Use Enterprise Manager to monitor shard performance
5. **Load Testing**: Test with high-volume transactions

## Resources

- [Oracle Sharding Documentation](https://docs.oracle.com/en/database/oracle/oracle-database/23/shard/)
- [Oracle Database Free Edition](https://www.oracle.com/database/free/)
- [Oracle Container Registry](https://container-registry.oracle.com/)

## Dashboard

A real-time web dashboard is available to monitor statistics and insert new records.

### Start Dashboard

```bash
# Start the dashboard server
./dashboard/start-dashboard.sh
```

The dashboard will be available at: **http://localhost:5000**

### Dashboard Features

- **Real-time Statistics**: Auto-refreshing statistics by region and overall totals
- **Regional Breakdown**: View users, accounts, and transactions by region (NA, EU, APAC)
- **Insert Records**: Add new users, accounts, and transactions directly from the dashboard
- **Recent Transactions**: View the latest 20 transactions
- **Auto-refresh**: Automatically updates every 3-30 seconds (configurable)

### Dashboard Views

The following SQL views are created for the dashboard:
- `dashboard_regional_stats`: Statistics broken down by region
- `dashboard_overall_stats`: Overall totals across all regions
- `dashboard_recent_transactions`: Recent transaction list
- `dashboard_accounts_by_region`: Account breakdown by region and type
- `dashboard_transactions_by_date`: Transaction volume by date

### Prerequisites for Dashboard

- Python 3 installed
- Oracle Database container running
- `cx_Oracle` Python library (installed automatically by start script)

### Manual Setup

If you prefer to install dependencies manually:

```bash
cd dashboard
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python3 app.py
```

## License

[Your License Here]
