import 'package:flutter/material.dart';
import '../../../const/app_color.dart';
import '../widgets/date_range_picker.dart';
import 'package:excel/excel.dart' as excel_lib hide Border;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../../services/supabase_service.dart'; // เพิ่มบรรทัดนี้

/// Tab แสดงรายงานสินค้า (Product Performance)
/// - ตารางแสดงยอดขายแต่ละเมนู
/// - ค้นหาและเรียงลำดับ
/// - Excel Export (รองรับภาษาไทย)
/// - Top Seller Badge
/// - เปรียบเทียบกับช่วงก่อนหน้า
class ProductReportTab extends StatefulWidget {
  final int restaurantId;
  final String restaurantName;

  const ProductReportTab({
    Key? key,
    required this.restaurantId,
    required this.restaurantName,
  }) : super(key: key);

  @override
  State<ProductReportTab> createState() => _ProductReportTabState();
}

class _ProductReportTabState extends State<ProductReportTab> {
  bool _isLoading = true;
  String _selectedPeriod = 'today';
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _previousProducts = []; // สำหรับเปรียบเทียบ
  String _searchQuery = '';
  String _sortBy = 'quantity'; // 'quantity', 'revenue', 'name'
  bool _isDescending = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // กำหนดช่วงเวลาตาม period
      DateTime startDate;
      DateTime endDate;
      
      final now = DateTime.now();
      
      switch (_selectedPeriod) {
        case 'today':
          // วันนี้ 00:00:00 ถึง 23:59:59
          startDate = DateTime(now.year, now.month, now.day);
          endDate = startDate.add(const Duration(days: 1));
          break;
        case 'week':
          // 7 วันย้อนหลัง
          endDate = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
          startDate = endDate.subtract(const Duration(days: 7));
          break;
        case 'month':
          // เดือนนี้ทั้งหมด
          startDate = DateTime(now.year, now.month, 1);
          endDate = DateTime(now.year, now.month + 1, 1);
          break;
        case 'custom':
          if (_customStartDate != null && _customEndDate != null) {
            startDate = DateTime(_customStartDate!.year, _customStartDate!.month, _customStartDate!.day);
            endDate = DateTime(_customEndDate!.year, _customEndDate!.month, _customEndDate!.day).add(const Duration(days: 1));
          } else {
            startDate = DateTime(now.year, now.month, now.day);
            endDate = startDate.add(const Duration(days: 1));
          }
          break;
        default:
          startDate = DateTime(now.year, now.month, now.day);
          endDate = startDate.add(const Duration(days: 1));
      }
      
      print('📊 กำลังดึงข้อมูลสินค้า period: $_selectedPeriod');
      print('📅 วันที่: ${startDate.toLocal()} ถึง ${endDate.toLocal()}');
      
      // ดึงข้อมูลจริงจาก Supabase
      final products = await SupabaseService.getProductSalesReport(
        widget.restaurantId,
        startDate: startDate,
        endDate: endDate,
      );
      
      // ดึงข้อมูลช่วงก่อนหน้าเพื่อเปรียบเทียบ
      final previousStartDate = startDate.subtract(endDate.difference(startDate));
      final previousEndDate = startDate;
      
      final previousProducts = await SupabaseService.getProductSalesReport(
        widget.restaurantId,
        startDate: previousStartDate,
        endDate: previousEndDate,
      );
      
      setState(() {
        _products = products;
        _previousProducts = previousProducts;
        _isLoading = false;
      });
      
