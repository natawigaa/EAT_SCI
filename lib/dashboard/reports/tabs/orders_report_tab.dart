import 'package:flutter/material.dart';
import '../../../const/app_color.dart';
import '../../../services/supabase_service.dart';
import '../widgets/date_range_picker.dart';
import 'package:excel/excel.dart' as excel_lib hide Border;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

/// Tab แสดงรายละเอียดออเดอร์
/// - สรุปยอดออเดอร์ (Summary Cards)
/// - ตารางออเดอร์ทั้งหมด
/// - กรองตามช่วงเวลาและสถานะ (วันนี้, เมื่อวาน, สัปดาห์, เดือน, กำหนดเอง)
/// - คลิกดูรายละเอียดแต่ละออเดอร์
/// - Excel Export (รองรับภาษาไทย)
class OrdersReportTab extends StatefulWidget {
  final int restaurantId;
  final String restaurantName;

  const OrdersReportTab({
    Key? key,
    required this.restaurantId,
    required this.restaurantName,
  }) : super(key: key);

  @override
  State<OrdersReportTab> createState() => _OrdersReportTabState();
}

class _OrdersReportTabState extends State<OrdersReportTab> {
  bool _isLoading = true;
  String _selectedPeriod = 'today'; // 'today', 'yesterday', 'week', 'month', 'custom'
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  String _selectedStatus = 'all'; // 'all', 'pending', 'completed', etc.
  List<Map<String, dynamic>> _orders = [];
  Map<String, dynamic> _summary = {}; // สรุปยอดรวม

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      print('📊 กำลังดึงข้อมูลออเดอร์ช่วง: $_selectedPeriod');
      
      // คำนวณช่วงวันที่ตาม period
      DateTime startDate;
      DateTime endDate;
      
      if (_selectedPeriod == 'custom' && _customStartDate != null && _customEndDate != null) {
        startDate = _customStartDate!;
        endDate = _customEndDate!;
      } else {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        switch (_selectedPeriod) {
          case 'yesterday':
            startDate = today.subtract(const Duration(days: 1));
            endDate = today;
            break;
          case 'week':
            startDate = today.subtract(const Duration(days: 7));
            endDate = today.add(const Duration(days: 1));
            break;
          case 'month':
            startDate = today.subtract(const Duration(days: 30));
            endDate = today.add(const Duration(days: 1));
            break;
          case 'today':
          default:
            startDate = today;
            endDate = today.add(const Duration(days: 1));
            break;
        }
      }
      
      print('📅 ช่วงวันที่: ${startDate.toLocal()} ถึง ${endDate.toLocal()}');
      
      // ดึงข้อมูลจริงจาก Supabase (ทุกสถานะ รวม ready และ completed)
      final allOrders = await SupabaseService.getAllRestaurantOrders(widget.restaurantId);
      print('📦 ดึงได้ทั้งหมด ${allOrders.length} orders (รวมทุกสถานะ)');
      
      // กรองตามช่วงเวลาที่เลือก
      final filteredOrders = allOrders.where((order) {
        final createdAt = DateTime.parse(order['created_at']).toLocal();
        final orderDateOnly = DateTime(createdAt.year, createdAt.month, createdAt.day);
        return orderDateOnly.isAfter(startDate.subtract(const Duration(days: 1))) && 
               orderDateOnly.isBefore(endDate);
      }).toList();
      
      print('✅ กรองแล้วได้ ${filteredOrders.length} orders สำหรับช่วง $_selectedPeriod');
      
      // กรองตามสถานะ (ถ้าเลือก)
      final statusFiltered = _selectedStatus == 'all' 
          ? filteredOrders 
          : filteredOrders.where((order) => order['status'] == _selectedStatus).toList();
      
      
      // คำนวณสรุปยอดรวม
      int totalOrders = statusFiltered.length;
      int completedOrders = statusFiltered.where((o) => o['status'] == 'completed').length;
      int pendingOrders = statusFiltered.where((o) => o['status'] == 'pending').length;
      int readyOrders = statusFiltered.where((o) => o['status'] == 'ready').length;
      double totalRevenue = statusFiltered.fold(0.0, (sum, order) => sum + (order['total_amount'] ?? 0.0));
      double avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;
      
      setState(() {
        _orders = statusFiltered;
        _summary = {
          'total_orders': totalOrders,
          'completed_orders': completedOrders,
          'pending_orders': pendingOrders,
          'ready_orders': readyOrders,
          'total_revenue': totalRevenue,
          'avg_order_value': avgOrderValue,
        };
        _isLoading = false;
      });
      
