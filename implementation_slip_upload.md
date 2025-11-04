# 📸 Implementation: Slip Upload & Verification

## Database Schema

```sql
-- เพิ่ม column payment_slip_url ใน orders table
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS payment_slip_url TEXT,
ADD COLUMN IF NOT EXISTS slip_verified BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS slip_amount NUMERIC(10,2),
ADD COLUMN IF NOT EXISTS slip_ref_number TEXT,
ADD COLUMN IF NOT EXISTS slip_uploaded_at TIMESTAMPTZ;

-- เพิ่ม comment
COMMENT ON COLUMN orders.payment_slip_url IS 'URL ของสลิปโอนเงิน (Supabase Storage)';
COMMENT ON COLUMN orders.slip_verified IS 'ร้านค้ายืนยันสลิปแล้วหรือยัง';
```

## Storage Bucket

1. สร้าง bucket: `payment-slips`
2. ตั้งค่า: Public = false (เพื่อความปลอดภัย)
3. RLS Policy: ให้เฉพาะ owner + restaurant เข้าถึง

## Flutter Implementation

### 1. เพิ่ม dependencies

```yaml
# pubspec.yaml
dependencies:
  image_picker: ^1.0.4
  google_ml_kit: ^0.16.0
  supabase_flutter: ^2.0.0
```

### 2. Upload Slip Function

```dart
// lib/services/supabase_service.dart

static Future<String?> uploadPaymentSlip(File imageFile, int orderId) async {
  try {
    final fileName = 'slip-$orderId-${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'payment-slips/$fileName';
    
    // อัปโหลดไปยัง Supabase Storage
    await _client.storage
        .from('payment-slips')
        .upload(path, imageFile);
    
    // ดึง URL
    final url = _client.storage
        .from('payment-slips')
        .getPublicUrl(path);
    
    print('✅ อัปโหลด slip สำเร็จ: $url');
    return url;
  } catch (e) {
    print('❌ Error uploading slip: $e');
    return null;
  }
}

static Future<bool> updateOrderWithSlip({
  required int orderId,
  required String slipUrl,
  double? slipAmount,
  String? refNumber,
}) async {
  try {
    await _client
        .from('orders')
        .update({
          'payment_slip_url': slipUrl,
          'slip_amount': slipAmount,
          'slip_ref_number': refNumber,
          'slip_uploaded_at': DateTime.now().toIso8601String(),
          'status': 'pending', // รอร้านยืนยัน
        })
        .eq('id', orderId);
    
    print('✅ อัปเดต order #$orderId ด้วย slip');
    return true;
  } catch (e) {
    print('❌ Error updating order: $e');
    return false;
  }
}
```

### 3. OCR Verification (Optional - ฟรี)

```dart
// lib/services/slip_ocr_service.dart
import 'package:google_ml_kit/google_ml_kit.dart';
import 'dart:io';

class SlipOcrService {
  static Future<Map<String, dynamic>> extractSlipData(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer();
    
    try {
      final RecognizedText recognizedText = 
          await textRecognizer.processImage(inputImage);
      
      String allText = recognizedText.text.toLowerCase();
      print('📝 OCR Text: $allText');
      
      // ดึงยอดเงิน
      double? amount = _extractAmount(allText);
      
      // ดึงเลขอ้างอิง
      String? refNumber = _extractRefNumber(allText);
      
      // ดึงวันที่
      DateTime? date = _extractDate(allText);
      
      return {
        'success': true,
        'amount': amount,
        'ref_number': refNumber,
        'date': date,
        'raw_text': recognizedText.text,
      };
    } catch (e) {
      print('❌ OCR Error: $e');
      return {'success': false, 'error': e.toString()};
    } finally {
      textRecognizer.close();
    }
  }
  
  static double? _extractAmount(String text) {
    // หาคำว่า "จำนวนเงิน" หรือ "amount"
    final amountPattern = RegExp(r'(?:จำนวนเงิน|amount|ยอดโอน)[\s:]*(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)', caseSensitive: false);
    final match = amountPattern.firstMatch(text);
    
    if (match != null) {
      String amountStr = match.group(1)!.replaceAll(',', '');
      return double.tryParse(amountStr);
    }
    
    // Fallback: หาตัวเลขที่มีจุดทศนิยม
    final numberPattern = RegExp(r'(\d{1,3}(?:,\d{3})*\.\d{2})');
    final numbers = numberPattern.allMatches(text);
    if (numbers.isNotEmpty) {
      String amountStr = numbers.first.group(1)!.replaceAll(',', '');
      return double.tryParse(amountStr);
    }
    
    return null;
  }
  
  static String? _extractRefNumber(String text) {
    // หาเลขอ้างอิง (ปกติเป็นตัวเลข 10-20 หลัก)
    final refPattern = RegExp(r'(?:ref|อ้างอิง)[\s:]*([0-9]{10,20})', caseSensitive: false);
    final match = refPattern.firstMatch(text);
    return match?.group(1);
  }
  
  static DateTime? _extractDate(String text) {
    // หารูปแบบวันที่ (เช่น 02/11/2025, 2-11-25)
    final datePattern = RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})');
    final match = datePattern.firstMatch(text);
    
    if (match != null) {
      int day = int.parse(match.group(1)!);
      int month = int.parse(match.group(2)!);
      int year = int.parse(match.group(3)!);
      
      if (year < 100) year += 2000; // แปลง 25 -> 2025
      
      try {
        return DateTime(year, month, day);
      } catch (e) {
        return null;
      }
    }
    
    return null;
  }
  
  static bool validateSlip({
    required Map<String, dynamic> ocrData,
    required double expectedAmount,
  }) {
    if (!ocrData['success'] || ocrData['amount'] == null) {
      return false;
    }
    
    double slipAmount = ocrData['amount'];
    double difference = (slipAmount - expectedAmount).abs();
    
    // ยอมรับผลต่าง ±1 บาท
    return difference <= 1.0;
  }
}
```