      print('✅ โหลดข้อมูล ${products.length} รายการสินค้า');
    } catch (e) {
      print('❌ Error loading product data: $e');
      setState(() {
        _products = [];
        _previousProducts = [];
        _isLoading = false;
      });
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

  List<Map<String, dynamic>> get _filteredProducts {
    var filtered = _products.where((p) {
      return p['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // เรียงลำดับ
    filtered.sort((a, b) {
      int compare = 0;
      if (_sortBy == 'quantity') {
        compare = a['quantity'].compareTo(b['quantity']);
      } else if (_sortBy == 'revenue') {
        compare = a['revenue'].compareTo(b['revenue']);
      } else if (_sortBy == 'name') {
        compare = a['name'].compareTo(b['name']);
      }
      return _isDescending ? -compare : compare;
    });

    return filtered;
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
                Icon(Icons.restaurant_menu, size: 28, color: AppColors.mainOrange),
                const SizedBox(width: 12),
                const Text(
                  'รายงานสินค้า',
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
            
            // Date Range Picker
            DateRangePicker(
              selectedPeriod: _selectedPeriod,
              customStartDate: _customStartDate,
              customEndDate: _customEndDate,
              onPeriodChanged: _onPeriodChanged,
            ),
            
            const SizedBox(height: 20),
            
            // Search and Sort
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
                // Sort Dropdown
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
                  icon: Icon(
                    _isDescending ? Icons.arrow_downward : Icons.arrow_upward,
                    color: AppColors.mainOrange,
                  ),
                  onPressed: () {
                    setState(() => _isDescending = !_isDescending);
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Product Table
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              _buildProductTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductTable() {
    final totalRevenue = _filteredProducts.fold<double>(
      0.0,
      (sum, p) => sum + p['revenue'],
    );
    
    // หา Top Seller (ขายดีที่สุด)
    final topSeller = _filteredProducts.isNotEmpty 
        ? _filteredProducts.reduce((a, b) => a['quantity'] > b['quantity'] ? a : b)['name']
        : null;

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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.mainOrange.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text(
                    'ชื่อเมนู',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: Text(
                    'จำนวน',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: Text(
                    'เปลี่ยนแปลง',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: Text(
                    'ราคา/ชิ้น',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: Text(
                    'รายได้รวม',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: Text(
                    'สัดส่วน',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          
          // Rows
          ..._filteredProducts.map((product) {
            final percentage = totalRevenue > 0
                ? (product['revenue'] / totalRevenue * 100)
                : 0.0;
            
            // คำนวณ % change
            final previousProduct = _previousProducts.firstWhere(
              (p) => p['name'] == product['name'],
              orElse: () => {'quantity': 0, 'revenue': 0.0},
            );
            final prevQty = previousProduct['quantity'] as int;
            final currentQty = product['quantity'] as int;
            final change = prevQty > 0 
                ? ((currentQty - prevQty) / prevQty * 100)
                : 0.0;
            
            // เช็คว่าเป็น Top Seller หรือไม่
            final isTopSeller = product['name'] == topSeller;
            
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!),
                ),
                color: isTopSeller ? Colors.amber.withOpacity(0.05) : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        Text(
                          product['name'],
                          style: TextStyle(
                            fontWeight: isTopSeller ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (isTopSeller) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, size: 12, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'ขายดี',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${product['quantity']}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (change != 0.0) ...[
                          Icon(
                            change > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                            size: 12,
                            color: change > 0 ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${change > 0 ? '+' : ''}${change.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: change > 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ] else
                          Text(
                            '-',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '฿${product['price'].toStringAsFixed(0)}',
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '฿${product['revenue'].toStringAsFixed(0)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${percentage.toStringAsFixed(1)}%',
                      textAlign: TextAlign.right,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          
          // Total
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text(
                    'รวมทั้งหมด',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    '${_filteredProducts.fold<int>(0, (sum, p) => sum + (p['quantity'] as int))}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const Expanded(flex: 1, child: SizedBox()),
                const Expanded(flex: 1, child: SizedBox()),
                Expanded(
                  flex: 1,
                  child: Text(
                    '฿${totalRevenue.toStringAsFixed(0)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: Text(
                    '100%',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Export Excel (รองรับภาษาไทย)
  Future<void> _exportExcel() async {
    try {
      // สร้าง Excel
      var excel = excel_lib.Excel.createExcel();
      excel_lib.Sheet sheet = excel['รายงานสินค้า'];
      
      // Header
      sheet.appendRow([
        excel_lib.TextCellValue('ร้าน ${widget.restaurantName}'),
      ]);
      sheet.appendRow([
        excel_lib.TextCellValue('รายงานสินค้า'),
      ]);
      
      // ช่วงเวลา
      String dateRange = '';
      switch (_selectedPeriod) {
        case 'today':
          dateRange = 'วันนี้ ${DateFormat('dd/MM/yyyy').format(DateTime.now())}';
          break;
        case 'week':
          dateRange = 'สัปดาห์นี้';
          break;
        case 'month':
          dateRange = 'เดือนนี้';
          break;
        case 'custom':
          if (_customStartDate != null && _customEndDate != null) {
            dateRange = '${DateFormat('dd/MM/yyyy').format(_customStartDate!)} - ${DateFormat('dd/MM/yyyy').format(_customEndDate!)}';
          }
          break;
      }
      sheet.appendRow([excel_lib.TextCellValue('ช่วงเวลา: $dateRange')]);
      sheet.appendRow([excel_lib.TextCellValue('')]);
      
      // คอลัมน์หัวตาราง
      sheet.appendRow([
        excel_lib.TextCellValue('ชื่อเมนู'),
        excel_lib.TextCellValue('จำนวนขาย'),
        excel_lib.TextCellValue('เปลี่ยนแปลง (%)'),
        excel_lib.TextCellValue('ราคา/ชิ้น'),
        excel_lib.TextCellValue('รายได้รวม'),
        excel_lib.TextCellValue('สัดส่วน (%)'),
      ]);
      
      // ข้อมูล
      final totalRevenue = _filteredProducts.fold<double>(0.0, (sum, p) => sum + p['revenue']);
      
      for (var product in _filteredProducts) {
        final percentage = totalRevenue > 0 ? (product['revenue'] / totalRevenue * 100) : 0.0;
        
        // คำนวณ % change
        final previousProduct = _previousProducts.firstWhere(
          (p) => p['name'] == product['name'],
          orElse: () => {'quantity': 0},
        );
        final prevQty = previousProduct['quantity'] as int;
        final currentQty = product['quantity'] as int;
        final change = prevQty > 0 ? ((currentQty - prevQty) / prevQty * 100) : 0.0;
        
        sheet.appendRow([
          excel_lib.TextCellValue(product['name']),
          excel_lib.IntCellValue(product['quantity']),
          excel_lib.DoubleCellValue(change),
          excel_lib.DoubleCellValue(product['price']),
          excel_lib.DoubleCellValue(product['revenue']),
          excel_lib.DoubleCellValue(percentage),
        ]);
      }
      
      // รวมทั้งหมด
      sheet.appendRow([excel_lib.TextCellValue('')]);
      sheet.appendRow([
        excel_lib.TextCellValue('รวมทั้งหมด'),
        excel_lib.IntCellValue(_filteredProducts.fold<int>(0, (sum, p) => sum + (p['quantity'] as int))),
        excel_lib.TextCellValue(''),
        excel_lib.TextCellValue(''),
        excel_lib.DoubleCellValue(totalRevenue),
        excel_lib.DoubleCellValue(100.0),
      ]);
      
      // Generate ไฟล์
      final fileBytes = excel.encode();
      if (fileBytes == null) throw Exception('ไม่สามารถสร้างไฟล์ Excel ได้');
      
      // ชื่อไฟล์
      final safeFileName = dateRange.replaceAll(RegExp(r'[/\\:*?"<>|]'), '_');
      final fileName = 'ProductReport_${widget.restaurantName}_$safeFileName.xlsx';
      
      // บันทึกไฟล์ตาม platform
      if (Platform.isAndroid || Platform.isIOS) {
        // Mobile: ใช้ Share dialog
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/$fileName');
        await tempFile.writeAsBytes(fileBytes);
        
        final result = await Share.shareXFiles(
          [XFile(tempFile.path)],
          subject: 'รายงานสินค้า - ${widget.restaurantName}',
          text: 'รายงานสินค้า $dateRange',
        );
        
        if (mounted) {
          if (result.status == ShareResultStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ แชร์ไฟล์สำเร็จ!'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('ℹ️ เลือก "Save to Files" เพื่อบันทึกไฟล์'),
                backgroundColor: Colors.blue,
              ),
            );
          }
        }
      } else {
        // Desktop: บันทึกไป Downloads
        String filePath;
        final userProfile = Platform.environment['USERPROFILE'];
        final home = Platform.environment['HOME'];
        
        if (Platform.isWindows) {
          filePath = '$userProfile\\Downloads\\$fileName';
        } else if (Platform.isMacOS) {
          filePath = '$home/Downloads/$fileName';
        } else if (Platform.isLinux) {
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
                  } else if (Platform.isLinux) {
                    await Process.run('xdg-open', [filePath]);
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
          SnackBar(
            content: Text('❌ เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
