import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../const/app_color.dart';

/// หน้าสรุปยอดขายรายวัน - แบบกระดาษ A4 เรียบง่าย ไม่มีลูกเล่น
class DailySalesReportScreen extends StatefulWidget {
  final int restaurantId;
  final String restaurantName;

  const DailySalesReportScreen({
    Key? key,
    required this.restaurantId,
    required this.restaurantName,
  }) : super(key: key);

  @override
  State<DailySalesReportScreen> createState() => _DailySalesReportScreenState();
}

class _DailySalesReportScreenState extends State<DailySalesReportScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  
  // ข้อมูลสรุป
  List<Map<String, dynamic>> _orders = [];
  double _totalRevenue = 0.0;
  double _cancelledRevenue = 0.0;
  int _totalOrders = 0;
  int _completedOrders = 0;
  int _cancelledOrders = 0;

  @override
  void initState() {
    super.initState();
    _loadDailySales();
  }

  Future<void> _loadDailySales() async {
    setState(() => _isLoading = true);
    
    try {
      final startDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final endDate = startDate.add(const Duration(days: 1));
      
      // แปลงเป็น UTC สำหรับ query
      final startDateUtc = startDate.toUtc();
      final endDateUtc = endDate.toUtc();
      
      // ดึง orders ทั้งหมดของวันนั้น (รวมยกเลิก)
      final response = await Supabase.instance.client
          .from('orders')
          .select('*, order_items(*)')
          .eq('restaurant_id', widget.restaurantId)
          .gte('created_at', startDateUtc.toIso8601String())
          .lt('created_at', endDateUtc.toIso8601String())
          .order('created_at', ascending: true);
      
      final orders = List<Map<String, dynamic>>.from(response);
      
      // คำนวณสรุป
      double totalRev = 0.0;
      double cancelledRev = 0.0;
      int completed = 0;
      int cancelled = 0;
      
      for (var order in orders) {
        final amount = (order['total_amount'] ?? 0).toDouble();
        if (order['status'] == 'cancelled') {
          cancelledRev += amount;
          cancelled++;
        } else if (order['status'] == 'completed') {
          totalRev += amount;
          completed++;
        } else {
          // pending, confirmed, preparing, ready ยังไม่นับเป็นรายได้จริง
          // แต่นับเป็น order
        }
      }
      
      setState(() {
        _orders = orders;
        _totalRevenue = totalRev;
        _cancelledRevenue = cancelledRev;
        _totalOrders = orders.length;
        _completedOrders = completed;
        _cancelledOrders = cancelled;
        _isLoading = false;
      });
      
      print('✅ โหลดยอดขายวันที่ ${_formatDate(_selectedDate)}: ${orders.length} orders');
    } catch (e) {
      print('❌ Error loading daily sales: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime date) {
    // ใช้รูปแบบง่ายๆ ไม่ต้อง locale
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(String? dateTime) {
    if (dateTime == null) return '-';
    try {
      // แปลง UTC เป็นเวลาท้องถิ่น (เวลาไทย GMT+7)
      final dt = DateTime.parse(dateTime).toLocal();
      return DateFormat('HH:mm').format(dt);
    } catch (e) {
      return '-';
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'รอยืนยัน';
      case 'confirmed': return 'ยืนยันแล้ว';
      case 'preparing': return 'กำลังทำ';
      case 'ready': return 'พร้อมรับ';
      case 'completed': return 'เสร็จสิ้น';
      case 'cancelled': return 'ยกเลิก';
      default: return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  /// แสดงรายละเอียด order แบบ Dialog (Overlay)
  void _showOrderDetails(Map<String, dynamic> order) {
    final items = order['order_items'] as List? ?? [];
    
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
                  decoration: BoxDecoration(
                    color: AppColors.mainOrange,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Order #${order['id']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
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
                            _buildInfoRow('เวลาสั่ง', _formatDateTime(order['created_at'])),
                          ]),
                          const Divider(height: 32),
                          
                          // รายการอาหาร
                          _buildInfoSection('รายการอาหาร', [
                            ...items.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item['food_name'] ?? '-',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  Text(
                                    'x${item['quantity']}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    '฿${(item['price'] * item['quantity']).toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            )).toList(),
                          ]),
                          const Divider(height: 32),
                          
                          // ยอดรวม
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'ยอดรวมทั้งหมด',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '฿${order['total_amount']?.toStringAsFixed(0) ?? '0'}',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.mainOrange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // สถานะ
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _getStatusColor(order['status'] ?? '').withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getStatusColor(order['status'] ?? ''),
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _getStatusIcon(order['status'] ?? ''),
                                  color: _getStatusColor(order['status'] ?? ''),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'สถานะ: ${_getStatusText(order['status'] ?? '')}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _getStatusColor(order['status'] ?? ''),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // สลิปการโอนเงิน (ถ้ามี)
                          if (order['payment_slip_url'] != null) ...[
                            const SizedBox(height: 24),
                            const Text(
                              'หลักฐานการชำระเงิน',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              elevation: 2,
                              shadowColor: Colors.black.withOpacity(0.1),
                              child: InkWell(
                                onTap: () {
                                  // แสดงรูปสลิป
                                  showDialog(
                                    context: context,
                                    builder: (context) => Dialog(
                                      backgroundColor: Colors.transparent,
                                      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
                                          color: Colors.white,
                                          child: Stack(
                                            children: [
                                              Image.network(
                                                order['payment_slip_url'],
                                                fit: BoxFit.contain,
                                                loadingBuilder: (context, child, loadingProgress) {
                                                  if (loadingProgress == null) return child;
                                                  return Center(
                                                    child: CircularProgressIndicator(
                                                      value: loadingProgress.expectedTotalBytes != null
                                                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                          : null,
                                                    ),
                                                  );
                                                },
                                                errorBuilder: (context, error, stackTrace) {
                                                  return const Center(
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Icon(Icons.error_outline, size: 48, color: Colors.red),
                                                        SizedBox(height: 16),
                                                        Text('ไม่สามารถโหลดรูปได้'),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                              Positioned(
                                                top: 8,
                                                right: 8,
                                                child: IconButton(
                                                  icon: const Icon(Icons.close, color: Colors.white),
                                                  style: IconButton.styleFrom(
                                                    backgroundColor: Colors.black54,
                                                  ),
                                                  onPressed: () => Navigator.pop(context),
                                                ),
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
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.receipt_outlined,
                                          color: Colors.grey[700],
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      const Expanded(
                                        child: Text(
                                          'ดูสลิปการโอนเงิน',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right,
                                        color: Colors.grey[400],
                                        size: 24,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
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
      final dt = DateTime.parse(dateTime).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending': return Icons.schedule;
      case 'confirmed': return Icons.check_circle;
      case 'preparing': return Icons.restaurant;
      case 'ready': return Icons.done_all;
      case 'completed': return Icons.check_circle_outline;
      case 'cancelled': return Icons.cancel;
      default: return Icons.help_outline;
    }
  }

  /// เลือกวันที่
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadDailySales();
    }
  }

  /// สร้าง PDF
  Future<void> _generatePDF() async {
    final pdf = pw.Document();
    
    // สร้าง PDF ภาษาไทย (ต้องใช้ font ที่รองรับ)
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Text(
                '${widget.restaurantName}',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Text('สรุปยอดขายประจำวัน', style: const pw.TextStyle(fontSize: 18)),
              pw.Text('วันที่: ${_formatDate(_selectedDate)}', style: const pw.TextStyle(fontSize: 14)),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 16),
              
              // สรุปยอด
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('ยอดรวมทั้งหมด:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.Text('฿${_totalRevenue.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('ออเดอร์ทั้งหมด:', style: const pw.TextStyle(fontSize: 12)),
                  pw.Text('$_totalOrders orders', style: const pw.TextStyle(fontSize: 12)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('- สำเร็จ:', style: const pw.TextStyle(fontSize: 12)),
                  pw.Text('$_completedOrders orders', style: const pw.TextStyle(fontSize: 12)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('- ยกเลิก:', style: const pw.TextStyle(fontSize: 12)),
                  pw.Text('$_cancelledOrders orders', style: const pw.TextStyle(fontSize: 12)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('เงินที่เสียจากการยกเลิก:', style: const pw.TextStyle(fontSize: 12, color: PdfColors.red)),
                  pw.Text('-฿${_cancelledRevenue.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 12, color: PdfColors.red)),
                ],
              ),
              pw.Divider(),
              pw.SizedBox(height: 16),
              
              // ตารางออเดอร์
              pw.Text('รายการออเดอร์ทั้งหมด', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  // Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Order #', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Time', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Amount', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Status', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  // Rows
                  ..._orders.map((order) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('#${order['id']}', style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(_formatTime(order['created_at']), style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('฿${(order['total_amount'] ?? 0).toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(_getStatusText(order['status'] ?? ''), style: const pw.TextStyle(fontSize: 9))),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ],
          );
        },
      ),
    );
    
    // บันทึก PDF และดาวน์โหลดลงเครื่อง
    try {
      final bytes = await pdf.save();
      final fileName = 'daily_sales_${_formatDate(_selectedDate).replaceAll('/', '-')}.pdf';
      
      await Printing.sharePdf(
        bytes: bytes,
        filename: fileName,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ บันทึก PDF สำเร็จ: $fileName'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error saving PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ ไม่สามารถบันทึก PDF ได้'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('สรุปยอดขายรายวัน'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          // ปุ่มเลือกวันที่
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
            tooltip: 'เลือกวันที่',
          ),
          // ปุ่ม Download PDF
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _isLoading || _orders.isEmpty ? null : _generatePDF,
            tooltip: 'ดาวน์โหลด PDF',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // วันที่
                    Text(
                      'วันที่: ${_formatDate(_selectedDate)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    // สรุปยอด - แบบกระดาษธรรมดา
                    _buildSummarySection(),
                    
                    const SizedBox(height: 24),
                    
                    // ตารางออเดอร์
                    _buildOrdersTable(),
                  ],
                ),
              ),
            ),
    );
  }

  /// สรุปยอดขาย - เรียบง่ายแบบกระดาษ
  Widget _buildSummarySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'สรุปยอดขาย',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          const SizedBox(height: 8),
          
          _buildSummaryRow('ยอดรวมทั้งหมด', '฿${_totalRevenue.toStringAsFixed(2)}', isBold: true),
          const SizedBox(height: 12),
          _buildSummaryRow('ออเดอร์ทั้งหมด', '$_totalOrders orders'),
          _buildSummaryRow('  - สำเร็จ', '$_completedOrders orders', color: Colors.green.shade700),
          _buildSummaryRow('  - ยกเลิก', '$_cancelledOrders orders', color: Colors.red.shade700),
          const SizedBox(height: 12),
          _buildSummaryRow('เงินที่เสียจากการยกเลิก', '-฿${_cancelledRevenue.toStringAsFixed(2)}', color: Colors.red),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// ตารางออเดอร์ - คลิก row = ดูรายละเอียด
  Widget _buildOrdersTable() {
    if (_orders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text('ไม่มีออเดอร์ในวันนี้', style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: const Text(
              'รายการออเดอร์ทั้งหมด',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          
          // Table
          Table(
            border: TableBorder.symmetric(
              inside: BorderSide(color: Colors.grey.shade200),
            ),
            columnWidths: const {
              0: FlexColumnWidth(1.0),
              1: FlexColumnWidth(1.5),
              2: FlexColumnWidth(1.5),
              3: FlexColumnWidth(1.5),
            },
            children: [
              // Header Row
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade100),
                children: [
                  _buildTableHeader('Order #'),
                  _buildTableHeader('เวลา'),
                  _buildTableHeader('ยอดรวม'),
                  _buildTableHeader('สถานะ'),
                ],
              ),
              
              // Data Rows
              ..._orders.map((order) {
                return TableRow(
                  children: [
                    _buildTableCell('#${order['id']}', order),
                    _buildTableCell(_formatTime(order['created_at']), order),
                    _buildTableCell('฿${(order['total_amount'] ?? 0).toStringAsFixed(0)}', order),
                    _buildTableCellWithStatus(order),
                  ],
                );
              }).toList(),
            ],
          ),
          

        ],
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _buildTableCell(String text, Map<String, dynamic> order) {
    return InkWell(
      onTap: () => _showOrderDetails(order),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(text, style: const TextStyle(fontSize: 13)),
      ),
    );
  }

  Widget _buildTableCellWithStatus(Map<String, dynamic> order) {
    final status = order['status'] ?? '';
    return InkWell(
      onTap: () => _showOrderDetails(order),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          _getStatusText(status),
          style: TextStyle(
            fontSize: 13,
            color: _getStatusColor(status),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
