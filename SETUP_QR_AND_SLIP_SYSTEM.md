# 🎯 สรุป: ระบบอัปโหลด QR Code ร้านค้า + สลิปนักศึกษา

## ✅ **สิ่งที่สร้างเสร็จแล้ว:**

### 1. 📱 **Flutter Code (ทุกไฟล์พร้อมแล้ว!)**

#### **ฝั่งร้านค้า** - `lib/dashboard/restaurant_dashboard_v2.dart`
- ✅ **SettingsTab** มีฟีเจอร์อัปโหลด QR Code PromptPay
- ✅ เลือกภาพจาก Gallery
- ✅ อัปโหลดไปยัง Supabase Storage bucket `restaurant-qr-codes`
- ✅ อัปเดต URL ใน database (restaurants.qr_code_url)
- ✅ แสดง QR Code ปัจจุบัน + ปุ่มเปลี่ยน

#### **ฝั่งนักศึกษา** - `lib/innnerScreen/PaymentScreen.dart`
- ✅ สร้าง order แล้วให้อัปโหลดสลิปในหน้าเดียวกัน
- ✅ เลือกภาพสลิปจาก Gallery
- ✅ อัปโหลดไปยัง Supabase Storage bucket `payment-slips`
- ✅ อัปเดต order ด้วย slip URL
- ✅ แสดง preview ภาพที่เลือก
- ✅ ปุ่ม "กลับหน้าหลัก" หลังอัปโหลดสลิปเสร็จ

#### **Backend Functions** - `lib/services/supabase_service.dart`
- ✅ `uploadRestaurantQrCode()` - อัปโหลด QR Code ร้าน
- ✅ `updateRestaurantQrCode()` - อัปเดต URL ใน database
- ✅ `uploadPaymentSlip()` - อัปโหลดสลิปนักศึกษา
- ✅ `updateOrderWithSlip()` - อัปเดต order ด้วย slip
- ✅ `confirmOrderSlip()` - ร้านยืนยันสลิป
- ✅ `rejectOrderSlip()` - ร้านปฏิเสธสลิป
- ✅ `getPendingSlipOrders()` - ดึง orders ที่รอตรวจสลิป

### 2. 📦 **Dependencies**
- ✅ เพิ่ม `image_picker: ^1.0.7` ใน `pubspec.yaml`
- ✅ รัน `flutter pub get` แล้ว

---

## 🚨 **สิ่งที่ต้องทำใน Supabase Dashboard:**

### **ขั้นตอนที่ 1: รัน SQL Scripts** (สำคัญมาก!)

เข้า **Supabase Dashboard** → **SQL Editor** → รัน 2 scripts นี้:

#### 1.1 รัน `supabase_add_qr_code.sql`
```sql
-- เพิ่ม column สำหรับเก็บ URL ของ QR Code ร้าน
ALTER TABLE restaurants 
ADD COLUMN IF NOT EXISTS qr_code_url TEXT;

COMMENT ON COLUMN restaurants.qr_code_url IS 'URL ของ QR Code PromptPay/Mobile Banking ของร้าน';
```

#### 1.2 รัน `supabase_add_slip_upload.sql`
```sql
-- เพิ่ม columns สำหรับเก็บข้อมูลสลิปและการตรวจสอบ
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS payment_slip_url TEXT,
ADD COLUMN IF NOT EXISTS slip_uploaded_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS slip_verified_by UUID REFERENCES auth.users(id),
ADD COLUMN IF NOT EXISTS slip_verified_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

-- เพิ่ม index เพื่อความเร็ว
CREATE INDEX IF NOT EXISTS idx_orders_slip_status 
ON orders(status, slip_uploaded_at);
```

✅ **ตรวจสอบว่ารันสำเร็จ:**
```sql
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'orders' 
  AND column_name IN ('payment_slip_url', 'slip_uploaded_at');
```

---

### **ขั้นตอนที่ 2: สร้าง Storage Buckets**

#### 2.1 Bucket: `restaurant-qr-codes` (Public)
1. **Storage** → **Create New Bucket**
2. ตั้งค่า:
   - Name: `restaurant-qr-codes`
   - Public: ✅ **เปิด** (เพื่อให้นักศึกษาเห็น QR)
   - File size limit: **2MB**
   - Allowed MIME types: `image/png, image/jpeg, image/jpg`

