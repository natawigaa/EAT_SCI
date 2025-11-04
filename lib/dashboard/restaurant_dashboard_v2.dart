import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eatscikmitl/services/supabase_service.dart';
import 'package:eatscikmitl/screen/auth/LoginScreen.dart';
import 'package:eatscikmitl/dashboard/orders_management_screen.dart';
import 'package:eatscikmitl/dashboard/daily_sales_report_screen.dart';
import 'package:eatscikmitl/dashboard/reports/reports_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../utils/notification_helper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class RestaurantDashboardV2 extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;

  const RestaurantDashboardV2({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<RestaurantDashboardV2> createState() => _RestaurantDashboardV2State();
}

class _RestaurantDashboardV2State extends State<RestaurantDashboardV2> {
  int _selectedTabIndex = 0;
  
  final List<Map<String, dynamic>> _tabs = [
    {'icon': Icons.receipt_long, 'label': 'คำสั่งซื้อ'},
    {'icon': Icons.bar_chart, 'label': 'รายงาน'},
    {'icon': Icons.restaurant_menu, 'label': 'จัดการเมนู'},
    {'icon': Icons.settings, 'label': 'ตั้งค่า'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _buildMainContent(), // เอา Row ออก แสดงแค่ content
      bottomNavigationBar: _buildBottomNavigationBar(), // เพิ่ม bottom nav
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.store,
              color: Colors.orange.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.restaurantName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Restaurant Dashboard',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Notification Bell
        IconButton(
          icon: Badge(
            label: const Text('3'),
            child: const Icon(Icons.notifications_outlined),
          ),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
        
        // User Profile
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: PopupMenuButton(
            offset: const Offset(0, 50),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.orange.shade100,
                  child: Icon(
                    Icons.person,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.account_circle, size: 20),
                    SizedBox(width: 12),
                    Text('โปรไฟล์'),
                  ],
                ),
                onTap: () {},
              ),
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('ออกจากระบบ', style: TextStyle(color: Colors.red)),
                  ],
                ),
                onTap: () => _handleLogout(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08), // ปรับให้เหมือนฝั่งนักศึกษา
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 65, // กำหนดความสูงเท่ากับฝั่งนักศึกษา
          child: BottomNavigationBar(
            currentIndex: _selectedTabIndex,
            onTap: (index) {
              setState(() {
                _selectedTabIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.orange.shade700,
            unselectedItemColor: Colors.grey[600],
            selectedFontSize: 12,
            unselectedFontSize: 12,
            iconSize: 24, // กำหนดขนาดไอคอนให้ชัดเจน
            elevation: 0,
            items: _tabs.map((tab) {
              return BottomNavigationBarItem(
                icon: Icon(tab['icon']),
                label: tab['label'],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_selectedTabIndex) {
      case 0:
        // เปิดหน้า Orders Management จริง
        return OrdersManagementScreen(
          restaurantId: int.parse(widget.restaurantId),
          restaurantName: widget.restaurantName,
        );
      case 1:
        return ReportsScreen(
          restaurantId: int.parse(widget.restaurantId),
          restaurantName: widget.restaurantName,
        );
      case 2:
        return MenuManagementTab(restaurantId: widget.restaurantId);
      case 3:
        return SettingsTab(
          restaurantId: widget.restaurantId,
          restaurantName: widget.restaurantName,
        );
      default:
        return const Center(child: Text('Unknown tab'));
    }
  }

  void _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ออกจากระบบ'),
        content: const Text('คุณต้องการออกจากระบบใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ออกจากระบบ'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        await Supabase.instance.client.auth.signOut();
        print('✅ Logout สำเร็จ');
      } catch (e) {
        print('❌ Logout error: $e');
      }
    }
  }
}

// ===========================================
// 📦 Orders Tab - จัดการคำสั่งซื้อ
// ===========================================
class OrdersTab extends StatefulWidget {
  final String restaurantId;

  const OrdersTab({super.key, required this.restaurantId});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  List<Map<String, dynamic>> _pendingOrders = [];
  bool _isLoading = true;
  String _selectedFilter = 'pending'; // pending, confirmed, all

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: เปลี่ยนเป็น query จริงตาม filter
      final orders = await SupabaseService.getPendingSlipOrders(
        int.parse(widget.restaurantId),
      );
      
      setState(() {
        _pendingOrders = orders;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading orders: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'คำสั่งซื้อ',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _loadOrders,
                icon: const Icon(Icons.refresh),
                label: const Text('รีเฟรช'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('รอตรวจสอบ', 'pending', Icons.hourglass_empty),
                _buildFilterChip('ยืนยันแล้ว', 'confirmed', Icons.check_circle),
                _buildFilterChip('กำลังทำ', 'preparing', Icons.restaurant),
                _buildFilterChip('พร้อมรับ', 'ready', Icons.shopping_bag),
                _buildFilterChip('ทั้งหมด', 'all', Icons.list),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Orders List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _pendingOrders.isEmpty
                    ? _buildEmptyState()
                    : _buildOrdersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = value;
          });
          _loadOrders();
        },
        selectedColor: Colors.orange.shade100,
        checkmarkColor: Colors.orange.shade700,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'ไม่มีคำสั่งซื้อ',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    return ListView.builder(
      itemCount: _pendingOrders.length,
      itemBuilder: (context, index) {
        final order = _pendingOrders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order['id']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'นักศึกษา: ${order['student_id']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '฿${order['total_amount']?.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    Text(
                      '${order['total_items']} รายการ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const Divider(height: 24),
            
            // Payment Slip
            if (order['payment_slip_url'] != null) ...[
              Row(
                children: [
                  Icon(Icons.receipt, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  const Text(
                    'สลิปการโอนเงิน:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _viewSlip(order['payment_slip_url']),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('ดูสลิป'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectOrder(order['id']),
                    icon: const Icon(Icons.close),
                    label: const Text('ปฏิเสธ'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmOrder(order['id']),
                    icon: const Icon(Icons.check),
                    label: const Text('ยืนยันรับออเดอร์'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _viewSlip(String slipUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('สลิปการโอนเงิน'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Image.network(
                slipUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Text('ไม่สามารถโหลดรูปได้');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmOrder(int orderId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    
    try {
      final success = await SupabaseService.confirmOrderSlip(orderId, userId);
      
      if (success) {
        NotificationHelper.showSuccess(
          context,
          'ยืนยันออเดอร์สำเร็จ',
        );
        _loadOrders();
      }
    } catch (e) {
      print('❌ Error: $e');
    }
  }

  Future<void> _rejectOrder(int orderId) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _buildRejectDialog(),
    );
    
    if (reason != null && reason.isNotEmpty) {
      try {
        final success = await SupabaseService.rejectOrderSlip(orderId, reason);
        
        if (success) {
          NotificationHelper.showError(
            context,
            'ปฏิเสธออเดอร์แล้ว',
          );
          _loadOrders();
        }
      } catch (e) {
        print('❌ Error: $e');
      }
    }
  }

  Widget _buildRejectDialog() {
    final controller = TextEditingController();
    
    return AlertDialog(
      title: const Text('ปฏิเสธออเดอร์'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('กรุณาระบุเหตุผลในการปฏิเสธ:'),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'เช่น สลิปไม่ตรงกับยอดเงิน',
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, controller.text),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('ยืนยัน'),
        ),
      ],
    );
  }
}

// ===========================================
// 📊 Reports Tab - รายงานยอดขาย (Phase 7)
// ===========================================
class ReportsTab extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;

  const ReportsTab({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _weeklySales = [];
  List<Map<String, dynamic>> _topMenus = [];
  List<Map<String, dynamic>> _peakHours = [];
  Map<String, dynamic> _processingTime = {};
  
  // Period filter
  String _selectedPeriod = 'today'; // 'today', 'week', 'month'
  Map<String, dynamic> _periodSummary = {};
  Map<String, dynamic> _comparison = {}; // เพิ่มตัวแปรเก็บข้อมูลเปรียบเทียบ
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    print('🔄 Dashboard: กำลังโหลดข้อมูล...');
    print('🏪 Restaurant ID: ${widget.restaurantId}');
    print('📅 Selected Period: $_selectedPeriod');
    
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        SupabaseService.getWeeklySales(int.parse(widget.restaurantId)),
        SupabaseService.getTopMenus(int.parse(widget.restaurantId), days: 7, limit: 5),
        SupabaseService.getPeakHours(int.parse(widget.restaurantId), days: 7),
        SupabaseService.getSalesByPeriod(int.parse(widget.restaurantId), _selectedPeriod),
        SupabaseService.getAverageProcessingTime(int.parse(widget.restaurantId)),
        SupabaseService.getPeriodComparison(int.parse(widget.restaurantId), _selectedPeriod), // เพิ่มการโหลดข้อมูลเปรียบเทียบ
      ]);
      
      print('✅ Dashboard: ได้รับข้อมูลจาก API แล้ว');
      print('📊 Period Summary: ${results[3]}');
      
      setState(() {
        _weeklySales = results[0] as List<Map<String, dynamic>>;
        _topMenus = results[1] as List<Map<String, dynamic>>;
        _peakHours = results[2] as List<Map<String, dynamic>>;
        _periodSummary = results[3] as Map<String, dynamic>;
        _processingTime = results[4] as Map<String, dynamic>;
        _comparison = results[5] as Map<String, dynamic>; // เก็บข้อมูลเปรียบเทียบ
        _isLoading = false;
      });
      
      print('✅ Dashboard: setState เสร็จแล้ว');
    } catch (e) {
      print('❌ Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _onPeriodChanged(String? newPeriod) async {
    if (newPeriod == null || newPeriod == _selectedPeriod) return;
    
    setState(() {
      _selectedPeriod = newPeriod;
      _isLoading = true;
    });
    
    try {
      final results = await Future.wait([
        SupabaseService.getSalesByPeriod(
          int.parse(widget.restaurantId),
          newPeriod,
        ),
        SupabaseService.getPeriodComparison(
          int.parse(widget.restaurantId),
          newPeriod,
        ),
      ]);
      
      setState(() {
        _periodSummary = results[0] as Map<String, dynamic>;
        _comparison = results[1] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error changing period: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Period Filter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '📊 รายงานยอดขาย',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    // ปุ่มสรุปรายวัน
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DailySalesReportScreen(
                              restaurantId: int.parse(widget.restaurantId),
                              restaurantName: widget.restaurantName,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.receipt_long, size: 18),
                      label: const Text('สรุปรายวัน'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Period Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedPeriod,
                        underline: const SizedBox(),
                        icon: Icon(Icons.arrow_drop_down, color: Colors.orange.shade700),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'today', child: Text('📅 วันนี้')),
                          DropdownMenuItem(value: 'week', child: Text('📆 สัปดาห์นี้')),
                          DropdownMenuItem(value: 'month', child: Text('📅 เดือนนี้')),
                        ],
                        onChanged: _onPeriodChanged,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Summary Cards (4 cards) - แสดงข้อมูลตาม period ที่เลือก
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              _buildSummaryCards(),
            
            const SizedBox(height: 32),
            
            // Weekly Sales Chart
            _buildWeeklySalesChart(),
            
            const SizedBox(height: 32),
            
            // Top 5 Menus
            _buildTopMenus(),
            
            const SizedBox(height: 32),
            
            // Peak Hours Chart
            _buildPeakHoursChart(),
            
            const SizedBox(height: 32),
            
            // Average Processing Time
            _buildProcessingTime(),
            
            const SizedBox(height: 32),
            
            // Period Comparison
            _buildPeriodComparison(),
          ],
        ),
      ),
    );
  }

  /// Widget แสดงการเปรียบเทียบกับช่วงเวลาก่อนหน้า
  Widget _buildPeriodComparison() {
    if (_comparison.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final revenueChange = _comparison['revenue_change_percent'] ?? 0.0;
    final ordersChange = _comparison['orders_change_percent'] ?? 0.0;
    final isRevenueIncreased = _comparison['is_revenue_increased'] ?? false;
    final isOrdersIncreased = _comparison['is_orders_increased'] ?? false;
    final currentRevenue = _comparison['current_revenue'] ?? 0.0;
    final previousRevenue = _comparison['previous_revenue'] ?? 0.0;
    final currentOrders = _comparison['current_orders'] ?? 0;
    final previousOrders = _comparison['previous_orders'] ?? 0;
    
    // Label ตาม period
    String periodLabel = '';
    String comparisonLabel = '';
    if (_selectedPeriod == 'today') {
      periodLabel = 'วันนี้';
      comparisonLabel = 'เมื่อวาน';
    } else if (_selectedPeriod == 'week') {
      periodLabel = 'สัปดาห์นี้';
      comparisonLabel = 'สัปดาห์ที่แล้ว';
    } else if (_selectedPeriod == 'month') {
      periodLabel = 'เดือนนี้';
      comparisonLabel = 'เดือนที่แล้ว';
    }
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.compare_arrows, color: Colors.grey.shade700, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'เปรียบเทียบ $periodLabel vs $comparisonLabel',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Revenue Comparison
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.attach_money,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ยอดขาย',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Current
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            periodLabel,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '฿${currentRevenue.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Arrow and %
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isRevenueIncreased
                            ? Colors.blue.shade50
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isRevenueIncreased
                              ? Colors.blue.shade200
                              : Colors.grey.shade400,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isRevenueIncreased
                                ? Icons.trending_up
                                : Icons.trending_down,
                            color: isRevenueIncreased
                                ? Colors.blue.shade700
                                : Colors.grey.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${revenueChange >= 0 ? '+' : ''}${revenueChange.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isRevenueIncreased
                                  ? Colors.blue.shade700
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Previous
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            comparisonLabel,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '฿${previousRevenue.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Orders Comparison
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.shopping_bag,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'จำนวนออเดอร์',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Current
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            periodLabel,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$currentOrders ออเดอร์',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Arrow and %
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isOrdersIncreased
                            ? Colors.blue.shade50
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isOrdersIncreased
                              ? Colors.blue.shade200
                              : Colors.grey.shade400,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isOrdersIncreased
                                ? Icons.trending_up
                                : Icons.trending_down,
                            color: isOrdersIncreased
                                ? Colors.blue.shade700
                                : Colors.grey.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${ordersChange >= 0 ? '+' : ''}${ordersChange.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isOrdersIncreased
                                  ? Colors.blue.shade700
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Previous
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            comparisonLabel,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$previousOrders ออเดอร์',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalRevenue = _periodSummary['total_revenue'] ?? 0.0;
    final totalOrders = _periodSummary['total_orders'] ?? 0;
    final completedOrders = _periodSummary['completed_orders'] ?? 0;
    final averageValue = _periodSummary['average_order_value'] ?? 0.0;
    
    // Debug: แสดงข้อมูลที่ได้จาก API
    print('🎯 Dashboard Summary Cards - Period: $_selectedPeriod');
    print('📊 _periodSummary data: $_periodSummary');
    print('💰 Total Revenue: ฿$totalRevenue');
    print('📦 Total Orders: $totalOrders');
    print('✅ Completed Orders: $completedOrders');
    print('📈 Average Value: ฿$averageValue');
    
    // Label ตาม period
    String periodLabel = '';
    if (_selectedPeriod == 'today') {
      periodLabel = 'วันนี้';
    } else if (_selectedPeriod == 'week') {
      periodLabel = 'สัปดาห์นี้';
    } else if (_selectedPeriod == 'month') {
      periodLabel = 'เดือนนี้';
    }
    
    return Column(
      children: [
        // Row 1: ยอดขาย + ออเดอร์ทั้งหมด
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'ยอดขาย$periodLabel',
                value: '฿${totalRevenue.toStringAsFixed(0)}',
                icon: Icons.payments_rounded,
                color: Colors.green,
                backgroundColor: Colors.green.shade50,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                title: 'ออเดอร์ทั้งหมด',
                value: '$totalOrders',
                subtitle: 'ออเดอร์',
                icon: Icons.shopping_bag_rounded,
                color: Colors.orange,
                backgroundColor: Colors.orange.shade50,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Row 2: เสร็จสิ้น + มูลค่าเฉลี่ย
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'เสร็จสิ้นแล้ว',
                value: '$completedOrders',
                subtitle: 'ออเดอร์',
                icon: Icons.check_circle_rounded,
                color: Colors.blue,
                backgroundColor: Colors.blue.shade50,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                title: 'มูลค่าเฉลี่ย',
                value: '฿${averageValue.toStringAsFixed(0)}',
                subtitle: 'ต่อออเดอร์',
                icon: Icons.analytics_rounded,
                color: Colors.purple,
                backgroundColor: Colors.purple.shade50,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Value
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          
          // Subtitle
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopMenus() {
    if (_topMenus.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.emoji_events, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'ยังไม่มีข้อมูลเมนูขายดี',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber.shade700, size: 24),
              const SizedBox(width: 12),
              Text(
                'เมนูขายดี Top 5',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const Spacer(),
              Text(
                '7 วันย้อนหลัง',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Menu List
          ...List.generate(_topMenus.length, (index) {
            final menu = _topMenus[index];
            final menuName = menu['menu_name'] ?? 'ไม่ระบุ';
            final totalQuantity = menu['total_quantity'] ?? 0;
            final rank = index + 1;
            
            // Medal colors
            Color rankColor;
            IconData rankIcon;
            
            if (rank == 1) {
              rankColor = Colors.amber.shade600;
              rankIcon = Icons.emoji_events;
            } else if (rank == 2) {
              rankColor = Colors.grey.shade400;
              rankIcon = Icons.emoji_events_outlined;
            } else if (rank == 3) {
              rankColor = Colors.orange.shade800;
              rankIcon = Icons.emoji_events_outlined;
            } else {
              rankColor = Colors.grey.shade300;
              rankIcon = Icons.restaurant_menu;
            }
            
            return Column(
              children: [
                if (index > 0) const Divider(height: 24),
                Row(
                  children: [
                    // Rank Icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: rankColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: rank <= 3
                          ? Icon(rankIcon, color: rankColor, size: 22)
                          : Text(
                              '$rank',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: rankColor,
                              ),
                            ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Menu Name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            menuName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ขายได้ $totalQuantity จาน',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Quantity Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shopping_bag_outlined, 
                            size: 16, 
                            color: Colors.orange.shade700
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$totalQuantity',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPeakHoursChart() {
    if (_peakHours.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.schedule, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'ยังไม่มีข้อมูลช่วงเวลาขายดี',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    // Find max orders for scaling
    int maxOrders = 0;
    for (var hourData in _peakHours) {
      final orders = hourData['order_count'] ?? 0;
      if (orders > maxOrders) maxOrders = orders;
    }
    
    // Prepare bar groups
    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < _peakHours.length; i++) {
      final hourData = _peakHours[i];
      final orderCount = (hourData['order_count'] ?? 0).toDouble();
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: orderCount,
              color: Colors.blue.shade600,
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade400,
                  Colors.blue.shade600,
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.schedule, color: Colors.blue.shade700, size: 24),
              const SizedBox(width: 12),
              Text(
                'ช่วงเวลาขายดี (Peak Hours)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const Spacer(),
              Text(
                '7 วันย้อนหลัง',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Chart
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxOrders > 0 ? maxOrders * 1.2 : 10,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.grey.shade800,
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      if (groupIndex < 0 || groupIndex >= _peakHours.length) {
                        return null;
                      }
                      final hour = _peakHours[groupIndex]['hour'] ?? 0;
                      final orders = rod.toY.toInt();
                      return BarTooltipItem(
                        '${hour.toString().padLeft(2, '0')}:00\n$orders ออเดอร์',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= _peakHours.length) {
                          return const Text('');
                        }
                        final hour = _peakHours[index]['hour'] ?? 0;
                        // Show every 2 hours to avoid crowding
                        if (hour % 2 != 0 && _peakHours.length > 10) {
                          return const Text('');
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${hour.toString().padLeft(2, '0')}:00',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: maxOrders > 0 ? (maxOrders / 5).ceilToDouble() : 2,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max) return const Text('');
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxOrders > 0 ? (maxOrders / 5).ceilToDouble() : 2,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                    left: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                ),
                barGroups: barGroups,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklySalesChart() {
    if (_weeklySales.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.show_chart, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'ยังไม่มีข้อมูลยอดขาย',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    // Prepare chart data
    List<FlSpot> spots = [];
    double maxY = 0;
    
    for (int i = 0; i < _weeklySales.length; i++) {
      final revenue = (_weeklySales[i]['revenue'] ?? 0.0) as double;
      spots.add(FlSpot(i.toDouble(), revenue));
      if (revenue > maxY) maxY = revenue;
    }

    // Add some padding to max value
    maxY = maxY * 1.2;
    if (maxY == 0) maxY = 1000; // Default if no sales

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.show_chart, color: Colors.orange.shade700, size: 24),
              const SizedBox(width: 12),
              Text(
                'ยอดขาย 7 วันย้อนหลัง',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Chart
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= _weeklySales.length) {
                          return const Text('');
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _weeklySales[index]['day_name'] ?? '',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      interval: maxY / 5,
                      getTitlesWidget: (value, meta) {
                        if (value == maxY) return const Text('');
                        return Text(
                          '฿${(value / 1000).toStringAsFixed(0)}k',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                    left: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.orange.shade600,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: Colors.orange.shade600,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.orange.shade100.withOpacity(0.3),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => Colors.grey.shade800,
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        if (index < 0 || index >= _weeklySales.length) {
                          return null;
                        }
                        final dayName = _weeklySales[index]['day_name'] ?? '';
                        final revenue = spot.y;
                        final orders = _weeklySales[index]['order_count'] ?? 0;
                        
                        return LineTooltipItem(
                          '$dayName\n฿${revenue.toStringAsFixed(0)}\n$orders ออเดอร์',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingTime() {
    if (_processingTime.isEmpty || _processingTime['sample_size'] == 0) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.timer_off, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'ยังไม่มีข้อมูลเวลาทำอาหาร',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    final pendingToConfirmed = (_processingTime['pending_to_confirmed_minutes'] ?? 0).toInt();
    final confirmedToPreparing = (_processingTime['confirmed_to_preparing_minutes'] ?? 0).toInt();
    final preparingToReady = (_processingTime['preparing_to_ready_minutes'] ?? 0).toInt();
    final totalMinutes = (_processingTime['total_minutes'] ?? 0).toInt();
    final sampleSize = _processingTime['sample_size'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.timer, color: Colors.grey.shade700, size: 24),
              const SizedBox(width: 12),
              Text(
                'เวลาทำอาหารเฉลี่ย',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  'จาก $sampleSize ออเดอร์',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Total Time Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: Colors.white, size: 32),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'เวลารวมทั้งหมด',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade300,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalMinutes นาที',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Process Steps - ใช้สีฟ้าเป็นจุดเน้น
          _buildProcessStep(
            '1. รับออเดอร์ → ยืนยัน',
            pendingToConfirmed,
            Icons.check_circle_outline,
            Colors.blue,
          ),
          
          const SizedBox(height: 12),
          
          _buildProcessStep(
            '2. ยืนยัน → เริ่มทำ',
            confirmedToPreparing,
            Icons.restaurant_menu,
            Colors.blue,
          ),
          
          const SizedBox(height: 12),
          
          _buildProcessStep(
            '3. กำลังทำ → พร้อมเสิร์ฟ',
            preparingToReady,
            Icons.done_all,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildProcessStep(String label, int minutes, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Text(
            '$minutes นาที',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================
// 🍽️ Menu Management Tab - จัดการเมนู
// ===========================================
class MenuManagementTab extends StatelessWidget {
  final String restaurantId;

  const MenuManagementTab({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'จัดการเมนูอาหาร',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.construction, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  '🚧 อยู่ระหว่างพัฒนา',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'ฟีเจอร์การจัดการเมนู, เปลี่ยนสถานะ, แก้ไขรายละเอียด',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================
// ⚙️ Settings Tab - ตั้งค่า
// ===========================================
class SettingsTab extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;

  const SettingsTab({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  String? _currentQrCodeUrl;
  bool _isLoadingQr = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentQrCode();
  }

  Future<void> _loadCurrentQrCode() async {
    try {
      final restaurants = await SupabaseService.getRestaurants();
      final restaurant = restaurants.firstWhere(
        (r) => r['id'].toString() == widget.restaurantId,
        orElse: () => {},
      );

      if (restaurant.isNotEmpty) {
        setState(() {
          _currentQrCodeUrl = restaurant['qr_code_url'];
          _isLoadingQr = false;
        });
      }
    } catch (e) {
      print('❌ Error loading QR: $e');
      setState(() {
        _isLoadingQr = false;
      });
    }
  }

  Future<void> _pickAndUploadQrCode() async {
    final ImagePicker picker = ImagePicker();
    
    try {
      // เลือกภาพจาก gallery
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) {
        print('⚠️ ไม่ได้เลือกภาพ');
        return;
      }

      setState(() {
        _isUploading = true;
      });

      // Clear cache ของรูปเก่าก่อนอัปโหลด (ป้องกัน cache ค้าง)
      if (_currentQrCodeUrl != null) {
        imageCache.evict(_currentQrCodeUrl!);
        print('🗑️ Clear image cache: $_currentQrCodeUrl');
      }

      // อัปโหลดไป Supabase Storage
      final qrUrl = await SupabaseService.uploadRestaurantQrCode(
        image.path,
        int.parse(widget.restaurantId),
      );

      if (qrUrl != null) {
        // อัปเดต URL ใน database
        final success = await SupabaseService.updateRestaurantQrCode(
          int.parse(widget.restaurantId),
          qrUrl,
        );

        if (success) {
          // บังคับ clear cache ของ URL ใหม่ด้วย (เผื่อมี timestamp เดิมติดอยู่)
          imageCache.clear();
          print('🧹 Clear all image cache');

          setState(() {
            _currentQrCodeUrl = qrUrl;
            _isUploading = false;
          });

          if (mounted) {
            NotificationHelper.showSuccess(
              context,
              'อัปโหลด QR Code สำเร็จ!',
            );
          }
        } else {
          throw Exception('ไม่สามารถอัปเดต URL ใน database');
        }
      } else {
        throw Exception('อัปโหลดไฟล์ไม่สำเร็จ');
      }
    } catch (e) {
      print('❌ Error: $e');
      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        NotificationHelper.showError(
          context,
          'เกิดข้อผิดพลาด: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ตั้งค่าร้าน',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // ข้อมูลร้าน
            Card(
              child: ListTile(
                leading: const Icon(Icons.store),
                title: const Text('ชื่อร้าน'),
                subtitle: Text(widget.restaurantName),
                trailing: const Icon(Icons.edit),
                onTap: () {
                  NotificationHelper.showInfo(
                    context,
                    '🚧 ฟีเจอร์แก้ไขชื่อร้านกำลังพัฒนา',
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // QR Code Section
            Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.qr_code, color: Colors.orange),
                      const SizedBox(width: 12),
                      const Text(
                        'QR Code ชำระเงิน',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'อัปโหลด QR Code PromptPay หรือ QR Mobile Banking ของร้าน',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // แสดง QR Code ปัจจุบัน
                  if (_isLoadingQr)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_currentQrCodeUrl != null)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _currentQrCodeUrl!,
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                                cacheWidth: 400, // บังคับ cache size
                                cacheHeight: 400,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 200,
                                    height: 200,
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.broken_image,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: 200,
                                    height: 200,
                                    alignment: Alignment.center,
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'QR Code ปัจจุบัน',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.qr_code_2,
                              size: 60,
                              color: Colors.orange,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'ยังไม่มี QR Code',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // ปุ่มอัปโหลด
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isUploading ? null : _pickAndUploadQrCode,
                      icon: _isUploading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.upload_file),
                      label: Text(
                        _isUploading
                            ? 'กำลังอัปโหลด...'
                            : (_currentQrCodeUrl != null
                                ? 'เปลี่ยน QR Code'
                                : 'อัปโหลด QR Code'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          const Center(
            child: Text(
              '🚧 ฟีเจอร์เพิ่มเติมกำลังพัฒนา',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          
          // เพิ่ม spacing ท้ายหน้า
          const SizedBox(height: 40),
        ],
      ),
      ),
    );
  }
}
