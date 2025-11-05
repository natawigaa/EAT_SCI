import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../const/app_color.dart';
import '../utils/notification_helper.dart';

/// หน้าจัดการคำสั่งซื้อสำหรับร้านค้า
/// แสดงรายการ orders ที่เข้ามาแบบ real-time พร้อมรูปสลิปการโอนเงิน
class OrdersManagementScreen extends StatefulWidget {
  final int restaurantId;
  final String restaurantName;

  const OrdersManagementScreen({
    Key? key,
    required this.restaurantId,
    required this.restaurantName,
  }) : super(key: key);

  @override
  State<OrdersManagementScreen> createState() => _OrdersManagementScreenState();
}

class _OrdersManagementScreenState extends State<OrdersManagementScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  RealtimeChannel? _subscription;
  int _newOrdersCount = 0; // จำนวน order ใหม่ที่ยังไม่ได้เปิดดู

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }

  /// โหลดรายการ orders ทั้งหมดของร้าน
  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await SupabaseService.getRestaurantOrders(widget.restaurantId);
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
      print('✅ โหลด ${orders.length} orders สำหรับร้าน ${widget.restaurantName}');
    } catch (e) {
      print('❌ Error loading orders: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        NotificationHelper.showError(
          context,
          'เกิดข้อผิดพลาดในการโหลดข้อมูล: $e',
        );
      }
    }
  }

  /// ตั้งค่า Realtime subscription เพื่อรับ order ใหม่
  void _setupRealtimeSubscription() {
    print('🎯 กำลังตั้งค่า realtime subscription ใน OrdersManagementScreen...');
    print('🏪 Restaurant ID: ${widget.restaurantId}');
    
    _subscription = SupabaseService.setupOrdersRealtimeSubscription(
      widget.restaurantId,
      (newOrder) {
        print('🔔 OrdersManagementScreen: ได้รับ order ใหม่ Order #${newOrder['id']}');
        print('📦 Order data: $newOrder');
        
        setState(() {
          _orders.insert(0, newOrder); // ใส่ order ใหม่ไว้ด้านบน
          _newOrdersCount++;
          print('🛒 จำนวน orders ทั้งหมด: ${_orders.length}');
          print('🔔 New orders count: $_newOrdersCount');
        });
        
        // แสดง notification
        if (mounted) {
          NotificationHelper.showSuccess(
            context,
            '🔔 มีคำสั่งซื้อใหม่! Order #${newOrder['id']}',
          );
          print('✅ แสดง SnackBar notification แล้ว');
        }
      },
    );
    
    print('✅ Realtime subscription setup เสร็จสิ้น');
  }

  /// แสดงรายละเอียด order แบบเต็ม
  void _showOrderDetails(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
            color: Colors.white,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.mainOrange),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Order #${order['id']}',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ข้อมูลลูกค้า
                          _buildInfoSection('ข้อมูลลูกค้า', [
                            _buildInfoRow('Student ID', order['student_id']?.toString() ?? '-'),
                            if (order['customer_phone'] != null) _buildInfoRow('เบอร์โทร', order['customer_phone']),
                            _buildInfoRow('เวลาสั่ง', _formatDateTime(order['created_at'])),
                          ]),
                          const Divider(height: 32),

                          // รายการอาหาร
                          _buildInfoSection('รายการอาหาร', [
                            // แสดงแต่ละเมนู พร้อมคำขอพิเศษ (ถ้ามี)
                            ...(order['items'] as List? ?? []).map((item) {
                                  final special = (item['special_request'] ?? item['specialRequest'] ?? '').toString();
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(child: Text('${item['menu_name']}', style: const TextStyle(fontSize: 16))),
                                            Text('x${item['quantity']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                            const SizedBox(width: 16),
                                            Text('฿${( (item['price'] ?? 0) * (item['quantity'] ?? 1) ).toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        if (special.trim().isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            'คำขอพิเศษ: $special',
                                            style: TextStyle(fontSize: 13, color: Colors.blue[700]),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                }).toList(),
                          ]),
                          const Divider(height: 32),

                          // ยอดรวม
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('ยอดรวมทั้งหมด', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text('฿${order['total_amount']?.toStringAsFixed(0) ?? '0'}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.mainOrange)),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Timeline สถานะ (Phase 3)
                          _buildStatusTimeline(order),
                          const SizedBox(height: 24),

                          // สลิปการโอนเงิน - ให้แสดงก่อนปุ่มจัดการสถานะเพื่อให้ร้านค้าดูสลิปก่อนตัดสินใจ
                          if (order['payment_slip_url'] != null) ...[
                            const Text('หลักฐานการชำระเงิน', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              elevation: 2,
                              shadowColor: Colors.black.withOpacity(0.1),
                              child: InkWell(
                                onTap: () {
                                  print('🖼️ กำลังเปิดสลิป URL: ${order['payment_slip_url']}');
                                  showDialog(
                                    context: context,
                                    builder: (context) => Dialog(
                                      backgroundColor: Colors.transparent,
                                      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
                                          color: Colors.black,
                                          child: Stack(
                                            children: [
                                              Center(
                                                child: InteractiveViewer(
                                                  child: Image.network(
                                                    order['payment_slip_url'],
                                                    fit: BoxFit.contain,
                                                    loadingBuilder: (context, child, progress) {
                                                      if (progress == null) return child;
                                                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                                                    },
                                                    errorBuilder: (context, error, stack) {
                                                      print('❌ Error loading image: $error');
                                                      return Container(
                                                        color: Colors.grey[900],
                                                        alignment: Alignment.center,
                                                        child: Column(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            const Icon(Icons.error_outline, size: 64, color: Colors.white),
                                                            const SizedBox(height: 16),
                                                            const Text('ไม่สามารถโหลดรูปสลิปได้', style: TextStyle(color: Colors.white, fontSize: 16)),
                                                            const SizedBox(height: 8),
                                                            Padding(padding: const EdgeInsets.all(16.0), child: Text('URL: ${order['payment_slip_url']}', style: const TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center)),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: 16,
                                                right: 16,
                                                child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 32), onPressed: () => Navigator.pop(context), style: IconButton.styleFrom(backgroundColor: Colors.black54)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)), child: Icon(Icons.receipt_outlined, color: Colors.grey[700], size: 22)),
                                      const SizedBox(width: 14),
                                      Expanded(child: Text('ดูสลิปการโอนเงิน', style: TextStyle(fontSize: 15, color: Colors.grey[900], fontWeight: FontWeight.w500))),
                                      Icon(Icons.chevron_right, color: Colors.grey[400], size: 24),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!, width: 1)),
                              child: Row(children: [Icon(Icons.info_outline, color: Colors.grey[400], size: 22), const SizedBox(width: 12), Expanded(child: Text('ยังไม่ได้รับสลิปการโอนเงิน', style: TextStyle(color: Colors.grey[600], fontSize: 14))),]),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // ปุ่มจัดการสถานะ (Phase 3) - แสดงหลังจากสลิป
                          _buildStatusActions(order),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return '-';
    try {
      // แปลง UTC เป็นเวลาท้องถิ่น (เวลาไทย GMT+7)
      final dt = DateTime.parse(dateTime).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'รอยืนยัน';
      case 'confirmed':
        return 'ยืนยันแล้ว';
      case 'preparing':
        return 'กำลังทำ';
      case 'ready':
        return 'พร้อมรับ';
      case 'completed':
        return 'เสร็จสิ้น';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange; // รอยืนยัน = สีส้ม
      case 'confirmed':
      case 'preparing':
        return Colors.blue; // ยืนยันแล้ว, กำลังทำ = สีฟ้า
      case 'ready':
        return Colors.green; // พร้อมรับ = สีเขียว
      case 'completed':
      case 'cancelled':
        return Colors.grey; // เสร็จสิ้น, ยกเลิก = สีเทา
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // เอา Scaffold ออก เพราะจะแสดงใน Dashboard
    return Column(
      children: [
        // Header with badge and refresh button
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Text(
                'คำสั่งซื้อทั้งหมด',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // (notification bell removed)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadOrders,
              ),
            ],
          ),
        ),
        
        // Content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _orders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'ยังไม่มีคำสั่งซื้อ',
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadOrders,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          final items = order['items'] as List? ?? [];
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            child: InkWell(
                              onTap: () => _showOrderDetails(order),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header: Order ID + Status
                                    Row(
                                      children: [
                                        Text(
                                          'Order #${order['id']}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(order['status'] ?? 'pending').withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            _getStatusText(order['status'] ?? 'pending'),
                                            style: TextStyle(
                                              color: _getStatusColor(order['status'] ?? 'pending'),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    // เวลา
                                    Text(
                                      _formatDateTime(order['created_at']),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    
                                              // รายการอาหาร (แสดงชื่อสั้น ๆ) และไอคอนบอกว่ามีคำขอพิเศษ
                                              Builder(builder: (context) {
                                                final summaryText = items.map((item) => '${item['menu_name']} x${item['quantity']}').join(', ');
                                                final hasSpecial = (items as List).any((i) {
                                                  final s = (i['special_request'] ?? i['specialRequest'] ?? '').toString();
                                                  return s.trim().isNotEmpty;
                                                });
                                                return Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        summaryText,
                                                        style: const TextStyle(fontSize: 14),
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    if (hasSpecial) ...[
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: Colors.orange.shade50,
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.note, size: 14, color: Colors.orange.shade700),
                                                            const SizedBox(width: 6),
                                                            Text('มีคำขอพิเศษ', style: TextStyle(fontSize: 12, color: Colors.orange.shade700, fontWeight: FontWeight.w600)),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                );
                                              }),
                                    const SizedBox(height: 12),
                                    
                                    // Total + Slip indicator
                                    Row(
                                      children: [
                                        Text(
                                          'ยอดรวม ฿${order['total_amount']?.toStringAsFixed(0) ?? '0'}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.mainOrange,
                                          ),
                                        ),
                                        const Spacer(),
                                        if (order['payment_slip_url'] != null)
                                          Row(
                                            children: [
                                              Icon(Icons.check_circle, color: Colors.green, size: 18),
                                              const SizedBox(width: 4),
                                              const Text(
                                                'มีสลิป',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  /// สร้าง Timeline แสดงสถานะ order (Phase 3)
  Widget _buildStatusTimeline(Map<String, dynamic> order) {
    final status = order['status'] ?? 'pending';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'สถานะออเดอร์',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTimelineStep(
            icon: Icons.shopping_cart,
            title: 'รับออเดอร์',
            time: _formatDateTime(order['created_at']),
            isCompleted: true,
            isActive: status == 'pending',
          ),
          _buildTimelineStep(
            icon: Icons.check_circle,
            title: 'ยืนยันรับ',
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
            icon: Icons.check,
            title: 'อาหารพร้อม',
            time: order['ready_at'] != null ? _formatDateTime(order['ready_at']) : null,
            isCompleted: ['ready', 'completed'].contains(status),
            isActive: status == 'ready',
            isLast: true,
          ),
        ],
      ),
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.mainOrange.withOpacity(0.1) : Colors.grey[100],
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: 2,
                ),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: color.withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(width: 16),
        // ข้อความ
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
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

  /// สร้างปุ่มจัดการสถานะ (Phase 3)
  Widget _buildStatusActions(Map<String, dynamic> order) {
    final status = order['status'] ?? 'pending';
    final orderId = order['id'] as int;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (status == 'pending') ...[
          // ปุ่มยืนยันรับออเดอร์
          ElevatedButton.icon(
            onPressed: () => _confirmOrder(orderId),
            icon: const Icon(Icons.check_circle),
            label: const Text('ยืนยันรับออเดอร์', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          // ปุ่มปฏิเสธออเดอร์
          OutlinedButton.icon(
            onPressed: () => _showCancelDialog(orderId),
            icon: const Icon(Icons.cancel),
            label: const Text('ปฏิเสธออเดอร์', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ] else if (status == 'confirmed') ...[
          // ปุ่มเริ่มทำอาหาร
          ElevatedButton.icon(
            onPressed: () => _startPreparing(orderId),
            icon: const Icon(Icons.restaurant),
            label: const Text('เริ่มทำอาหาร', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mainOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ] else if (status == 'preparing') ...[
          // ปุ่มอาหารพร้อม
          ElevatedButton.icon(
            onPressed: () => _markAsReady(orderId),
            icon: const Icon(Icons.done_all),
            label: const Text('อาหารพร้อม', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ] else if (status == 'ready') ...[
          // แสดงข้อความรอลูกค้ารับ
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'รอลูกค้ามารับอาหาร',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue[900],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else if (status == 'cancelled') ...[
          // แสดงเหตุผลการยกเลิก
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.cancel, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Text(
                      'ออเดอร์ถูกยกเลิก',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.red[900],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (order['cancellation_reason'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'เหตุผล: ${order['cancellation_reason']}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red[700],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// ยืนยันรับออเดอร์
  Future<void> _confirmOrder(int orderId) async {
    final success = await SupabaseService.updateOrderStatus(orderId, 'confirmed');
    if (success) {
      _loadOrders();
      Navigator.pop(context); // ปิด dialog
      NotificationHelper.showSuccess(
        context,
        'ยืนยันรับออเดอร์สำเร็จ',
      );
    } else {
      NotificationHelper.showError(
        context,
        'ไม่สามารถยืนยันได้',
      );
    }
  }

  /// เริ่มทำอาหาร
  Future<void> _startPreparing(int orderId) async {
    final success = await SupabaseService.updateOrderStatus(orderId, 'preparing');
    if (success) {
      _loadOrders();
      Navigator.pop(context);
      NotificationHelper.showInfo(
        context,
        '👨‍🍳 เริ่มทำอาหารแล้ว',
      );
    }
  }

  /// อาหารพร้อม
  Future<void> _markAsReady(int orderId) async {
    final success = await SupabaseService.updateOrderStatus(orderId, 'ready');
    if (success) {
      _loadOrders();
      Navigator.pop(context);
      NotificationHelper.showSuccess(
        context,
        'อาหารพร้อมแล้ว รอลูกค้ามารับ',
      );
    }
  }

  /// แสดง Dialog ยกเลิกออเดอร์
  void _showCancelDialog(int orderId) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ปฏิเสธออเดอร์'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('กรุณาระบุเหตุผลในการปฏิเสธออเดอร์:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'เช่น วัตถุดิบหมด, ปิดร้านชั่วคราว',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                NotificationHelper.showWarning(
                  context,
                  'กรุณาระบุเหตุผล',
                );
                return;
              }
              
              Navigator.pop(context); // ปิด dialog เหตุผล
              Navigator.pop(context); // ปิด dialog รายละเอียด
              
              final success = await SupabaseService.cancelOrder(orderId, reason);
              if (success) {
                _loadOrders();
                NotificationHelper.showError(
                  context,
                  '🚫 ปฏิเสธออเดอร์แล้ว',
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ยืนยันปฏิเสธ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
