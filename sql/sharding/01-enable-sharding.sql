-- Enable Sharding on Database
-- Run this on the catalog database first
-- Usage: Run as SYS user

PROMPT ====================================
PROMPT Enabling Oracle Sharding
PROMPT ====================================

-- Enable sharding on the database
ALTER DATABASE ENABLE SHARDING;

-- Set global names for distributed operations
ALTER SYSTEM SET GLOBAL_NAMES = TRUE;

-- Configure distributed lock timeout
ALTER SYSTEM SET DISTRIBUTED_LOCK_TIMEOUT = 60;

-- Enable shard DDL mode for the session (needed for creating sharded tables)
ALTER SESSION ENABLE SHARD DDL;

-- Verify sharding is enabled
SELECT 
    name,
    value,
    CASE 
        WHEN name = 'global_names' AND value = 'TRUE' THEN '✅ Enabled'
        ELSE ''
    END AS status
FROM v$parameter 
WHERE name IN ('global_names', 'distributed_lock_timeout');

PROMPT ====================================
PROMPT Sharding enabled successfully!
PROMPT ====================================

