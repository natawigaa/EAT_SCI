-- ========================================
-- เพิ่ม Payment Slip Upload สำหรับ Orders
-- ========================================
-- ใช้สำหรับเก็บสลิปโอนเงินที่นักศึกษาอัปโหลด
-- ร้านค้าจะตรวจสอบและยืนยัน/ปฏิเสธ order

-- 1. เพิ่ม columns ใน orders table
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS payment_slip_url TEXT,
ADD COLUMN IF NOT EXISTS slip_uploaded_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS slip_verified_by UUID REFERENCES auth.users(id),
ADD COLUMN IF NOT EXISTS slip_verified_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

-- 2. เพิ่ม comments อธิบาย
COMMENT ON COLUMN orders.payment_slip_url IS 'URL ของสลิปโอนเงิน (อัปโหลดจาก Supabase Storage bucket: payment-slips)';
COMMENT ON COLUMN orders.slip_uploaded_at IS 'เวลาที่นักศึกษาอัปโหลดสลิป';
COMMENT ON COLUMN orders.slip_verified_by IS 'เจ้าของร้านที่ยืนยันสลิป (auth.users.id)';
COMMENT ON COLUMN orders.slip_verified_at IS 'เวลาที่ร้านยืนยันสลิป';
COMMENT ON COLUMN orders.rejection_reason IS 'เหตุผลที่ปฏิเสธ order (ถ้า status = cancelled)';

-- 3. เพิ่ม index สำหรับ query ที่รวดเร็ว
CREATE INDEX IF NOT EXISTS idx_orders_slip_status ON orders(status, slip_uploaded_at);

-- ========================================
-- Status Flow สำหรับ Slip Verification:
-- ========================================
-- 1. นักศึกษาสั่งอาหาร + สแกน QR → status = 'pending' (ยังไม่อัปโหลดสลิป)
-- 2. นักศึกษาโอนเงิน + อัปโหลดสลิป → status = 'pending' + มี payment_slip_url
-- 3. ร้านค้าเปิดดูสลิป:
--    - กดยืนยัน → status = 'confirmed' + slip_verified_at = NOW()
--    - กดปฏิเสธ → status = 'cancelled' + rejection_reason
-- 4. หลังยืนยัน ร้านทำอาหาร → status = 'preparing' → 'ready' → 'completed'

-- ========================================
-- Storage Bucket Setup (ทำใน Supabase Dashboard):
-- ========================================
-- 1. สร้าง bucket: "payment-slips"
-- 2. ตั้งค่า: Public = false (ความปลอดภัย)
-- 3. RLS Policy:
--    - Student: อัปโหลดได้เฉพาะ order ของตัวเอง
--    - Restaurant: ดูได้เฉพาะ order ของร้านตัวเอง

-- ========================================
-- RLS Policies สำหรับ Storage
-- ========================================
-- ใน Supabase Dashboard → Storage → payment-slips → Policies

-- Policy 1: นักศึกษาอัปโหลดสลิปได้
-- CREATE POLICY "Students can upload their slips"
-- ON storage.objects FOR INSERT
-- TO authenticated
-- WITH CHECK (
--   bucket_id = 'payment-slips' AND
--   (storage.foldername(name))[1] = auth.uid()::text
-- );

-- Policy 2: เจ้าของ order ดูสลิปได้ (นักศึกษา + ร้านค้า)
-- CREATE POLICY "Order participants can view slips"
-- ON storage.objects FOR SELECT
-- TO authenticated
-- USING (
--   bucket_id = 'payment-slips'
-- );

-- ========================================
-- ตัวอย่างการใช้งาน:
-- ========================================

-- 1. นักศึกษาอัปโหลดสลิป (ใน Flutter)
-- UPDATE orders 
-- SET payment_slip_url = 'https://xxx.supabase.co/storage/v1/object/payment-slips/order-123-slip.jpg',
--     slip_uploaded_at = NOW()
-- WHERE id = 123 AND student_id = '65070001';

-- 2. ร้านค้าดูรายการ order ที่รอตรวจสลิป
-- SELECT id, student_id, total_amount, payment_slip_url, slip_uploaded_at
-- FROM orders
-- WHERE restaurant_id = 1 
--   AND status = 'pending'
--   AND payment_slip_url IS NOT NULL
-- ORDER BY slip_uploaded_at ASC;

-- 3. ร้านค้ายืนยันสลิป (กดรับ order)
-- UPDATE orders 
-- SET status = 'confirmed',
--     slip_verified_by = '<restaurant-owner-uuid>',
--     slip_verified_at = NOW()
-- WHERE id = 123 AND restaurant_id = 1;

-- 4. ร้านค้าปฏิเสธสลิป (ยกเลิก order)
-- UPDATE orders 
-- SET status = 'cancelled',
--     rejection_reason = 'สลิปไม่ตรงกับยอดเงิน',
--     cancelled_at = NOW()
-- WHERE id = 123 AND restaurant_id = 1;

-- 5. ดูสถิติสลิปที่รอตรวจสอบ
-- SELECT 
--   restaurant_id,
--   restaurant_name,
--   COUNT(*) as pending_slips,
--   SUM(total_amount) as total_pending_amount
-- FROM orders
-- WHERE status = 'pending' 
--   AND payment_slip_url IS NOT NULL
--   AND slip_verified_at IS NULL
-- GROUP BY restaurant_id, restaurant_name;

-- 6. Dashboard ร้านค้า - order ที่รอตรวจสลิปนานเกิน 30 นาที
-- SELECT id, student_id, total_amount, 
--        EXTRACT(EPOCH FROM (NOW() - slip_uploaded_at))/60 as minutes_waiting
-- FROM orders
-- WHERE restaurant_id = 1
--   AND status = 'pending'
--   AND payment_slip_url IS NOT NULL
--   AND slip_verified_at IS NULL
--   AND (NOW() - slip_uploaded_at) > INTERVAL '30 minutes'
-- ORDER BY slip_uploaded_at ASC;
