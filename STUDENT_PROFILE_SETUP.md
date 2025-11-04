# 📸 Student Profile Management Setup Guide

## 🎯 ภาพรวม

การจัดการโปรไฟล์นักศึกษาประกอบด้วย:
1. **Database:** ตาราง `students` เก็บข้อมูลนักศึกษา
2. **Storage:** Bucket `student_profile_images` เก็บรูปโปรไฟล์
3. **Flutter:** หน้า `ProfileScreen` และ `EditProfileScreen` จัดการ UI
4. **Service:** `SupabaseService` จัดการการอัปโหลดและอัปเดต

---

## 📋 ขั้นตอนการ Setup Database

### 1️⃣ สร้าง Students Table

เข้า **Supabase Dashboard** → **SQL Editor** → รัน:

```sql
-- ไฟล์: supabase_create_students_table.sql
```

**ฟิลด์สำคัญ:**
- `id` (UUID) - Foreign Key จาก `auth.users`
- `student_id` (VARCHAR) - รหัสนักศึกษา (ไม่สามารถแก้ไข)
- `first_name`, `last_name` - ชื่อ-นามสกุล (แก้ไขได้)
- `email` - อีเมล (แก้ไขได้)
- `phone_number` - เบอร์โทร (แก้ไขได้)
- `profile_image_url` - URL รูปโปรไฟล์ (แก้ไขได้)
- `faculty`, `department`, `year`, `university` - ข้อมูลการศึกษา (อ่านอย่างเดียว)

**RLS Policies:**
✅ นักศึกษาดู/แก้ไขข้อมูลตัวเองได้  
✅ ป้องกันการแก้ไขฟิลด์การศึกษา  
✅ ร้านค้าดูข้อมูลพื้นฐานของลูกค้าได้

---

### 2️⃣ สร้าง Storage Bucket สำหรับรูปโปรไฟล์

#### A. สร้าง Bucket (ใน Dashboard)

1. ไปที่ **Storage** → **Create New Bucket**
2. ตั้งค่า:
   - **Name:** `student_profile_images`
   - **Public:** ❌ **ปิด** (เฉพาะเจ้าของดูได้)
   - **File size limit:** 5MB
   - **Allowed MIME types:** 
     ```
     image/png
     image/jpeg
     image/jpg
     image/webp
     ```

#### B. ตั้งค่า RLS Policies

รัน SQL นี้:

```sql
-- ไฟล์: supabase_create_profile_images_bucket.sql
```

**Policies:**
✅ นักศึกษาอัปโหลด/ดู/แก้ไข/ลบรูปตัวเองได้  
✅ ร้านค้าดูรูปลูกค้าที่สั่งอาหารได้ (optional)

---

### 3️⃣ ตรวจสอบการติดตั้ง

รัน SQL เพื่อเช็ค:

```sql
-- เช็คว่ามี students table
SELECT * FROM students LIMIT 1;

-- เช็ค columns
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'students'
ORDER BY ordinal_position;

-- เช็ค storage bucket
SELECT id, name, public 
FROM storage.buckets 
WHERE name = 'student_profile_images';

-- เช็ค policies
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE tablename = 'students';
```

---

## 🔧 ขั้นตอนการ Setup Flutter

### 4️⃣ เพิ่ม Dependencies

```bash
flutter pub add image_picker
flutter pub get
```

### 5️⃣ อัปเดต SupabaseService

เพิ่มฟังก์ชันเหล่านี้ใน `lib/services/supabase_service.dart`:

