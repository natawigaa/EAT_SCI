-- ========================================
-- เพิ่ม QR Code URL สำหรับแต่ละร้านอาหาร
-- ========================================

-- 1. เพิ่ม column qr_code_url ใน restaurants table
ALTER TABLE restaurants 
ADD COLUMN IF NOT EXISTS qr_code_url TEXT;

-- 2. เพิ่ม comment อธิบาย column
COMMENT ON COLUMN restaurants.qr_code_url IS 'URL ของ QR Code PromptPay/Mobile Banking ของร้าน (จาก Supabase Storage)';

-- ========================================
-- วิธีใช้งาน:
-- ========================================

-- 1. สร้าง Storage Bucket ชื่อ "restaurant-qr-codes" (Public)
--    ไปที่ Supabase Dashboard → Storage → Create New Bucket
--    ตั้งค่า: Public bucket = true

-- 2. อัปโหลดรูป QR Code ของแต่ละร้าน
--    ชื่อไฟล์แนะนำ: restaurant-{id}-qr.png
--    ตัวอย่าง: restaurant-1-qr.png, restaurant-2-qr.png

-- 3. คัดลอก Public URL ของรูปที่อัปโหลด
--    รูปแบบ URL: https://{project-id}.supabase.co/storage/v1/object/public/restaurant-qr-codes/restaurant-1-qr.png

-- 4. Update qr_code_url ให้กับแต่ละร้าน
-- UPDATE restaurants 
-- SET qr_code_url = 'https://your-project.supabase.co/storage/v1/object/public/restaurant-qr-codes/restaurant-1-qr.png'
-- WHERE id = 1;

-- UPDATE restaurants 
-- SET qr_code_url = 'https://your-project.supabase.co/storage/v1/object/public/restaurant-qr-codes/restaurant-2-qr.png'
-- WHERE id = 2;

-- 5. ตรวจสอบ
-- SELECT id, name, qr_code_url FROM restaurants;

-- ========================================
-- Note: ถ้าร้านไม่มี QR Code (qr_code_url = NULL)
-- แอปจะแสดง QR Code แบบ text fallback
-- ========================================
