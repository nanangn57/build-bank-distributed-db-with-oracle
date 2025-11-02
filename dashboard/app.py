#!/usr/bin/env python3
"""
Oracle Database Dashboard API
Provides REST API endpoints for dashboard statistics and data insertion
"""

from flask import Flask, jsonify, request, render_template
from flask_cors import CORS
try:
    import oracledb
    # Use python-oracledb (thick mode is optional, works in thin mode without Oracle Client)
except ImportError:
    # Fallback to cx_Oracle if oracledb not available
    import cx_Oracle as oracledb
import os
from datetime import datetime

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Database configuration
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'port': os.getenv('DB_PORT', '1521'),
    'service_name': os.getenv('DB_SERVICE_NAME', 'FREEPDB1'),
    'user': os.getenv('DB_USER', 'bank_app'),
    'password': os.getenv('DB_PASSWORD', 'BankAppPass123')
}

def get_db_connection():
    """Create and return database connection"""
    try:
        # Use oracledb (works in thin mode without Oracle Client)
        host = DB_CONFIG['host']
        
        # Create connection string
        dsn = oracledb.makedsn(
            host,
            DB_CONFIG['port'],
            service_name=DB_CONFIG['service_name']
        )
        
        # oracledb.connect can use dsn as positional or keyword argument
        connection = oracledb.connect(
            user=DB_CONFIG['user'],
            password=DB_CONFIG['password'],
            dsn=dsn
        )
        print(f"Successfully connected to database at {host}:{DB_CONFIG['port']}")
        return connection
    except Exception as e:
        print(f"Database connection error: {e}")
        print(f"Attempted connection to: {host}:{DB_CONFIG['port']}/{DB_CONFIG['service_name']}")
        import traceback
        traceback.print_exc()
        return None

@app.route('/')
def index():
    """Serve the dashboard HTML page"""
    return render_template('dashboard.html')

@app.route('/api/stats/regional', methods=['GET'])
def get_regional_stats():
    """Get statistics by region"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM dashboard_regional_stats")
        
        columns = [desc[0] for desc in cursor.description]
        results = []
        
        for row in cursor.fetchall():
            row_dict = {}
            # Convert to lowercase keys for consistency
            for i, col in enumerate(columns):
                key = col.lower()
                value = row[i]
                if isinstance(value, datetime):
                    row_dict[key] = value.strftime('%Y-%m-%d %H:%M:%S')
                elif isinstance(value, (int, float)) and value is not None:
                    row_dict[key] = float(value)
                else:
                    row_dict[key] = value
            results.append(row_dict)
        
        cursor.close()
        conn.close()
        
        return jsonify(results)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/stats/overall', methods=['GET'])
def get_overall_stats():
    """Get overall statistics"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed', 'details': 'Check database is running and connection settings'}), 500
    
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM dashboard_overall_stats")
        
        columns = [desc[0] for desc in cursor.description]
        row = cursor.fetchone()
        
        if row:
            result = {}
            # Convert to lowercase keys for consistency
            for i, col in enumerate(columns):
                key = col.lower()
                value = row[i]
                if isinstance(value, datetime):
                    result[key] = value.strftime('%Y-%m-%d %H:%M:%S')
                elif isinstance(value, (int, float)) and value is not None:
                    result[key] = float(value)
                else:
                    result[key] = value
        else:
            result = {}
        
        cursor.close()
        conn.close()
        
        return jsonify(result)
    except Exception as e:
        import traceback
        error_details = traceback.format_exc()
        print(f"Error in get_overall_stats: {error_details}")
        return jsonify({'error': str(e), 'details': error_details}), 500

@app.route('/api/transactions/recent', methods=['GET'])
def get_recent_transactions():
    """Get recent transactions"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM dashboard_recent_transactions")
        
        columns = [desc[0] for desc in cursor.description]
        results = []
        
        for row in cursor.fetchall():
            row_dict = {}
            # Convert to lowercase keys for consistency
            for i, col in enumerate(columns):
                key = col.lower()
                value = row[i]
                # Convert datetime to string if present
                if isinstance(value, datetime):
                    row_dict[key] = value.strftime('%Y-%m-%d %H:%M:%S')
                elif isinstance(value, (int, float)) and value is not None:
                    row_dict[key] = float(value)
                else:
                    row_dict[key] = value
            results.append(row_dict)
        
        cursor.close()
        conn.close()
        
        return jsonify(results)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/accounts/by-region', methods=['GET'])
def get_accounts_by_region():
    """Get accounts breakdown by region"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM dashboard_accounts_by_region")
        
        columns = [desc[0] for desc in cursor.description]
        results = []
        
        for row in cursor.fetchall():
            row_dict = {}
            # Convert to lowercase keys for consistency
            for i, col in enumerate(columns):
                key = col.lower()
                value = row[i]
                if isinstance(value, datetime):
                    row_dict[key] = value.strftime('%Y-%m-%d %H:%M:%S')
                elif isinstance(value, (int, float)) and value is not None:
                    row_dict[key] = float(value)
                else:
                    row_dict[key] = value
            results.append(row_dict)
        
        cursor.close()
        conn.close()
        
        return jsonify(results)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/transactions/by-date', methods=['GET'])
