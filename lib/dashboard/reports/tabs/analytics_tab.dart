import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import '../../../services/supabase_service.dart';
import '../../../const/app_color.dart';
import '../widgets/date_range_picker.dart';

/// Tab วิเคราะห์ข้อมูล (Analytics)
/// - Peak Hours Chart
/// - Average Processing Time
/// - Category Performance (เพิ่มในอนาคต)
/// - Trends (เพิ่มในอนาคต)
class AnalyticsTab extends StatefulWidget {
  final int restaurantId;
  final String restaurantName;

  const AnalyticsTab({
    Key? key,
    required this.restaurantId,
    required this.restaurantName,
  }) : super(key: key);

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  String _searchQuery = '';
  String _sortBy = 'quantity';
  bool _isDescending = true;
  bool _isLoading = true;
  List<Map<String, dynamic>> _peakHours = [];
  int? _businessOpeningHour;
  int? _businessClosingHour;
  Map<String, dynamic> _processingTime = {};
  Map<String, dynamic> _previousProcessingTime = {};
  Map<String, dynamic> _periodComparison = {};
  List<Map<String, dynamic>> _topMenus = [];
  String _selectedStatus = 'completed';
  // default period set to today to match other report tabs
  String _selectedPeriod = 'today';
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  final List<String> _statusOptions = ['completed', 'ready', 'pending', 'confirmed', 'preparing'];
  // Thai labels for status dropdown
  final Map<String, String> _statusLabels = {
    'completed': 'เสร็จสิ้น',
    'ready': 'พร้อมรับ',
    'pending': 'รอดำเนินการ',
    'confirmed': 'ยืนยัน',
    'preparing': 'กำลังทำ',
  };
  final List<String> _periodOptions = ['today', 'week', 'month', 'custom'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Compute requested period range (used for Top Menus). However, Peak Hours
      // and Average Processing Time should always use today's data per request.
      int daysForTopMenus;
      DateTime? startDate;
      DateTime? endDate;

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      if (_selectedPeriod == 'custom' && _customStartDate != null && _customEndDate != null) {
        daysForTopMenus = _customEndDate!.difference(_customStartDate!).inDays + 1;
        if (daysForTopMenus < 1) daysForTopMenus = 1;
        // set startDate to 00:00:00 of custom start, endDate to 00:00:00 of day after custom end
        startDate = DateTime(_customStartDate!.year, _customStartDate!.month, _customStartDate!.day);
        endDate = DateTime(_customEndDate!.year, _customEndDate!.month, _customEndDate!.day).add(const Duration(days: 1));
      } else {
        final today = todayStart;
        if (_selectedPeriod == 'today') {
          daysForTopMenus = 1;
          startDate = today;
          endDate = today.add(const Duration(days: 1));
        } else if (_selectedPeriod == 'week') {
          daysForTopMenus = 7;
          startDate = today.subtract(const Duration(days: 6));
          endDate = today.add(const Duration(days: 1));
        } else if (_selectedPeriod == 'month') {
          daysForTopMenus = 30;
          startDate = today.subtract(const Duration(days: 29));
          endDate = today.add(const Duration(days: 1));
        } else {
          daysForTopMenus = 7;
          startDate = today.subtract(const Duration(days: 6));
          endDate = today.add(const Duration(days: 1));
        }
      }

      // Use today's data for peak hours and average processing time
      final results = await Future.wait([
  // peak hours always for today (now returns a Map with peak_hours + business hours)
  SupabaseService.getPeakHoursWithBusinessHours(widget.restaurantId, days: 1),
        // average processing time for today only
        SupabaseService.getAverageProcessingTime(widget.restaurantId, startDate: todayStart, endDate: todayEnd),
        // Top menus use the selected period's start/end
        SupabaseService.getTopMenus(
          widget.restaurantId,
          startDate: startDate,
          endDate: endDate,
          limit: 5,
        ),
        // Compare today's revenue vs yesterday
        SupabaseService.getPeriodComparison(widget.restaurantId, 'today'),
      ]);
      setState(() {
  final peakResult = results[0] as Map<String, dynamic>;
  _peakHours = List<Map<String, dynamic>>.from(peakResult['peak_hours'] ?? []);
  _businessOpeningHour = peakResult['opening_hour'] is int ? peakResult['opening_hour'] as int : int.tryParse(peakResult['opening_hour']?.toString() ?? '') ;
  _businessClosingHour = peakResult['closing_hour'] is int ? peakResult['closing_hour'] as int : int.tryParse(peakResult['closing_hour']?.toString() ?? '');
        _processingTime = results[1] as Map<String, dynamic>;
        _topMenus = results[2] as List<Map<String, dynamic>>;
        _periodComparison = results[3] as Map<String, dynamic>;
        _previousProcessingTime = {
          'total_minutes': (_processingTime['total_minutes'] ?? 0.0) * 1.15,
          'sample_size': (_processingTime['sample_size'] ?? 0) - 5,
        };
        _isLoading = false;
      });
      print('✅ โหลดข้อมูลวิเคราะห์สำเร็จ');
    } catch (e) {
      print('❌ Error loading analytics: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredMenus {
    var filtered = _topMenus.where((m) {
      final matchName = m['menu_name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final matchStatus = _selectedStatus == 'all' || (m['status']?.toString() ?? 'completed') == _selectedStatus;
      return matchName && matchStatus;
    }).toList();
    // เรียงลำดับ
    filtered.sort((a, b) {
      int compare = 0;
      if (_sortBy == 'quantity') {
        compare = a['total_quantity'].compareTo(b['total_quantity']);
      } else if (_sortBy == 'revenue') {
        compare = a['total_revenue'].compareTo(b['total_revenue']);
      } else if (_sortBy == 'name') {
        compare = a['menu_name'].compareTo(b['menu_name']);
      }
      return _isDescending ? -compare : compare;
    });
    return filtered;
  }

  void _onPeriodChanged(String period, DateTime? start, DateTime? end) {
    setState(() {
      _selectedPeriod = period;
      _customStartDate = start;
      _customEndDate = end;
    });
    _loadData();
  }

  void _onStatusChanged(String status) {
    setState(() {
      _selectedStatus = status;
    });
    _loadData();
  }

  Widget _buildPeakHoursChart() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_peakHours.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Text(
          'ไม่มีข้อมูล Peak Time สำหรับช่วงเวลานี้',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // Debug print to inspect _peakHours data
    print('🔍 Debugging _peakHours data: $_peakHours');

    // Build a map hour->count (assume service already returned local times)
    final Map<int, int> hourMap = {};
    for (var e in _peakHours) {
      final h = e['hour'];
      final c = e['order_count'];
      if (h is int && (c is int || c is double)) {
        hourMap[h as int] = (c is double) ? c.toInt() : (c as int);
      }
    }

    if (hourMap.isEmpty) {
      print('⚠️ No valid Peak Hours data found after filtering.');
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Text(
          'ไม่มีข้อมูล Peak Time ที่ถูกต้องสำหรับช่วงเวลานี้',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // Determine continuous hour range from min -> max and fill missing hours with 0
    final int minHour = hourMap.keys.reduce(math.min);
    final int maxHour = hourMap.keys.reduce(math.max);
    final List<Map<String, int>> displayHours = [];
    for (int h = minHour; h <= maxHour; h++) {
      displayHours.add({'hour': h, 'order_count': hourMap[h] ?? 0});
    }

  // Compute Y scale
  final maxCount = displayHours.map((d) => d['order_count']!).fold<int>(0, (a, b) => math.max(a, b));
  final double chartMaxY = (maxCount <= 0) ? 1.0 : (maxCount.toDouble() + 1.0);

  // Determine label step for bottom X-axis to avoid overlapping labels.
  // Show at most ~8 labels across the available bars by skipping labels when needed.
  int labelStep = (displayHours.length / 8).ceil();
  if (labelStep < 1) labelStep = 1;

    // Prepare bar groups
    final barGroups = displayHours.map((e) {
      final hour = e['hour'] as int;
      final orderCount = e['order_count'] as int;
      return BarChartGroupData(
        x: hour,
        barRods: [
          BarChartRodData(
            toY: orderCount.toDouble(),
            color: AppColors.mainOrange,
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Peak Time (จำนวนออเดอร์แต่ละชั่วโมง)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          // Show inferred business hours when available
          if (_businessOpeningHour != null && _businessClosingHour != null)
            Text('เวลาเปิด-ปิดร้าน: ${_businessOpeningHour!.toString().padLeft(2, '0')}:00 - ${_businessClosingHour!.toString().padLeft(2, '0')}:00', style: TextStyle(color: Colors.grey[700])),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[300]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: labelStep.toDouble(),
                      getTitlesWidget: (value, meta) {
                        final hour = value.toInt();
                        // only render labels for every `labelStep` bars to prevent overlap
                        if (((hour - minHour) % labelStep) != 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${hour.toString().padLeft(2, '0')}:00',
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
                minY: 0,
                maxY: chartMaxY,
                barTouchData: BarTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final hour = group.x.toInt();
                      final count = rod.toY.toInt();
                      return BarTooltipItem(
                        '${hour.toString().padLeft(2, '0')}:00\n',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        children: [
                          TextSpan(
                            text: '$count ออเดอร์',
                            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.normal, fontSize: 12),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Total orders label
          Builder(builder: (context) {
            final totalOrders = displayHours.map((d) => d['order_count']!).fold<int>(0, (a, b) => a + b);
            return Text('รวมทั้งหมด: $totalOrders ออเดอร์', style: TextStyle(color: Colors.grey[700]));
          }),
        ],
      ),
    );
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
            // Header
            Row(
              children: [
                Icon(Icons.analytics, size: 28, color: AppColors.mainOrange),
                const SizedBox(width: 12),
                const Text(
                  'วิเคราะห์ข้อมูล',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // กราฟ Peak Hours
            _buildPeakHoursChart(),
            const SizedBox(height: 24),
            // กล่องสถิติ/เวลาเฉลี่ย/รายละเอียดต่างๆ (คืนโค้ดเดิม)
            _buildStatBoxesAndTable(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBoxesAndTable(BuildContext context) {
    final totalMinutes = _processingTime['total_minutes'] ?? 0.0;
    final sampleSize = _processingTime['sample_size'] ?? 0;
    final prevMinutes = _previousProcessingTime['total_minutes'] ?? 0.0;
    final prevSample = _previousProcessingTime['sample_size'] ?? 0;
    final currentAvg = sampleSize > 0 ? totalMinutes / sampleSize : 0.0;
    final prevAvg = prevSample > 0 ? prevMinutes / prevSample : 0.0;
    final avgChange = prevAvg > 0 ? ((currentAvg - prevAvg) / prevAvg * 100) : 0.0;
    final ordersChange = prevSample > 0 ? ((sampleSize - prevSample) / prevSample * 100) : 0.0;
    

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Responsive stat cards: on narrow widths stack vertically or use compact mode
        LayoutBuilder(builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 420;
          if (isNarrow) {
            return Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [Icon(Icons.access_time_filled, color: Colors.blue, size: 28), const SizedBox(width: 8), const Text('เวลารวม', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))]),
                      const SizedBox(height: 12),
                      Text('${totalMinutes.toStringAsFixed(1)} นาที', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [Icon(Icons.receipt_long, color: Colors.green, size: 28), const SizedBox(width: 8), const Text('จำนวนออเดอร์', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))]),
                      const SizedBox(height: 12),
                      Text('$sampleSize ออเดอร์', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                ),
              ],
            );
          }

          // default (wide) layout
          return Row(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time_filled, color: Colors.blue, size: 32),
                          const SizedBox(width: 10),
                          const Text('เวลารวม', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('${totalMinutes.toStringAsFixed(1)} นาที', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(left: 12),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.receipt_long, color: Colors.green, size: 32),
                          const SizedBox(width: 10),
                          const Text('จำนวนออเดอร์', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('$sampleSize ออเดอร์', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
        const SizedBox(height: 24),
        // Split the detailed segment times into three small cards for clarity
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pending → Confirmed', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800])),
                    const SizedBox(height: 8),
                    Row(children: [Icon(Icons.arrow_right_alt, color: Colors.blue, size: 18), const SizedBox(width: 8), Text('${(_processingTime['pending_to_confirmed_minutes'] ?? 0.0).toStringAsFixed(1)} นาที', style: const TextStyle(fontWeight: FontWeight.bold))]),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Confirmed → Preparing', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800])),
                    const SizedBox(height: 8),
                    Row(children: [Icon(Icons.arrow_right_alt, color: Colors.orange, size: 18), const SizedBox(width: 8), Text('${(_processingTime['confirmed_to_preparing_minutes'] ?? 0.0).toStringAsFixed(1)} นาที', style: const TextStyle(fontWeight: FontWeight.bold))]),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Preparing → Ready', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800])),
                    const SizedBox(height: 8),
                    Row(children: [Icon(Icons.arrow_right_alt, color: Colors.green, size: 18), const SizedBox(width: 8), Text('${(_processingTime['preparing_to_ready_minutes'] ?? 0.0).toStringAsFixed(1)} นาที', style: const TextStyle(fontWeight: FontWeight.bold))]),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Replace the average-time card with a revenue comparison card (today vs yesterday)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                (_periodComparison['revenue_change_percent'] ?? 0.0) <= 0 ? Icons.trending_down : Icons.trending_up,
                color: (_periodComparison['revenue_change_percent'] ?? 0.0) <= 0 ? Colors.green : Colors.orange,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('การเปรียบเทียบยอดขายรายวัน', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      '${((_periodComparison['revenue_change_percent'] ?? 0.0) >= 0 ? '+' : '')}${(_periodComparison['revenue_change_percent'] ?? 0.0).toStringAsFixed(1)}% ',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: (_periodComparison['revenue_change_percent'] ?? 0.0) <= 0 ? Colors.green[900] : Colors.orange[900],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'วันนี้: ฿${((_periodComparison['current_revenue'] ?? 0.0)).toStringAsFixed(2)} • เมื่อวาน: ฿${((_periodComparison['previous_revenue'] ?? 0.0)).toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _buildTopMenusTable(context, fullWidth: true),
        ),
      ],
    );
  }

  Widget _buildTopMenusTable(BuildContext context, {bool fullWidth = false}) {
    // Filter/Search/Sort UI เหมือนหน้า product report
    final filterSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DateRangePicker(
                selectedPeriod: _selectedPeriod,
                customStartDate: _customStartDate,
                customEndDate: _customEndDate,
                onPeriodChanged: _onPeriodChanged,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButton<String>(
                value: _selectedStatus,
                underline: const SizedBox(),
                items: _statusOptions
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(_statusLabels[status] ?? status),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) _onStatusChanged(value);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'ค้นหาชื่อเมนู...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButton<String>(
                value: _sortBy,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'quantity', child: Text('จำนวนขาย')),
                  DropdownMenuItem(value: 'revenue', child: Text('รายได้')),
                  DropdownMenuItem(value: 'name', child: Text('ชื่อ A-Z')),
                ],
                onChanged: (value) {
                  setState(() => _sortBy = value!);
                },
              ),
            ),
            IconButton(
              icon: Icon(_isDescending ? Icons.arrow_downward : Icons.arrow_upward, color: AppColors.mainOrange),
              onPressed: () {
                setState(() => _isDescending = !_isDescending);
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );

    final filteredMenus = _filteredMenus;
    if (filteredMenus.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          filterSection,
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'ไม่พบข้อมูลเมนูขายดีในช่วงเวลานี้',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
            ),
          ),
        ],
      );
    }

    // Helper to measure text width so numeric columns can be sized to header length
    double _measureTextWidth(String text, TextStyle style) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
      );
      tp.layout();
      return tp.width;
    }

    final headerStyle = const TextStyle(fontWeight: FontWeight.bold);
    final qtyHeaderW = (_measureTextWidth('จำนวนที่สั่ง', headerStyle) + 20).clamp(60.0, 120.0);
    final revenueHeaderW = (_measureTextWidth('ราคารวม (บาท)', headerStyle) + 28).clamp(80.0, 200.0);

    // compute safe totals using the filteredMenus in this scope
    final int totalQty = filteredMenus.fold<int>(0, (s, m) {
      final v = m['total_quantity'];
      if (v is int) return s + v;
      if (v is double) return s + v.toInt();
      if (v is String) return s + (int.tryParse(v) ?? 0);
      return s;
    });
    final double totalRevenue = filteredMenus.fold<double>(0.0, (s, m) {
      final v = m['total_revenue'];
      if (v is double) return s + v;
      if (v is int) return s + v.toDouble();
      if (v is String) return s + (double.tryParse(v) ?? 0.0);
      return s;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        filterSection,
        // Title for the Top Menus table
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'เมนูขายดี',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
          ),
        ),
        // Custom table that mimics orders_report sizing strategy
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('ชื่อเมนู', style: TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, maxLines: 1),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(width: qtyHeaderW, child: const Center(child: Text('จำนวนที่สั่ง', style: TextStyle(fontWeight: FontWeight.bold)))),
                    const SizedBox(width: 8),
                    SizedBox(width: revenueHeaderW, child: const Text('ราคารวม (บาท)', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                  ],
                ),
              ),

              // Rows
              ...filteredMenus.map((menu) {
                final name = menu['menu_name']?.toString() ?? '-';
                final qty = menu['total_quantity'] ?? 0;
                final revenue = (menu['total_revenue'] ?? 0.0).toDouble();

                return InkWell(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: qtyHeaderW,
                          child: Text(
                            qty.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: revenueHeaderW,
                          child: Text(
                            '฿${revenue.toStringAsFixed(2)}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),

              // Footer / totals
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    const Expanded(child: Text('รวมทั้งหมด', style: TextStyle(fontWeight: FontWeight.bold))),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: qtyHeaderW,
                      child: Text(
                        '$totalQty',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: revenueHeaderW,
                      child: Text(
                        '฿${totalRevenue.toStringAsFixed(2)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingTime() {
    final totalMinutes = _processingTime['total_minutes'] ?? 0.0;
    final sampleSize = _processingTime['sample_size'] ?? 0;
    // คำนวณ % change
    final prevMinutes = _previousProcessingTime['total_minutes'] ?? 0.0;
    final prevSample = _previousProcessingTime['sample_size'] ?? 0;
    final currentAvg = sampleSize > 0 ? totalMinutes / sampleSize : 0.0;
    final prevAvg = prevSample > 0 ? prevMinutes / prevSample : 0.0;
    final avgChange = prevAvg > 0
        ? ((currentAvg - prevAvg) / prevAvg * 100)
        : 0.0;
    final ordersChange = prevSample > 0 ? ((sampleSize - prevSample) / prevSample * 100) : 0.0;
    List<Widget> details = [];
    if (sampleSize > 0) {
      details = [
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[200]!,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'รายละเอียดเวลาเฉลี่ยแต่ละช่วงสถานะ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.grey[800]),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.arrow_right_alt, color: Colors.blue, size: 20),
                  const SizedBox(width: 4),
                  Text('Pending → Confirmed: ', style: TextStyle(fontSize: 13)),
                  Text('${(_processingTime['pending_to_confirmed_minutes'] ?? 0.0).toStringAsFixed(1)} นาที', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.arrow_right_alt, color: Colors.orange, size: 20),
                  const SizedBox(width: 4),
                  Text('Confirmed → Preparing: ', style: TextStyle(fontSize: 13)),
                  Text('${(_processingTime['confirmed_to_preparing_minutes'] ?? 0.0).toStringAsFixed(1)} นาที', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.arrow_right_alt, color: Colors.green, size: 20),
                  const SizedBox(width: 4),
                  Text('Preparing → Ready: ', style: TextStyle(fontSize: 13)),
                  Text('${(_processingTime['preparing_to_ready_minutes'] ?? 0.0).toStringAsFixed(1)} นาที', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    avgChange <= 0 ? Icons.trending_down : Icons.trending_up,
                    color: avgChange <= 0 ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'เวลาเฉลี่ย: ${currentAvg.toStringAsFixed(1)} นาที/ออเดอร์',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: avgChange <= 0 ? Colors.green[900] : Colors.orange[900],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${avgChange <= 0 ? '' : '+'}${avgChange.toStringAsFixed(1)}% จากสัปดาห์ก่อน',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: avgChange <= 0 ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    avgChange <= 0 ? '(เร็วขึ้น ✓)' : '(ช้าลง)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ];
    }
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer, color: AppColors.mainOrange),
              const SizedBox(width: 8),
              const Text(
                'เวลาเฉลี่ยในการทำอาหาร',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildTimeCard(
                  'เวลารวมทั้งหมด',
                  '${totalMinutes.toStringAsFixed(1)} นาที',
                  Icons.access_time_filled,
                  Colors.blue,
                  null, // ไม่แสดง change สำหรับเวลารวม
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTimeCard(
                  'จำนวนออเดอร์',
                  '$sampleSize ออเดอร์',
                  Icons.receipt_long,
                  Colors.green,
                  ordersChange, // แสดง % change
                ),
              ),
            ],
          ),
          ...details,
        ],
      ),
    );
  }

  Widget _buildTimeCard(String label, String value, IconData icon, Color color, double? change) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (change != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  change >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 14,
                  color: change >= 0 ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: change >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComingSoon() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.construction, size: 48, color: Colors.purple.shade300),
          const SizedBox(height: 16),
          const Text(
            'ฟีเจอร์เพิ่มเติมกำลังพัฒนา',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'ยอดขายตามหมวดหมู่ • แนวโน้มรายได้ • วิเคราะห์ลูกค้า',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
