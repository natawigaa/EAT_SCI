-- ========================================
-- Eat@Sci: สร้าง Tables สำหรับระบบ Orders
-- ========================================
-- ใช้สำหรับเก็บคำสั่งซื้อหลังจากชำระเงินเสร็จแล้วเท่านั้น

-- ========================================
-- Status Flow (การไหลของสถานะ)
-- ========================================
-- 1. pending      → สร้างหลังจ่ายเงินสำเร็จ รอร้านยืนยัน
-- 2. confirmed    → ร้านกดรับออเดอร์ (ร้านดำเนินการ)
-- 3. preparing    → ร้านกำลังทำอาหาร (ร้านดำเนินการ)
-- 4. ready        → อาหารพร้อมรับแล้ว รอลูกค้ามารับ (ร้านดำเนินการ)
-- 5. completed    → ลูกค้ารับอาหารแล้ว (นักศึกษายืนยันการรับ)
-- 
-- Status พิเศษ:
-- - cancelled     → ยกเลิกออเดอร์ (ร้านหรือนักศึกษา ภายใน 5 นาที)
-- - refunded      → คืนเงินแล้ว (Admin เท่านั้น)
-- ========================================

-- Table 1: orders (คำสั่งซื้อหลัก)
CREATE TABLE orders (
  id SERIAL PRIMARY KEY,
  student_id TEXT NOT NULL,
  restaurant_id INT NOT NULL REFERENCES restaurants(id),
  restaurant_name TEXT NOT NULL,
  total_amount NUMERIC(10,2) NOT NULL,
  total_items INT NOT NULL,
  
  -- Status Flow: pending -> confirmed -> preparing -> ready -> completed
  status TEXT DEFAULT 'pending' CHECK (status IN (
    'pending',      -- รอร้านยืนยัน (สร้างหลังจ่ายเงินสำเร็จ)
    'confirmed',    -- ร้านรับออเดอร์แล้ว
    'preparing',    -- กำลังเตรียมอาหาร
    'ready',        -- พร้อมรับแล้ว
    'completed',    -- เสร็จสิ้น (รับอาหารแล้ว)
    'cancelled',    -- ยกเลิก
    'refunded'      -- คืนเงินแล้ว (กรณีมีปัญหา)
  )),
  
  payment_method TEXT DEFAULT 'qr_code',
  payment_date TIMESTAMPTZ DEFAULT NOW(),
  notes TEXT,
  
  -- Tracking timestamps
  confirmed_at TIMESTAMPTZ,   -- เวลาที่ร้านยืนยัน
  preparing_at TIMESTAMPTZ,   -- เวลาที่เริ่มทำอาหาร
  ready_at TIMESTAMPTZ,       -- เวลาที่อาหารพร้อม
  completed_at TIMESTAMPTZ,   -- เวลาที่ส่งมอบเสร็จ
  cancelled_at TIMESTAMPTZ,   -- เวลาที่ยกเลิก
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table 2: order_items (รายการอาหารในแต่ละ order)
CREATE TABLE order_items (
  id SERIAL PRIMARY KEY,
  order_id INT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  menu_item_id INT NOT NULL REFERENCES menu_items(id),
  food_name TEXT NOT NULL,
  price NUMERIC(10,2) NOT NULL,
  quantity INT NOT NULL CHECK (quantity > 0),
  special_request TEXT,
  subtotal NUMERIC(10,2) GENERATED ALWAYS AS (price * quantity) STORED,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes สำหรับเพิ่มประสิทธิภาพ (เฉพาะที่จำเป็น)
CREATE INDEX idx_orders_restaurant_id ON orders(restaurant_id);  -- ร้านค้าดู order ของตัวเอง
CREATE INDEX idx_orders_student_id ON orders(student_id);        -- นักศึกษาดูประวัติ
CREATE INDEX idx_orders_status ON orders(status);               -- ฟิลเตอร์ตาม status
CREATE INDEX idx_order_items_order_id ON order_items(order_id);  -- JOIN order กับ order_items

-- Indexes ที่ไม่จำเป็นสำหรับระบบเล็ก:
-- CREATE INDEX idx_orders_created_at ON orders(created_at DESC);        -- เพิ่มทีหลังถ้าต้องการเรียงตามวันที่
-- CREATE INDEX idx_order_items_menu_item_id ON order_items(menu_item_id); -- เพิ่มทีหลังถ้าต้องการสถิติเมนูขายดี

-- Trigger สำหรับอัพเดท updated_at อัตโนมัติ
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_orders_updated_at
BEFORE UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Trigger สำหรับอัพเดท timestamp ตาม status
CREATE OR REPLACE FUNCTION update_order_status_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  -- เมื่อเปลี่ยน status ให้บันทึกเวลาอัตโนมัติ
  IF NEW.status = 'confirmed' AND OLD.status != 'confirmed' THEN
    NEW.confirmed_at = NOW();
  ELSIF NEW.status = 'preparing' AND OLD.status != 'preparing' THEN
    NEW.preparing_at = NOW();
  ELSIF NEW.status = 'ready' AND OLD.status != 'ready' THEN
    NEW.ready_at = NOW();
  ELSIF NEW.status = 'completed' AND OLD.status != 'completed' THEN
    NEW.completed_at = NOW();
  ELSIF NEW.status = 'cancelled' AND OLD.status != 'cancelled' THEN
    NEW.cancelled_at = NOW();
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_order_status_timestamp_trigger
BEFORE UPDATE ON orders
FOR EACH ROW
WHEN (OLD.status IS DISTINCT FROM NEW.status)
EXECUTE FUNCTION update_order_status_timestamp();

-- Enable Row Level Security (RLS)
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

-- ========================================
-- เพิ่ม owner_id column สำหรับ Restaurant Authentication
-- ========================================
-- เพิ่ม column สำหรับเชื่อมโยงร้านอาหารกับเจ้าของร้าน (auth.users)
ALTER TABLE restaurants 
ADD COLUMN IF NOT EXISTS owner_id UUID REFERENCES auth.users(id);

-- สร้าง index สำหรับ owner_id เพื่อเพิ่มประสิทธิภาพการ query
CREATE INDEX IF NOT EXISTS idx_restaurants_owner_id ON restaurants(owner_id);

-- หมายเหตุ: หลังจากรัน SQL นี้แล้ว ให้ admin ไป update owner_id ให้กับแต่ละร้าน
-- UPDATE restaurants SET owner_id = '<uuid-of-restaurant-owner>' WHERE id = 1;
-- ========================================

-- Policy: นักศึกษาดูได้เฉพาะ order ของตัวเอง
CREATE POLICY "Students can view their own orders"
ON orders FOR SELECT
USING (auth.uid()::text = student_id);

-- Policy: ร้านค้าดูได้เฉพาะ order ของร้านตัวเอง
CREATE POLICY "Restaurants can view their orders"
ON orders FOR SELECT
USING (restaurant_id IN (
  SELECT id FROM restaurants WHERE owner_id = auth.uid()
));

-- Policy: ระบบสามารถ insert order ได้ (อนุญาตทั้ง anon และ authenticated)
CREATE POLICY "Allow insert orders"
ON orders FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- Policy: ร้านค้าสามารถอัพเดท status ของ order ของร้านตัวเอง
CREATE POLICY "Restaurants can update their order status"
ON orders FOR UPDATE
USING (restaurant_id IN (
  SELECT id FROM restaurants WHERE owner_id = auth.uid()
))
WITH CHECK (restaurant_id IN (
  SELECT id FROM restaurants WHERE owner_id = auth.uid()
));

-- หมายเหตุ: นักศึกษามีสิทธิ์กดยืนยันเมื่อไปรับอาหารจริง (ready -> completed)
-- ร้านค้าอัพเดท pending -> confirmed -> preparing -> ready
-- นักศึกษาอัพเดท ready -> completed (เมื่อรับอาหารแล้ว)

-- Policy: นักศึกษาสามารถอัพเดท order ของตัวเอง (เฉพาะ completed)
CREATE POLICY "Students can complete their orders"
ON orders FOR UPDATE
USING (student_id = auth.uid()::text AND status = 'ready')
WITH CHECK (student_id = auth.uid()::text AND status = 'completed');

-- Policy: ดู order_items ได้ตาม order ที่มีสิทธิ์
CREATE POLICY "View order items"
ON order_items FOR SELECT
USING (
  order_id IN (
    SELECT id FROM orders 
    WHERE student_id = auth.uid()::text
    OR restaurant_id IN (
      SELECT id FROM restaurants WHERE owner_id = auth.uid()
    )
  )
);

-- Policy: Insert order_items ได้
CREATE POLICY "Allow insert order items"
ON order_items FOR INSERT
WITH CHECK (true);

-- ========================================
-- ตัวอย่างการใช้งาน
-- ========================================

-- 1. ดูคำสั่งซื้อใหม่ของร้าน (status = pending)
-- SELECT o.*, 
--        json_agg(json_build_object(
--          'food_name', oi.food_name,
--          'quantity', oi.quantity,
--          'price', oi.price,
--          'special_request', oi.special_request
--        )) as items
-- FROM orders o
-- LEFT JOIN order_items oi ON o.id = oi.order_id
-- WHERE o.restaurant_id = 1 AND o.status = 'pending'
-- GROUP BY o.id
-- ORDER BY o.created_at DESC;

-- 2. ร้านค้ายืนยันรับออเดอร์
-- UPDATE orders 
-- SET status = 'confirmed'
-- WHERE id = 1 AND restaurant_id = 1;

-- 3. ร้านค้าเริ่มทำอาหาร
-- UPDATE orders 
-- SET status = 'preparing'
-- WHERE id = 1 AND restaurant_id = 1 AND status = 'confirmed';

-- 4. ร้านค้าแจ้งอาหารพร้อม
-- UPDATE orders 
-- SET status = 'ready'
-- WHERE id = 1 AND restaurant_id = 1 AND status = 'preparing';

-- 5. นักศึกษายืนยันรับอาหารแล้ว (กดในแอป)
-- UPDATE orders 
-- SET status = 'completed'
-- WHERE id = 1 AND student_id = '65070001' AND status = 'ready';
-- UPDATE orders 
-- SET status = 'completed'
-- WHERE id = 1 AND student_id = '65070001' AND status = 'ready';

-- 6. ดูประวัติการสั่งของนักศึกษา (พร้อม status timeline)
-- SELECT o.id,
--        o.restaurant_name,
--        o.total_amount,
--        o.status,
--        o.created_at as order_time,
--        o.confirmed_at,
--        o.preparing_at,
--        o.ready_at,
--        o.completed_at,
--        CASE 
--          WHEN o.status = 'completed' THEN 
--            EXTRACT(EPOCH FROM (o.completed_at - o.created_at))/60
--          ELSE NULL
--        END as total_minutes,
--        json_agg(json_build_object(
--          'food_name', oi.food_name,
--          'quantity', oi.quantity,
--          'price', oi.price
--        )) as items
-- FROM orders o
-- LEFT JOIN order_items oi ON o.id = oi.order_id
-- WHERE o.student_id = '65070001'
-- GROUP BY o.id
-- ORDER BY o.created_at DESC;

-- 7. สถิติเมนูขายดี (Top 10)
-- SELECT mi.name, 
--        mi.category,
--        SUM(oi.quantity) as total_sold,
--        SUM(oi.subtotal) as total_revenue,
--        COUNT(DISTINCT oi.order_id) as total_orders
-- FROM order_items oi
-- JOIN menu_items mi ON oi.menu_item_id = mi.id
-- JOIN orders o ON oi.order_id = o.id
-- WHERE o.status IN ('ready', 'completed')
-- GROUP BY mi.id, mi.name, mi.category
-- ORDER BY total_sold DESC
-- LIMIT 10;

-- 8. Dashboard ร้านค้า - สรุปออเดอร์วันนี้
-- SELECT 
--   COUNT(*) FILTER (WHERE status = 'pending') as pending_orders,
--   COUNT(*) FILTER (WHERE status = 'confirmed') as confirmed_orders,
--   COUNT(*) FILTER (WHERE status = 'preparing') as preparing_orders,
--   COUNT(*) FILTER (WHERE status = 'ready') as ready_orders,
--   COUNT(*) FILTER (WHERE status = 'completed') as completed_orders,
--   SUM(total_amount) FILTER (WHERE status IN ('ready', 'completed')) as today_revenue
-- FROM orders
-- WHERE restaurant_id = 1 
--   AND created_at >= CURRENT_DATE
--   AND created_at < CURRENT_DATE + INTERVAL '1 day';

-- 9. เวลาเฉลี่ยในการเตรียมอาหารของร้าน
-- SELECT 
--   AVG(EXTRACT(EPOCH FROM (ready_at - confirmed_at))/60) as avg_preparation_minutes
-- FROM orders
-- WHERE restaurant_id = 1 
--   AND status IN ('ready', 'completed')
--   AND confirmed_at IS NOT NULL 
--   AND ready_at IS NOT NULL;

-- 10. ออเดอร์ที่รอนานเกิน 30 นาที (แจ้งเตือนร้านค้า)
-- SELECT o.id,
--        o.student_id,
--        o.status,
--        o.created_at,
--        EXTRACT(EPOCH FROM (NOW() - o.created_at))/60 as minutes_waiting
-- FROM orders o
-- WHERE o.restaurant_id = 1
--   AND o.status IN ('pending', 'confirmed', 'preparing')
--   AND (NOW() - o.created_at) > INTERVAL '30 minutes'
-- ORDER BY o.created_at ASC;
