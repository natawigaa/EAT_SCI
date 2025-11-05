-- Prevent creating orders when the restaurant is currently closed
-- This trigger checks restaurants.is_open before an INSERT into orders.

CREATE OR REPLACE FUNCTION prevent_orders_when_restaurant_closed()
RETURNS TRIGGER AS $$
DECLARE
  r_is_open BOOLEAN;
BEGIN
  -- Fetch authoritative is_open for the restaurant referenced by the order
  SELECT is_open INTO r_is_open FROM restaurants WHERE id = NEW.restaurant_id;

  -- If the DB explicitly marks the restaurant as closed, block the insert
  IF r_is_open IS NOT NULL AND r_is_open = FALSE THEN
    RAISE EXCEPTION 'Cannot create order: restaurant % is currently closed', NEW.restaurant_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_prevent_orders_when_closed ON orders;
CREATE TRIGGER trg_prevent_orders_when_closed
BEFORE INSERT ON orders
FOR EACH ROW
EXECUTE FUNCTION prevent_orders_when_restaurant_closed();
