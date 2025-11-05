-- Create RPC function to clear expired manual overrides and record an audit row
-- Run this once in your database (e.g., via Supabase SQL editor)

CREATE OR REPLACE FUNCTION public.clear_manual_overrides()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  WITH cleared AS (
    UPDATE restaurants
    SET is_open_manual = false,
        manual_override_expires = NULL,
        manual_override_by = NULL
    WHERE is_open_manual = true
      AND manual_override_expires IS NOT NULL
      AND manual_override_expires <= now()
    RETURNING id AS restaurant_id, is_open
  )
  INSERT INTO restaurant_open_history (restaurant_id, is_open, source, changed_by, expires_at)
  SELECT restaurant_id, is_open, 'system', NULL, NULL FROM cleared;
END;
$$;

-- Usage: SELECT public.clear_manual_overrides();
