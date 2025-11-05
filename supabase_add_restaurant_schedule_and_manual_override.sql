-- Migration: Add schedule / timezone / manual override columns to restaurants
-- Adds an audit table restaurant_open_history for tracking manual changes

ALTER TABLE IF EXISTS restaurants
  ADD COLUMN IF NOT EXISTS schedule jsonb DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS timezone text DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS is_open_manual boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS manual_override_expires timestamptz DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS manual_override_by text DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS opening_hour integer DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS closing_hour integer DEFAULT NULL;

-- Audit/history table for manual overrides and scheduler-driven writes
CREATE TABLE IF NOT EXISTS restaurant_open_history (
  id bigserial PRIMARY KEY,
  restaurant_id integer NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
  is_open boolean NOT NULL,
  source text NOT NULL, -- 'manual' | 'schedule' | 'system'
  changed_by text DEFAULT NULL,
  expires_at timestamptz DEFAULT NULL,
  created_at timestamptz DEFAULT now()
);

-- Optional: index to help querying recent manual overrides
CREATE INDEX IF NOT EXISTS idx_restaurant_open_history_restaurant_created_at
  ON restaurant_open_history (restaurant_id, created_at DESC);

-- NOTE: After running this migration, update any restaurant rows with desired
-- schedule JSON. Example schedule format (per restaurant):
-- {
--   "monday": {"open": 8, "close": 17},
--   "tuesday": {"open": 8, "close": 17},
--   ...
-- }
