"""
Response formatting utilities
Converts database cursor results to JSON-friendly dictionaries
"""

from datetime import datetime

def cursor_to_dict(cursor, row=None):
    """
    Convert a single database row to a dictionary with lowercase keys
    
    Args:
        cursor: Database cursor with executed query
        row: Optional row tuple. If None, fetches one row from cursor
    
    Returns:
        dict: Dictionary with lowercase keys and formatted values
    """
    if row is None:
        row = cursor.fetchone()
        if row is None:
            return {}
    
    columns = [desc[0] for desc in cursor.description]
    result = {}
    
    for i, col in enumerate(columns):
        key = col.lower()
        value = row[i]
        
        # Format datetime values
        if isinstance(value, datetime):
            result[key] = value.strftime('%Y-%m-%d %H:%M:%S')
        # Convert numeric values
        elif isinstance(value, (int, float)) and value is not None:
            result[key] = float(value)
        else:
            result[key] = value
    
    return result

def cursor_to_dicts(cursor, fetch_all=True):
    """
    Convert database cursor results to a list of dictionaries with lowercase keys
    
    Args:
        cursor: Database cursor with executed query
        fetch_all (bool): If True, fetch all rows. If False, only fetch one row
    
    Returns:
        list: List of dictionaries with lowercase keys and formatted values
    """
    columns = [desc[0] for desc in cursor.description]
    results = []
    
    if fetch_all:
        rows = cursor.fetchall()
    else:
        row = cursor.fetchone()
        rows = [row] if row else []
    
    for row in rows:
        row_dict = {}
        for i, col in enumerate(columns):
            key = col.lower()
            value = row[i]
            
            # Format datetime values
            if isinstance(value, datetime):
                row_dict[key] = value.strftime('%Y-%m-%d %H:%M:%S')
            # Convert numeric values
            elif isinstance(value, (int, float)) and value is not None:
                row_dict[key] = float(value)
            else:
                row_dict[key] = value
        
        results.append(row_dict)
    
    return results

def format_balance(value):
    """
    Format balance value to float
    
    Args:
        value: Balance value to format
    
    Returns:
        float: Formatted balance or None
    """
    if value is None:
        return None
    return float(value)

def format_account_count(value):
    """
    Format account count value to int
    
    Args:
        value: Account count value to format
    
    Returns:
        int: Formatted count or 0
    """
    if value is None:
        return 0
    return int(value)

