-- ========================================
-- CREATE STUDENTS TABLE WITH AUTO-REGISTRATION
-- Version: 3.0 - Science Faculty Only
-- Total Lines: ~221
-- ========================================

-- ========================================
-- สร้างตาราง students สำหรับนักศึกษา
-- ========================================

CREATE TABLE IF NOT EXISTS students (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  student_id VARCHAR(20) UNIQUE NOT NULL, -- รหัสนักศึกษา (ดึงจากอีเมลอัตโนมัติ เช่น 65070001)
  
  -- ข้อมูลสำคัญ (บังคับกรอกตั้งแต่ SignUp)
  username VARCHAR(50) UNIQUE,             -- ชื่อผู้ใช้ (บังคับ) เช่น "somchai_k"
  phone_number VARCHAR(20),                -- เบอร์โทร (บังคับ) สำหรับติดต่อร้านค้า
  email VARCHAR(255) UNIQUE NOT NULL,      -- อีเมล (ดึงจาก auth.users อัตโนมัติ)
  
  -- ข้อมูลเพิ่มเติม (optional)
  first_name VARCHAR(100),                 -- ชื่อจริง (ไม่บังคับ)
  last_name VARCHAR(100),                  -- นามสกุล (ไม่บังคับ)
  profile_image_url TEXT,                  -- URL รูปโปรไฟล์จาก Storage (ไม่บังคับ)
  
  -- ข้อมูลการศึกษา (กำหนดโดยระบบ - สำคัญต่อการระบุตำแหน่งรับอาหาร)
  faculty VARCHAR(200) DEFAULT 'วิทยาศาสตร์',  -- คณะวิทยาศาสตร์ (ตายตัว)
  year INTEGER CHECK (year >= 1 AND year <= 5), -- ชั้นปี (คำนวณจากรหัส - แก้ไขได้)
  university VARCHAR(200) DEFAULT 'สถาบันเทคโนโลยีพระจอมเกล้าเจ้าคุณทหารลาดกระบัง',
  
  -- สถานะการกรอกข้อมูล
  profile_completed BOOLEAN DEFAULT FALSE, -- TRUE เมื่อกรอกครบ: username, phone
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ========================================
-- Indexes สำหรับการค้นหาที่เร็วขึ้น
-- ========================================

CREATE INDEX IF NOT EXISTS idx_students_student_id ON students(student_id);
CREATE INDEX IF NOT EXISTS idx_students_username ON students(username);
CREATE INDEX IF NOT EXISTS idx_students_email ON students(email);
CREATE INDEX IF NOT EXISTS idx_students_phone ON students(phone_number);

-- ========================================
-- Function: Auto-update updated_at
-- ========================================

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

-- ========================================
-- Function: Auto-create student profile after signup
-- สร้างข้อมูลนักศึกษาอัตโนมัติเมื่อลงทะเบียนด้วยอีเมลมหาวิทยาลัย
-- ========================================

CREATE OR REPLACE FUNCTION create_student_profile()
RETURNS TRIGGER AS $$
DECLARE
  v_student_id VARCHAR(20);
  v_email VARCHAR(255);
  v_year INTEGER;
  v_university VARCHAR(200);
BEGIN
  -- ดึงอีเมลจาก auth.users
  v_email := NEW.email;
  
  -- ตรวจสอบว่าเป็นอีเมล KMITL หรือไม่
  IF v_email LIKE '%@kmitl.ac.th' THEN
    -- แยกรหัสนักศึกษาจากอีเมล (เช่น 65070001@kmitl.ac.th → 65070001)
    v_student_id := SPLIT_PART(v_email, '@', 1);
    
    -- คำนวณชั้นปีจากรหัสนักศึกษา (เช่น 65070001 → ปี 2565)
    -- สมมติ: 2 หลักแรกคือปีที่เข้า (65 = 2565)
    -- ปีปัจจุบัน 2568 - 2565 = 3 (ชั้นปี 3)
    v_year := (EXTRACT(YEAR FROM NOW()) + 543) - (2500 + SUBSTRING(v_student_id, 1, 2)::INTEGER);
    
    -- จำกัดชั้นปีไม่เกิน 1-5
    IF v_year < 1 THEN v_year := 1; END IF;
    IF v_year > 5 THEN v_year := 5; END IF;
    
    v_university := 'สถาบันเทคโนโลยีพระจอมเกล้าเจ้าคุณทหารลาดกระบัง';
    
    -- สร้างข้อมูลนักศึกษา (คณะวิทยาศาสตร์เท่านั้น)
    INSERT INTO students (
      id,
      student_id,
      email,
      faculty,
      year,
      university,
      profile_completed
    ) VALUES (
      NEW.id,
      v_student_id,
      v_email,
      'วิทยาศาสตร์',
      v_year,
      v_university,
      FALSE -- ยังกรอกข้อมูลไม่ครบ
    );
    
    RAISE NOTICE 'Created student profile for: % (Year: %)', v_student_id, v_year;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- สร้าง Trigger ที่ทำงานหลังจากมีการสร้าง user ใหม่ใน auth.users
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION create_student_profile();

-- ========================================
-- Row Level Security (RLS) Policies
-- ========================================

ALTER TABLE students ENABLE ROW LEVEL SECURITY;

-- นักศึกษาดูข้อมูลตัวเองได้
CREATE POLICY "Students can view their own profile"
ON students FOR SELECT
TO authenticated
USING (auth.uid() = id);

-- นักศึกษาแก้ไขข้อมูลตัวเองได้ (เฉพาะฟิลด์ที่อนุญาต)
CREATE POLICY "Students can update their own profile"
ON students FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (
  auth.uid() = id AND
  -- ห้ามเปลี่ยนฟิลด์เหล่านี้ (ดึงจากระบบอัตโนมัติ)
  student_id = (SELECT student_id FROM students WHERE id = auth.uid()) AND
  email = (SELECT email FROM students WHERE id = auth.uid()) AND
  university = (SELECT university FROM students WHERE id = auth.uid())
  -- faculty, department, year สามารถแก้ไขได้ (กรณีเปลี่ยนสาขา/ชั้นปี)
);

-- ร้านค้าดูข้อมูลนักศึกษาที่สั่งอาหารได้ (สำหรับ order management)
CREATE POLICY "Restaurants can view student basic info"
ON students FOR SELECT
TO authenticated
USING (
  id IN (
    SELECT DISTINCT student_id::uuid 
    FROM orders 
    WHERE restaurant_id IN (
      SELECT id FROM restaurants WHERE owner_id = auth.uid()
    )
  )
);

-- ========================================
-- Comments สำหรับ Documentation
-- ========================================

COMMENT ON TABLE students IS 'ข้อมูลนักศึกษาที่ใช้แอปพลิเคชัน (สร้างอัตโนมัติจากอีเมลมหาวิทยาลัย)';
COMMENT ON COLUMN students.student_id IS 'รหัสนักศึกษา (ดึงจากอีเมลอัตโนมัติ เช่น 65070001@kmitl.ac.th → 65070001)';
COMMENT ON COLUMN students.username IS 'ชื่อผู้ใช้ (กรอกหลัง signup - ต้องกรอกก่อนสั่งอาหาร) ใช้แสดงในระบบและติดต่อกับร้านค้า';
COMMENT ON COLUMN students.phone_number IS 'เบอร์โทรศัพท์ (กรอกหลัง signup - ต้องกรอกก่อนสั่งอาหาร) สำหรับติดต่อร้านค้าเรื่องออเดอร์';
COMMENT ON COLUMN students.email IS 'อีเมลมหาวิทยาลัย (ต้องลงท้ายด้วย @kmitl.ac.th)';
COMMENT ON COLUMN students.profile_image_url IS 'URL รูปโปรไฟล์จาก Supabase Storage (ไม่บังคับ)';
COMMENT ON COLUMN students.faculty IS 'คณะ (ตายตัว = วิทยาศาสตร์)';
COMMENT ON COLUMN students.year IS 'ชั้นปี 1-5 (คำนวณจากรหัสนักศึกษา แต่แก้ไขได้)';
COMMENT ON COLUMN students.profile_completed IS 'สถานะการกรอกข้อมูล (TRUE = กรอกครบ: username, phone)';
COMMENT ON COLUMN students.first_name IS 'ชื่อจริง (ไม่บังคับ - เพิ่มทีหลังได้)';
COMMENT ON COLUMN students.last_name IS 'นามสกุล (ไม่บังคับ - เพิ่มทีหลังได้)';

-- ========================================
-- Helper Function: ตรวจสอบว่ากรอกข้อมูลครบหรือยัง
-- ========================================

CREATE OR REPLACE FUNCTION check_profile_completed()
RETURNS TRIGGER AS $$
BEGIN
  -- ตรวจสอบว่ากรอกข้อมูลสำคัญครบหรือยัง (สำหรับการสั่งอาหาร)
  IF NEW.username IS NOT NULL 
     AND NEW.phone_number IS NOT NULL THEN
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

-- ========================================
-- Insert Sample Data (สำหรับทดสอบ)
-- ========================================

-- หมายเหตุ: ต้องมี auth.users ที่สอดคล้องกับ UUID ก่อน
-- ตัวอย่างการ insert (ใช้ UUID จริงจาก auth.users):

/*
INSERT INTO students (id, student_id, first_name, last_name, email, phone_number, faculty, department, year)
VALUES 
  ('uuid-from-auth-users-1', '65070001', 'สมชาย', 'ใจดี', 'somchai@kmitl.ac.th', '081-234-5678', 'วิทยาศาสตร์', 'วิทยาการคอมพิวเตอร์', 3),
  ('uuid-from-auth-users-2', '65070002', 'สมหญิง', 'รักเรียน', 'somying@kmitl.ac.th', '082-345-6789', 'วิศวกรรมศาสตร์', 'วิศวกรรมคอมพิวเตอร์', 2);
*/

-- ========================================
-- ✅ เสร็จสิ้น
-- ========================================

SELECT 'Students table created successfully!' AS status;
