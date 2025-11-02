-- Create Stored Procedures for Bank Transactions
-- Run as bank_app user
-- Includes cross-shard transaction handling

PROMPT ====================================
PROMPT Creating Transaction Procedures
PROMPT ====================================

CONNECT bank_app/BankAppPass123@FREEPDB1

-- Procedure for transferring money between accounts
-- Automatically handles same-shard and cross-shard transfers
CREATE OR REPLACE PROCEDURE transfer_money(
    p_from_account_id NUMBER,
    p_to_account_id NUMBER,
    p_amount NUMBER,
    p_description VARCHAR2 DEFAULT NULL
) AS
    v_from_balance NUMBER;
    v_from_status VARCHAR2(10);
    v_to_status VARCHAR2(10);
BEGIN
    -- Check and lock from account (automatically routed to correct shard)
    SELECT balance, status INTO v_from_balance, v_from_status
    FROM accounts 
    WHERE account_id = p_from_account_id 
    FOR UPDATE;
    
    -- Validate account status
    IF v_from_status != 'ACTIVE' THEN
        RAISE_APPLICATION_ERROR(-20001, 'Source account is not active');
    END IF;
    
    -- Validate sufficient balance
    IF v_from_balance < p_amount THEN
        RAISE_APPLICATION_ERROR(-20002, 'Insufficient balance. Current balance: ' || v_from_balance);
    END IF;
    
    -- Check destination account exists and is active
    SELECT status INTO v_to_status
    FROM accounts
    WHERE account_id = p_to_account_id;
    
    IF v_to_status != 'ACTIVE' THEN
        RAISE_APPLICATION_ERROR(-20003, 'Destination account is not active');
    END IF;
    
    -- Deduct from source account (automatically routed to correct shard)
    UPDATE accounts 
    SET balance = balance - p_amount, 
        last_updated = SYSDATE 
    WHERE account_id = p_from_account_id;
    
    -- Add to destination account (automatically routed to correct shard)
    -- Oracle Sharding handles cross-shard transactions automatically
    UPDATE accounts 
    SET balance = balance + p_amount, 
        last_updated = SYSDATE 
    WHERE account_id = p_to_account_id;
    
    -- Create transaction record (on source account shard)
    INSERT INTO transactions (
        from_account_id,
        to_account_id,
        transaction_type,
        amount,
        status,
        description
    )
    VALUES (
        p_from_account_id,
        p_to_account_id,
        'TRANSFER',
        p_amount,
        'COMPLETED',
        p_description
    );
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Transfer completed successfully');
    DBMS_OUTPUT.PUT_LINE('From Account: ' || p_from_account_id || ', Amount: ' || p_amount);
    DBMS_OUTPUT.PUT_LINE('To Account: ' || p_to_account_id);
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20004, 'Account not found');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

-- Procedure for depositing money
CREATE OR REPLACE PROCEDURE deposit_money(
    p_to_account_id NUMBER,
    p_amount NUMBER,
    p_description VARCHAR2 DEFAULT NULL
) AS
    v_status VARCHAR2(10);
BEGIN
    -- Check account status
    SELECT status INTO v_status
    FROM accounts
    WHERE account_id = p_to_account_id;
    
    IF v_status != 'ACTIVE' THEN
        RAISE_APPLICATION_ERROR(-20001, 'Account is not active');
    END IF;
    
    -- Update account balance
    UPDATE accounts 
    SET balance = balance + p_amount,
        last_updated = SYSDATE
    WHERE account_id = p_to_account_id;
    
    -- Create transaction record
    INSERT INTO transactions (
        from_account_id,
        to_account_id,
        transaction_type,
        amount,
        status,
        description
    )
    VALUES (
        NULL,
        p_to_account_id,
        'DEPOSIT',
        p_amount,
        'COMPLETED',
        p_description
    );
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Deposit completed successfully');
    DBMS_OUTPUT.PUT_LINE('Account: ' || p_to_account_id || ', Amount: ' || p_amount);
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20002, 'Account not found');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

-- Procedure for withdrawing money
CREATE OR REPLACE PROCEDURE withdraw_money(
    p_from_account_id NUMBER,
    p_amount NUMBER,
    p_description VARCHAR2 DEFAULT NULL
) AS
    v_balance NUMBER;
    v_status VARCHAR2(10);
BEGIN
    -- Check and lock account
    SELECT balance, status INTO v_balance, v_status
    FROM accounts
    WHERE account_id = p_from_account_id
    FOR UPDATE;
    
    IF v_status != 'ACTIVE' THEN
        RAISE_APPLICATION_ERROR(-20001, 'Account is not active');
    END IF;
    
    IF v_balance < p_amount THEN
        RAISE_APPLICATION_ERROR(-20002, 'Insufficient balance. Current balance: ' || v_balance);
    END IF;
    
    -- Update account balance
    UPDATE accounts
    SET balance = balance - p_amount,
        last_updated = SYSDATE
    WHERE account_id = p_from_account_id;
    
    -- Create transaction record
    INSERT INTO transactions (
        from_account_id,
        to_account_id,
        transaction_type,
        amount,
        status,
        description
    )
    VALUES (
        p_from_account_id,
        NULL,
        'WITHDRAWAL',
        p_amount,
        'COMPLETED',
        p_description
    );
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Withdrawal completed successfully');
    DBMS_OUTPUT.PUT_LINE('Account: ' || p_from_account_id || ', Amount: ' || p_amount);
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20003, 'Account not found');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

-- Function to get account balance
CREATE OR REPLACE FUNCTION get_account_balance(
    p_account_id NUMBER
) RETURN NUMBER AS
    v_balance NUMBER;
BEGIN
    SELECT balance INTO v_balance
    FROM accounts
    WHERE account_id = p_account_id;
    
    RETURN v_balance;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
END;
/

-- View for account summary
CREATE OR REPLACE VIEW account_summary AS
SELECT 
    a.account_id,
    a.account_number,
    a.user_id,
    u.username,
    u.full_name,
    a.account_type,
    a.balance,
    a.currency,
    a.region,
    a.status,
    COUNT(t.transaction_id) AS transaction_count,
    MAX(t.transaction_date) AS last_transaction_date
FROM accounts a
JOIN users u ON a.user_id = u.user_id
LEFT JOIN transactions t ON a.account_id = t.from_account_id OR a.account_id = t.to_account_id
GROUP BY a.account_id, a.account_number, a.user_id, u.username, u.full_name,
         a.account_type, a.balance, a.currency, a.region, a.status;

PROMPT ====================================
PROMPT Procedures created successfully!
PROMPT ====================================
PROMPT
PROMPT Procedures:
PROMPT   - transfer_money: Transfer between accounts (handles cross-shard)
PROMPT   - deposit_money: Deposit to account
PROMPT   - withdraw_money: Withdraw from account
PROMPT   - get_account_balance: Get account balance
PROMPT ====================================

