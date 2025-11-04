-- ========================================
-- UPDATE STUDENTS TABLE - Fix NOT NULL constraint issue
-- Run this in Supabase SQL Editor
-- ========================================

-- 1. Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- 2. Drop the table to recreate with new schema
DROP TABLE IF EXISTS students CASCADE;

-- 3. Create table with username and phone_number as optional (nullable)
CREATE TABLE students (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  student_id VARCHAR(20) UNIQUE NOT NULL,
  
  -- Allow NULL for username and phone during signup
  username VARCHAR(50) UNIQUE,
  phone_number VARCHAR(20),
  email VARCHAR(255) UNIQUE NOT NULL,
  
  -- Optional fields
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  profile_image_url TEXT,
  
  -- Auto-filled fields
  faculty VARCHAR(200) DEFAULT 'วิทยาศาสตร์',
  year INTEGER CHECK (year >= 1 AND year <= 5),
  university VARCHAR(200) DEFAULT 'สถาบันเทคโนโลยีพระจอมเกล้าเจ้าคุณทหารลาดกระบัง',
  
  -- Status
  profile_completed BOOLEAN DEFAULT FALSE,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Create indexes
CREATE INDEX idx_students_student_id ON students(student_id);
CREATE INDEX idx_students_username ON students(username);
CREATE INDEX idx_students_email ON students(email);
CREATE INDEX idx_students_phone ON students(phone_number);

-- 5. Recreate auto-update trigger
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

-- 6. Recreate auto-registration function (WITHOUT username/phone requirement)
CREATE OR REPLACE FUNCTION create_student_profile()
RETURNS TRIGGER AS $$
DECLARE
  v_student_id VARCHAR(20);
  v_email VARCHAR(255);
  v_year INTEGER;
BEGIN
  v_email := NEW.email;
  
  IF v_email LIKE '%@kmitl.ac.th' THEN
    v_student_id := SPLIT_PART(v_email, '@', 1);
    
    -- Calculate year
    v_year := (EXTRACT(YEAR FROM NOW()) + 543) - (2500 + SUBSTRING(v_student_id, 1, 2)::INTEGER);
    IF v_year < 1 THEN v_year := 1; END IF;
    IF v_year > 5 THEN v_year := 5; END IF;
    
    -- Create student record (username and phone_number will be NULL initially)
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
      'สถาบันเทคโนโลยีพระจอมเกล้าเจ้าคุณทหารลาดกระบัง',
      FALSE
    );
    
    RAISE NOTICE 'Created student profile for: % (Year: %)', v_student_id, v_year;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Recreate the trigger
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION create_student_profile();

-- 8. Create profile completion checker
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

-- 9. Enable RLS
ALTER TABLE students ENABLE ROW LEVEL SECURITY;

-- 10. Create RLS policies
CREATE POLICY "Students can view their own profile"
ON students FOR SELECT
TO authenticated
USING (auth.uid() = id);

CREATE POLICY "Students can update their own profile"
ON students FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (
  auth.uid() = id AND
  student_id = (SELECT student_id FROM students WHERE id = auth.uid()) AND
  email = (SELECT email FROM students WHERE id = auth.uid()) AND
  university = (SELECT university FROM students WHERE id = auth.uid())
);

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
-- ✅ DONE
-- ========================================

SELECT 'Students table updated successfully! Try signup now.' AS status;