def get_transactions_by_date():
    """Get transaction volume by date"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM dashboard_transactions_by_date")
        
        columns = [desc[0] for desc in cursor.description]
        results = []
        
        for row in cursor.fetchall():
            row_dict = {}
            # Convert to lowercase keys for consistency
            for i, col in enumerate(columns):
                key = col.lower()
                value = row[i]
                if isinstance(value, datetime):
                    row_dict[key] = value.strftime('%Y-%m-%d %H:%M:%S')
                elif isinstance(value, (int, float)) and value is not None:
                    row_dict[key] = float(value)
                else:
                    row_dict[key] = value
            results.append(row_dict)
        
        cursor.close()
        conn.close()
        
        return jsonify(results)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/insert/user', methods=['POST'])
def insert_user():
    """Insert a new user"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        data = request.json
        cursor = conn.cursor()
        
        cursor.execute("""
            INSERT INTO users (user_id, username, email, full_name, phone, address, region)
            VALUES (user_seq.NEXTVAL, :username, :email, :full_name, :phone, :address, :region)
        """, {
            'username': data.get('username'),
            'email': data.get('email'),
            'full_name': data.get('full_name'),
            'phone': data.get('phone', None),
            'address': data.get('address', None),
            'region': data.get('region', 'NA')
        })
        
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({'success': True, 'message': 'User inserted successfully'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/insert/account', methods=['POST'])
def insert_account():
    """Insert a new account"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        data = request.json
        cursor = conn.cursor()
        
        cursor.execute("""
            INSERT INTO accounts (account_id, user_id, account_number, account_type, balance, currency, region)
            VALUES (account_seq.NEXTVAL, :user_id, :account_number, :account_type, :balance, :currency, :region)
        """, {
            'user_id': data.get('user_id'),
            'account_number': data.get('account_number'),
            'account_type': data.get('account_type'),
            'balance': data.get('balance', 0),
            'currency': data.get('currency', 'USD'),
            'region': data.get('region', 'NA')
        })
        
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({'success': True, 'message': 'Account inserted successfully'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/insert/transaction', methods=['POST'])
def insert_transaction():
    """Insert a new transaction"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        data = request.json
        print(f"Received transaction data: {data}")  # Debug log
        
        # Validate and clean data
        transaction_type = data.get('transaction_type')
        from_account_id = data.get('from_account_id')
        to_account_id = data.get('to_account_id')
        amount = data.get('amount')
        
        # Convert to appropriate types and handle None/empty
        if from_account_id and from_account_id != '':
            from_account_id = int(from_account_id)
        else:
            from_account_id = None
            
        if to_account_id and to_account_id != '':
            to_account_id = int(to_account_id)
        else:
            to_account_id = None
        
        if amount:
            amount = float(amount)
        
        # Validate required fields based on transaction type
        if transaction_type == 'TRANSFER':
            if not from_account_id or not to_account_id:
                return jsonify({'error': 'Transfer requires both from_account_id and to_account_id'}), 400
            if from_account_id == to_account_id:
                return jsonify({'error': 'Cannot transfer to the same account'}), 400
        elif transaction_type == 'DEPOSIT':
            if not to_account_id:
                return jsonify({'error': 'Deposit requires to_account_id'}), 400
            from_account_id = None
        elif transaction_type == 'WITHDRAWAL':
            if not from_account_id:
                return jsonify({'error': 'Withdrawal requires from_account_id'}), 400
            to_account_id = None
        
        cursor = conn.cursor()
        
        # Use stored procedures for all transaction types (handle balance updates automatically)
        try:
            if transaction_type == 'TRANSFER' and from_account_id and to_account_id:
                print(f"Calling transfer_money procedure: from={from_account_id}, to={to_account_id}, amount={amount}")
                cursor.callproc('transfer_money', [
                    from_account_id,
                    to_account_id,
                    amount,
                    data.get('description', '')
                ])
                conn.commit()
                cursor.close()
                conn.close()
                return jsonify({'success': True, 'message': 'Transfer completed successfully'})
            elif transaction_type == 'DEPOSIT' and to_account_id:
                print(f"Calling deposit_money procedure: to={to_account_id}, amount={amount}")
                cursor.callproc('deposit_money', [
                    to_account_id,
                    amount,
                    data.get('description', '')
                ])
                conn.commit()
                cursor.close()
                conn.close()
                return jsonify({'success': True, 'message': 'Deposit completed successfully'})
            elif transaction_type == 'WITHDRAWAL' and from_account_id:
                print(f"Calling withdraw_money procedure: from={from_account_id}, amount={amount}")
                cursor.callproc('withdraw_money', [
                    from_account_id,
                    amount,
                    data.get('description', '')
                ])
                conn.commit()
                cursor.close()
                conn.close()
                return jsonify({'success': True, 'message': 'Withdrawal completed successfully'})
            else:
                # Fallback for other transaction types or invalid combinations
                cursor.execute("""
                    INSERT INTO transactions (from_account_id, to_account_id, transaction_type, amount, status, description)
                    VALUES (:from_account_id, :to_account_id, :transaction_type, :amount, :status, :description)
                """, {
                    'from_account_id': from_account_id,
                    'to_account_id': to_account_id,
                    'transaction_type': transaction_type,
                    'amount': amount,
                    'status': data.get('status', 'COMPLETED'),
                    'description': data.get('description', '')
                })
                conn.commit()
                cursor.close()
                conn.close()
                return jsonify({'success': True, 'message': 'Transaction inserted successfully'})
        except Exception as proc_error:
            conn.rollback()
            print(f"Transaction procedure error: {proc_error}")
            error_msg = str(proc_error)
            # Extract error message if it's an Oracle error
            if hasattr(proc_error, 'args') and proc_error.args:
                error_msg = str(proc_error.args[0])
            cursor.close()
            conn.close()
            return jsonify({'error': f'Transaction failed: {error_msg}'}), 500
    except Exception as e:
        import traceback
        error_details = traceback.format_exc()
        print(f"Error in insert_transaction: {error_details}")
        if conn:
            try:
                conn.rollback()
                conn.close()
            except:
                pass
        return jsonify({'error': str(e), 'details': error_details}), 500

@app.route('/api/users', methods=['GET'])
def get_users():
    """Get all users for dropdown"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT user_id, username, full_name FROM users ORDER BY username")
        
        results = []
        for row in cursor.fetchall():
            results.append({
                'user_id': row[0],
                'username': row[1],
                'full_name': row[2]
            })
        
        cursor.close()
        conn.close()
        
        return jsonify(results)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/accounts', methods=['GET'])
def get_accounts():
    """Get all accounts for dropdown or list"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor()
        # Get accounts with user information for the list view
        cursor.execute("""
            SELECT 
                a.account_id,
                a.account_number,
                a.account_type,
                a.balance,
                a.currency,
                a.region,
                a.status,
                a.created_date,
                u.user_id,
                u.username,
                u.full_name
            FROM accounts a
            LEFT JOIN users u ON a.user_id = u.user_id
            ORDER BY a.account_id
        """)
        
        columns = [desc[0] for desc in cursor.description]
        results = []
        
        for row in cursor.fetchall():
            row_dict = {}
            # Convert to lowercase keys for consistency
            for i, col in enumerate(columns):
                key = col.lower()
                value = row[i]
                # Convert datetime to string if present
                if isinstance(value, datetime):
                    row_dict[key] = value.strftime('%Y-%m-%d %H:%M:%S')
                # Convert numeric values
                elif key == 'balance' and value is not None:
                    row_dict[key] = float(value)
                else:
                    row_dict[key] = value
            results.append(row_dict)
        
        cursor.close()
        conn.close()
        
        return jsonify(results)
    except Exception as e:
        import traceback
        print(f"Error in get_accounts: {traceback.format_exc()}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/users/list', methods=['GET'])
def get_users_list():
    """Get all users with full details for list view"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT 
                u.user_id,
                u.username,
                u.email,
                u.full_name,
                u.phone,
                u.address,
                u.region,
                u.created_date,
                COUNT(DISTINCT a.account_id) AS account_count,
                COALESCE(SUM(a.balance), 0) AS total_balance
            FROM users u
            LEFT JOIN accounts a ON u.user_id = a.user_id
            GROUP BY u.user_id, u.username, u.email, u.full_name, u.phone, u.address, u.region, u.created_date
            ORDER BY u.user_id
        """)
        
        columns = [desc[0] for desc in cursor.description]
        results = []
        
        for row in cursor.fetchall():
            row_dict = {}
            # Convert to lowercase keys for consistency
            for i, col in enumerate(columns):
                key = col.lower()
                value = row[i]
                # Convert datetime to string if present
                if isinstance(value, datetime):
                    row_dict[key] = value.strftime('%Y-%m-%d %H:%M:%S')
                # Convert numeric values
                elif key in ['account_count'] and value is not None:
                    row_dict[key] = int(value) if value else 0
                elif key == 'total_balance' and value is not None:
                    row_dict[key] = float(value)
                else:
                    row_dict[key] = value
            results.append(row_dict)
        
        cursor.close()
        conn.close()
        
        return jsonify(results)
    except Exception as e:
        import traceback
        print(f"Error in get_users_list: {traceback.format_exc()}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    # Check if running in Docker
    if os.path.exists('/.dockerenv'):
        DB_CONFIG['host'] = 'oracle-catalog'
    
    # Use port 5001 to avoid macOS AirPlay conflict on port 5000
    port = int(os.getenv('PORT', 5001))
    print(f"\n🚀 Starting Dashboard Server on http://localhost:{port}")
    print(f"📊 Dashboard will be available at: http://localhost:{port}")
    print(f"🔗 API endpoints available at: http://localhost:{port}/api/...\n")
    
    app.run(host='0.0.0.0', port=port, debug=True)

