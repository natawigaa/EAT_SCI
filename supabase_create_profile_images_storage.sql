-- สร้าง Storage bucket สำหรับรูปโปรไฟล์นักศึกษา
-- Run this in Supabase SQL Editor

-- สร้าง bucket ชื่อ 'profile_images'
INSERT INTO storage.buckets (id, name, public)
VALUES ('profile_images', 'profile_images', true)
ON CONFLICT (id) DO NOTHING;

-- ตั้งค่า Storage policies เพื่อให้นักศึกษาอัปโหลดและลบรูปของตัวเองได้

-- Policy 1: ให้ทุกคนดูรูปได้ (public read)
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
USING ( bucket_id = 'profile_images' );

-- Policy 2: ให้นักศึกษาอัปโหลดรูปของตัวเองได้
CREATE POLICY "Students can upload their own profile images"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'profile_images' 
  AND auth.role() = 'authenticated'
  AND (storage.foldername(name))[1] = 'profile_images'
);

-- Policy 3: ให้นักศึกษาลบรูปของตัวเองได้
CREATE POLICY "Students can delete their own profile images"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'profile_images'
  AND auth.role() = 'authenticated'
);

-- Policy 4: ให้นักศึกษาอัปเดตรูปของตัวเองได้ (upsert)
CREATE POLICY "Students can update their own profile images"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'profile_images'
  AND auth.role() = 'authenticated'
);
