import 'package:flutter/material.dart';
import '../../../services/supabase_service.dart';
import '../../../const/app_color.dart';
import '../widgets/date_range_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as excel_lib hide Border;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Tab แสดงรายงานยอดขาย
/// - Cards สรุปยอดขาย
/// - กราฟยอดขาย 7 วัน
/// - เปรียบเทียบช่วงก่อนหน้า
/// - Export Excel (รองรับภาษาไทย)
class SalesReportTab extends StatefulWidget {
  final int restaurantId;
  final String restaurantName;

  const SalesReportTab({
    Key? key,
    required this.restaurantId,
    required this.restaurantName,
  }) : super(key: key);

  @override
  State<SalesReportTab> createState() => _SalesReportTabState();
}

class _SalesReportTabState extends State<SalesReportTab> {
  bool _isLoading = true;
  String _selectedPeriod = 'today'; // 'today', 'week', 'month', 'custom'
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  
  Map<String, dynamic> _periodSummary = {};
  Map<String, dynamic> _comparison = {};
  List<Map<String, dynamic>> _weeklySales = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      late List<dynamic> results;
      
      if (_selectedPeriod == 'custom' && _customStartDate != null && _customEndDate != null) {
        // ใช้ช่วงวันที่ที่กำหนดเอง
        results = await Future.wait([
          SupabaseService.getWeeklySales(widget.restaurantId),
          SupabaseService.getSalesByCustomDateRange(
            widget.restaurantId,
            _customStartDate!,
            _customEndDate!,
          ),
          // สำหรับ custom range จะไม่มีการเปรียบเทียบ
          Future.value({}),
        ]);
      } else {
        // ใช้ช่วงเวลาที่กำหนดไว้ (today/week/month)
        results = await Future.wait([
          SupabaseService.getWeeklySales(widget.restaurantId),
          SupabaseService.getSalesByPeriod(widget.restaurantId, _selectedPeriod),
          SupabaseService.getPeriodComparison(widget.restaurantId, _selectedPeriod),
        ]);
      }
      
      setState(() {
        _weeklySales = results[0] as List<Map<String, dynamic>>;
        _periodSummary = results[1] as Map<String, dynamic>;
        _comparison = results[2] as Map<String, dynamic>;
        _isLoading = false;
      });
      
