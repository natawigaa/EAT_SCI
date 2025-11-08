import 'package:eatscikmitl/data/datademo.dart';
import 'package:eatscikmitl/services/cart_service.dart';
import 'package:eatscikmitl/services/supabase_service.dart';
import 'package:eatscikmitl/rootScreen.dart';
import 'package:eatscikmitl/utils/notification_helper.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class PaymentScreen extends StatefulWidget {
  final double totalAmount;
  final int itemCount;
  final int restaurantId;
  final String restaurantName;

  const PaymentScreen({
    super.key,
    required this.totalAmount,
    required this.itemCount,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final CartService _cartService = CartService();
  bool _isCreatingOrder = false;
  String? _restaurantQrCodeUrl;
  bool _isLoadingQr = true;
  
  // สำหรับอัปโหลดสลิป
  File? _selectedSlipImage;
  bool _isUploadingSlip = false;
  int? _createdOrderId; // เก็บ order ID หลังสร้างเสร็จ
  
  // เก็บ student_id ของ user ที่ login
  String? _studentId;

  @override
  void initState() {
    super.initState();
    _loadRestaurantQrCode();
    _loadStudentId();
  }
  
  Future<void> _loadStudentId() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        print('❌ ไม่พบ user ที่ login');
        return;
      }
      
      final profile = await Supabase.instance.client
          .from('students')
          .select('student_id')
          .eq('id', userId)
          .single();
      
      setState(() {
        _studentId = profile['student_id'] as String?;
      });
      print('✅ โหลด Student ID: $_studentId');
    } catch (e) {
      print('❌ Error loading student ID: $e');
    }
  }

  Future<void> _loadRestaurantQrCode() async {
    try {
      final restaurants = await SupabaseService.getRestaurants();
      final restaurant = restaurants.firstWhere(
        (r) => r['id'] == widget.restaurantId,
        orElse: () => {},
      );
      
      if (restaurant.isNotEmpty && restaurant['qr_code_url'] != null) {
        setState(() {
          _restaurantQrCodeUrl = restaurant['qr_code_url'];
          _isLoadingQr = false;
        });
        print('✅ โหลด QR Code URL: $_restaurantQrCodeUrl');
      } else {
        setState(() {
          _isLoadingQr = false;
        });
        print('⚠️ ร้าน ${widget.restaurantName} ยังไม่มี QR Code URL');
      }
    } catch (e) {
      print('❌ Error loading QR Code: $e');
      setState(() {
        _isLoadingQr = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String paymentData =
        "TOTAL:${widget.totalAmount.toStringAsFixed(2)}|ITEMS:${widget.itemCount}";

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'ชำระเงิน',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    _buildMinimalHeader(),
                    const SizedBox(height: 24),
                    _buildMinimalQRSection(paymentData),
                    const SizedBox(height: 20),
                    _buildMinimalAmount(),
                    const SizedBox(height: 16),
                    _buildDownloadButton(),
                    const SizedBox(height: 24),
                    
                    // ส่วนอัปโหลดสลิป (แสดงตลอด)
                    _buildSlipUploadSection(),
                    const SizedBox(height: 100), // เผื่อพื้นที่สำหรับปุ่มด้านล่าง
                  ],
                ),
              ),
            ),
          ),
          // ปุ่มยืนยันการชำระเงิน (อัปโหลดสลิป + สร้าง order)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: _buildConfirmPaymentButton(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalHeader() {
    return Column(
      children: [
        // Logo หรือชื่อแอป
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 239, 119, 34), // สีใหม่ตามที่ขอ
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'EaT@Sci',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalQRSection(String paymentData) {
    return Column(
      children: [
        const Text(
          'Scan Restaurant QR code to Pay',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'สแกน QR Code เพื่อชำระเงินให้ร้าน ${widget.restaurantName}',
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        // QR Code Container
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _isLoadingQr
              ? const SizedBox(
                  width: 180,
                  height: 180,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : _restaurantQrCodeUrl != null
                  // แสดงรูป QR Code จาก URL จริง
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _restaurantQrCodeUrl!,
                        width: 180,
                        height: 180,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return SizedBox(
                            width: 180,
                            height: 180,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          print('❌ Error loading QR image: $error');
                          return _buildFallbackQR(paymentData);
                        },
                      ),
                    )
                  // Fallback: แสดง QR Code แบบ text (ถ้าร้านยังไม่มี QR Code URL)
                  : _buildFallbackQR(paymentData),
        ),
      ],
    );
  }

  // Fallback QR Code (text-based)
  Widget _buildFallbackQR(String paymentData) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        QrImageView(
          data: paymentData,
          version: QrVersions.auto,
          size: 180,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '⚠️ ร้านนี้ยังไม่มี QR Code',
            style: TextStyle(
              fontSize: 11,
              color: Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalAmount() {
    return Column(
      children: [
        Text(
          'TOTAL${widget.totalAmount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        
      ],
    );
  }

  Widget _buildDownloadButton() {
    return InkWell(
      onTap: () {
        _downloadQRCode();
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download,
            color: const Color.fromARGB(255, 239, 119, 34),
            size: 18,
          ),
          const SizedBox(width: 8),
          const Text(
            'Download QR Code',
            style: TextStyle(
              color: Color.fromARGB(255, 239, 119, 34),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _downloadQRCode() {
    // แสดงข้อความแจ้งเตือนว่า download สำเร็จ
    NotificationHelper.showSuccess(context, 'QR Code ถูกบันทึกแล้ว');
  }

  Widget _buildConfirmPaymentButton() {
    // ถ้าสร้าง order แล้ว = แสดงปุ่มกลับหน้าหลัก
    if (_createdOrderId != null) {
      return Container(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            // ล้างตะกร้า
            _cartService.clearCart();
            
            // กลับไปหน้าหลัก
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const RootScreen(currentScreens: 1),
              ),
              (route) => false,
            );
          },
          icon: const Icon(Icons.home),
          label: const Text(
            'กลับหน้าหลัก',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),
      );
    }
    
    // ยังไม่ได้สร้าง order = แสดงปุ่มยืนยันการชำระเงิน
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_selectedSlipImage != null && !_isUploadingSlip && !_isCreatingOrder)
            ? _confirmPaymentWithSlip
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 239, 119, 34),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          disabledBackgroundColor: Colors.grey.shade300,
        ),
        child: (_isUploadingSlip || _isCreatingOrder)
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                _selectedSlipImage == null 
                    ? 'กรุณาเลือกสลิปการโอนเงิน' 
                    : 'ยืนยันการชำระเงิน',
                style: TextStyle(
                  color: _selectedSlipImage == null ? Colors.grey.shade600 : Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  // ส่วนอัปโหลดสลิป
  Widget _buildSlipUploadSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'อัปโหลดสลิปการโอนเงิน',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'แนบหลักฐานการโอนเงินเพื่อให้ร้านตรวจสอบ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // แสดงภาพที่เลือก
            if (_selectedSlipImage != null) ...[
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedSlipImage!,
                    width: 200,
                    height: 300,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ปุ่มเลือกภาพ
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isUploadingSlip ? null : _pickSlipImage,
                icon: const Icon(Icons.image),
                label: Text(
                  _selectedSlipImage == null
                      ? 'เลือกภาพสลิป'
                      : 'เปลี่ยนภาพสลิป',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.blue.shade300),
                ),
              ),
            ),
            
            // ลบปุ่มอัปโหลดออก เพราะใช้ปุ่มหลักด้านล่างแทน
          ],
        ),
      ),
    );
  }

  Future<void> _pickSlipImage() async {
    final ImagePicker picker = ImagePicker();

    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedSlipImage = File(image.path);
        });
        print('✅ เลือกภาพสลิป: ${image.path}');
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      NotificationHelper.showError(context, 'เกิดข้อผิดพลาด: $e');
    }
  }

  Future<void> _uploadSlip() async {
    if (_selectedSlipImage == null || _createdOrderId == null) return;

    setState(() {
      _isUploadingSlip = true;
    });

    try {
      // 1. อัปโหลดไฟล์ไป Supabase Storage
      final slipUrl = await SupabaseService.uploadPaymentSlip(
        _selectedSlipImage!.path,
        _createdOrderId!,
      );

      if (slipUrl == null) {
        throw Exception('อัปโหลดไฟล์ไม่สำเร็จ');
      }

      // 2. อัปเดต order ด้วย slip URL
      final success = await SupabaseService.updateOrderWithSlip(
        _createdOrderId!,
        slipUrl,
      );

      if (success) {
        setState(() {
          _isUploadingSlip = false;
        });

      NotificationHelper.showSuccess(
        context,
        'อัปโหลดสลิปสำเร็จ! รอร้านตรวจสอบ',
      );        // แสดง dialog สำเร็จ
        _showSlipUploadedDialog();
      } else {
        throw Exception('อัปเดต order ไม่สำเร็จ');
      }
    } catch (e) {
      print('❌ Error uploading slip: $e');
      setState(() {
        _isUploadingSlip = false;
      });

      NotificationHelper.showError(
        context,
        'เกิดข้อผิดพลาด: $e',
      );
    }
  }

  void _showSlipUploadedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600, size: 28),
            const SizedBox(width: 12),
            const Text('อัปโหลดสลิปสำเร็จ'),
          ],
        ),
        content: const Text(
          'สลิปการโอนเงินถูกส่งให้ร้านตรวจสอบแล้ว\nกรุณารอร้านยืนยันคำสั่งซื้อ',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // ปิด dialog
              // ปุ่มกลับหน้าหลักจะแสดงที่ล่างสุด
            },
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmPaymentButton_OLD() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton(
        onPressed: _isCreatingOrder ? null : () {
          _confirmPayment();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 239, 119, 34),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isCreatingOrder
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'ยืนยันการชำระเงิน',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  // ฟังก์ชันใหม่: อัปโหลดสลิป + สร้าง order พร้อมกัน
  Future<void> _confirmPaymentWithSlip() async {
    if (_selectedSlipImage == null) {
      NotificationHelper.showWarning(
        context,
        'กรุณาเลือกสลิปการโอนเงินก่อน',
      );
      return;
    }

    setState(() {
      _isUploadingSlip = true;
      _isCreatingOrder = true;
    });

    try {
      // ดึงข้อมูลจาก cart
      final cartItems = _cartService.cartItems;
      final restaurantId = _cartService.currentRestaurantId;
      final restaurantName = _cartService.currentRestaurantName;

      if (cartItems.isEmpty || restaurantId == null || restaurantName == null) {
        throw Exception('ตะกร้าสินค้าว่างเปล่า');
      }
      
      if (_studentId == null) {
        throw Exception('ไม่พบข้อมูลนักศึกษา กรุณา login ใหม่');
      }

      print('🔄 ขั้นตอนที่ 1: สร้าง order ก่อน...');
      
      // ขั้นตอนที่ 1: สร้าง order (ยังไม่มีสลิป)
      final orderResult = await SupabaseService.createOrder(
        studentId: _studentId!,
        restaurantId: int.parse(restaurantId),
        restaurantName: restaurantName,
        totalAmount: _cartService.totalAmount,
        totalItems: _cartService.totalItems,
        cartItems: cartItems,
        notes: null,
      );

      if (orderResult == null) {
        throw Exception('ไม่สามารถสร้างคำสั่งซื้อได้');
      }

      final orderId = orderResult['id'] as int;
      print('✅ Order ID: $orderId');

      print('🔄 ขั้นตอนที่ 2: อัปโหลดสลิป...');
      
      // ขั้นตอนที่ 2: อัปโหลดสลิป
      final slipUrl = await SupabaseService.uploadPaymentSlip(
        _selectedSlipImage!.path,
        orderId,
      );

      if (slipUrl == null) {
        throw Exception('อัปโหลดสลิปไม่สำเร็จ');
      }

      print('🔄 ขั้นตอนที่ 3: อัปเดต order พร้อมสลิป...');
      
      // ขั้นตอนที่ 3: อัปเดต order ด้วย slip URL
      final updateSuccess = await SupabaseService.updateOrderWithSlip(
        orderId,
        slipUrl,
      );

      if (!updateSuccess) {
        throw Exception('อัปเดต order ไม่สำเร็จ');
      }

      print('✅ สร้าง order พร้อมสลิปสำเร็จ!');

      setState(() {
        _createdOrderId = orderId;
        _isUploadingSlip = false;
        _isCreatingOrder = false;
      });

      // ล้างตะกร้า
      _cartService.clearCart();

      // แสดง success dialog
      _showSuccessDialogAndNavigate();

    } catch (e) {
      print('❌ Error: $e');
      setState(() {
        _isUploadingSlip = false;
        _isCreatingOrder = false;
      });
      _showErrorDialog('เกิดข้อผิดพลาด: $e');
    }
  }

  void _showSuccessDialogAndNavigate() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 60,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'สั่งอาหารสำเร็จ!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'ร้านค้าจะตรวจสอบการชำระเงิน\nและเริ่มเตรียมอาหาร',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // ปิด dialog
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const RootScreen(currentScreens: 0),
                ),
                (route) => false,
              );
            },
            child: const Text('กลับหน้าหลัก'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmPayment() async {
    setState(() {
      _isCreatingOrder = true;
    });

    try {
      // ดึงข้อมูลจาก cart
      final cartItems = _cartService.cartItems;
      final restaurantId = _cartService.currentRestaurantId;
      final restaurantName = _cartService.currentRestaurantName;

      if (cartItems.isEmpty || restaurantId == null || restaurantName == null) {
        throw Exception('ตะกร้าสินค้าว่างเปล่า');
      }
      
      if (_studentId == null) {
        throw Exception('ไม่พบข้อมูลนักศึกษา กรุณา login ใหม่');
      }

      // สร้าง order
      final orderResult = await SupabaseService.createOrder(
        studentId: _studentId!,
        restaurantId: int.parse(restaurantId),
        restaurantName: restaurantName,
        totalAmount: _cartService.totalAmount,
        totalItems: _cartService.totalItems,
        cartItems: cartItems,
        notes: null,
      );

      if (orderResult != null) {
        // สร้าง order สำเร็จ
        print('🎉 Order ID: ${orderResult['id']}');
        
        setState(() {
          _createdOrderId = orderResult['id'];
          _isCreatingOrder = false;
        });
        
        // แสดง success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ สร้างคำสั่งซื้อสำเร็จ! กรุณาอัปโหลดสลิปการโอนเงิน'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Scroll ลงไปด้านล่างเพื่อให้เห็นส่วนอัปโหลดสลิป
        // (ไม่ต้องแสดง dialog เพราะจะให้อัปโหลดสลิปในหน้าเดียวกัน)
      } else {
        // สร้าง order ไม่สำเร็จ
        _showErrorDialog('ไม่สามารถสร้างคำสั่งซื้อได้ กรุณาลองใหม่อีกครั้ง');
      }
    } catch (e) {
      print('❌ Error confirming payment: $e');
      _showErrorDialog('เกิดข้อผิดพลาด: $e');
    } finally {
      setState(() {
        _isCreatingOrder = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('เกิดข้อผิดพลาด'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(int orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade600],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 60,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'ชำระเงินสำเร็จ!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'หมายเลขคำสั่งซื้อ: #$orderId',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ดำเนินการสั่งซื้อเรียบร้อยแล้ว',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ยอดชำระ:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '฿${widget.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // ล้างตะกร้า
                    _cartService.clearCart();
                    
                    // ปิด dialog
                    Navigator.of(context).pop();
                    
                    // กลับไปหน้าหลัก (RootScreen tab หลัก) โดยใช้ pushAndRemoveUntil
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const RootScreen(currentScreens: 1), // tab 1 = HomeScreen
                      ),
                      (route) => false,
                    );
                    
                    // แสดง success message
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ สั่งอาหารสำเร็จ! ตะกร้าถูกล้างแล้ว'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'กลับหน้าหลัก',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}