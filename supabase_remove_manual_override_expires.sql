-- Migration: remove manual_override_expires column from restaurants
-- WARNING: This is destructive. Run only after you have backed up your data.
-- Steps recommended:
-- 1) Backup table: CREATE TABLE restaurants_backup AS SELECT * FROM restaurants;
-- 2) Review restaurant_open_history for any references to expires_at if you need to keep them.

BEGIN;

-- Clear any existing values (optional but ensures no leftover data)
UPDATE restaurants SET manual_override_expires = NULL WHERE manual_override_expires IS NOT NULL;

-- Drop index if it exists (example name used earlier)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE c.relname = 'idx_restaurants_manual_override_expires') THEN
    EXECUTE 'DROP INDEX IF EXISTS idx_restaurants_manual_override_expires';
  END IF;
END$$;

-- Finally drop the column
ALTER TABLE restaurants DROP COLUMN IF EXISTS manual_override_expires;

COMMIT;

-- Note: This migration removes only the expiry column. The manual override flag
-- (`is_open_manual`) and audit table (`restaurant_open_history`) are unchanged.
