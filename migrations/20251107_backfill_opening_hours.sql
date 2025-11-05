-- Migration: Backfill opening_hour and closing_hour from legacy open_time/close_time
-- Purpose: Safely populate integer hour columns (0-23) using existing text fields
-- Usage: Run this as the DB owner / a user with UPDATE privileges on `restaurants`.
-- Steps recommended before running:
--  1) BACKUP the `restaurants` table (or full DB).
--  2) Run this migration in a transaction. It will only update rows where
--     opening_hour/closing_hour are NULL and open_time/close_time contain
--     parsable hour values (e.g. '08:00', '8', '8:30').
--  3) Inspect results: SELECT id, open_time, opening_hour, close_time, closing_hour FROM restaurants WHERE opening_hour IS NOT NULL OR closing_hour IS NOT NULL;
--  4) If everything looks good, you can later DROP the legacy columns `open_time`/`close_time` after a suitable verification window.

DO $$
BEGIN
  -- Update opening_hour from open_time when opening_hour is NULL and open_time looks like 'H' or 'HH' or 'HH:MM'
  UPDATE restaurants
  SET opening_hour = GREATEST(0, LEAST(23, (split_part(open_time, ':', 1))::int))
  WHERE opening_hour IS NULL
    AND open_time IS NOT NULL
    AND trim(open_time) <> ''
    AND open_time ~ '^[0-9]{1,2}(:[0-9]{2})?$';

  -- Update closing_hour from close_time when closing_hour is NULL and close_time looks like 'H' or 'HH' or 'HH:MM'
  UPDATE restaurants
  SET closing_hour = GREATEST(0, LEAST(23, (split_part(close_time, ':', 1))::int))
  WHERE closing_hour IS NULL
    AND close_time IS NOT NULL
    AND trim(close_time) <> ''
    AND close_time ~ '^[0-9]{1,2}(:[0-9]{2})?$';

  RAISE NOTICE 'Backfill completed: opening_hour/closing_hour updated from open_time/close_time where applicable.';
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'Backfill failed: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Notes:
-- - This migration is intentionally conservative: it only updates rows where the
--   integer columns are NULL and the legacy text columns contain a recognisable
--   hour. It clamps values to the 0-23 range.
-- - After running, verify the mapping and only DROP the legacy columns when
--   you are confident all callers have migrated to the integer fields.
