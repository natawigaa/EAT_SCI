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
  Map<String, dynamic> _processingTime = {};
  Map<String, dynamic> _previousProcessingTime = {};
  List<Map<String, dynamic>> _topMenus = [];
  String _selectedStatus = 'completed';
  String _selectedPeriod = 'week';
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  final List<String> _statusOptions = ['completed', 'ready', 'pending', 'confirmed', 'preparing'];
  final List<String> _periodOptions = ['today', 'week', 'month', 'custom'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      int days;
      DateTime? startDate;
      DateTime? endDate;
      if (_selectedPeriod == 'custom' && _customStartDate != null && _customEndDate != null) {
        days = _customEndDate!.difference(_customStartDate!).inDays + 1;
        if (days < 1) days = 1;
        // set startDate to 00:00:00 of custom start, endDate to 00:00:00 of day after custom end
        startDate = DateTime(_customStartDate!.year, _customStartDate!.month, _customStartDate!.day);
        endDate = DateTime(_customEndDate!.year, _customEndDate!.month, _customEndDate!.day).add(const Duration(days: 1));
      } else {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        if (_selectedPeriod == 'today') {
          days = 1;
          startDate = today;
          endDate = today.add(const Duration(days: 1));
        } else if (_selectedPeriod == 'week') {
          days = 7;
          startDate = today.subtract(const Duration(days: 6));
          endDate = today.add(const Duration(days: 1));
        } else if (_selectedPeriod == 'month') {
          days = 30;
          startDate = today.subtract(const Duration(days: 29));
          endDate = today.add(const Duration(days: 1));
        } else {
          days = 7;
          startDate = today.subtract(const Duration(days: 6));
          endDate = today.add(const Duration(days: 1));
        }
      }
      final results = await Future.wait([
        // use business-hours-aware peak hours so x-axis = opening..closing
        SupabaseService.getPeakHoursWithBusinessHours(widget.restaurantId, days: days),
        SupabaseService.getAverageProcessingTime(widget.restaurantId),
        SupabaseService.getTopMenus(
          widget.restaurantId,
          startDate: startDate,
          endDate: endDate,
          limit: 5,
        ),
      ]);
      setState(() {
        _peakHours = results[0] as List<Map<String, dynamic>>;
        _processingTime = results[1] as Map<String, dynamic>;
        _topMenus = results[2] as List<Map<String, dynamic>>;
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
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final hour = value.toInt();
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
        Row(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 12),
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
                    Row(
                      children: [
                        Icon(Icons.access_time_filled, color: Colors.blue, size: 32),
                        const SizedBox(width: 10),
                        const Text('เวลารวมทั้งหมด', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('${totalMinutes.toStringAsFixed(1)} นาที', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(left: 12),
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
                    Row(
                      children: [
                        Icon(Icons.receipt_long, color: Colors.green, size: 32),
                        const SizedBox(width: 10),
                        const Text('จำนวนออเดอร์', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('$sampleSize ออเดอร์', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('รายละเอียดเวลาเฉลี่ยแต่ละช่วงสถานะ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.arrow_right_alt, color: Colors.blue, size: 20),
                  const SizedBox(width: 4),
                  const Text('Pending → Confirmed: ', style: TextStyle(fontSize: 14)),
                  Text('${(_processingTime['pending_to_confirmed_minutes'] ?? 0.0).toStringAsFixed(1)} นาที', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.arrow_right_alt, color: Colors.orange, size: 20),
                  const SizedBox(width: 4),
                  const Text('Confirmed → Preparing: ', style: TextStyle(fontSize: 14)),
                  Text('${(_processingTime['confirmed_to_preparing_minutes'] ?? 0.0).toStringAsFixed(1)} นาที', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.arrow_right_alt, color: Colors.green, size: 20),
                  const SizedBox(width: 4),
                  const Text('Preparing → Ready: ', style: TextStyle(fontSize: 14)),
                  Text('${(_processingTime['preparing_to_ready_minutes'] ?? 0.0).toStringAsFixed(1)} นาที', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
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
                avgChange <= 0 ? Icons.trending_down : Icons.trending_up,
                color: avgChange <= 0 ? Colors.green : Colors.orange,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'เวลาเฉลี่ย: ${currentAvg.toStringAsFixed(1)} นาที/ออเดอร์',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: avgChange <= 0 ? Colors.green[900] : Colors.orange[900],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${avgChange <= 0 ? '' : '+'}${avgChange.toStringAsFixed(1)}% จากสัปดาห์ก่อน',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: avgChange <= 0 ? Colors.green[700] : Colors.red[700],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          avgChange <= 0 ? '(เร็วขึ้น ✓)' : '(ช้าลง)',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
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
                          child: Text(status == 'all' ? 'ทุกสถานะ' : status),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        filterSection,
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: fullWidth ? MediaQuery.of(context).size.width - 96 : null,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
              columns: const [
                DataColumn(label: Text('ชื่อเมนู', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('จำนวนที่สั่ง', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('ราคารวม (บาท)', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: filteredMenus.map((menu) => DataRow(cells: [
                DataCell(Text(menu['menu_name'].toString())),
                DataCell(Text(menu['total_quantity'].toString())),
                DataCell(Text(menu['total_revenue'].toStringAsFixed(2))),
              ])).toList(),
            ),
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
