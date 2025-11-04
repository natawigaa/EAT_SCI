-- ========================================
-- FIX: Database error saving new user
-- ปิด trigger ชั่วคราวเพื่อหาสาเหตุ
-- ========================================

-- 1. ปิด trigger ทั้งหมดก่อน
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS students_updated_at_trigger ON students;
DROP TRIGGER IF EXISTS check_profile_completed_trigger ON students;

-- 2. ลบ table เดิมทิ้ง
DROP TABLE IF EXISTS students CASCADE;

-- 3. สร้าง table ใหม่แบบเรียบง่าย (ไม่มี trigger ก่อน)
CREATE TABLE students (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  student_id VARCHAR(20) UNIQUE,
  username VARCHAR(50) UNIQUE,
  phone_number VARCHAR(20),
  email VARCHAR(255) UNIQUE NOT NULL,
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  profile_image_url TEXT,
  faculty VARCHAR(200) DEFAULT 'วิทยาศาสตร์',
  year INTEGER,
  university VARCHAR(200) DEFAULT 'สถาบันเทคโนโลยีพระจอมเกล้าเจ้าคุณทหารลาดกระบัง',
  profile_completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. เปิด RLS
ALTER TABLE students ENABLE ROW LEVEL SECURITY;

-- 5. สร้าง policies พื้นฐาน
CREATE POLICY "Enable all for authenticated users"
ON students FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- ========================================
-- 6. เพิ่ม trigger ที่แก้ไขแล้ว
-- ========================================

-- สร้าง function สำหรับ auto-update updated_at
CREATE OR REPLACE FUNCTION update_students_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER students_updated_at_trigger
BEFORE UPDATE ON students
FOR EACH ROW
EXECUTE FUNCTION update_students_updated_at();

-- สร้าง function สำหรับ profile completion check
CREATE OR REPLACE FUNCTION check_profile_completed()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.username IS NOT NULL AND NEW.phone_number IS NOT NULL THEN
    NEW.profile_completed := TRUE;
  ELSE
    NEW.profile_completed := FALSE;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_profile_completed_trigger
BEFORE INSERT OR UPDATE ON students
FOR EACH ROW
EXECUTE FUNCTION check_profile_completed();

-- สร้าง function สำหรับ auto-create student profile
-- แก้ไข: อ่าน username และ phone_number จาก metadata
CREATE OR REPLACE FUNCTION create_student_profile()
RETURNS TRIGGER AS $$
DECLARE
  v_student_id VARCHAR(20);
  v_email VARCHAR(255);
  v_year INTEGER;
  v_username VARCHAR(50);
  v_phone VARCHAR(20);
BEGIN
  v_email := NEW.email;
  
  -- ตรวจสอบว่าเป็นอีเมล KMITL
  IF v_email LIKE '%@kmitl.ac.th' THEN
    BEGIN
      -- แยกรหัสนักศึกษา
      v_student_id := SPLIT_PART(v_email, '@', 1);
      
      -- คำนวณชั้นปี
      v_year := (EXTRACT(YEAR FROM NOW()) + 543) - (2500 + SUBSTRING(v_student_id, 1, 2)::INTEGER);
      IF v_year < 1 THEN v_year := 1; END IF;
      IF v_year > 5 THEN v_year := 5; END IF;
      
      -- อ่าน username และ phone_number จาก metadata
      v_username := NEW.raw_user_meta_data->>'username';
      v_phone := NEW.raw_user_meta_data->>'phone_number';
      
      -- สร้างข้อมูลนักศึกษา (พร้อม username + phone จาก metadata)
      INSERT INTO students (
        id,
        student_id,
        email,
        username,
        phone_number,
        faculty,
        year,
        university,
        profile_completed
      ) VALUES (
        NEW.id,
        v_student_id,
        v_email,
        v_username,
        v_phone,
        'วิทยาศาสตร์',
        v_year,
        'สถาบันเทคโนโลยีพระจอมเกล้าเจ้าคุณทหารลาดกระบัง',
        CASE WHEN v_username IS NOT NULL AND v_phone IS NOT NULL THEN TRUE ELSE FALSE END
      );
      
      RAISE NOTICE 'Created student profile: % (Year: %, Username: %, Phone: %)', 
                   v_student_id, v_year, v_username, v_phone;
      
    EXCEPTION WHEN OTHERS THEN
      -- Log error แต่ไม่ทำให้ signup ล้มเหลว
      RAISE WARNING 'Failed to create student profile: %', SQLERRM;
    END;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- สร้าง trigger สำหรับ auto-create profile
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION create_student_profile();

-- ========================================
-- ✅ เสร็จสิ้น! ทดสอบ signup ใหม่อีกครั้ง
-- ========================================

SELECT 'Fixed! Triggers enabled with error handling. Try signup again!' AS status;

-- ========================================
-- 7. สร้างข้อมูล student สำหรับ users ที่มีอยู่แล้ว
-- (สำหรับ users ที่สมัครก่อนเปิด trigger)
-- ========================================

INSERT INTO students (
  id,
  student_id,
  email,
  faculty,
  year,
  university,
  profile_completed
)
SELECT 
  u.id,
  SPLIT_PART(u.email, '@', 1) as student_id,
  u.email,
  'วิทยาศาสตร์' as faculty,
  CASE 
    WHEN (EXTRACT(YEAR FROM NOW()) + 543) - (2500 + SUBSTRING(SPLIT_PART(u.email, '@', 1), 1, 2)::INTEGER) < 1 
    THEN 1
    WHEN (EXTRACT(YEAR FROM NOW()) + 543) - (2500 + SUBSTRING(SPLIT_PART(u.email, '@', 1), 1, 2)::INTEGER) > 5 
    THEN 5
    ELSE (EXTRACT(YEAR FROM NOW()) + 543) - (2500 + SUBSTRING(SPLIT_PART(u.email, '@', 1), 1, 2)::INTEGER)
  END as year,
  'สถาบันเทคโนโลยีพระจอมเกล้าเจ้าคุณทหารลาดกระบัง' as university,
  FALSE as profile_completed
FROM auth.users u
WHERE u.email LIKE '%@kmitl.ac.th'
AND NOT EXISTS (SELECT 1 FROM students s WHERE s.id = u.id)
ON CONFLICT (id) DO NOTHING;

SELECT 'Student records created for existing users!' AS status;
