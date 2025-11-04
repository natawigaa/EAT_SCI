-- ========================================
-- WORKAROUND: ปิด RLS ชั่วคราว (เพื่อทดสอบ)
-- ========================================
-- ⚠️ WARNING: อย่าใช้ใน production!
-- ใช้แค่เพื่อยืนยันว่าปัญหาอยู่ที่ RLS Policy
-- ========================================

-- ปิด RLS สำหรับ orders table
ALTER TABLE orders DISABLE ROW LEVEL SECURITY;

-- ปิด RLS สำหรับ order_items table
ALTER TABLE order_items DISABLE ROW LEVEL SECURITY;

-- ========================================
-- หลังจากทดสอบเสร็จ ให้เปิด RLS กลับ:
-- ========================================
-- ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
-- ========================================
