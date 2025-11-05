-- Migration: Fix sequence for menu_items.id
-- Use this when you see errors like:
-- ERROR: duplicate key value violates unique constraint "menu_items_pkey"
-- Key (id)=(11) already exists.
--
-- What it does:
-- 1) Finds the sequence backing menu_items.id
-- 2) Sets the sequence's last_value to the current MAX(id) in the table
--    so subsequent nextval() calls will produce values > current max.
--
-- How to run:
-- - Supabase SQL editor: open the SQL editor and paste/run this file.
-- - Or with psql (PowerShell):
--   psql "postgresql://<POSTGRES_USER>:<PASSWORD>@<HOST>:5432/postgres" -f migrations/20251106_fix_menu_items_sequence.sql
-- Running as the DB owner or a privileged user is recommended.

BEGIN;

-- Get the sequence name and set it to max(id)
DO $$
DECLARE
  seq_name text;
  max_id bigint;
BEGIN
  SELECT pg_get_serial_sequence('menu_items', 'id') INTO seq_name;
  IF seq_name IS NULL THEN
    RAISE NOTICE 'No serial sequence found for menu_items.id. Skipping.';
    RETURN;
  END IF;

  SELECT COALESCE(MAX(id), 0) INTO max_id FROM menu_items;

  -- Set the sequence last_value to max_id and mark it as called so nextval() returns max_id+1
  EXECUTE format('SELECT setval(%L, %s, true);', seq_name, max_id);
  RAISE NOTICE 'Sequence % set to %', seq_name, max_id;
END$$;

COMMIT;

-- End migration