      print('✅ โหลดข้อมูลยอดขาย: $_periodSummary');
    } catch (e) {
      print('❌ Error loading sales data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _onPeriodChanged(String period, DateTime? start, DateTime? end) {
    setState(() {
      _selectedPeriod = period;
      _customStartDate = start;
      _customEndDate = end;
    });
    _loadData();
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
            // Header with Action Buttons (responsive)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.attach_money, size: 28, color: AppColors.mainOrange),
                    const SizedBox(width: 12),
                    const Text(
                      'รายงานยอดขาย',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 8),
                // Buttons placed on their own row so they can wrap on small widths
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _showSalesSummary,
                      icon: const Icon(Icons.summarize, size: 18),
                      label: const Text('สรุปยอดขาย'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mainOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _exportExcel,
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Export Excel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.mainOrange,
                        side: BorderSide(color: AppColors.mainOrange),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Date Range Picker
            DateRangePicker(
              selectedPeriod: _selectedPeriod,
              customStartDate: _customStartDate,
              customEndDate: _customEndDate,
              onPeriodChanged: _onPeriodChanged,
            ),
            
            const SizedBox(height: 24),
            
            // Loading หรือ Summary Cards
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              _buildSummaryCards(),
              
              const SizedBox(height: 32),
              
              // Weekly Sales Chart
              _buildWeeklySalesChart(),
            ],
          ],
        ),
      ),
    );
  }

  /// Summary Cards (4 การ์ด)
  Widget _buildSummaryCards() {
    final revenue = _periodSummary['total_revenue'] ?? 0.0;
    final orders = _periodSummary['total_orders'] ?? 0;
    final avgValue = _periodSummary['average_order_value'] ?? 0.0;
    
    // ข้อมูลเปรียบเทียบ (เปรียบเทียบกับช่วงเวลาก่อนหน้า)
    final revenueChange = _comparison['revenue_change'] ?? 0.0;
    final ordersChange = _comparison['orders_change'] ?? 0.0;
    final avgChange = _comparison['average_change'] ?? 0.0;
    final completedChange = _comparison['completed_change'] ?? 0.0;
    
    // Use LayoutBuilder to choose number of columns based on available width.
    // On small screens show 2 columns (2x2 grid), on wide screens show 4 columns.
    return LayoutBuilder(builder: (context, constraints) {
  final isNarrow = constraints.maxWidth < 700; // tweak breakpoint as needed
  final crossAxis = isNarrow ? 2 : 4;
  // Reduce childAspectRatio to make cards slightly taller to avoid bottom overflow
  final childAspect = isNarrow ? 1.0 : 1.2;

      return GridView.count(
        crossAxisCount: crossAxis,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: childAspect,
        children: [
          _buildSummaryCard(
            title: 'ยอดขายรวม',
            value: '฿${revenue.toStringAsFixed(0)}',
            icon: Icons.attach_money,
            color: Colors.green,
            change: revenueChange,
          ),
          _buildSummaryCard(
            title: 'จำนวนออเดอร์',
            value: '$orders',
            icon: Icons.receipt_long,
            color: Colors.blue,
            change: ordersChange,
          ),
          _buildSummaryCard(
            title: 'ค่าเฉลี่ย/ออเดอร์',
            value: '฿${avgValue.toStringAsFixed(0)}',
            icon: Icons.trending_up,
            color: Colors.orange,
            change: avgChange != 0.0 ? avgChange : null, // แสดง change ถ้ามีข้อมูล
          ),
          _buildSummaryCard(
            title: 'ออเดอร์สำเร็จ',
            value: '${_periodSummary['completed_orders'] ?? 0}',
            icon: Icons.check_circle,
            color: Colors.purple,
            change: completedChange != 0.0 ? completedChange : null, // แสดง change ถ้ามีข้อมูล
          ),
        ],
      );
    });
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    double? change,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title + Icon
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          // Spacer เพื่อดันให้เนื้อหากลางอยู่ตรงกลาง
          const Spacer(),
          // Value - ตัวเลขหลัก (กลางการ์ด)
          Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: color,
                height: 1.1,
              ),
            ),
          ),
          // Spacer เพื่อดันให้เนื้อหากลางอยู่ตรงกลาง
          const Spacer(),
          // Change indicator (หรือพื้นที่ว่างเท่ากัน)
          SizedBox(
            height: 20, // กำหนดความสูงคงที่
            child: change != null
                ? Row(
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
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: change >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  )
                : const SizedBox(), // ช่องว่างเท่ากันแม้ไม่มี change
          ),
        ],
      ),
    );
  }

  /// กราฟยอดขาย 7 วัน
  Widget _buildWeeklySalesChart() {
    if (_weeklySales.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text('ไม่มีข้อมูลยอดขาย', style: TextStyle(color: Colors.grey[600])),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
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
              Icon(Icons.show_chart, color: AppColors.mainOrange),
              const SizedBox(width: 8),
              const Text(
                'ยอดขาย 7 วันล่าสุด',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 100,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[200]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '฿${value.toInt()}',
                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < _weeklySales.length) {
                          final dateStr = _weeklySales[index]['date'];
                          // แปลง String เป็น DateTime
                          final date = DateTime.parse(dateStr);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('d/M').format(date),
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _weeklySales.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        (entry.value['total_sales'] ?? 0).toDouble(),
                      );
                    }).toList(),
                    isCurved: true,
                    color: AppColors.mainOrange,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.mainOrange,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.mainOrange.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// แสดง Dialog สรุปยอดขาย (รูปแบบใบเสร็จ)
  void _showSalesSummary() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
            color: Colors.white,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.mainOrange,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'สรุปยอดขาย',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Content - ใบเสร็จ
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: _buildReceiptContent(),
                  ),
                ),
                // Footer - ปุ่ม Download
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(top: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          label: const Text('ปิด'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _exportExcel,
                          icon: const Icon(Icons.download),
                          label: const Text('ดาวน์โหลด Excel'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.mainOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// สร้างเนื้อหาใบเสร็จ
  Widget _buildReceiptContent() {
    final revenue = _periodSummary['total_revenue'] ?? 0.0;
    final orders = _periodSummary['total_orders'] ?? 0;
    final avgValue = _periodSummary['average_order_value'] ?? 0.0;
    final completedOrders = _periodSummary['completed_orders'] ?? 0;
    final cancelledOrders = _periodSummary['cancelled_orders'] ?? 0;
    final processingTime = _periodSummary['average_processing_time'] ?? 0.0;
    final peakHours = _periodSummary['peak_hours'] ?? '-';

    // กำหนดช่วงวันที่
    String dateRange;
    if (_selectedPeriod == 'custom' && _customStartDate != null && _customEndDate != null) {
      dateRange = '${DateFormat('d/MM/yyyy').format(_customStartDate!)} - ${DateFormat('d/MM/yyyy').format(_customEndDate!)}';
    } else if (_selectedPeriod == 'today') {
      dateRange = DateFormat('d/MM/yyyy').format(DateTime.now());
    } else if (_selectedPeriod == 'week') {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      dateRange = '${DateFormat('d/MM').format(startOfWeek)} - ${DateFormat('d/MM/yyyy').format(endOfWeek)}';
    } else {
      final now = DateTime.now();
      dateRange = DateFormat('MM/yyyy').format(now);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ชื่อร้าน (กลาง)
        Center(
          child: Column(
            children: [
              Text(
                widget.restaurantName.toUpperCase(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'สรุปยอดขาย',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Divider(thickness: 2),
        const SizedBox(height: 16),
        
        // ช่วงวันที่
        _buildReceiptRow('ช่วงวันที่', dateRange, isBold: true),
        const SizedBox(height: 8),
        _buildReceiptRow('วันที่พิมพ์', DateFormat('d/M/yyyy HH:mm').format(DateTime.now())),
        
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 20),
        
        // สรุปยอดขาย
        const Text(
          'สรุปยอดขาย',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        _buildReceiptRow('จำนวนออเดอร์ทั้งหมด', '$orders ออเดอร์'),
        _buildReceiptRow('ออเดอร์สำเร็จ', '$completedOrders ออเดอร์'),
        if (cancelledOrders > 0)
          _buildReceiptRow('ออเดอร์ยกเลิก', '$cancelledOrders ออเดอร์'),
        _buildReceiptRow('ค่าเฉลี่ยต่อออเดอร์', '฿${avgValue.toStringAsFixed(2)}'),
        
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 20),
        
        // ข้อมูลเพิ่มเติม
        const Text(
          'ข้อมูลเพิ่มเติม',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        _buildReceiptRow('เวลาเฉลี่ยในการประมวลผล', '${processingTime.toStringAsFixed(1)} นาที'),
        _buildReceiptRow('ช่วงเวลายอดนิยม', peakHours),
        
        const SizedBox(height: 20),
        const Divider(thickness: 2),
        const SizedBox(height: 20),
        
        // รายได้รวม (ไม่มีกรอบ ใช้สีดำธรรมดา)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'รายได้รวม',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '฿${revenue.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 32),
        
        // ขอบคุณ
        Center(
          child: Column(
            children: [
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'ขอบคุณที่ใช้บริการ',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'EatSci - Food Ordering System',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// แถวข้อมูลในใบเสร็จ
  Widget _buildReceiptRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// Export เป็น PDF (รองรับทุก platform + Thai font)
  void _exportExcel() async {
    if (!mounted) return;
    
    try {
      // แสดง loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                SizedBox(width: 16),
                Text('กำลังสร้าง Excel...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // สร้าง Excel file
      var excel = excel_lib.Excel.createExcel();
      excel_lib.Sheet sheet = excel['สรุปยอดขาย'];
      
      // ดึงข้อมูล
      final revenue = _periodSummary['total_revenue'] ?? 0.0;
      final orders = _periodSummary['total_orders'] ?? 0;
      final avgValue = _periodSummary['average_order_value'] ?? 0.0;
      final completedOrders = _periodSummary['completed_orders'] ?? 0;
      final cancelledOrders = _periodSummary['cancelled_orders'] ?? 0;
      final processingTime = _periodSummary['average_processing_time'] ?? 0.0;
      final peakHours = _periodSummary['peak_hours'] ?? '-';

      String dateRange, safeFileName;
      if (_selectedPeriod == 'custom' && _customStartDate != null && _customEndDate != null) {
        dateRange = '${DateFormat('d/MM/yyyy').format(_customStartDate!)} - ${DateFormat('d/MM/yyyy').format(_customEndDate!)}';
        safeFileName = '${DateFormat('ddMMyyyy').format(_customStartDate!)}-${DateFormat('ddMMyyyy').format(_customEndDate!)}';
      } else if (_selectedPeriod == 'today') {
        dateRange = DateFormat('d/MM/yyyy').format(DateTime.now());
        safeFileName = DateFormat('ddMMyyyy').format(DateTime.now());
      } else if (_selectedPeriod == 'week') {
        final now = DateTime.now();
        final start = now.subtract(Duration(days: now.weekday - 1));
        final end = start.add(const Duration(days: 6));
        dateRange = '${DateFormat('d/MM').format(start)} - ${DateFormat('d/MM/yyyy').format(end)}';
        safeFileName = '${DateFormat('ddMM').format(start)}-${DateFormat('ddMMyyyy').format(end)}';
      } else {
        final now = DateTime.now();
        dateRange = DateFormat('MM/yyyy').format(now);
        safeFileName = DateFormat('MMyyyy').format(now);
      }

      // เพิ่มข้อมูลใน Excel (รองรับภาษาไทย 100%)
      int rowIndex = 0;
      
      // Header
      sheet.appendRow([excel_lib.TextCellValue('ร้าน${widget.restaurantName}')]);
      sheet.merge(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex), 
                  excel_lib.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex));
      rowIndex++;
      
      sheet.appendRow([excel_lib.TextCellValue('สรุปยอดขาย')]);
      sheet.merge(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex), 
                  excel_lib.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex));
      rowIndex++;
      rowIndex++; // Empty row
      
      // ช่วงวันที่
      sheet.appendRow([excel_lib.TextCellValue('ช่วงวันที่:'), excel_lib.TextCellValue(dateRange)]);
      rowIndex++;
      sheet.appendRow([excel_lib.TextCellValue('วันที่พิมพ์:'), excel_lib.TextCellValue(DateFormat('d/M/yyyy HH:mm').format(DateTime.now()))]);
      rowIndex++;
      rowIndex++; // Empty row
      
      // สรุปยอดขาย
      sheet.appendRow([excel_lib.TextCellValue('สรุปยอดขาย')]);
      sheet.merge(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex), 
                  excel_lib.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex));
      rowIndex++;
      
      sheet.appendRow([excel_lib.TextCellValue('จำนวนออเดอร์ทั้งหมด'), excel_lib.TextCellValue('$orders ออเดอร์')]);
      rowIndex++;
      sheet.appendRow([excel_lib.TextCellValue('ออเดอร์สำเร็จ'), excel_lib.TextCellValue('$completedOrders ออเดอร์')]);
      rowIndex++;
      if (cancelledOrders > 0) {
        sheet.appendRow([excel_lib.TextCellValue('ออเดอร์ยกเลิก'), excel_lib.TextCellValue('$cancelledOrders ออเดอร์')]);
        rowIndex++;
      }
      sheet.appendRow([excel_lib.TextCellValue('ค่าเฉลี่ยต่อออเดอร์'), excel_lib.TextCellValue('฿${avgValue.toStringAsFixed(2)}')]);
      rowIndex++;
      rowIndex++; // Empty row
      
      // ข้อมูลเพิ่มเติม
      sheet.appendRow([excel_lib.TextCellValue('ข้อมูลเพิ่มเติม')]);
      sheet.merge(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex), 
                  excel_lib.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex));
      rowIndex++;
      
      sheet.appendRow([excel_lib.TextCellValue('เวลาเฉลี่ยในการประมวลผล'), excel_lib.TextCellValue('${processingTime.toStringAsFixed(1)} นาที')]);
      rowIndex++;
      sheet.appendRow([excel_lib.TextCellValue('ช่วงเวลายอดนิยม'), excel_lib.TextCellValue(peakHours)]);
      rowIndex++;
      rowIndex++; // Empty row
      
      // รายได้รวม
      sheet.appendRow([excel_lib.TextCellValue('รายได้รวม'), excel_lib.TextCellValue('฿${revenue.toStringAsFixed(2)}')]);
      rowIndex++;
      rowIndex++; // Empty row
      
      // Footer
      sheet.appendRow([excel_lib.TextCellValue('ขอบคุณที่ใช้บริการ')]);
      rowIndex++;
      sheet.appendRow([excel_lib.TextCellValue('EatSci - Food Ordering System')]);
      
      // ปรับความกว้างคอลัมน์
      sheet.setColumnWidth(0, 30);
      sheet.setColumnWidth(1, 30);

      // บันทึกไฟล์ - รองรับทุก platform
      final fileBytes = excel.encode();
      if (fileBytes == null) {
        throw Exception('ไม่สามารถสร้างไฟล์ Excel ได้');
      }

      final fileName = 'SalesSummary_${widget.restaurantName}_$safeFileName.xlsx';
      
      // Android & iOS: ใช้ Share dialog (ให้ผู้ใช้เลือกว่าจะบันทึกหรือแชร์)
      if (Platform.isAndroid || Platform.isIOS) {
        // สร้างไฟล์ชั่วคราว
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/$fileName');
        await tempFile.writeAsBytes(fileBytes);
        
        print('✅ สร้างไฟล์ชั่วคราวที่: ${tempFile.path}');
        
        // แชร์ไฟล์ผ่าน Share dialog
        final result = await Share.shareXFiles(
          [XFile(tempFile.path)],
          subject: 'สรุปยอดขาย - ${widget.restaurantName}',
          text: 'รายงานสรุปยอดขาย $dateRange',
        );
        
        if (mounted) {
          if (result.status == ShareResultStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ แชร์ไฟล์สำเร็จ!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ℹ️ สร้างไฟล์สำเร็จแล้ว',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'เลือก "Save to Files" เพื่อบันทึกไฟล์',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }
      // Desktop (Windows, macOS, Linux): บันทึกโดยตรงที่ Downloads
      else {
        String filePath;
        
        if (Platform.isWindows) {
          final userProfile = Platform.environment['USERPROFILE'];
          if (userProfile != null) {
            filePath = '$userProfile\\Downloads\\$fileName';
          } else {
            throw Exception('ไม่สามารถหา Downloads folder ได้');
          }
        } else if (Platform.isMacOS) {
          final home = Platform.environment['HOME'];
          if (home != null) {
            filePath = '$home/Downloads/$fileName';
          } else {
            throw Exception('ไม่สามารถหา Downloads folder ได้');
          }
        } else if (Platform.isLinux) {
          final home = Platform.environment['HOME'];
          if (home != null) {
            filePath = '$home/Downloads/$fileName';
          } else {
            throw Exception('ไม่สามารถหา Downloads folder ได้');
          }
        } else {
          final directory = await getApplicationDocumentsDirectory();
          filePath = '${directory.path}/$fileName';
        }
        
        // สร้างไฟล์
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);
        
        print('✅ บันทึกไฟล์สำเร็จที่: $filePath');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '✅ ดาวน์โหลด Excel สำเร็จ!',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'บันทึกที่: Downloads',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'เปิดโฟลเดอร์',
                textColor: Colors.white,
                onPressed: () async {
                  try {
                    if (Platform.isWindows) {
                      await Process.run('explorer.exe', ['/select,', filePath]);
                    } else if (Platform.isMacOS) {
                      await Process.run('open', ['-R', filePath]);
                    }
                  } catch (e) {
                    print('❌ Error opening folder: $e');
                  }
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error exporting Excel: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
