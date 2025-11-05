import 'package:flutter/material.dart';
import 'package:eatscikmitl/const/app_color.dart';

class OrderStatusScreen extends StatefulWidget {
  const OrderStatusScreen({super.key});

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> orders = [
    {
      'orderId': 'ORD001',
      'studentId': '65070001',
      'orderDate': '2024-03-20 14:30',
      'status': 'preparing', // preparing, ready, completed, cancelled
      'totalAmount': 90.0,
      'estimatedTime': '15 นาที',
      'restaurantName': 'ร้านป้าสมใส',
      'restaurantId': 'shop_001',
      'pickupLocation': 'ตึกอาหาร ชั้น 1',
      'items': [
        {
          'foodname': 'ผัดกะเพราไก่',
          'quantity': 2,
          'price': 40,
          'imgUrl': 'assets/images/pad_kra_pao_gai.jpg',
          'specialRequest': 'ไข่ดาวสุกมาก',
          'addOns': [{'name': 'ข้าวเพิ่ม', 'price': 5}]
        }
      ]
    },
    {
      'orderId': 'ORD002',
      'studentId': '65070001',
      'orderDate': '2024-03-20 13:15',
      'status': 'ready',
      'totalAmount': 40.0,
      'estimatedTime': 'พร้อมรับ',
      'restaurantName': 'ข้าวมันไก่ป้าเล็ก',
      'restaurantId': 'shop_003',
      'pickupLocation': 'ตึกอาหาร ชั้น 2',
      'items': [
        {
          'foodname': 'ข้าวมันไก่ต้ม',
          'quantity': 1,
          'price': 40,
          'imgUrl': 'assets/images/khao_man_gai.jpg',
          'specialRequest': '',
          'addOns': []
        }
      ]
    },
    {
      'orderId': 'ORD003',
      'studentId': '65070001',
      'orderDate': '2024-03-20 12:00',
      'status': 'completed',
      'totalAmount': 60.0,
      'estimatedTime': 'เสร็จสิ้น',
      'restaurantName': 'Uncle Coffee',
      'restaurantId': 'shop_005',
      'pickupLocation': 'ตึกอาหาร ชั้น 1',
      'items': [
        {
          'foodname': 'ชาไทยเย็น',
          'quantity': 3,
          'price': 20,
          'imgUrl': 'assets/images/thai_tea.jpg',
          'specialRequest': 'น้ำแข็งเยอะๆ',
          'addOns': []
        }
      ]
    },
    {
      'orderId': 'ORD004',
      'studentId': '65070001',
      'orderDate': '2024-03-19 18:45',
      'status': 'cancelled',
      'totalAmount': 85.0,
      'estimatedTime': 'ยกเลิกแล้ว',
      'restaurantName': 'ร้านป้าสมใส',
      'restaurantId': 'shop_001',
      'pickupLocation': 'ตึกอาหาร ชั้น 1',
      'items': [
        {
          'foodname': 'ผัดไทย',
          'quantity': 1,
          'price': 45,
          'imgUrl': 'assets/images/pad_thai.jpg',
          'specialRequest': 'ไม่ใส่ถั่วงอก',
          'addOns': []
        },
        {
          'foodname': 'ต้มยำกุ้ง',
          'quantity': 1,
          'price': 40,
          'imgUrl': 'assets/images/tom_yum.jpg',
          'specialRequest': '',
          'addOns': []
        }
      ]
    },
  ];

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

  List<Map<String, dynamic>> getOrdersByStatus(String status) {
    return orders.where((order) => order['status'] == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'สถานะคำสั่งซื้อ',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.mainOrange,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: AppColors.mainOrange,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          tabs: const [
            Tab(
              text: 'กำลังเตรียม',
              icon: Icon(Icons.restaurant, size: 20),
            ),
            Tab(
              text: 'พร้อมรับ',
              icon: Icon(Icons.check_circle_outline, size: 20),
            ),
            Tab(
              text: 'เสร็จสิ้น',
              icon: Icon(Icons.done_all, size: 20),
            ),
            Tab(
              text: 'ยกเลิก',
              icon: Icon(Icons.cancel_outlined, size: 20),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList('preparing'),
          _buildOrderList('ready'),
          _buildOrderList('completed'),
          _buildOrderList('cancelled'),
        ],
      ),
    );
  }

  Widget _buildOrderList(String status) {
    List<Map<String, dynamic>> statusOrders = getOrdersByStatus(status);

    if (statusOrders.isEmpty) {
      return _buildEmptyState(status);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: statusOrders.length,
      itemBuilder: (context, index) {
        return _buildOrderCard(statusOrders[index]);
      },
    );
  }

