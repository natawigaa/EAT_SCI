-- ========================================
-- Setup Storage Bucket สำหรับรูปโปรไฟล์นักศึกษา
-- ========================================

-- ขั้นตอนที่ 1: สร้าง Bucket (ทำใน Supabase Dashboard)
-- ไปที่ Storage → Create New Bucket
-- ตั้งค่า:
--   Name: student_profile_images
--   Public: ❌ ปิด (เฉพาะเจ้าของดูได้)
--   File size limit: 5MB
--   Allowed MIME types: image/png, image/jpeg, image/jpg, image/webp

-- ========================================
-- ขั้นตอนที่ 2: ตั้งค่า RLS Policies
-- ========================================

-- Policy 1: นักศึกษาอัปโหลดรูปโปรไฟล์ของตัวเองได้
CREATE POLICY "Students can upload their own profile images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'student_profile_images' AND
  -- ชื่อไฟล์ต้องขึ้นต้นด้วย user_id ของตัวเอง
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy 2: นักศึกษาดูรูปโปรไฟล์ของตัวเองได้
CREATE POLICY "Students can view their own profile images"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'student_profile_images' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy 3: นักศึกษาอัปเดตรูปโปรไฟล์ของตัวเองได้
CREATE POLICY "Students can update their own profile images"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'student_profile_images' AND
  (storage.foldername(name))[1] = auth.uid()::text
)
WITH CHECK (
  bucket_id = 'student_profile_images' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy 4: นักศึกษาลบรูปโปรไฟล์ของตัวเองได้
CREATE POLICY "Students can delete their own profile images"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'student_profile_images' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy 5: ร้านค้าดูรูปโปรไฟล์นักศึกษาที่สั่งอาหารได้ (optional)
CREATE POLICY "Restaurants can view customer profile images"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'student_profile_images' AND
  (storage.foldername(name))[1]::uuid IN (
    SELECT DISTINCT student_id::uuid 
    FROM orders 
    WHERE restaurant_id IN (
      SELECT id FROM restaurants WHERE owner_id = auth.uid()
    )
  )
);

-- ========================================
-- ✅ เสร็จสิ้น
-- ========================================

SELECT 'Profile images bucket policies created successfully!' AS status;

-- ========================================
-- 📝 วิธีใช้งานจาก Flutter
-- ========================================

/*
// 1. อัปโหลดรูปโปรไฟล์
final userId = Supabase.instance.client.auth.currentUser!.id;
final fileName = '$userId/profile-${DateTime.now().millisecondsSinceEpoch}.jpg';

await Supabase.instance.client.storage
  .from('student_profile_images')
  .upload(fileName, File(imagePath));

// 2. ดึง Public URL (สำหรับแสดงรูป)
final url = Supabase.instance.client.storage
  .from('student_profile_images')
  .getPublicUrl(fileName);

// 3. อัปเดต students table
await Supabase.instance.client
  .from('students')
  .update({'profile_image_url': url})
  .eq('id', userId);
*/
