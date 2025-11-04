-- ========================================
-- UPDATE TRIGGER: อ่าน username และ phone จาก metadata
-- Run this in Supabase SQL Editor
-- ========================================

-- 1. Drop trigger เดิม
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- 2. สร้าง function ใหม่ที่อ่าน metadata
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

-- 3. สร้าง trigger ใหม่
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION create_student_profile();

-- ========================================
-- ✅ เสร็จสิ้น!
-- ========================================

SELECT 'Trigger updated! Now signup will save username + phone automatically.' AS status;
