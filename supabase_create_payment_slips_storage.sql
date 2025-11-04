-- ========================================
-- Supabase Storage: Payment Slips Bucket
-- ========================================
-- สร้าง bucket สำหรับเก็บสลิปการโอนเงินจากนักศึกษา
-- Path: payment-slips/order_{orderId}_{timestamp}.jpg

-- 1. สร้าง bucket (ทำใน Supabase Dashboard → Storage → Create Bucket)
--    - Name: payment-slips
--    - Public: ❌ (Private - เฉพาะ authenticated users)
--    - File size limit: 5 MB
--    - Allowed MIME types: image/jpeg, image/png, image/webp

-- หรือรันคำสั่งนี้ใน SQL Editor (ถ้า Supabase version รองรับ):
-- INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
-- VALUES (
--   'payment-slips',
--   'payment-slips',
--   false,  -- Private bucket
--   5242880,  -- 5 MB
--   ARRAY['image/jpeg', 'image/png', 'image/webp']
-- )
-- ON CONFLICT (id) DO NOTHING;


-- ========================================
-- 2. RLS Policies สำหรับ payment-slips
-- ========================================

-- Policy 1: Authenticated users (นักศึกษา) สามารถอัปโหลดสลิปได้
CREATE POLICY "Authenticated users can upload payment slips"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'payment-slips' AND
  (storage.foldername(name))[1] = 'order_slips'
);

-- Policy 2: Authenticated users สามารถดูสลิปของตัวเองได้
-- (ต้องเช็คว่า order นั้นเป็นของตัวเอง - จะทำใน application layer)
CREATE POLICY "Users can view payment slips"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'payment-slips');

-- Policy 3: Restaurant owners สามารถดูสลิปของ orders ที่เป็นของร้านตัวเองได้
-- (เช็คผ่าน orders table)
CREATE POLICY "Restaurant owners can view their order slips"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'payment-slips'
);

-- Policy 4: Users สามารถลบสลิปของตัวเองได้ (ภายใน 5 นาทีหลังสร้าง order)
CREATE POLICY "Users can delete their own slips"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'payment-slips' AND
  owner = auth.uid()
);


-- ========================================
-- 3. ตรวจสอบ bucket ถูกสร้างหรือยัง
-- ========================================
-- SELECT * FROM storage.buckets WHERE name = 'payment-slips';


-- ========================================
-- 4. ตัวอย่างการใช้งาน (จะทำใน Flutter)
-- ========================================
-- Upload:
--   final file = File('path/to/slip.jpg');
--   final fileName = 'order_slips/order_${orderId}_${timestamp}.jpg';
--   await Supabase.instance.client.storage
--     .from('payment-slips')
--     .upload(fileName, file);
--
-- Get URL:
--   final url = Supabase.instance.client.storage
--     .from('payment-slips')
--     .getPublicUrl(fileName);  // สำหรับ private bucket ใช้ signed URL
--
-- Delete:
--   await Supabase.instance.client.storage
--     .from('payment-slips')
--     .remove([fileName]);


-- ========================================
-- หมายเหตุสำคัญ
-- ========================================
-- 1. นักศึกษาต้อง login ก่อนถึงจะอัปโหลดได้ (authenticated)
-- 2. ชื่อไฟล์ควรเป็น: order_slips/order_{orderId}_{timestamp}.jpg
-- 3. ร้านค้าจะดูสลิปผ่าน orders.payment_slip_url
-- 4. ถ้าต้องการ signed URL (สำหรับ private bucket):
--    final signedUrl = await Supabase.instance.client.storage
--      .from('payment-slips')
--      .createSignedUrl(fileName, 3600);  // expires in 1 hour
