# 🗄️ Database Setup Instructions

## ขั้นตอนที่ 1: Run SQL Scripts

เข้า **Supabase Dashboard** → **SQL Editor** แล้วรัน SQL files ตามลำดับ:

### 1.1 เพิ่ม QR Code Column
```sql
-- ไฟล์: supabase_add_qr_code.sql
ALTER TABLE restaurants 
ADD COLUMN IF NOT EXISTS qr_code_url TEXT;
```

### 1.2 เพิ่ม Payment Slip Columns
```sql
-- ไฟล์: supabase_add_slip_upload.sql
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS payment_slip_url TEXT,
ADD COLUMN IF NOT EXISTS slip_uploaded_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS slip_verified_by UUID REFERENCES auth.users(id),
ADD COLUMN IF NOT EXISTS slip_verified_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

CREATE INDEX IF NOT EXISTS idx_orders_slip_status ON orders(status, slip_uploaded_at);
```

---

## ขั้นตอนที่ 2: สร้าง Storage Buckets

### 2.1 Bucket สำหรับ QR Code ร้านค้า

1. ไปที่ **Storage** → **Create New Bucket**
2. ตั้งค่า:
   - **Name:** `restaurant-qr-codes`
   - **Public:** ✅ **เปิด** (ให้นักศึกษาเห็น QR Code)
   - **File size limit:** 2MB
   - **Allowed MIME types:** `image/png, image/jpeg, image/jpg`

### 2.2 Bucket สำหรับสลิปนักศึกษา

1. ไปที่ **Storage** → **Create New Bucket**
2. ตั้งค่า:
   - **Name:** `payment-slips`
   - **Public:** ❌ **ปิด** (เฉพาะร้านค้าดูได้)
   - **File size limit:** 5MB
   - **Allowed MIME types:** `image/png, image/jpeg, image/jpg`

---

## ขั้นตอนที่ 3: ตั้งค่า Storage Policies (RLS)

### 3.1 Policies สำหรับ `restaurant-qr-codes`

```sql
-- ร้านค้าอัปโหลด QR Code ของตัวเองได้
CREATE POLICY "Restaurant owners can upload their QR"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'restaurant-qr-codes' AND
  (storage.foldername(name))[1] = 'restaurant-' || (
    SELECT id::text FROM restaurants WHERE owner_id = auth.uid()
  )
);

-- ทุกคนอ่าน QR Code ได้ (public bucket)
CREATE POLICY "Anyone can view QR codes"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'restaurant-qr-codes');

-- ร้านค้าลบ QR Code ของตัวเองได้
CREATE POLICY "Restaurant owners can delete their QR"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'restaurant-qr-codes' AND
  (storage.foldername(name))[1] = 'restaurant-' || (
    SELECT id::text FROM restaurants WHERE owner_id = auth.uid()
  )
);
```

### 3.2 Policies สำหรับ `payment-slips`

```sql
-- นักศึกษาอัปโหลดสลิปได้ (ชื่อไฟล์ขึ้นต้นด้วย student_id)
CREATE POLICY "Students can upload payment slips"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'payment-slips'
);

-- เจ้าของ order ดูสลิปได้ (นักศึกษาและร้านค้า)
CREATE POLICY "Order participants can view slips"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'payment-slips');

-- นักศึกษาลบสลิปของตัวเองได้ (ถ้าอัปโหลดผิด)
CREATE POLICY "Students can delete their slips"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'payment-slips');
```

---

## ✅ ตรวจสอบการติดตั้ง

รัน SQL นี้เพื่อเช็คว่าทุกอย่างพร้อมหรือยัง:

```sql
-- เช็ค columns
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'restaurants' AND column_name = 'qr_code_url';

SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'orders' 
  AND column_name IN ('payment_slip_url', 'slip_uploaded_at', 'slip_verified_by');

-- เช็ค storage buckets
SELECT id, name, public FROM storage.buckets 
WHERE name IN ('restaurant-qr-codes', 'payment-slips');
```

---

## 📝 Note สำคัญ:

1. **รัน SQL scripts ก่อน** (supabase_add_qr_code.sql, supabase_add_slip_upload.sql)
2. **สร้าง storage buckets** (restaurant-qr-codes = public, payment-slips = private)
3. **ตั้งค่า RLS policies** ตามด้านบน
4. เสร็จแล้วกลับมา Flutter เพื่อทำ UI ส่วนอัปโหลด

---

## 🚀 พร้อมแล้ว? 

หลังจาก setup เสร็จ ให้กลับมาที่ Flutter และรัน:

```bash
flutter pub add image_picker
flutter pub add file_picker
flutter pub get
```

แล้วเริ่มสร้าง UI สำหรับ:
- ร้านค้าอัปโหลด QR Code (SettingsTab)
- นักศึกษาอัปโหลดสลิป (PaymentScreen)
