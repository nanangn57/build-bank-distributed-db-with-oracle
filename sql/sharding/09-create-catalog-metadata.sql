-- Create Catalog Metadata Tables
-- Run as bank_app user on CATALOG database only
-- Catalog should only contain metadata/routing information, NOT application data

PROMPT ====================================
PROMPT Creating Catalog Metadata Tables
PROMPT Note: Catalog database stores metadata only, not application data
PROMPT ====================================

WHENEVER SQLERROR EXIT SQL.SQLCODE
WHENEVER OSERROR EXIT FAILURE

CONNECT bank_app/BankAppPass123@freepdb1

-- Shard routing metadata table
-- This table tracks which shard handles which user_id ranges
CREATE TABLE shard_routing_metadata (
    shard_id NUMBER PRIMARY KEY,
    shard_name VARCHAR2(50) NOT NULL,
    region VARCHAR2(50) NOT NULL,
    user_id_range_start NUMBER NOT NULL,
    user_id_range_end NUMBER NOT NULL,
    connection_string VARCHAR2(200),
    hostname VARCHAR2(100),
    port NUMBER,
    status VARCHAR2(20) DEFAULT 'ACTIVE',
    created_date DATE DEFAULT SYSDATE,
    last_updated DATE DEFAULT SYSDATE,
    CONSTRAINT chk_shard_region CHECK (region IN ('NA', 'EU', 'APAC')),
    CONSTRAINT chk_shard_status CHECK (status IN ('ACTIVE', 'INACTIVE', 'MAINTENANCE'))
);

-- Insert shard routing information
INSERT INTO shard_routing_metadata (
    shard_id, shard_name, region, user_id_range_start, user_id_range_end,
    hostname, port, status
) VALUES (
    1, 'oracle-shard1', 'NA', 1, 10000000,
    'oracle-shard1', 1521, 'ACTIVE'
);

INSERT INTO shard_routing_metadata (
    shard_id, shard_name, region, user_id_range_start, user_id_range_end,
    hostname, port, status
) VALUES (
    2, 'oracle-shard2', 'EU', 10000001, 20000000,
    'oracle-shard2', 1521, 'ACTIVE'
);

INSERT INTO shard_routing_metadata (
    shard_id, shard_name, region, user_id_range_start, user_id_range_end,
    hostname, port, status
) VALUES (
    3, 'oracle-shard3', 'APAC', 20000001, 30000000,
    'oracle-shard3', 1521, 'ACTIVE'
);

COMMIT;

-- Function to determine which shard a user_id belongs to
CREATE OR REPLACE FUNCTION get_shard_for_user(p_user_id NUMBER) RETURN NUMBER AS
    v_shard_id NUMBER;
BEGIN
    SELECT shard_id INTO v_shard_id
    FROM shard_routing_metadata
    WHERE p_user_id >= user_id_range_start
      AND p_user_id <= user_id_range_end
      AND status = 'ACTIVE'
      AND ROWNUM = 1;
    
    RETURN v_shard_id;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
END;
/

-- Function to get shard connection info for a region
CREATE OR REPLACE FUNCTION get_shard_for_region(p_region VARCHAR2) RETURN NUMBER AS
    v_shard_id NUMBER;
BEGIN
    SELECT shard_id INTO v_shard_id
    FROM shard_routing_metadata
    WHERE region = UPPER(p_region)
      AND status = 'ACTIVE'
      AND ROWNUM = 1;
    
    RETURN v_shard_id;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
END;
/

-- View to show shard routing information
CREATE OR REPLACE VIEW shard_routing_view AS
SELECT 
    shard_id,
    shard_name,
    region,
    user_id_range_start,
    user_id_range_end,
    hostname,
    port,
    status,
    (user_id_range_end - user_id_range_start + 1) AS id_range_size
FROM shard_routing_metadata
ORDER BY shard_id;

COMMIT;

PROMPT ====================================
PROMPT Catalog metadata created successfully!
PROMPT ====================================
PROMPT
PROMPT Metadata tables:
PROMPT   - shard_routing_metadata: Shard routing information
PROMPT   - shard_routing_view: View of shard routing
PROMPT   - get_shard_for_user(): Function to get shard for user_id
PROMPT   - get_shard_for_region(): Function to get shard for region
PROMPT
PROMPT Note: Catalog database contains metadata only, no application data
PROMPT Application data (users, accounts, transactions) stored on shards only
PROMPT ====================================

