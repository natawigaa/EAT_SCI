-- ========================================
-- แก้ไข และ ยืนยัน RLS Policy ทันที
-- ========================================

-- Step 1: ลบ policy เดิม
DROP POLICY IF EXISTS "Students can view their own orders" ON orders;
DROP POLICY IF EXISTS "Students can complete their orders" ON orders;

-- Step 2: สร้าง policy ใหม่ (authenticated users only)
CREATE POLICY "Students can view their own orders"
ON orders FOR SELECT
TO authenticated
USING (
  student_id IN (
    SELECT student_id FROM students WHERE id = auth.uid()
  )
);

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

-- Step 3: ยืนยันว่า Policy ถูกสร้างแล้ว
SELECT 
  policyname,
  cmd,
  roles,
  qual
FROM pg_policies
WHERE tablename = 'orders'
  AND policyname LIKE '%Students%';

-- Step 4: ทดสอบว่ามี orders อะไรบ้าง
SELECT 
  id,
  student_id,
  restaurant_name,
  status,
  total_amount,
  created_at
FROM orders
WHERE student_id = '66050711'
ORDER BY created_at DESC
LIMIT 5;

-- ========================================
-- Expected: ควรเห็น
-- 1. Policy ใหม่ที่ใช้ authenticated role
-- 2. Order #22 (และ order อื่นๆ ถ้ามี) ของ student 66050711
-- ========================================
