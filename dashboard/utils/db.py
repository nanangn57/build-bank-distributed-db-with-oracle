"""
Database connection utilities
Handles connections to catalog and shard databases
"""

import os
try:
    import oracledb
    # Use python-oracledb (thick mode is optional, works in thin mode without Oracle Client)
except ImportError:
    # Fallback to cx_Oracle if oracledb not available
    import cx_Oracle as oracledb

# Normalize service name (Oracle service names are case-sensitive)
_default_service = os.getenv('DB_SERVICE_NAME', 'freepdb1')
if _default_service:
    _default_service = _default_service.strip()
service_normalized = _default_service.lower()

# Database configuration
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'port': os.getenv('DB_PORT', '1521'),
    'service_name': service_normalized,
    'user': os.getenv('DB_USER', 'bank_app'),
    'password': os.getenv('DB_PASSWORD', 'BankAppPass123')
}

def get_db_connection(shard_region=None):
    """
    Create and return database connection
    If shard_region is provided, connects to the appropriate shard:
    - 'NA' -> oracle-shard1 (or localhost:1522 when not in Docker)
    - 'EU' -> oracle-shard2 (or localhost:1523 when not in Docker)
    - 'APAC' -> oracle-shard3 (or localhost:1524 when not in Docker)
    If shard_region is None, connects to catalog (for SELECT queries via union views)
    
    Args:
        shard_region (str, optional): Region to connect to ('NA', 'EU', 'APAC')
    
    Returns:
        Connection object or None if connection fails
    """
    is_docker = os.path.exists('/.dockerenv')
    
    try:
        # Use oracledb (works in thin mode without Oracle Client)
        if shard_region:
            # Connect to specific shard based on region
            region_upper = shard_region.upper()
            
            if is_docker:
                # Inside Docker: use Docker hostnames and internal port 1521
                shard_map = {
                    'NA': ('oracle-shard1', 1521),
                    'EU': ('oracle-shard2', 1521),
                    'APAC': ('oracle-shard3', 1521)
                }
            else:
                # Outside Docker: use localhost with mapped ports
                shard_map = {
                    'NA': ('localhost', 1522),   # Shard 1 mapped to 1522
                    'EU': ('localhost', 1523),   # Shard 2 mapped to 1523
                    'APAC': ('localhost', 1524)  # Shard 3 mapped to 1524
                }
            
            host_port = shard_map.get(region_upper)
            if not host_port:
                raise ValueError(f"Invalid region: {shard_region}. Must be NA, EU, or APAC")
            
            host, port = host_port
            print(f"Connecting to shard for region {region_upper} at {host}:{port}")
        else:
            # Connect to catalog (for SELECT queries via union views)
            if is_docker:
                host = 'oracle-catalog'
                port = 1521
            else:
                host = DB_CONFIG['host']  # Default: localhost
                port = DB_CONFIG['port']    # Default: 1521
            print(f"Connecting to catalog at {host}:{port}")
        
        # Create connection string
        dsn = oracledb.makedsn(
            host,
            port,
            service_name=DB_CONFIG['service_name']
        )
        
        # oracledb.connect can use dsn as positional or keyword argument
        connection = oracledb.connect(
            user=DB_CONFIG['user'],
            password=DB_CONFIG['password'],
            dsn=dsn
        )
        print(f"Successfully connected to database at {host}:{port}")
        return connection
    except Exception as e:
        print(f"Database connection error: {e}")
        if 'host' in locals() and 'port' in locals():
            print(f"Attempted connection to: {host}:{port}/{DB_CONFIG['service_name']}")
        import traceback
        traceback.print_exc()
        return None

