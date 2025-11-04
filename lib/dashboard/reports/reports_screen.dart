import 'package:flutter/material.dart';
import '../../const/app_color.dart';
import 'tabs/sales_report_tab.dart';
import 'tabs/product_report_tab.dart';
import 'tabs/orders_report_tab.dart';
import 'tabs/analytics_tab.dart';

/// หน้ารายงานหลักที่มี TabBar 4 tabs
/// - ยอดขาย (Sales)
/// - สินค้า (Products)
/// - ออเดอร์ (Orders)
/// - วิเคราะห์ (Analytics)
class ReportsScreen extends StatefulWidget {
  final int restaurantId;
  final String restaurantName;

  const ReportsScreen({
    Key? key,
    required this.restaurantId,
    required this.restaurantName,
  }) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.assessment, size: 28, color: AppColors.mainOrange),
                    const SizedBox(width: 12),
                    Text(
                      'รายงาน',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.restaurantName,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                
                // TabBar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppColors.mainOrange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey[700],
                    labelStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.attach_money, size: 20),
                        text: 'ยอดขาย',
                      ),
                      Tab(
                        icon: Icon(Icons.restaurant_menu, size: 20),
                        text: 'สินค้า',
                      ),
                      Tab(
                        icon: Icon(Icons.receipt_long, size: 20),
                        text: 'ออเดอร์',
                      ),
                      Tab(
                        icon: Icon(Icons.analytics, size: 20),
                        text: 'วิเคราะห์',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                SalesReportTab(
                  restaurantId: widget.restaurantId,
                  restaurantName: widget.restaurantName,
                ),
                ProductReportTab(
                  restaurantId: widget.restaurantId,
                  restaurantName: widget.restaurantName,
                ),
                OrdersReportTab(
                  restaurantId: widget.restaurantId,
                  restaurantName: widget.restaurantName,
                ),
                AnalyticsTab(
                  restaurantId: widget.restaurantId,
                  restaurantName: widget.restaurantName,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
