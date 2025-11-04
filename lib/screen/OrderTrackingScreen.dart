import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../const/app_color.dart';
import '../utils/notification_helper.dart';

/// หน้าติดตามสถานะ Order สำหรับนักศึกษา (Phase 4)
/// แสดงเฉพาะ orders ที่กำลังดำเนินการ (pending, confirmed, preparing, ready)
class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({Key? key}) : super(key: key);

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  List<Map<String, dynamic>> _activeOrders = [];
  bool _isLoading = false;
  RealtimeChannel? _subscription;
  String? _studentId;

  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }

  /// เริ่มต้นระบบติดตามออเดอร์
  Future<void> _initializeTracking() async {
    setState(() => _isLoading = true);
    
    // ดึง Student ID จาก Supabase auth
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      print('❌ ไม่มีผู้ใช้ login');
      setState(() => _isLoading = false);
      return;
    }

    // ดึง student_id จากตาราง students
    final studentData = await SupabaseService.getStudentProfile(user.id);
    if (studentData == null) {
      print('❌ ไม่พบข้อมูล student');
      setState(() => _isLoading = false);
      return;
    }

    _studentId = studentData['student_id']?.toString();
    print('✅ Student ID: $_studentId');

    // โหลด active orders
    await _loadActiveOrders();

    // ตั้งค่า Realtime subscription
    _setupRealtimeSubscription();

    setState(() => _isLoading = false);
  }

  /// โหลด orders ที่กำลังดำเนินการ
  Future<void> _loadActiveOrders() async {
    if (_studentId == null) return;

    try {
      print('📦 กำลังดึง active orders ของ student $_studentId...');
      
      final orders = await SupabaseService.getStudentActiveOrders(_studentId!);
      
      setState(() {
        _activeOrders = orders;
      });
      
      print('✅ โหลด ${orders.length} active orders สำเร็จ');
    } catch (e) {
      print('❌ Error loading active orders: $e');
    }
  }

  /// ตั้งค่า Realtime subscription สำหรับ orders ของนักศึกษา
  void _setupRealtimeSubscription() {
    if (_studentId == null) return;

    print('🔔 ตั้งค่า realtime subscription สำหรับ student $_studentId');

    _subscription = SupabaseService.setupStudentOrdersSubscription(
      _studentId!,
      onOrderUpdate: (orderData) {
        print('🔔 ได้รับการอัปเดต order: ${orderData['id']} → ${orderData['status']}');
        
        // โหลด orders ใหม่
        _loadActiveOrders();
        
        // แสดง notification
        _showOrderNotification(orderData);
      },
    );
  }

  /// แสดง notification เมื่อสถานะเปลี่ยน
  void _showOrderNotification(Map<String, dynamic> order) {
    final status = order['status'];
    final orderId = order['id'];

    switch (status) {
      case 'confirmed':
        NotificationHelper.showSuccess(
          context, 
          'ร้านยืนยันรับออเดอร์ #$orderId แล้ว',
        );
        break;
      case 'preparing':
        NotificationHelper.showInfo(
          context,
          'ร้านกำลังทำอาหาร Order #$orderId 👨‍🍳',
        );
        break;
      case 'ready':
        NotificationHelper.showSuccess(
          context,
          'อาหาร Order #$orderId พร้อมแล้ว! มารับได้เลย 🎉',
        );
        break;
      case 'cancelled':
        NotificationHelper.showError(
          context,
          'ออเดอร์ #$orderId ถูกยกเลิก',
        );
        break;
    }
  }

  /// ยืนยันรับอาหารแล้ว (เปลี่ยนสถานะเป็น completed) - Phase 6
  Future<void> _confirmPickup(int orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันรับอาหารแล้ว'),
        content: const Text('คุณได้รับอาหารแล้วใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6F00),
            ),
            child: const Text('ยืนยัน', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // เรียกใช้ function ใหม่ markOrderAsCompleted แทน updateOrderStatus
      final success = await SupabaseService.markOrderAsCompleted(orderId);
      if (success) {
        await _loadActiveOrders(); // โหลดข้อมูลใหม่
        NotificationHelper.showSuccess(
          context,
          'ขอบคุณค่ะ! หวังว่าจะอร่อยนะคะ 😊',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header แบบ custom แทน AppBar
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20,
              right: 20,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.receipt_long, color: AppColors.mainOrange, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'ติดตามออเดอร์',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _activeOrders.isEmpty
                    ? _buildEmptyState()
                    : _buildOrdersList(),
          ),
        ],
      ),
    );
  }

  /// แสดงเมื่อไม่มี orders
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'ไม่มีออเดอร์ที่กำลังดำเนินการ',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'สั่งอาหารเลยไหม? 😋',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  /// แสดงรายการ orders
  Widget _buildOrdersList() {
    return RefreshIndicator(
      onRefresh: _loadActiveOrders,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _activeOrders.length,
        itemBuilder: (context, index) {
          final order = _activeOrders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  /// Card แสดงข้อมูล order
  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'pending';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Order ID + ร้านอาหาร
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.mainOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Order #${order['id']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.mainOrange,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Spacer(),
                _buildStatusBadge(status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              order['restaurant_name'] ?? 'Unknown Restaurant',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Timeline
            _buildOrderTimeline(order),
            const SizedBox(height: 20),

            // รายการอาหาร
            _buildOrderItems(order),
            const SizedBox(height: 16),

            // ยอดรวม
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ยอดรวม',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '฿${order['total_amount']?.toStringAsFixed(0) ?? '0'}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.mainOrange,
                    ),
                  ),
                ],
              ),
            ),

            // ปุ่มรับอาหาร (แสดงเมื่อสถานะ ready)
            if (status == 'ready') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _confirmPickup(order['id'] as int),
                  icon: const Icon(Icons.check_circle),
                  label: const Text(
                    'รับอาหารแล้ว',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Badge สถานะ
  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    
    switch (status) {
      case 'pending':
        color = Colors.blue; // สีฟ้า
        text = 'รอยืนยัน';
        break;
      case 'confirmed':
        color = Colors.blue; // สีฟ้า
        text = 'ยืนยันแล้ว';
        break;
      case 'preparing':
        color = Colors.blue; // สีฟ้า
        text = 'กำลังทำ';
        break;
      case 'ready':
        color = Colors.green; // เฉพาะ ready เป็นสีเขียว
        text = 'พร้อมแล้ว';
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'ยกเลิก';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15), // เปลี่ยนเป็นสีโปร่งแสง
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color, // ข้อความใช้สีเข้ม
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Timeline แสดงสถานะ
  Widget _buildOrderTimeline(Map<String, dynamic> order) {
    final status = order['status'] ?? 'pending';
    
    return Column(
      children: [
        _buildTimelineStep(
          icon: Icons.receipt,
          title: 'สั่งอาหาร',
          time: _formatDateTime(order['created_at']),
          isCompleted: true,
          isActive: status == 'pending',
        ),
        _buildTimelineStep(
          icon: Icons.check_circle,
          title: 'ร้านยืนยันรับ',
          time: order['confirmed_at'] != null ? _formatDateTime(order['confirmed_at']) : null,
          isCompleted: ['confirmed', 'preparing', 'ready', 'completed'].contains(status),
          isActive: status == 'confirmed',
        ),
        _buildTimelineStep(
          icon: Icons.restaurant,
          title: 'กำลังทำอาหาร',
          time: order['preparing_at'] != null ? _formatDateTime(order['preparing_at']) : null,
          isCompleted: ['preparing', 'ready', 'completed'].contains(status),
          isActive: status == 'preparing',
        ),
        _buildTimelineStep(
          icon: Icons.done_all,
          title: 'อาหารพร้อม',
          time: order['ready_at'] != null ? _formatDateTime(order['ready_at']) : null,
          isCompleted: ['ready', 'completed'].contains(status),
          isActive: status == 'ready',
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildTimelineStep({
    required IconData icon,
    required String title,
    String? time,
    required bool isCompleted,
    required bool isActive,
    bool isLast = false,
  }) {
    final color = isCompleted ? AppColors.mainOrange : Colors.grey[400]!;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon และเส้นเชื่อม
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.mainOrange.withOpacity(0.1) : Colors.grey[100],
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: color.withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(width: 12),
        // ข้อความ
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isCompleted ? Colors.black : Colors.grey[600],
                  ),
                ),
                if (time != null)
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// แสดงรายการอาหาร
  Widget _buildOrderItems(Map<String, dynamic> order) {
    final items = order['items'] as List? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'รายการอาหาร',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${item['menu_name']} x${item['quantity']}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              Text(
                '฿${(item['price'] * item['quantity']).toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  /// Format DateTime
  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return '-';
    try {
      // แปลง UTC เป็นเวลาท้องถิ่น (เวลาไทย GMT+7)
      final dt = DateTime.parse(dateTime.toString()).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime.toString();
    }
  }
}