### 4. UI - Upload Slip Button

```dart
// lib/innnerScreen/PaymentScreen.dart

import 'package:image_picker/image_picker.dart';
import 'dart:io';

class _PaymentScreenState extends State<PaymentScreen> {
  File? _slipImage;
  bool _isUploadingSlip = false;
  
  Future<void> _pickAndUploadSlip() async {
    final ImagePicker picker = ImagePicker();
    
    // เลือกรูปจาก gallery
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    
    if (image == null) return;
    
    setState(() {
      _slipImage = File(image.path);
      _isUploadingSlip = true;
    });
    
    try {
      // 1. OCR อ่านข้อมูล (optional)
      final ocrData = await SlipOcrService.extractSlipData(_slipImage!);
      print('📄 OCR Result: $ocrData');
      
      // 2. ตรวจสอบยอดเงิน
      bool isValid = SlipOcrService.validateSlip(
        ocrData: ocrData,
        expectedAmount: widget.totalAmount,
      );
      
      if (!isValid && ocrData['amount'] != null) {
        _showErrorDialog(
          'ยอดเงินในสลิปไม่ตรงกัน\n'
          'ยอดที่ต้องจ่าย: ฿${widget.totalAmount.toStringAsFixed(2)}\n'
          'ยอดในสลิป: ฿${ocrData['amount'].toStringAsFixed(2)}'
        );
        setState(() {
          _isUploadingSlip = false;
        });
        return;
      }
      
      // 3. อัปโหลดไป Supabase Storage
      final slipUrl = await SupabaseService.uploadPaymentSlip(
        _slipImage!,
        widget.orderId, // ต้องเก็บ orderId ไว้หลังสร้าง order
      );
      
      if (slipUrl == null) {
        throw Exception('ไม่สามารถอัปโหลดสลิปได้');
      }
      
      // 4. อัปเดต order
      await SupabaseService.updateOrderWithSlip(
        orderId: widget.orderId,
        slipUrl: slipUrl,
        slipAmount: ocrData['amount'],
        refNumber: ocrData['ref_number'],
      );
      
      setState(() {
        _isUploadingSlip = false;
      });
      
      _showSuccessDialog('อัปโหลดสลิปสำเร็จ!\nรอร้านค้ายืนยัน');
      
    } catch (e) {
      setState(() {
        _isUploadingSlip = false;
      });
      _showErrorDialog('เกิดข้อผิดพลาด: $e');
    }
  }
  
  // เพิ่มปุ่มใน UI
  Widget _buildUploadSlipButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: OutlinedButton.icon(
        onPressed: _isUploadingSlip ? null : _pickAndUploadSlip,
        icon: _isUploadingSlip
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.upload_file),
        label: Text(
          _isUploadingSlip 
              ? 'กำลังอัปโหลด...' 
              : 'อัปโหลดสลิปการโอนเงิน',
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Colors.orange, width: 2),
        ),
      ),
    );
  }
}
```

## Summary

### ฟรี (ใช้ได้เลย):
- ✅ Google ML Kit OCR
- ✅ ตรวจสอบยอดเงินพื้นฐาน
- ✅ ร้านค้ายืนยันด้วยตาเองสุดท้าย

### มีค่าใช้จ่าย (แนะนำถ้ามีงบ):
- 💰 SlipOK.com (~1-3 บาท/slip)
- 💰 SCB Slip Verification API
- ✅ ตรวจจับ slip ปลอม
- ✅ ยืนยันอัตโนมัติ 100%

## Next Steps

1. รัน SQL สร้าง columns
2. สร้าง Storage bucket `payment-slips`
3. เพิ่ม dependencies
4. Implement upload slip function
5. ทดสอบ OCR
