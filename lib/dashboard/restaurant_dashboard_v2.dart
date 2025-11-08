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
  SupabaseService.getAverageProcessingTime(int.parse(widget.restaurantId), period: _selectedPeriod),
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
        SupabaseService.getAverageProcessingTime(int.parse(widget.restaurantId), period: newPeriod),
        SupabaseService.getPeriodComparison(
          int.parse(widget.restaurantId),
          newPeriod,
        ),
      ]);
      
      setState(() {
        _periodSummary = results[0] as Map<String, dynamic>;
        _processingTime = results[1] as Map<String, dynamic>;
        _comparison = results[2] as Map<String, dynamic>;
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
                color: Colors.black,
                backgroundColor: Colors.black,
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
class MenuManagementTab extends StatefulWidget {
  final String restaurantId;

  const MenuManagementTab({super.key, required this.restaurantId});

  @override
  State<MenuManagementTab> createState() => _MenuManagementTabState();
}

class _MenuManagementTabState extends State<MenuManagementTab> {
  List<Map<String, dynamic>> _menuItems = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadMenuItems();
  }

  Future<void> _loadMenuItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await SupabaseService.getMenuItems(int.parse(widget.restaurantId));
      setState(() {
        _menuItems = items;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading menu items: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showEditDialog({Map<String, dynamic>? item}) async {
    final isNew = item == null;
    final nameCtrl = TextEditingController(text: item != null ? item['name']?.toString() ?? '' : '');
    final priceCtrl = TextEditingController(text: item != null ? (item['price']?.toString() ?? '') : '');
    final categoryCtrl = TextEditingController(text: item != null ? item['category']?.toString() ?? '' : '');
    final descCtrl = TextEditingController(text: item != null ? item['description']?.toString() ?? '' : '');
  bool available = item != null ? (item['is_available'] == true || item['available'] == true) : true;
    String? imageUrl = item != null ? item['image_url'] ?? item['imageUrl'] : null;
    XFile? pickedImage;

    final parentContext = context;

    await showDialog<void>(
      context: parentContext,
      builder: (context) => StatefulBuilder(builder: (context, setStateDialog) {
        return AlertDialog(
          title: Text(isNew ? 'เพิ่มเมนูใหม่' : 'แก้ไขเมนู'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'ชื่อเมนู'),
                  onChanged: (s) => print('onChanged [RestaurantDashboardV2.editMenu.name]: "$s"'),
                  onEditingComplete: () => print('editingComplete [RestaurantDashboardV2.editMenu.name] -> "${nameCtrl.text}"'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'ราคา'),
                  onChanged: (s) => print('onChanged [RestaurantDashboardV2.editMenu.price]: "$s"'),
                  onEditingComplete: () => print('editingComplete [RestaurantDashboardV2.editMenu.price] -> "${priceCtrl.text}"'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: categoryCtrl,
                  decoration: const InputDecoration(labelText: 'หมวดหมู่'),
                  onChanged: (s) => print('onChanged [RestaurantDashboardV2.editMenu.category]: "$s"'),
                  onEditingComplete: () => print('editingComplete [RestaurantDashboardV2.editMenu.category] -> "${categoryCtrl.text}"'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'คำอธิบาย (ไม่บังคับ)'),
                  onChanged: (s) => print('onChanged [RestaurantDashboardV2.editMenu.description]: "$s"'),
                  onEditingComplete: () => print('editingComplete [RestaurantDashboardV2.editMenu.description] -> "${descCtrl.text}"'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('สถานะ: '),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SwitchListTile(
                        value: available,
                        title: Text(available ? 'พร้อมขาย' : 'หมด'),
                        onChanged: (v) => setStateDialog(() => available = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (imageUrl != null)
                  Column(children: [
                    Image.network(imageUrl, height: 80, fit: BoxFit.cover),
                    const SizedBox(height: 8),
                  ]),
                ElevatedButton.icon(
                  icon: const Icon(Icons.image),
                  label: const Text('เลือกรูปเมนู'),
                  onPressed: () async {
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, maxHeight: 1200, imageQuality: 80);
                    if (image != null) {
                      setStateDialog(() {
                        pickedImage = image;
                      });
                    }
                  },
                ),
                if (pickedImage != null) Text('ไฟล์ที่เลือก: ${pickedImage!.name}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                final category = categoryCtrl.text.trim();
                final description = descCtrl.text.trim();
                if (name.isEmpty || price <= 0) {
                  NotificationHelper.showWarning(context, 'กรุณากรอกชื่อและราคาถูกต้อง');
                  return;
                }

                Navigator.pop(context);
                setState(() => _isSaving = true);
                try {
                  String? uploadedUrl = imageUrl;
                  if (pickedImage != null) {
                    uploadedUrl = await SupabaseService.uploadMenuImage(pickedImage!.path, int.parse(widget.restaurantId));
                  }

                  final data = {
                    'restaurant_id': int.parse(widget.restaurantId),
                    'name': name,
                    'price': price,
                    'category': category,
                    'description': description,
                      'is_available': available,
                    'image_url': uploadedUrl,
                  };

                  if (isNew) {
                    final created = await SupabaseService.createMenuItem(data);
                    if (created != null) {
                      NotificationHelper.showSuccess(parentContext, 'เพิ่มเมนูสำเร็จ');
                    } else {
                      NotificationHelper.showError(parentContext, 'ไม่สามารถเพิ่มเมนูได้');
                    }
                  } else {
                    final success = await SupabaseService.updateMenuItem(item!['id'] as int, data);
                    if (success) NotificationHelper.showSuccess(parentContext, 'อัปเดตเมนูสำเร็จ');
                    else NotificationHelper.showError(parentContext, 'ไม่สามารถอัปเดตเมนูได้');
                  }
                } catch (e) {
                  print('❌ Error saving menu: $e');
                  NotificationHelper.showError(parentContext, 'เกิดข้อผิดพลาด: $e');
                } finally {
                  setState(() => _isSaving = false);
                  _loadMenuItems();
                }
              },
              child: const Text('บันทึก'),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _toggleAvailable(Map<String, dynamic> item, bool val) async {
    final id = item['id'] as int;
  final success = await SupabaseService.updateMenuItem(id, {'is_available': val});
    if (success) {
      setState(() {
        final idx = _menuItems.indexWhere((m) => m['id'] == id);
        if (idx != -1) {
          _menuItems[idx]['is_available'] = val;
          _menuItems[idx]['available'] = val; // keep fallback key for older code
        }
      });
    } else {
      NotificationHelper.showError(context, 'ไม่สามารถเปลี่ยนสถานะได้');
    }
  }

  Future<void> _confirmDelete(int id) async {
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('ยืนยันลบ'),
      content: const Text('ต้องการลบเมนูนี้หรือไม่?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('ยกเลิก')),
        ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('ลบ')),
      ],
    ));
    if (ok == true) {
      final success = await SupabaseService.deleteMenuItem(id);
      if (success) {
        NotificationHelper.showSuccess(context, 'ลบเมนูแล้ว');
        _loadMenuItems();
      } else {
        NotificationHelper.showError(context, 'ไม่สามารถลบเมนูได้');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('จัดการเมนูอาหาร', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
              ElevatedButton.icon(onPressed: () => _showEditDialog(), icon: const Icon(Icons.add), label: const Text('เพิ่มเมนู')),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _menuItems.isEmpty
                    ? Center(child: Text('ยังไม่มีเมนูสำหรับร้านนี้', style: TextStyle(color: Colors.grey[600])))
                    : RefreshIndicator(
                        onRefresh: _loadMenuItems,
                        child: ListView.builder(
                          itemCount: _menuItems.length,
                          itemBuilder: (context, idx) {
                            final m = _menuItems[idx];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: m['image_url'] != null
                                    ? Image.network(m['image_url'], width: 56, height: 56, fit: BoxFit.cover)
                                    : Container(width: 56, height: 56, color: Colors.grey[100], child: Icon(Icons.restaurant_menu, color: Colors.grey[600])),
                                title: Text(m['name'] ?? '-'),
                                subtitle: Text('${m['category'] ?? '-'} • ฿${(m['price'] ?? 0).toString()}'),
                                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Switch(value: (m['is_available'] == true) || (m['available'] == true), onChanged: (v) => _toggleAvailable(m, v)),
                                  IconButton(icon: const Icon(Icons.edit), onPressed: () => _showEditDialog(item: m)),
                                  IconButton(icon: const Icon(Icons.delete), onPressed: () => _confirmDelete(m['id'] as int)),
                                ]),
                              ),
                            );
                          },
                        ),
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
  String? _pendingQrUrl;
  bool _isLoadingOpen = true;
  bool _isOpen = true;
  String _isOpenSource = 'stored';
  bool _manualModeEditing = false; // UI: show manual toggle only when merchant enables manual mode
  int? _openingHour;
  int? _closingHour;
  // Profile fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _currentProfileImageUrl;
  String? _pendingProfileImageUrl;
  // history UI removed; audit table is still available via DB if needed
  String? _openErrorMessage;

  @override
  void initState() {
    super.initState();
    _loadCurrentQrCode();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentQrCode() async {
    try {
      // Use the new helper that computes effective is_open considering manual override and schedule
      final info = await SupabaseService.getRestaurantEffectiveIsOpen(int.parse(widget.restaurantId));
      Map<String, dynamic>? restaurant;
      bool computedOpen = true;
      String source = 'stored';
      if (info != null) {
        restaurant = Map<String, dynamic>.from(info['restaurant'] ?? {});
        computedOpen = info['is_open'] == true;
        source = info['source']?.toString() ?? 'stored';
        // store opening hours if present
        try {
          _openingHour = restaurant.containsKey('opening_hour') ? (restaurant['opening_hour'] is int ? restaurant['opening_hour'] as int : int.tryParse(restaurant['opening_hour'].toString())) : null;
          _closingHour = restaurant.containsKey('closing_hour') ? (restaurant['closing_hour'] is int ? restaurant['closing_hour'] as int : int.tryParse(restaurant['closing_hour'].toString())) : null;
        } catch (_) {
          _openingHour = null;
          _closingHour = null;
        }
      } else {
        // fallback to querying restaurants
        final restaurants = await SupabaseService.getRestaurants();
        final r = restaurants.firstWhere((r) => r['id'].toString() == widget.restaurantId, orElse: () => {});
        restaurant = r is Map<String, dynamic> ? r : {};
        try {
          if (restaurant.containsKey('is_open')) computedOpen = restaurant['is_open'] == true;
        } catch (_) {}
      }

      setState(() {
        _currentQrCodeUrl = restaurant != null ? restaurant['qr_code_url'] : null;
        _currentProfileImageUrl = restaurant != null ? (restaurant['image_url'] ?? restaurant['profile_image_url']) : null;
        // populate editable fields
        try {
          if (restaurant != null) {
            _nameController.text = (restaurant['name'] ?? widget.restaurantName)?.toString() ?? '';
            _phoneController.text = restaurant['phone']?.toString() ?? '';
          }
        } catch (_) {}
        _isLoadingQr = false;
        _isOpen = computedOpen;
        _isLoadingOpen = false;
        _isOpenSource = source;
        // Show manual controls if the effective source is manual
        _manualModeEditing = source == 'manual';
      });
  // Note: user-facing UI no longer mentions internal "effective" term
  print('ℹ️ Restaurant is_open computed: $_isOpen (source: $source)');
    } catch (e) {
      print('❌ Error loading QR: $e');
      setState(() {
        _isLoadingQr = false;
        _isLoadingOpen = false;
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

      // อัปโหลดไป Supabase Storage (แต่ยังไม่ยืนยันเข้าฐานข้อมูล)
      final qrUrl = await SupabaseService.uploadRestaurantQrCode(
        image.path,
        int.parse(widget.restaurantId),
      );

      if (qrUrl != null) {
        // keep pending url until merchant confirms
        setState(() {
          _pendingQrUrl = qrUrl;
          _isUploading = false;
        });
        if (mounted) NotificationHelper.showInfo(context, 'อัปโหลดสำเร็จ — กรุณากด "ยืนยัน" เพื่อบันทึก URL ลงฐานข้อมูล');
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

  // Confirm and save pending QR URL into DB
  Future<void> _confirmPendingQr() async {
    if (_pendingQrUrl == null) return;
    setState(() => _isUploading = true);
    try {
      final success = await SupabaseService.updateRestaurantQrCode(int.parse(widget.restaurantId), _pendingQrUrl!);
      if (success) {
        imageCache.clear();
        setState(() {
          _currentQrCodeUrl = _pendingQrUrl;
          _pendingQrUrl = null;
          _isUploading = false;
        });
        NotificationHelper.showSuccess(context, 'บันทึก QR Code สำเร็จ');
      } else {
        setState(() => _isUploading = false);
        NotificationHelper.showError(context, 'ไม่สามารถบันทึก QR Code ได้');
      }
    } catch (e) {
      setState(() => _isUploading = false);
      NotificationHelper.showError(context, 'เกิดข้อผิดพลาด: $e');
    }
  }

  Future<void> _clearQr() async {
    setState(() => _isUploading = true);
    try {
      final success = await SupabaseService.updateRestaurantQrCode(int.parse(widget.restaurantId), null);
      if (success) {
        imageCache.clear();
        setState(() {
          _currentQrCodeUrl = null;
          _pendingQrUrl = null;
          _isUploading = false;
        });
        NotificationHelper.showSuccess(context, 'ล้าง QR Code สำเร็จ');
      } else {
        setState(() => _isUploading = false);
        NotificationHelper.showError(context, 'ไม่สามารถล้าง QR Code ได้');
      }
    } catch (e) {
      setState(() => _isUploading = false);
      NotificationHelper.showError(context, 'เกิดข้อผิดพลาด: $e');
    }
  }

  // Profile image upload + confirm flow
  Future<void> _pickAndUploadProfileImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image == null) return;
      setState(() => _isUploading = true);

      final imgUrl = await SupabaseService.uploadRestaurantImage(image.path, int.parse(widget.restaurantId));
      if (imgUrl != null) {
        setState(() {
          _pendingProfileImageUrl = imgUrl;
          _isUploading = false;
        });
        if (mounted) NotificationHelper.showInfo(context, 'อัปโหลดรูปสำเร็จ — กรุณากด "ยืนยัน" เพื่อบันทึก');
      } else {
        throw Exception('อัปโหลดรูปไม่สำเร็จ');
      }
    } catch (e) {
      print('❌ Error uploading profile image: $e');
      setState(() => _isUploading = false);
      if (mounted) NotificationHelper.showError(context, 'เกิดข้อผิดพลาด: $e');
    }
  }

  Future<void> _confirmPendingProfileImage() async {
    if (_pendingProfileImageUrl == null) return;
    setState(() => _isUploading = true);
    try {
      final success = await SupabaseService.updateRestaurantDetails(int.parse(widget.restaurantId), imageUrl: _pendingProfileImageUrl);
      if (success) {
        imageCache.clear();
        setState(() {
          _currentProfileImageUrl = _pendingProfileImageUrl;
          _pendingProfileImageUrl = null;
          _isUploading = false;
        });
        NotificationHelper.showSuccess(context, 'บันทึกรูปโปรไฟล์เรียบร้อย');
      } else {
        setState(() => _isUploading = false);
        NotificationHelper.showError(context, 'ไม่สามารถบันทึกรูปโปรไฟล์ได้');
      }
    } catch (e) {
      setState(() => _isUploading = false);
      NotificationHelper.showError(context, 'เกิดข้อผิดพลาด: $e');
    }
  }

  Future<void> _clearProfileImage() async {
    setState(() => _isUploading = true);
    try {
      final success = await SupabaseService.updateRestaurantDetails(int.parse(widget.restaurantId), imageUrl: null, setImageToNull: true);
      if (success) {
        imageCache.clear();
        setState(() {
          _currentProfileImageUrl = null;
          _pendingProfileImageUrl = null;
          _isUploading = false;
        });
        NotificationHelper.showSuccess(context, 'ลบรูปโปรไฟล์เรียบร้อย');
      } else {
        setState(() => _isUploading = false);
        NotificationHelper.showError(context, 'ไม่สามารถลบรูปโปรไฟล์ได้');
      }
    } catch (e) {
      setState(() => _isUploading = false);
      NotificationHelper.showError(context, 'เกิดข้อผิดพลาด: $e');
    }
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return '0 นาที';
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    final parts = <String>[];
    if (days > 0) parts.add('${days}d');
    if (hours > 0) parts.add('${hours}ชั่วโมง');
    if (minutes > 0) parts.add('${minutes}นาที');
    return parts.isEmpty ? '0 นาที' : parts.join(' ');
  }

  // history UI removed; audit data remains in DB (`restaurant_open_history`)

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

            // ข้อมูลร้าน (แก้ไขชื่อ เบอร์ รูปโปรไฟล์)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ข้อมูลร้าน', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _currentProfileImageUrl != null
                              ? Image.network(
                                  _currentProfileImageUrl!,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.broken_image),
                                  ),
                                )
                              : Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.orange.withOpacity(0.1),
                                  child: const Icon(Icons.store, color: Colors.orange, size: 36),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _nameController,
                                decoration: const InputDecoration(labelText: 'ชื่อร้าน'),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _phoneController,
                                decoration: const InputDecoration(labelText: 'เบอร์โทรศัพท์'),
                                keyboardType: TextInputType.phone,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Image upload controls for profile image
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isUploading ? null : _pickAndUploadProfileImage,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('อัปโหลดรูปโปรไฟล์'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: _isUploading || (_currentProfileImageUrl == null && _pendingProfileImageUrl == null) ? null : _clearProfileImage,
                          icon: const Icon(Icons.delete),
                          label: const Text('ลบรูป'),
                        ),
                      ],
                    ),

                    if (_pendingProfileImageUrl != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(_pendingProfileImageUrl!, width: 80, height: 80, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _isUploading ? null : _confirmPendingProfileImage,
                            icon: const Icon(Icons.check),
                            label: const Text('ยืนยันรูป'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _isUploading
                                ? null
                                : () {
                                    setState(() => _pendingProfileImageUrl = null);
                                    NotificationHelper.showInfo(context, 'ยกเลิกการเปลี่ยนรูป (ไฟล์ยังคงอยู่ใน storage)');
                                  },
                            icon: const Icon(Icons.close),
                            label: const Text('ยกเลิก'),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            setState(() => _isLoadingOpen = true);
                            final name = _nameController.text.trim();
                            final phone = _phoneController.text.trim();
                            String? imageToSave;
                            if (_pendingProfileImageUrl != null) imageToSave = _pendingProfileImageUrl;

                            final success = await SupabaseService.updateRestaurantDetails(int.parse(widget.restaurantId), name: name.isEmpty ? null : name, phone: phone.isEmpty ? null : phone, imageUrl: imageToSave);
                            if (success) {
                              NotificationHelper.showSuccess(context, 'บันทึกข้อมูลร้านเรียบร้อย');
                              // reload
                              await _loadCurrentQrCode();
                            } else {
                              NotificationHelper.showError(context, 'ไม่สามารถบันทึกข้อมูลร้านได้');
                              setState(() => _isLoadingOpen = false);
                            }
                          },
                          child: const Text('บันทึกข้อมูลร้าน'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _nameController.text = widget.restaurantName;
                              _phoneController.text = '';
                              _pendingProfileImageUrl = null;
                            });
                          },
                          child: const Text('ยกเลิก'),
                        ),
                      ],
                    ),
                  ],
                ),
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
                  const SizedBox(height: 12),

                  // If there's a pending uploaded QR (not yet saved), show preview + confirm/ cancel
                  if (_pendingQrUrl != null)
                    Center(
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _pendingQrUrl!,
                              width: 160,
                              height: 160,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 160,
                                height: 160,
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image, size: 36),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _isUploading ? null : _confirmPendingQr,
                                icon: const Icon(Icons.check),
                                label: const Text('ยืนยัน'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: _isUploading
                                    ? null
                                    : () {
                                        // discard pending URL (object remains in storage)
                                        setState(() => _pendingQrUrl = null);
                                        NotificationHelper.showInfo(context, 'ยกเลิกการเปลี่ยน QR (ไฟล์จะถูกเก็บไว้ใน storage)');
                                      },
                                icon: const Icon(Icons.close),
                                label: const Text('ยกเลิก'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Manual mode control (separate card above status) — small button to enable/disable manual mode
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'กดการเปิด/ปิดร้านด้วยตนเอง (Manual Mode)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[800]),
                    ),
                  ),
                  SizedBox(
                    height: 36,
                    child: OutlinedButton(
                      onPressed: _isLoadingOpen
                          ? null
                          : () async {
                              if (!_manualModeEditing) {
                                setState(() {
                                  _isLoadingOpen = true;
                                  _openErrorMessage = null;
                                });

                                final success = await SupabaseService.updateRestaurantIsOpen(int.parse(widget.restaurantId), _isOpen, isManual: true);
                                if (success) {
                                  setState(() => _manualModeEditing = true);
                                  await _loadCurrentQrCode();
                                  NotificationHelper.showSuccess(context, 'เปิดโหมดตั้งสถานะด้วยตน');
                                } else {
                                  setState(() => _isLoadingOpen = false);
                                  NotificationHelper.showError(context, 'ไม่สามารถเปิดโหมดตั้งสถานะด้วยตนเองได้');
                                }
                              } else {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('ยืนยัน'),
                                    content: const Text('ต้องการยกเลิกการตั้งค่าสถานะแบบ manual และคืนค่าให้ใช้เวลาทำการตามระบบหรือไม่?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('ยกเลิก')),
                                      ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('ยืนยัน')),
                                    ],
                                  ),
                                );
                                if (confirm != true) return;

                                setState(() {
                                  _isLoadingOpen = true;
                                  _openErrorMessage = null;
                                });

                                bool isOpenToSet = _isOpen;
                                try {
                                  if (_openingHour != null && _closingHour != null) {
                                    final nowHour = DateTime.now().hour;
                                    final opening = _openingHour!;
                                    final closing = _closingHour!;
                                    bool isOpenBySchedule;
                                    if (opening <= closing) {
                                      isOpenBySchedule = nowHour >= opening && nowHour <= closing;
                                    } else {
                                      isOpenBySchedule = nowHour >= opening || nowHour <= closing;
                                    }
                                    isOpenToSet = isOpenBySchedule;
                                  }
                                } catch (_) {}

                                final success = await SupabaseService.updateRestaurantIsOpen(int.parse(widget.restaurantId), isOpenToSet, isManual: false);
                                if (success) {
                                  setState(() => _manualModeEditing = false);
                                  await _loadCurrentQrCode();
                                  NotificationHelper.showSuccess(context, 'ยกเลิกการตั้งค่าแบบ manual เรียบร้อย');
                                } else {
                                  setState(() {
                                    _isLoadingOpen = false;
                                    _openErrorMessage = 'ไม่สามารถยกเลิกการตั้งค่า manual ได้';
                                  });
                                  NotificationHelper.showError(context, 'ไม่สามารถยกเลิกการตั้งค่า manual ได้');
                                }
                              }
                            },
                      child: Text(_manualModeEditing ? 'ยกเลิก' : 'ตั้งค่า'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _manualModeEditing ? Colors.redAccent : Colors.orange.shade700,
                        side: BorderSide(color: _manualModeEditing ? Colors.redAccent : Colors.orange.shade700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Manual Open/Close toggle (manual override) with expiry picker + history
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      _isOpen ? Icons.storefront : Icons.store_mall_directory,
                      color: _isOpen ? Colors.green : Colors.grey,
                    ),
                    title: const Text('สถานะร้าน'),
                    subtitle: _isLoadingOpen
                        ? const Text('กำลังโหลดสถานะ...')
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_isOpen ? 'ร้านเปิด' : 'ร้านปิด',style: TextStyle(fontSize: 12, color: Colors.blue)),
                              const SizedBox(height: 6),
                              const Text('หมายเหตุ: การตั้งค่านี้จะคงอยู่จนกว่าจะยกเลิกโดยเจ้าของร้าน', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text('แหล่งสถานะ: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  const SizedBox(width: 6),
                                  Chip(
                                    label: Text(_isOpenSource, style: const TextStyle(fontSize: 12, color: Colors.white)),
                                    backgroundColor: _isOpenSource == 'manual' ? Colors.orange.shade700 : Colors.blue.shade600,
                                  ),
                                ],
                              ),
                              if (_openErrorMessage != null) ...[
                                const SizedBox(height: 8),
                                Text(_openErrorMessage!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                              ],
                            ],
                          ),
                    trailing: _manualModeEditing
                        ? Switch(
                            value: _isOpen,
                            onChanged: _isLoadingOpen
                                ? null
                                : (val) async {
                                    setState(() {
                                      _isLoadingOpen = true;
                                      _openErrorMessage = null;
                                    });
                                    final success = await SupabaseService.updateRestaurantIsOpen(int.parse(widget.restaurantId), val, isManual: true);
                                    if (success) {
                                      // reload state
                                      await _loadCurrentQrCode();
                                      setState(() {
                                        _openErrorMessage = null;
                                      });
                                      NotificationHelper.showSuccess(context, val ? 'ตั้งค่าสถานะเป็น เปิด แล้ว' : 'ตั้งค่าสถานะเป็น ปิด แล้ว');
                                    } else {
                                      setState(() {
                                        _isLoadingOpen = false;
                                        _openErrorMessage = 'ไม่สามารถเปลี่ยนสถานะร้านได้';
                                      });
                                      NotificationHelper.showError(context, 'ไม่สามารถเปลี่ยนสถานะร้านได้');
                                    }
                                  },
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),

          // Small control button: enable manual mode (shows toggle) / disable manual mode (clears manual override)
         /* Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                const Spacer(),
                SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: _isLoadingOpen
                        ? null
                        : () async {
                            // If not currently editing, enable manual mode and show toggle
                            if (!_manualModeEditing) {
                              setState(() {
                                _isLoadingOpen = true;
                                _openErrorMessage = null;
                              });

                              // Activate manual mode without changing open state (preserve current effective value)
                              final success = await SupabaseService.updateRestaurantIsOpen(int.parse(widget.restaurantId), _isOpen, isManual: true);
                              if (success) {
                                setState(() => _manualModeEditing = true);
                                await _loadCurrentQrCode();
                                NotificationHelper.showSuccess(context, 'เปิดโหมดตั้งสถานะด้วยตน');
                              } else {
                                setState(() => _isLoadingOpen = false);
                                NotificationHelper.showError(context, 'ไม่สามารถเปิดโหมดตั้งสถานะด้วยตนเองได้');
                              }
                            } else {
                              // Confirm before disabling manual mode
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: const Text('ยืนยัน'),
                                  content: const Text('ต้องการยกเลิกการตั้งค่าสถานะแบบ manual และคืนค่าให้ใช้เวลาทำการตามระบบหรือไม่?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('ยกเลิก')),
                                    ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('ยืนยัน')),
                                  ],
                                ),
                              );
                              if (confirm != true) return;

                              setState(() {
                                _isLoadingOpen = true;
                                _openErrorMessage = null;
                              });

                              // Compute schedule-derived isOpen if opening/closing hours are available
                              bool isOpenToSet = _isOpen; // fallback: keep current effective value
                              try {
                                if (_openingHour != null && _closingHour != null) {
                                  final nowHour = DateTime.now().hour;
                                  final opening = _openingHour!;
                                  final closing = _closingHour!;
                                  bool isOpenBySchedule;
                                  if (opening <= closing) {
                                    isOpenBySchedule = nowHour >= opening && nowHour <= closing;
                                  } else {
                                    isOpenBySchedule = nowHour >= opening || nowHour <= closing;
                                  }
                                  isOpenToSet = isOpenBySchedule;
                                }
                              } catch (_) {}

                              final success = await SupabaseService.updateRestaurantIsOpen(int.parse(widget.restaurantId), isOpenToSet, isManual: false);
                              if (success) {
                                setState(() => _manualModeEditing = false);
                                await _loadCurrentQrCode();
                                NotificationHelper.showSuccess(context, 'ยกเลิกการตั้งค่าแบบ manual เรียบร้อย');
                              } else {
                                setState(() {
                                  _isLoadingOpen = false;
                                  _openErrorMessage = 'ไม่สามารถยกเลิกการตั้งค่า manual ได้';
                                });
                                NotificationHelper.showError(context, 'ไม่สามารถยกเลิกการตั้งค่า manual ได้');
                              }
                            }
                          },
                    child: Text(_manualModeEditing ? 'ยกเลิกการต้ังค่าสถานะร้านเอง' : 'ตั้งสถานะร้านด้วยตนเอง'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _manualModeEditing ? Colors.black : Colors.orange.shade700,
                      side: BorderSide(color: _manualModeEditing ? Colors.black : Colors.orange.shade700),
                    ),
                  ),
                ),
              ],
            ),
          ),*/

          const SizedBox(height: 16),

          // Opening hours settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('เวลาทำการ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('ตั้งค่าเวลาที่เปิดและปิดร้าน (ชั่วโมงแบบ 24 ชั่วโมง) โดยค่าจะบันทึกลงในฐานข้อมูล'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButton<int>(
                          value: _openingHour,
                          hint: const Text('เวลาเปิด'),
                          isExpanded: true,
                          items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Text("${i.toString().padLeft(2, '0')}:00"))),
                          onChanged: (v) => setState(() => _openingHour = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButton<int>(
                          value: _closingHour,
                          hint: const Text('เวลาปิด'),
                          isExpanded: true,
                          items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Text("${i.toString().padLeft(2, '0')}:00"))),
                          onChanged: (v) => setState(() => _closingHour = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          setState(() => _isLoadingOpen = true);
                          final success = await SupabaseService.updateRestaurantHours(int.parse(widget.restaurantId), _openingHour, _closingHour);
                          if (success) {
                            NotificationHelper.showSuccess(context, 'บันทึกเวลาทำการเรียบร้อย');
                            await _loadCurrentQrCode();
                          } else {
                            NotificationHelper.showError(context, 'ไม่สามารถบันทึกเวลาทำการได้');
                            setState(() => _isLoadingOpen = false);
                          }
                        },
                        child: const Text('บันทึก'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _openingHour = null;
                            _closingHour = null;
                          });
                        },
                        child: const Text('รีเซ็ต'),
                      ),
                    ],
                  ),
                ],
              ),
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