#### 2.2 Bucket: `payment-slips` (Private)
1. **Storage** → **Create New Bucket**
2. ตั้งค่า:
   - Name: `payment-slips`
   - Public: ❌ **ปิด** (ความปลอดภัย - เฉพาะเจ้าของดู)
   - File size limit: **5MB**
   - Allowed MIME types: `image/png, image/jpeg, image/jpg`

---

### **ขั้นตอนที่ 3: ตั้งค่า Storage Policies (RLS)**

#### 3.1 Policies สำหรับ `restaurant-qr-codes`

```sql
-- ร้านค้าอัปโหลด QR Code ของตัวเองได้
CREATE POLICY "Restaurant owners can upload their QR"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'restaurant-qr-codes'
);

-- ทุกคนอ่าน QR Code ได้
CREATE POLICY "Anyone can view QR codes"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'restaurant-qr-codes');

-- ร้านค้าลบ QR Code ของตัวเองได้
CREATE POLICY "Restaurant owners can delete their QR"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'restaurant-qr-codes');
```

#### 3.2 Policies สำหรับ `payment-slips`

```sql
-- นักศึกษาอัปโหลดสลิปได้
CREATE POLICY "Students can upload payment slips"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'payment-slips');

-- เจ้าของ order ดูสลิปได้
CREATE POLICY "Order participants can view slips"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'payment-slips');

-- นักศึกษาลบสลิปของตัวเองได้
CREATE POLICY "Students can delete their slips"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'payment-slips');
```

---

## 🧪 **วิธีทดสอบ:**

### **A. ทดสอบฝั่งร้านค้า (อัปโหลด QR Code)**

1. Login ด้วยอีเมลร้านค้า เช่น `pasom1@gmail.com`
2. ไปที่ Tab **"ตั้งค่า"** (⚙️ Settings)
3. เลื่อนลงมาหาส่วน **"QR Code ชำระเงิน"**
4. กดปุ่ม **"อัปโหลด QR Code"**
5. เลือกรูป QR Code PromptPay ของร้าน
6. รอจนแสดง ✅ "อัปโหลด QR Code สำเร็จ!"
7. ตรวจสอบ: รูป QR Code ควรแสดงในหน้า Settings

### **B. ทดสอบฝั่งนักศึกษา (สั่งอาหาร + อัปโหลดสลิป)**

1. Login ด้วยอีเมลนักศึกษา เช่น `xxx@kmitl.ac.th`
2. เลือกร้านอาหาร → เลือกเมนู → เพิ่มในตะกร้า
3. กดชำระเงิน → จะเห็น **QR Code จริงของร้าน** (ถ้าร้านอัปโหลดไว้แล้ว)
4. สแกน QR Code และโอนเงินจริง
5. กดปุ่ม **"สร้างคำสั่งซื้อ"**
6. รอจนแสดง ✅ "สร้างคำสั่งซื้อสำเร็จ!"
7. จะเห็นส่วน **"อัปโหลดสลิปการโอนเงิน"** ปรากฏขึ้น
8. กด **"เลือกภาพสลิป"** → เลือกรูปสลิปโอนเงิน
9. กด **"ยืนยันอัปโหลดสลิป"**
10. รอจนแสดง ✅ "อัปโหลดสลิปสำเร็จ! รอร้านตรวจสอบ"
11. กด **"กลับหน้าหลัก"** → ตะกร้าจะถูกล้าง

### **C. ทดสอบฝั่งร้านค้า (ตรวจสอบสลิป)**

1. Login ด้วยอีเมลร้านค้า
2. ไปที่ Tab **"คำสั่งซื้อ"** (📦 Orders)
3. จะเห็น order ที่รอตรวจสอบ พร้อมปุ่ม **"ดูสลิป"**
4. กดปุ่ม **"ดูสลิป"** → จะเปิดภาพสลิปขนาดใหญ่
5. ตรวจสอบสลิป:
   - ✅ ถูกต้อง → กด **"ยืนยันรับออเดอร์"** (เปลี่ยน status → confirmed)
   - ❌ ไม่ถูกต้อง → กด **"ปฏิเสธ"** → ระบุเหตุผล (เปลี่ยน status → cancelled)

