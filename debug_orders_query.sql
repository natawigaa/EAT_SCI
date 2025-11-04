-- ========================================
-- Debug: ตรวจสอบ Orders และ RLS Policy
-- ========================================

-- 1. ตรวจสอบ Order #22 ว่ามีข้อมูลอะไรบ้าง
SELECT 
  id,
  student_id,
  restaurant_id,
  restaurant_name,
  status,
  total_amount,
  created_at
FROM orders
WHERE id = 22;

-- 2. ตรวจสอบ orders ทั้งหมดของ student_id = '66050711'
SELECT 
  id,
  student_id,
  restaurant_id,
  restaurant_name,
  status,
  total_amount,
  created_at
FROM orders
WHERE student_id = '66050711'
ORDER BY created_at DESC;

-- 3. ตรวจสอบว่า student_id ในตาราง students มีค่าอะไร
SELECT 
  id,
  student_id,
  email,
  first_name,
  last_name
FROM students
WHERE student_id = '66050711';

-- 4. ตรวจสอบ RLS Policy ปัจจุบันของ orders table
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'orders'
  AND policyname LIKE '%Students%';

-- ========================================
-- Expected Results:
-- ========================================
-- Query 1: ควรเห็น order #22 พร้อม student_id = '66050711'
-- Query 2: ควรเห็น orders ทั้งหมดของ student 66050711
-- Query 3: ควรเห็น students record พร้อม id (UUID) และ student_id = '66050711'
-- Query 4: ควรเห็น policy ที่มี qual (WHERE clause) เช็คจาก students table
-- ========================================