def get_user_id_by_username(username):
    """
    Look up user_id by username (query directly to shards since user_id removed from views)
    
    Args:
        username (str): Username to look up
    
    Returns:
        dict: User info with 'user_id', 'region', 'shard_location', or None if not found
    """
    # Try each shard to find the user
    for region in ['NA', 'EU', 'APAC']:
        conn = get_db_connection(shard_region=region)
        if not conn:
            continue
        
        try:
            cursor = conn.cursor()
            cursor.execute("""
                SELECT user_id, region 
                FROM users 
                WHERE username = :username
                FETCH FIRST 1 ROWS ONLY
            """, {'username': username})
            user_row = cursor.fetchone()
            cursor.close()
            conn.close()
            
            if user_row:
                return {
                    'user_id': user_row[0],
                    'region': user_row[1].upper(),
                    'shard_location': f'SHARD{["NA", "EU", "APAC"].index(region.upper()) + 1}'
                }
        except Exception as e:
            print(f"Error looking up user by username in {region}: {e}")
            if conn:
                try:
                    conn.close()
                except:
                    pass
    
    return None

def get_user_region(user_id):
    """
    Look up user's region from catalog database (user_id is globally unique)
    
    Args:
        user_id (int): User ID to look up
    
    Returns:
        str: Region ('NA', 'EU', 'APAC') or None if user not found
    """
    conn = get_db_connection()
    if not conn:
        return None
    
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT region FROM users_all WHERE user_id = :user_id", {'user_id': user_id})
        user_row = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if user_row:
            return user_row[0].upper()
        return None
    except Exception as e:
        print(f"Error looking up user region: {e}")
        if conn:
            try:
                conn.close()
            except:
                pass
        return None

def get_account_region(account_id):
    """
    Look up account's region from catalog database
    WARNING: account_id is not globally unique across shards!
    Use get_account_info_by_number() instead for reliable lookups.
    
    Args:
        account_id (int): Account ID to look up
    
    Returns:
        str: Region ('NA', 'EU', 'APAC') or None if account not found
    """
    conn = get_db_connection()
    if not conn:
        return None
    
    try:
        cursor = conn.cursor()
        # Note: account_id is not globally unique, so we might get multiple results
        # We'll take the first one, but this is not reliable!
        cursor.execute("""
            SELECT region, shard_location 
            FROM accounts_all 
            WHERE account_id = :account_id 
            ORDER BY shard_location
            FETCH FIRST 1 ROWS ONLY
        """, {'account_id': account_id})
        account_row = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if account_row:
            return account_row[0].upper()
        return None
    except Exception as e:
        print(f"Error looking up account region: {e}")
        if conn:
            try:
                conn.close()
            except:
                pass
        return None

def get_account_info_by_number(account_number):
    """
    Look up account information by account_number (which is globally unique)
    
    Args:
        account_number (str): Account number to look up
    
    Returns:
        dict: Account info with 'account_number', 'region', 'shard_location', or None if not found
    """
    conn = get_db_connection()
    if not conn:
        return None
    
    try:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT account_number, region, shard_location 
            FROM accounts_all 
            WHERE account_number = :account_number
            FETCH FIRST 1 ROWS ONLY
        """, {'account_number': account_number})
        account_row = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if account_row:
            return {
                'account_number': account_row[0],
                'region': account_row[1].upper(),
                'shard_location': account_row[2]
            }
        return None
    except Exception as e:
        print(f"Error looking up account by number: {e}")
        if conn:
            try:
                conn.close()
            except:
                pass
        return None

def get_account_id_by_number(account_number):
    """
    Look up account_id by account_number (which is globally unique)
    NOTE: account_id is not globally unique and is not in accounts_all view.
    This function queries directly from the shard to get account_id if needed.
    
    Args:
        account_number (str): Account number to look up
    
    Returns:
        int: Account ID or None if not found
    """
    # First get region to know which shard to query
    account_info = get_account_info_by_number(account_number)
    if not account_info:
        return None
    
    region = account_info['region']
    conn = get_db_connection(shard_region=region)
    if not conn:
        return None
    
    try:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT account_id 
            FROM accounts 
            WHERE account_number = :account_number
            FETCH FIRST 1 ROWS ONLY
        """, {'account_number': account_number})
        account_row = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if account_row:
            return account_row[0]
        return None
    except Exception as e:
        print(f"Error looking up account_id by number: {e}")
        if conn:
            try:
                conn.close()
            except:
                pass
        return None