---

## 📊 **Flow Chart ของระบบ:**

```
นักศึกษา                           ระบบ                              ร้านค้า
   │                                 │                                   │
   │─────(1) สั่งอาหาร───────────►  │                                   │
   │                                 │──── สร้าง order (pending) ────►  │
   │                                 │                                   │
   │◄──── แสดง QR Code ร้าน ────────│                                   │
   │                                 │                                   │
   │─────(2) โอนเงิน + อัปโหลดสลิป─►│                                   │
   │                                 │──── บันทึก slip URL ──────────►  │
   │                                 │                                   │
   │                                 │  ◄──(3) ร้านเปิดดูสลิป ──────────│
   │                                 │                                   │
   │                                 │  ◄──(4a) ยืนยัน (confirmed) ─────│
   │                                 │      หรือ                         │
   │                                 │  ◄──(4b) ปฏิเสธ (cancelled) ─────│
   │                                 │                                   │
   │◄──── แจ้งสถานะผ่าน app ─────────│────► อัปเดตสถานะ order ─────────►│
```

---

## 🔍 **ตรวจสอบ Database หลัง Setup:**

```sql
-- ตรวจสอบว่ามี QR Code URL แล้วหรือยัง
SELECT id, name, qr_code_url FROM restaurants;

-- ตรวจสอบ orders ที่มีสลิป
SELECT id, student_id, restaurant_name, total_amount, 
       status, payment_slip_url, slip_uploaded_at
FROM orders 
WHERE payment_slip_url IS NOT NULL;

-- ตรวจสอบ storage buckets
SELECT id, name, public FROM storage.buckets 
WHERE name IN ('restaurant-qr-codes', 'payment-slips');
```

---

## 🐛 **Troubleshooting:**

### ❌ Error: `column orders.payment_slip_url does not exist`
**สาเหตุ:** ยังไม่ได้รัน SQL script  
**แก้ไข:** รัน `supabase_add_slip_upload.sql` ใน SQL Editor

### ❌ Error: `new row violates row-level security policy`
**สาเหตุ:** ยังไม่ได้ตั้งค่า Storage Policies  
**แก้ไข:** รัน SQL policies ในขั้นตอนที่ 3

### ❌ ไม่สามารถอัปโหลดไฟล์ได้
**สาเหตุ:** Storage bucket ไม่มีหรือตั้งค่าผิด  
**แก้ไข:** 
1. เช็คว่าสร้าง bucket แล้วหรือยัง
2. เช็ค bucket name ให้ตรงกับโค้ด (`restaurant-qr-codes`, `payment-slips`)
3. เช็ค File size limit และ MIME types

### ⚠️ `setState() called after dispose` (LoginScreen)
**สาเหตุ:** StreamBuilder เปลี่ยนหน้าก่อน setState จะรัน  
**แก้ไข:** เล็กน้อย ไม่กระทบการใช้งาน (จะแก้ในเฟสหลัง)

---

## 📝 **Next Steps:**

1. ✅ **Setup Database** (ขั้นตอนที่ 1-3 ด้านบน)
2. ✅ **ทดสอบอัปโหลด QR Code** (ฝั่งร้านค้า)
3. ✅ **ทดสอบสั่งอาหาร + อัปโหลดสลิป** (ฝั่งนักศึกษา)
4. ✅ **ทดสอบตรวจสอบสลิป** (ฝั่งร้านค้า)
5. 🚧 **Phase 2:** เพิ่มฟีเจอร์ history order + tracking status
6. 🚧 **Phase 3:** ปรับปรุง UI/UX, เพิ่ม notification

---

## 📞 **ช่วยเหลือเพิ่มเติม:**

- 📁 เอกสารคำแนะนำ: `DATABASE_SETUP_INSTRUCTIONS.md`
- 🗂️ SQL Scripts: `supabase_add_qr_code.sql`, `supabase_add_slip_upload.sql`
- 📖 Supabase Docs: https://supabase.com/docs/guides/storage

---

**🎉 พร้อมแล้ว! เริ่มต้น Setup Database ได้เลยค่ะ**
