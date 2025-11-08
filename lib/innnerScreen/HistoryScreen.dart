import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../const/app_color.dart';
import '../utils/notification_helper.dart';

/// หน้าประวัติการสั่งซื้อ (Phase 6)
/// มี 2 แท็บ: ที่ต้องรับ (ready) และ สำเร็จ (completed 7 วันย้อนหลัง)
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _readyOrders = [];
  List<Map<String, dynamic>> _completedOrders = [];
  bool _isLoading = false;
  String? _studentId;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// เริ่มต้นโหลดข้อมูล
  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    
    // ดึง Student ID
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      print('❌ ไม่มีผู้ใช้ login');
      setState(() => _isLoading = false);
      return;
    }

    final studentData = await SupabaseService.getStudentProfile(user.id);
    if (studentData == null) {
      print('❌ ไม่พบข้อมูล student');
      setState(() => _isLoading = false);
      return;
    }

    _studentId = studentData['student_id']?.toString();
    print('✅ Student ID: $_studentId');

    // โหลดข้อมูล
    await _loadOrders();

    setState(() => _isLoading = false);
  }

  /// โหลด orders ทั้ง 2 ประเภท
  Future<void> _loadOrders() async {
    if (_studentId == null) return;

    try {
      print('📦 กำลังดึงประวัติ orders ของ student $_studentId...');
      // Load ready orders
      final readyFuture = SupabaseService.getReadyOrders(_studentId!);

      // Load completed + cancelled orders (we'll filter to last 7 days)
      final completedCancelledFuture = SupabaseService.getCompletedAndCancelledOrders(_studentId!);

      final results = await Future.wait([readyFuture, completedCancelledFuture]);

      final List<Map<String, dynamic>> ready = results[0];
      final List<Map<String, dynamic>> completedAndCancelled = results[1];

      // Filter to last 7 days to match previous behaviour
      final DateTime startDate = DateTime.now().subtract(const Duration(days: 7));
      final filtered = completedAndCancelled.where((order) {
        try {
          final created = order['created_at'] != null ? DateTime.parse(order['created_at']).toLocal() : null;
          if (created == null) return false;
          return created.isAfter(startDate);
        } catch (e) {
          return false;
        }
      }).toList();

      setState(() {
        _readyOrders = ready;
        _completedOrders = filtered;
      });

      print('✅ โหลด ${_readyOrders.length} ready orders และ ${_completedOrders.length} completed/cancelled orders (7d) สำเร็จ');
    } catch (e) {
      print('❌ Error loading orders: $e');
    }
  }

  /// ยืนยันรับอาหารแล้ว
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
      final success = await SupabaseService.markOrderAsCompleted(orderId);
      if (success) {
        await _loadOrders();
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
      appBar: AppBar(
        title: const Text('ประวัติการสั่งซื้อ'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.mainOrange,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.mainOrange,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('ที่ต้องรับ'),
                  if (_readyOrders.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_readyOrders.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Tab(text: 'สำเร็จ'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildReadyOrdersTab(),
                _buildCompletedOrdersTab(),
              ],
            ),
    );
  }

  /// แท็บ "ที่ต้องรับ"
  Widget _buildReadyOrdersTab() {
    if (_readyOrders.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle_outline,
        title: 'ไม่มีออเดอร์ที่ต้องรับ',
        subtitle: 'ออเดอร์ที่พร้อมจะแสดงที่นี่',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _readyOrders.length,
        itemBuilder: (context, index) {
          final order = _readyOrders[index];
          return _buildOrderCard(order, showPickupButton: true);
        },
      ),
    );
  }

  /// แท็บ "สำเร็จ"
  Widget _buildCompletedOrdersTab() {
    if (_completedOrders.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: 'ยังไม่มีประวัติการสั่งซื้อ',
        subtitle: 'ออเดอร์ 7 วันย้อนหลังจะแสดงที่นี่',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _completedOrders.length,
        itemBuilder: (context, index) {
          final order = _completedOrders[index];
          return _buildOrderCard(order, showPickupButton: false);
        },
      ),
    );
  }

  /// Empty state
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  /// Order Card
  Widget _buildOrderCard(Map<String, dynamic> order, {required bool showPickupButton}) {
    final status = order['status'] ?? 'pending';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                _buildStatusBadge(status),
              ],
            ),
            const SizedBox(height: 12),
            // ร้านอาหาร
            Row(
              children: [
                Icon(Icons.store, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  order['restaurant_name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // เวลา
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  _formatDateTime(order['created_at']),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // รายการอาหาร
            ...((order['items'] as List?) ?? []).map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item['menu_name']} x${item['quantity']}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      '฿${(item['price'] * item['quantity']).toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            }).toList(),
            // If order was cancelled, show cancellation / rejection reason supplied by restaurant
            if (status == 'cancelled') ...[
              const SizedBox(height: 8),
              Text(
                'เหตุผลการยกเลิก: ${order['cancellation_reason'] ?? order['rejection_reason'] ?? 'ไม่ระบุ'}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],

            const Divider(height: 24),
            // ยอดรวม
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ยอดรวม',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '฿${order['total_amount']?.toStringAsFixed(0) ?? '0'}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.mainOrange,
                  ),
                ),
              ],
            ),
            // ปุ่มรับอาหาร
            if (showPickupButton && status == 'ready') ...[
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
                    padding: const EdgeInsets.all(14),
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

  /// Status badge
  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    
    switch (status) {
      case 'ready':
        color = Colors.green;
        text = 'พร้อม';
        break;
      case 'completed':
        color = Colors.blue;
        text = 'สำเร็จ';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Format DateTime
  String _formatDateTime(dynamic datetime) {
    if (datetime == null) return '-';
    
    try {
      // แปลง UTC เป็นเวลาท้องถิ่น (เวลาไทย GMT+7)
      final dt = DateTime.parse(datetime.toString()).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      
      if (diff.inMinutes < 1) {
        return 'เมื่อสักครู่';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes} นาทีที่แล้ว';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} ชั่วโมงที่แล้ว';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} วันที่แล้ว';
      } else {
        return '${dt.day}/${dt.month}/${dt.year}';
      }
    } catch (e) {
      return datetime.toString();
    }
  }
}