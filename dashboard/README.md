# Bank Transaction Dashboard

Real-time web dashboard for monitoring Oracle Sharding bank transaction system.

## Features

- **Real-time Statistics**: Auto-refreshing statistics showing:
  - Total users, accounts, transactions
  - Regional breakdown (NA, EU, APAC)
  - Total balance and averages
- **Insert Records**: Add new users, accounts, and transactions
- **Recent Transactions**: View latest transactions
- **Auto-refresh**: Configurable auto-refresh (3-30 seconds)

## Quick Start

```bash
# From project root
./dashboard/start-dashboard.sh
```

Dashboard will be available at: **http://localhost:5000**

## Manual Setup

```bash
cd dashboard
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python3 app.py
```

## Configuration

The dashboard connects to Oracle database using environment variables:
- `DB_HOST`: Database host (default: localhost)
- `DB_PORT`: Database port (default: 1521)
- `DB_SERVICE_NAME`: Service name (default: FREEPDB1)
- `DB_USER`: Database user (default: bank_app)
- `DB_PASSWORD`: Database password (default: BankAppPass123)

Or set these in a `.env` file in the project root.

## API Endpoints

- `GET /api/stats/regional` - Regional statistics
- `GET /api/stats/overall` - Overall statistics
- `GET /api/transactions/recent` - Recent transactions
- `GET /api/users` - List all users
- `GET /api/accounts` - List all accounts
- `POST /api/insert/user` - Insert new user
- `POST /api/insert/account` - Insert new account
- `POST /api/insert/transaction` - Execute transaction

## Troubleshooting

### "Database connection failed"
- Ensure Oracle container is running: `docker ps | grep oracle-catalog`
- Check database credentials in `.env` file
- Verify database is ready: `docker logs oracle-catalog | grep "READY"`

### "Module cx_Oracle not found"
- Run: `pip install cx_Oracle` or use the start script which installs it automatically

### Dashboard not refreshing
- Check browser console for errors
- Verify API endpoints are accessible: `curl http://localhost:5000/api/stats/overall`
- Check Flask server logs