```dart
// ========================================
// Student Profile Management
// ========================================

/// ดึงข้อมูลโปรไฟล์นักศึกษา
static Future<Map<String, dynamic>?> getStudentProfile(String userId) async {
  try {
    final response = await _client
        .from('students')
        .select()
        .eq('id', userId)
        .single();
    
    print('✅ ดึงข้อมูลโปรไฟล์สำเร็จ');
    return response;
  } catch (e) {
    print('❌ Error fetching student profile: $e');
    return null;
  }
}

/// อัปเดตข้อมูลโปรไฟล์ (ยกเว้นฟิลด์การศึกษา)
static Future<bool> updateStudentProfile({
  required String userId,
  String? firstName,
  String? lastName,
  String? email,
  String? phoneNumber,
  String? profileImageUrl,
}) async {
  try {
    final updateData = <String, dynamic>{};
    if (firstName != null) updateData['first_name'] = firstName;
    if (lastName != null) updateData['last_name'] = lastName;
    if (email != null) updateData['email'] = email;
    if (phoneNumber != null) updateData['phone_number'] = phoneNumber;
    if (profileImageUrl != null) updateData['profile_image_url'] = profileImageUrl;
    
    await _client
        .from('students')
        .update(updateData)
        .eq('id', userId);
    
    print('✅ อัปเดตโปรไฟล์สำเร็จ');
    return true;
  } catch (e) {
    print('❌ Error updating student profile: $e');
    return false;
  }
}

/// อัปโหลดรูปโปรไฟล์
static Future<String?> uploadProfileImage(String filePath, String userId) async {
  try {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '$userId/profile-$timestamp.jpg';
    
    print('📤 กำลังอัปโหลดรูปโปรไฟล์: $fileName');
    
    // ลบรูปเก่า (ถ้ามี)
    try {
      final oldFiles = await _client.storage
          .from('student_profile_images')
          .list(path: userId);
      
      for (var file in oldFiles) {
        await _client.storage
            .from('student_profile_images')
            .remove(['$userId/${file.name}']);
      }
      print('🗑️ ลบรูปเก่าแล้ว');
    } catch (e) {
      print('⚠️ ไม่มีรูปเก่า หรือลบไม่สำเร็จ: $e');
    }
    
    // อัปโหลดรูปใหม่
    await _client.storage
        .from('student_profile_images')
        .upload(fileName, File(filePath));
    
    // ดึง Public URL
    final url = _client.storage
        .from('student_profile_images')
        .getPublicUrl(fileName);
    
    print('✅ อัปโหลดรูปโปรไฟล์สำเร็จ: $url');
    return url;
  } catch (e) {
    print('❌ Error uploading profile image: $e');
    return null;
  }
}

/// ลบรูปโปรไฟล์
static Future<bool> deleteProfileImage(String userId) async {
  try {
    final files = await _client.storage
        .from('student_profile_images')
        .list(path: userId);
    
    for (var file in files) {
      await _client.storage
          .from('student_profile_images')
          .remove(['$userId/${file.name}']);
    }
    
    print('✅ ลบรูปโปรไฟล์สำเร็จ');
    return true;
  } catch (e) {
    print('❌ Error deleting profile image: $e');
    return false;
  }
}
```

### 6️⃣ อัปเดต EditProfileScreen

แก้ไขฟังก์ชันเหล่านี้:

```dart
// เพิ่ม import
import 'package:image_picker/image_picker.dart';
import 'package:eatscikmitl/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

// เพิ่ม state
File? _selectedImage;
bool _isUploadingImage = false;

// แก้ไข _pickImageFromGallery
void _pickImageFromGallery() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 1024,
    maxHeight: 1024,
    imageQuality: 85,
  );
  
  if (pickedFile != null) {
    setState(() {
      _selectedImage = File(pickedFile.path);
      _hasChanges = true;
    });
    print('✅ เลือกรูปจากแกลเลอรี่แล้ว: ${pickedFile.path}');
  }
}

// แก้ไข _pickImageFromCamera
void _pickImageFromCamera() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(
    source: ImageSource.camera,
    maxWidth: 1024,
    maxHeight: 1024,
    imageQuality: 85,
  );
  
  if (pickedFile != null) {
    setState(() {
      _selectedImage = File(pickedFile.path);
      _hasChanges = true;
    });
    print('✅ ถ่ายรูปสำเร็จ: ${pickedFile.path}');
  }
}

// แก้ไข _removeProfileImage
void _removeProfileImage() async {
  setState(() {
    _selectedImage = null;
    _hasChanges = true;
  });
  
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId != null) {
    await SupabaseService.deleteProfileImage(userId);
    await SupabaseService.updateStudentProfile(
      userId: userId,
      profileImageUrl: null,
    );
  }
  
  print('✅ ลบรูปโปรไฟล์แล้ว');
}

// แก้ไข _saveProfile
void _saveProfile() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('ไม่พบข้อมูลผู้ใช้');
    }
    
    String? profileImageUrl;
    
    // อัปโหลดรูปโปรไฟล์ (ถ้ามีการเปลี่ยน)
    if (_selectedImage != null) {
      setState(() {
        _isUploadingImage = true;
      });
      
      profileImageUrl = await SupabaseService.uploadProfileImage(
        _selectedImage!.path,
        userId,
      );
      
      setState(() {
        _isUploadingImage = false;
      });
    }
    
    // อัปเดตข้อมูลโปรไฟล์
    final success = await SupabaseService.updateStudentProfile(
      userId: userId,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      profileImageUrl: profileImageUrl,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.75),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('บันทึกข้อมูลเรียบร้อยแล้ว'),
              ],
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      setState(() {
        _hasChanges = false;
      });
      
      Navigator.of(context).pop(true);
    }
  } catch (e) {
    print('❌ Error saving profile: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

// อัปเดต _buildProfileImageSection ให้แสดงรูปที่เลือก
Widget _buildProfileImageSection() {
  return Container(
    color: Colors.white,
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[200],
              backgroundImage: _selectedImage != null
                  ? FileImage(_selectedImage!)
                  : (currentUser.profileImage.isNotEmpty
                      ? NetworkImage(currentUser.profileImage) as ImageProvider
                      : null),
              child: _selectedImage == null && currentUser.profileImage.isEmpty
                  ? Icon(Icons.person, size: 60, color: Colors.grey[400])
                  : null,
            ),
            if (_isUploadingImage)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _changeProfileImage,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.mainOrange,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _selectedImage != null 
              ? 'รูปใหม่ที่เลือก (กดบันทึกเพื่ออัปโหลด)'
              : 'แตะเพื่อเปลี่ยนรูปโปรไฟล์',
          style: TextStyle(
            fontSize: 14,
            color: _selectedImage != null ? AppColors.mainOrange : Colors.grey[600],
            fontWeight: _selectedImage != null ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    ),
  );
}
```

---

## ✅ Checklist การ Setup

### Database
- [ ] รัน `supabase_create_students_table.sql`
- [ ] สร้าง bucket `student_profile_images`
- [ ] รัน `supabase_create_profile_images_bucket.sql`
- [ ] ตรวจสอบด้วย SQL queries

### Flutter
- [ ] เพิ่ม `image_picker` package
- [ ] เพิ่มฟังก์ชันใน `SupabaseService`
- [ ] อัปเดต `EditProfileScreen`
- [ ] อัปเดต `ProfileScreen`
- [ ] ทดสอบอัปโหลดรูป
- [ ] ทดสอบแก้ไขข้อมูล

---

## 🧪 การทดสอบ

1. **ทดสอบอัปโหลดรูป:**
   - เลือกจากแกลเลอรี่
   - ถ่ายรูปใหม่
   - ลบรูปโปรไฟล์

2. **ทดสอบแก้ไขข้อมูล:**
   - แก้ไขชื่อ-นามสกุล
   - แก้ไขอีเมล
   - แก้ไขเบอร์โทร
   - **ห้ามแก้ไข:** รหัสนักศึกษา, คณะ, สาขา, ชั้นปี

3. **ทดสอบ RLS:**
   - นักศึกษา A แก้ไขข้อมูลนักศึกษา B ไม่ได้
   - ร้านค้าดูข้อมูลลูกค้าที่สั่งอาหารได้

---

## 📝 สรุป

**สิ่งที่ต้องจัดการใน Database:**
1. ✅ สร้าง `students` table พร้อม RLS policies
2. ✅ สร้าง `student_profile_images` bucket พร้อม policies
3. ✅ ป้องกันการแก้ไขฟิลด์การศึกษา

**สิ่งที่ต้องทำใน Flutter:**
1. ✅ เพิ่ม `image_picker` package
2. ✅ สร้างฟังก์ชันอัปโหลด/ลบรูปใน `SupabaseService`
3. ✅ เชื่อมต่อ UI กับ database จริง
4. ✅ แทนที่ `SampleUserData` ด้วยข้อมูลจาก Supabase

---

## 🚀 พร้อมเริ่มต้น?

1. รัน SQL scripts ใน Supabase Dashboard
2. สร้าง storage bucket
3. อัปเดตโค้ด Flutter ตามคู่มือ
4. ทดสอบอัปโหลดรูปและแก้ไขข้อมูล

**หากมีปัญหา:** ตรวจสอบ logs ใน console และ Supabase Dashboard
