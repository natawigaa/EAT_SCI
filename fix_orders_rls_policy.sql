-- ========================================
-- แก้ไข RLS Policy สำหรับ orders table
-- ========================================
-- ปัญหา: Policy เดิมเช็ค auth.uid()::text = student_id
--         แต่ auth.uid() เป็น UUID ส่วน student_id เป็นรหัสนักศึกษา (เช่น "66050711")
--         ทำให้นักศึกษาดู order ของตัวเองไม่ได้
-- 
-- แก้ไข: เช็ค student_id จาก students table แทน
-- ========================================

-- 1. ลบ policy เดิม
DROP POLICY IF EXISTS "Students can view their own orders" ON orders;

-- 2. สร้าง policy ใหม่ที่เช็คจาก students table (authenticated users only)
CREATE POLICY "Students can view their own orders"
ON orders FOR SELECT
TO authenticated
USING (
  student_id IN (
    SELECT student_id FROM students WHERE id = auth.uid()
  )
);

-- 3. แก้ policy สำหรับนักศึกษาอัพเดท order (เฉพาะ ready -> completed)
DROP POLICY IF EXISTS "Students can complete their orders" ON orders;

CREATE POLICY "Students can complete their orders"
ON orders FOR UPDATE
TO authenticated
USING (
  student_id IN (
    SELECT student_id FROM students WHERE id = auth.uid()
  )
  AND status = 'ready'
)
WITH CHECK (
  student_id IN (
    SELECT student_id FROM students WHERE id = auth.uid()
  )
  AND status = 'completed'
);

-- ========================================
-- ทดสอบหลังรัน SQL นี้
-- ========================================
-- 1. Login ด้วยบัญชีนักศึกษา (66050711@kmitl.ac.th)
-- 2. ไปที่หน้า "ติดตามออเดอร์"
-- 3. ควรเห็น order ของตัวเองแล้ว (order #20)
-- ========================================