  Widget _buildEmptyState(String status) {
    String message;
    IconData icon;

    switch (status) {
      case 'preparing':
        message = 'ไม่มีคำสั่งซื้อที่กำลังเตรียม';
        icon = Icons.restaurant;
        break;
      case 'ready':
        message = 'ไม่มีคำสั่งซื้อที่พร้อมรับ';
        icon = Icons.check_circle_outline;
        break;
      case 'completed':
        message = 'ไม่มีคำสั่งซื้อที่เสร็จสิ้น';
        icon = Icons.done_all;
        break;
      case 'cancelled':
        message = 'ไม่มีคำสั่งซื้อที่ยกเลิก';
        icon = Icons.cancel_outlined;
        break;
      default:
        message = 'ไม่มีคำสั่งซื้อ';
        icon = Icons.shopping_cart_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header
            _buildOrderHeader(order),
            
            const SizedBox(height: 12),
            
            // Status and Time
            _buildStatusRow(order),
            
            const SizedBox(height: 12),
            
            // Restaurant Info
            _buildRestaurantInfo(order),
            
            const SizedBox(height: 12),
            
            // Order Items
            _buildOrderItems(order),
            
            const SizedBox(height: 12),
            
            // Action Buttons
            _buildActionButtons(order),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader(Map<String, dynamic> order) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'คำสั่งซื้อ #${order['orderId']}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              order['orderDate'],
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        Text(
          '฿${order['totalAmount'].toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.mainOrange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(Map<String, dynamic> order) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (order['status']) {
      case 'preparing':
        statusColor = Colors.orange;
        statusIcon = Icons.restaurant;
        statusText = 'กำลังเตรียม';
        break;
      case 'ready':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'พร้อมรับ';
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusIcon = Icons.done_all;
        statusText = 'เสร็จสิ้น';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'ยกเลิก';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        statusText = 'ไม่ทราบสถานะ';
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                statusIcon,
                size: 16,
                color: statusColor,
              ),
              const SizedBox(width: 4),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        if (order['status'] != 'completed' && order['status'] != 'cancelled')
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  order['estimatedTime'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildRestaurantInfo(Map<String, dynamic> order) {
    return Row(
      children: [
        Icon(
          Icons.store,
          size: 16,
          color: AppColors.mainOrange,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            order['restaurantName'],
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.mainOrange,
            ),
          ),
        ),
        Icon(
          Icons.location_on,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          order['pickupLocation'],
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItems(Map<String, dynamic> order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'รายการอาหาร:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        ...order['items'].map<Widget>((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: item['imgUrl'].isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset(
                            item['imgUrl'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.fastfood,
                                color: Colors.grey[400],
                                size: 16,
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.fastfood,
                          color: Colors.grey[400],
                          size: 16,
                        ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['foodname'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (item['specialRequest'].isNotEmpty)
                        Text(
                          'หมายเหตุ: ${item['specialRequest']}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      if (item['addOns'].isNotEmpty)
                        ...item['addOns'].map<Widget>((addon) {
                          return Text(
                            '+ ${addon['name']}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
                Text(
                  '×${item['quantity']}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> order) {
    switch (order['status']) {
      case 'preparing':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _cancelOrder(order['orderId']),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text(
                  'ยกเลิกคำสั่งซื้อ',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
        );
      case 'ready':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _confirmPickup(order['orderId']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text(
                  'ยืนยันการรับ',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _viewOrderDetails(order),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.mainOrange),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: Text(
                  'ดูรายละเอียด',
                  style: TextStyle(color: AppColors.mainOrange),
                ),
              ),
            ),
          ],
        );
      case 'completed':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _reorder(order),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.mainOrange),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: Text(
                  'สั่งซื้อซ้ำ',
                  style: TextStyle(color: AppColors.mainOrange),
                ),
              ),
            ),
          ],
        );
      case 'cancelled':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _reorder(order),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.mainOrange),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: Text(
                  'สั่งซื้อซ้ำ',
                  style: TextStyle(color: AppColors.mainOrange),
                ),
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _cancelOrder(String orderId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ยกเลิกคำสั่งซื้อ'),
          content: const Text('คุณต้องการยกเลิกคำสั่งซื้อนี้ใช่หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  int index = orders.indexWhere((order) => order['orderId'] == orderId);
                  if (index != -1) {
                    orders[index]['status'] = 'cancelled';
                  }
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ยกเลิกคำสั่งซื้อแล้ว'),
                  ),
                );
              },
              child: const Text(
                'ยืนยันยกเลิก',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmPickup(String orderId) {
    setState(() {
      int index = orders.indexWhere((order) => order['orderId'] == orderId);
      if (index != -1) {
        orders[index]['status'] = 'completed';
        orders[index]['estimatedTime'] = 'เสร็จสิ้น';
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ยืนยันการรับอาหารแล้ว'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _viewOrderDetails(Map<String, dynamic> order) {
    print('View details for order: ${order['orderId']}');
    // Navigate to order details screen
  }

  void _reorder(Map<String, dynamic> order) {
    print('Reorder: ${order['orderId']}');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('เพิ่มรายการลงตะกร้าแล้ว'),
      ),
    );
  }

  

}