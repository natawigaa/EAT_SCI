-- ========================================
-- เพิ่ม Foreign Key: orders.student_id → students.student_id
-- ========================================
-- วัตถุประสงค์: ให้ Supabase PostgREST สามารถ JOIN ตาราง orders กับ students ได้
-- ผลลัพธ์: ดึงเบอร์โทรได้เร็วขึ้นมาก (1 query แทน N queries)

-- Step 1: เช็คว่ามี Foreign Key อยู่แล้วหรือยัง
SELECT 
    conname AS constraint_name,
    conrelid::regclass AS table_name,
    confrelid::regclass AS referenced_table
FROM pg_constraint
WHERE conname = 'orders_student_id_fkey';

-- Step 2: เช็ค student_id ที่มีใน orders แต่ไม่มีใน students
SELECT DISTINCT o.student_id, COUNT(*) as order_count
FROM orders o
LEFT JOIN students s ON o.student_id = s.student_id
WHERE s.student_id IS NULL
GROUP BY o.student_id
ORDER BY order_count DESC;

-- Step 3: ลบ orders ที่มี student_id ไม่มีใน students (วิธี B)
-- ⚠️ คำเตือน: จะลบ orders ที่มี student_id ผิด/หายไป!
DELETE FROM orders
WHERE student_id NOT IN (
    SELECT student_id FROM students
);

-- เช็คอีกครั้งว่าลบหมดแล้ว
SELECT DISTINCT o.student_id, COUNT(*) as order_count
FROM orders o
LEFT JOIN students s ON o.student_id = s.student_id
WHERE s.student_id IS NULL
GROUP BY o.student_id;

-- Step 4: เพิ่ม Foreign Key (ตอนนี้ไม่มีข้อมูลขัดแย้งแล้ว)
ALTER TABLE orders
ADD CONSTRAINT orders_student_id_fkey
FOREIGN KEY (student_id)
REFERENCES students(student_id)
ON DELETE CASCADE;

-- Step 5: Verify Foreign Key
SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_name = 'orders'
    AND kcu.column_name = 'student_id';

-- ========================================
-- หมายเหตุ:
-- ========================================
-- 1. หลังจากรัน SQL นี้ Supabase จะรู้จัก relationship ระหว่าง orders ←→ students
-- 2. โค้ด Flutter จะสามารถใช้ .select('*, students!student_id(phone_number)') ได้
-- 3. ประสิทธิภาพจะดีขึ้นมาก: แทนที่จะ query 10 ครั้ง → เหลือแค่ 1 query
-- 4. ถ้ามี student_id ที่ไม่มีใน students table จะเกิด error
--    (แก้ไขด้วยการเพิ่ม student ให้ครบก่อน)