      print('✅ โหลดข้อมูล $totalOrders orders');
      print('💰 ยอดรวม: ฿$totalRevenue');
    } catch (e) {
      print('❌ Error loading orders: $e');
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
            // Header
            Row(
              children: [
                Icon(Icons.receipt_long, size: 28, color: AppColors.mainOrange),
                const SizedBox(width: 12),
                const Text(
                  'รายงานออเดอร์',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // ปุ่ม Export Excel
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _exportExcel,
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Export Excel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Date Range Picker (เพิ่มใหม่)
            DateRangePicker(
              selectedPeriod: _selectedPeriod,
              customStartDate: _customStartDate,
              customEndDate: _customEndDate,
              onPeriodChanged: _onPeriodChanged,
            ),
            
            const SizedBox(height: 24),
            
            // Status Filter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButton<String>(
                value: _selectedStatus,
                isExpanded: true,
                underline: const SizedBox(),
                icon: const Icon(Icons.filter_list),
                hint: const Text('กรองตามสถานะ'),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('ทั้งหมด')),
                  DropdownMenuItem(value: 'pending', child: Text('รอยืนยัน')),
                  DropdownMenuItem(value: 'confirmed', child: Text('ยืนยันแล้ว')),
                  DropdownMenuItem(value: 'preparing', child: Text('กำลังทำ')),
                  DropdownMenuItem(value: 'ready', child: Text('รอรับ')),
                  DropdownMenuItem(value: 'completed', child: Text('เสร็จสิ้น')),
                  DropdownMenuItem(value: 'cancelled', child: Text('ยกเลิก')),
                ],
                onChanged: (value) {
                  setState(() => _selectedStatus = value!);
                  _loadData();
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Orders Table
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              _buildOrdersTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersTable() {
    return Container(
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
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.mainOrange.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: const Row(
              children: [
                Expanded(flex: 1, child: Text('Order#', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('เวลา', style: TextStyle(fontWeight: FontWeight.bold))),
                // Student ID column removed to save horizontal space
                // Make 'รายการ' column even narrower (flex 1) and center the header label
                Expanded(flex: 1, child: Center(child: Text('รายการ', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center))),
                Expanded(flex: 1, child: Text('ยอดรวม', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                Expanded(flex: 1, child: Text('สถานะ', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
              ],
            ),
          ),
          
          // Rows
          ..._orders.map((order) {
            // แปลงเวลาให้แสดงเฉพาะชั่วโมง:นาที
            final createdAt = DateTime.parse(order['created_at']).toLocal();
            final timeStr = '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
            
            // รวมรายการอาหารเป็น string
            final items = order['items'] as List? ?? [];
            final itemsStr = items.map((item) => item['food_name'] ?? item['menu_name'] ?? '-').join(', ');
            
            return InkWell(
              onTap: () => _showOrderDetails(order),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Row(
                  children: [
                    Expanded(flex: 1, child: Text('#${order['id']}')),
                    Expanded(flex: 1, child: Text(timeStr)),
                    // Student ID removed from table rows
                    // Narrower items column (flex 1)
                    Expanded(flex: 1, child: Text(itemsStr.isEmpty ? '-' : itemsStr, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '฿${(order['total_amount'] ?? 0.0).toStringAsFixed(0)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: _buildStatusBadge(order['status'] ?? 'pending'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    
    switch (status) {
      case 'pending':
        color = Colors.orange;
        text = 'รอยืนยัน';
        break;
      case 'confirmed':
        color = Colors.blue;
        text = 'ยืนยันแล้ว';
        break;
      case 'preparing':
        color = Colors.blue;
        text = 'กำลังทำ';
        break;
      case 'ready':
        color = Colors.green;
        text = 'รอรับ';
        break;
      case 'completed':
        color = Colors.green;
        text = 'เสร็จสิ้น';
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  /// Export Excel
  Future<void> _exportExcel() async {
    try {
      var excel = excel_lib.Excel.createExcel();
      excel_lib.Sheet sheet = excel['รายงานออเดอร์'];
      
      // Header
      sheet.appendRow([excel_lib.TextCellValue('ร้าน ${widget.restaurantName}')]);
      sheet.appendRow([excel_lib.TextCellValue('รายงานออเดอร์')]);
      
      // แสดงช่วงเวลา
      String periodText;
      if (_selectedPeriod == 'custom' && _customStartDate != null && _customEndDate != null) {
        periodText = 'ช่วงเวลา: ${DateFormat('dd/MM/yyyy').format(_customStartDate!)} - ${DateFormat('dd/MM/yyyy').format(_customEndDate!)}';
      } else {
        switch (_selectedPeriod) {
          case 'yesterday':
            periodText = 'เมื่อวาน';
            break;
          case 'week':
            periodText = '7 วันที่ผ่านมา';
            break;
          case 'month':
            periodText = '30 วันที่ผ่านมา';
            break;
          case 'today':
          default:
            periodText = 'วันนี้';
            break;
        }
      }
      sheet.appendRow([excel_lib.TextCellValue(periodText)]);
      sheet.appendRow([excel_lib.TextCellValue('')]);
      
      // Summary
      sheet.appendRow([excel_lib.TextCellValue('สรุปยอดรวม')]);
      sheet.appendRow([
        excel_lib.TextCellValue('ออเดอร์ทั้งหมด:'),
        excel_lib.IntCellValue(_summary['total_orders'] ?? 0),
      ]);
      sheet.appendRow([
        excel_lib.TextCellValue('ออเดอร์สำเร็จ:'),
        excel_lib.IntCellValue(_summary['completed_orders'] ?? 0),
      ]);
      sheet.appendRow([
        excel_lib.TextCellValue('รอดำเนินการ:'),
        excel_lib.IntCellValue(_summary['pending_orders'] ?? 0),
      ]);
      sheet.appendRow([
        excel_lib.TextCellValue('รายได้รวม:'),
        excel_lib.DoubleCellValue(_summary['total_revenue'] ?? 0.0),
      ]);
      sheet.appendRow([excel_lib.TextCellValue('')]);
      
      // Table header (Student ID removed to match UI)
      sheet.appendRow([
        excel_lib.TextCellValue('Order ID'),
        excel_lib.TextCellValue('เวลา'),
        excel_lib.TextCellValue('Student ID'),
        excel_lib.TextCellValue('รายการ'),
        excel_lib.TextCellValue('ยอดรวม'),
        excel_lib.TextCellValue('สถานะ'),
      ]);
      
      // Orders data
      for (var order in _orders) {
        // แปลงเวลาจาก created_at
        final createdAt = DateTime.parse(order['created_at']).toLocal();
        final timeStr = '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
        
        // รวมรายการอาหาร
        final items = order['items'] as List? ?? [];
        final itemsStr = items.map((item) => item['food_name'] ?? item['menu_name'] ?? '-').join(', ');
        
        sheet.appendRow([
          excel_lib.IntCellValue(order['id']),
          excel_lib.TextCellValue(timeStr),
          excel_lib.TextCellValue(order['student_id']?.toString() ?? '-'),
          excel_lib.TextCellValue(itemsStr.isEmpty ? '-' : itemsStr),
          excel_lib.DoubleCellValue((order['total_amount'] ?? 0.0).toDouble()),
          excel_lib.TextCellValue(_getStatusTextForExport(order['status'] ?? 'pending')),
        ]);
      }
      
      // Generate file
      final fileBytes = excel.encode();
      if (fileBytes == null) throw Exception('ไม่สามารถสร้างไฟล์ Excel ได้');
      
      // สร้างชื่อไฟล์
      String dateStr;
      if (_selectedPeriod == 'custom' && _customStartDate != null && _customEndDate != null) {
        dateStr = '${DateFormat('ddMMyyyy').format(_customStartDate!)}-${DateFormat('ddMMyyyy').format(_customEndDate!)}';
      } else {
        dateStr = DateFormat('ddMMyyyy').format(DateTime.now());
      }
      
      final fileName = 'OrdersReport_${widget.restaurantName}_$dateStr.xlsx';
      
      // Save file (Platform-specific)
      if (Platform.isAndroid) {
        // Save to external storage (app-specific) Downloads folder so user can access the file
        final extDir = await getExternalStorageDirectory();
        if (extDir == null) throw Exception('ไม่สามารถเข้าถึงพื้นที่เก็บไฟล์ภายนอกได้');

        // Use a Downloads subfolder inside the app external dir to avoid needing extra permissions
        final downloadsDir = Directory('${extDir.path}/Download');
        if (!await downloadsDir.exists()) await downloadsDir.create(recursive: true);

        final outFile = File('${downloadsDir.path}/$fileName');
        await outFile.writeAsBytes(fileBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ดาวน์โหลดสำเร็จ: $fileName'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'เปิดโฟลเดอร์',
                textColor: Colors.white,
                onPressed: () async {
                  // Try opening the folder using a platform-appropriate command
                  try {
                    await Process.run('am', ['start', '-a', 'android.intent.action.VIEW', '-d', 'file://${downloadsDir.path}']);
                  } catch (_) {
                    // Fallback: try sharing the file (lets user open it)
                    await Share.shareXFiles([XFile(outFile.path)], subject: 'รายงานออเดอร์ - ${widget.restaurantName}', text: 'รายงานออเดอร์ช่วง: $periodText');
                  }
                },
              ),
            ),
          );
        }
      } else if (Platform.isIOS) {
        // On iOS we continue to use share sheet (no public Downloads folder)
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/$fileName');
        await tempFile.writeAsBytes(fileBytes);

        final result = await Share.shareXFiles(
          [XFile(tempFile.path)],
          subject: 'รายงานออเดอร์ - ${widget.restaurantName}',
          text: 'รายงานออเดอร์ช่วง: $periodText',
        );

        if (mounted) {
          if (result.status == ShareResultStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✅ แชร์ไฟล์สำเร็จ!'), backgroundColor: Colors.green),
            );
          }
        }
      } else {
        String filePath;
        final userProfile = Platform.environment['USERPROFILE'];
        final home = Platform.environment['HOME'];
        
        if (Platform.isWindows) {
          filePath = '$userProfile\\Downloads\\$fileName';
        } else if (Platform.isMacOS || Platform.isLinux) {
          filePath = '$home/Downloads/$fileName';
        } else {
          throw Exception('Platform ไม่รองรับ');
        }
        
        await File(filePath).writeAsBytes(fileBytes);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ บันทึกไฟล์สำเร็จ: $fileName'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'เปิดโฟลเดอร์',
                textColor: Colors.white,
                onPressed: () async {
                  if (Platform.isWindows) {
                    await Process.run('explorer.exe', ['/select,', filePath]);
                  } else if (Platform.isMacOS) {
                    await Process.run('open', ['-R', filePath]);
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
  
  String _getStatusTextForExport(String status) {
    switch (status) {
      case 'pending': return 'รอยืนยัน';
      case 'confirmed': return 'ยืนยันแล้ว';
      case 'preparing': return 'กำลังทำ';
      case 'ready': return 'รอรับ';
      case 'completed': return 'เสร็จสิ้น';
      case 'cancelled': return 'ยกเลิก';
      default: return status;
    }
  }

  /// แสดง Dialog รายละเอียดออเดอร์
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
                            if (order['customer_phone'] != null)
                              _buildInfoRow('เบอร์โทร', order['customer_phone']),
                            _buildInfoRow('เวลาสั่ง', _formatDateTime(order['created_at'])),
                          ]),
                          const Divider(height: 32),
                          
                          // รายการอาหาร
                          _buildInfoSection('รายการอาหาร', [
                            ...(order['items'] as List? ?? []).map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item['food_name'] ?? item['menu_name'] ?? '-'}',
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
                                    '฿${((item['price'] ?? 0) * (item['quantity'] ?? 1)).toStringAsFixed(0)}',
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
                                '฿${(order['total_amount'] ?? 0.0).toStringAsFixed(0)}',
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
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  'สถานะ: ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                _buildStatusBadge(order['status'] ?? 'pending'),
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
                                  // แสดงรูปสลิปแบบเต็ม
                                  showDialog(
                                    context: context,
                                    builder: (context) => Dialog(
                                      backgroundColor: Colors.transparent,
                                      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          constraints: const BoxConstraints(
                                            maxWidth: 500,
                                            maxHeight: 700,
                                          ),
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
                                                      return const Center(
                                                        child: CircularProgressIndicator(color: Colors.white),
                                                      );
                                                    },
                                                    errorBuilder: (context, error, stack) {
                                                      return Container(
                                                        color: Colors.grey[900],
                                                        alignment: Alignment.center,
                                                        child: const Column(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            Icon(Icons.error_outline, size: 64, color: Colors.white),
                                                            SizedBox(height: 16),
                                                            Text(
                                                              'ไม่สามารถโหลดรูปสลิปได้',
                                                              style: TextStyle(color: Colors.white, fontSize: 16),
                                                            ),
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
                                                child: IconButton(
                                                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                                                  onPressed: () => Navigator.pop(context),
                                                  style: IconButton.styleFrom(
                                                    backgroundColor: Colors.black54,
                                                  ),
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
                                            fontSize: 15,
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
}
