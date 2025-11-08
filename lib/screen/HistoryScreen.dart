import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eatscikmitl/services/supabase_service.dart';
import 'package:eatscikmitl/const/app_color.dart';
import 'package:intl/intl.dart';

/// หน้าประวัติการสั่งซื้อ
/// แยกเป็น 2 แท็บ: ต้องรับ (ready) และ สำเร็จ (completed)
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<Map<String, dynamic>> _readyOrders = [];
  List<Map<String, dynamic>> _completedOrders = [];
  
  bool _isLoadingReady = true;
  bool _isLoadingCompleted = true;
  
  String? _studentId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStudentData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        setState(() {
          _studentId = user.id;
        });
        await Future.wait([
          _loadReadyOrders(),
          _loadCompletedOrders(),
        ]);
      }
    } catch (e) {
      print('❌ Error loading student data: $e');
    }
  }

  Future<void> _loadReadyOrders() async {
    if (_studentId == null) return;
    
    setState(() {
      _isLoadingReady = true;
    });

    try {
      final orders = await SupabaseService.getReadyOrders(_studentId!);
      setState(() {
        _readyOrders = orders;
        _isLoadingReady = false;
      });
    } catch (e) {
      print('❌ Error loading ready orders: $e');
      setState(() {
        _isLoadingReady = false;
      });
    }
  }

  Future<void> _loadCompletedOrders() async {
    if (_studentId == null) return;
    
    setState(() {
      _isLoadingCompleted = true;
    });

    try {
      // Load both completed and cancelled orders so cancelled orders are
      // preserved in the student's history (display-only). Do not mutate DB.
      final orders = await SupabaseService.getCompletedAndCancelledOrders(_studentId!);
      setState(() {
        _completedOrders = orders;
        _isLoadingCompleted = false;
      });
    } catch (e) {
      print('❌ Error loading completed/cancelled orders: $e');
      setState(() {
        _isLoadingCompleted = false;
      });
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('ยืนยัน', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await SupabaseService.markOrderAsCompleted(orderId);
      if (success) {
        // โหลดข้อมูลใหม่
        await Future.wait([
          _loadReadyOrders(),
          _loadCompletedOrders(),
        ]);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ ขอบคุณค่ะ! หวังว่าจะอร่อยนะคะ 😊'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'ประวัติคำสั่งซื้อ',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.mainOrange,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.mainOrange,
          indicatorWeight: 3,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.pending_actions),
                  const SizedBox(width: 8),
                  const Text('ต้องรับ'),
                  if (_readyOrders.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
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
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.check_circle),
                  SizedBox(width: 8),
                  Text('สำเร็จ'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReadyOrdersTab(),
          _buildCompletedOrdersTab(),
        ],
      ),
    );
  }

  /// แท็บ "ต้องรับ" (status = ready)
  Widget _buildReadyOrdersTab() {
    if (_isLoadingReady) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_readyOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pending_actions_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'ไม่มีออเดอร์ที่ต้องรับ',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ออเดอร์ที่อาหารพร้อมแล้วจะแสดงที่นี่',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReadyOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _readyOrders.length,
        itemBuilder: (context, index) {
          final order = _readyOrders[index];
          return _buildOrderCard(order, isReady: true);
        },
      ),
    );
  }

  /// แท็บ "สำเร็จ" (status = completed)
  Widget _buildCompletedOrdersTab() {
    if (_isLoadingCompleted) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_completedOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'ยังไม่มีประวัติการสั่งซื้อ',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ออเดอร์ที่รับแล้วจะแสดงที่นี่',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCompletedOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _completedOrders.length,
        itemBuilder: (context, index) {
          final order = _completedOrders[index];
          return _buildOrderCard(order, isReady: false);
        },
      ),
    );
  }

  /// Card แสดง order
  Widget _buildOrderCard(Map<String, dynamic> order, {required bool isReady}) {
    final orderId = order['id'] as int;
    final restaurantName = order['restaurant_name'] ?? 'ร้านอาหาร';
    final totalAmount = (order['total_amount'] ?? 0).toDouble();
    final totalItems = order['total_items'] ?? 0;
  final status = (order['status'] ?? '').toString();
    final createdAt = order['created_at'] != null
        ? DateTime.parse(order['created_at']).toLocal()
        : DateTime.now();
    final updatedAt = order['updated_at'] != null
        ? DateTime.parse(order['updated_at']).toLocal()
        : null;
    
    final items = (order['items'] as List?) ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showOrderDetail(order),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Order ID + Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Choose icon/color based on actual status so cancelled orders
                      // are rendered clearly in the completed tab.
                      Icon(
                        status == 'ready'
                            ? Icons.pending_actions
                            : (status == 'cancelled' ? Icons.cancel : Icons.check_circle),
                        color: status == 'ready'
                            ? AppColors.mainOrange
                            : (status == 'cancelled' ? Colors.red : Colors.green),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Order #$orderId',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: status == 'ready'
                          ? AppColors.mainOrange.withOpacity(0.1)
                          : (status == 'cancelled' ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      // Display exact status for non-ready orders (keep DB status unchanged)
                      status == 'ready' ? 'พร้อมรับ' : (status == 'cancelled' ? 'ยกเลิก' : 'สำเร็จ'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: status == 'ready' ? AppColors.mainOrange : (status == 'cancelled' ? Colors.red : Colors.green),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Restaurant Name
              Row(
                children: [
                  const Icon(Icons.store, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      restaurantName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Items Summary
              Row(
                children: [
                  const Icon(Icons.restaurant_menu, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$totalItems รายการ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              
              if (items.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  items.take(2).map((item) => item['menu_name']).join(', ') +
                      (items.length > 2 ? ' และอื่นๆ' : ''),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              
              // Footer: Date + Price
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Date
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd/MM/yy HH:mm').format(
                          isReady || updatedAt == null ? createdAt : updatedAt
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  
                  // Total Price
                  Text(
                    '฿${totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.mainOrange,
                    ),
                  ),
                ],
              ),
              
              // ปุ่มรับอาหาร (เฉพาะแท็บ "ต้องรับ")
              if (isReady) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmPickup(orderId),
                    icon: const Icon(Icons.check_circle, color: Colors.white),
                    label: const Text(
                      'รับอาหารแล้ว',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// แสดง Dialog รายละเอียด order
  void _showOrderDetail(Map<String, dynamic> order) {
    final orderId = order['id'] as int;
    final restaurantName = order['restaurant_name'] ?? 'ร้านอาหาร';
    final totalAmount = (order['total_amount'] ?? 0).toDouble();
    final status = order['status'] ?? '';
    final createdAt = order['created_at'] != null
        ? DateTime.parse(order['created_at']).toLocal()
        : DateTime.now();
    final updatedAt = order['updated_at'] != null
        ? DateTime.parse(order['updated_at']).toLocal()
        : null;
    
    final items = (order['items'] as List?) ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order #$orderId'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Restaurant
              Text(
                restaurantName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Status
              Row(
                children: [
                  const Text('สถานะ: ', style: TextStyle(fontWeight: FontWeight.w500)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: status == 'ready'
                          ? AppColors.mainOrange.withOpacity(0.2)
                          : (status == 'cancelled' ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status == 'ready'
                          ? 'พร้อมรับ'
                          : (status == 'cancelled' ? 'ยกเลิก' : 'สำเร็จ'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: status == 'ready'
                            ? AppColors.mainOrange
                            : (status == 'cancelled' ? Colors.red : Colors.green),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Timeline
              Text(
                'สั่งเมื่อ: ${DateFormat('dd/MM/yyyy HH:mm').format(createdAt)}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              if (updatedAt != null)
                Text(
                  '${status == "ready" ? "พร้อม" : "รับ"}เมื่อ: ${DateFormat('dd/MM/yyyy HH:mm').format(updatedAt)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              
              // Items List
              const Text(
                'รายการอาหาร',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              ...items.map((item) {
                final menuName = item['menu_name'] ?? 'Unknown';
                final quantity = item['quantity'] ?? 1;
                final price = (item['price'] ?? 0).toDouble();
                final subtotal = price * quantity;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '$menuName x$quantity',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        '฿${subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              
              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'รวมทั้งหมด',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '฿${totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.mainOrange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }
}
