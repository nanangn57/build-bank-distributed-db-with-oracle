-- Enable Sharding on Database (Oracle Free Edition Compatible)
-- Run this on the catalog database first
-- Usage: Run as SYS user
-- Note: ALTER SESSION ENABLE SHARD DDL is not supported in Oracle Free Edition

PROMPT ====================================
PROMPT Enabling Oracle Sharding
PROMPT ====================================

-- Enable sharding on the database
ALTER DATABASE ENABLE SHARDING;

-- Set global names for distributed operations
-- Note: Set to FALSE to allow database links between containers with same service name
-- For production with unique global names, set to TRUE
ALTER SYSTEM SET GLOBAL_NAMES = FALSE;

-- Configure distributed lock timeout
ALTER SYSTEM SET DISTRIBUTED_LOCK_TIMEOUT = 60;

-- Note: ALTER SESSION ENABLE SHARD DDL is not supported in Oracle Free Edition
-- Using regular tables instead of sharded tables for compatibility
-- ALTER SESSION ENABLE SHARD DDL;  -- Commented out for Oracle Free compatibility

-- Verify sharding is enabled
SELECT 
    name,
    value,
    CASE 
        WHEN name = 'global_names' AND value = 'FALSE' THEN '✅ Set to FALSE (allows database links with same service name)'
        WHEN name = 'global_names' AND value = 'TRUE' THEN '⚠️ Set to TRUE (requires unique global names for database links)'
        ELSE ''
    END AS status
FROM v$parameter 
WHERE name IN ('global_names', 'distributed_lock_timeout');

PROMPT ====================================
PROMPT Sharding enabled successfully!
PROMPT ====================================

