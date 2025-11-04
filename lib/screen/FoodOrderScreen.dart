import 'package:flutter/material.dart';
import 'package:eatscikmitl/const/app_color.dart';
import 'package:eatscikmitl/services/cart_service.dart';
import 'package:eatscikmitl/innnerScreen/PaymentScreen.dart';
import '../utils/notification_helper.dart';

class FoodOrderScreen extends StatefulWidget {
  const FoodOrderScreen({super.key});

  @override
  State<FoodOrderScreen> createState() => _FoodOrderScreenState();
}

class _FoodOrderScreenState extends State<FoodOrderScreen> {
  final CartService _cartService = CartService();
  
  // เนเธเนเธเนเธญเธกเธนเธฅเธเธฒเธ CartService เนเธ—เธเธเธฒเธฃเน€เธเนเธเน€เธญเธ
  List<Map<String, dynamic>> get cartItems => _cartService.cartItems;
  
  double get totalAmount => _cartService.totalAmount;
  
  int get totalItems => _cartService.totalItems;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'รายการตะกร้า',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _clearAllCart(),
          ),
        ],
      ),
      body: cartItems.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: [
                // Cart Summary
                _buildCartSummary(),
                
                // Cart Items List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      return _buildCartItem(cartItems[index], index);
                    },
                  ),
                ),
                const SizedBox(height: 20,),
                // Bottom Section
                _buildBottomSection(),

              ],
            ),
    );
  }

  Widget _buildCartSummary() {
    final restaurantName = _cartService.currentRestaurantName;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          // เนเธชเธ”เธเธเธทเนเธญเธฃเนเธฒเธเธ—เธตเนเธเธณเธฅเธฑเธเธชเธฑเนเธ
          if (restaurantName != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.mainOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.mainOrange.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.restaurant,
                    size: 16,
                    color: AppColors.mainOrange,
                  ),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      restaurantName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainOrange,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          
          // เธเธณเธเธงเธเนเธฅเธฐเธขเธญเธ”เธฃเธงเธก
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                     'ยอดรวม',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '฿${totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'ยอดรวม',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '฿${totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.mainOrange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, int index) {
    double itemTotalPrice = (item['price'] * item['quantity']).toDouble();
    
    // Calculate add-ons price
    double addOnsPrice = 0;
    for (var addon in item['addOns']) {
      addOnsPrice += addon['price'] * item['quantity'];
    }
    itemTotalPrice += addOnsPrice;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant name
            Row(
              children: [
                const Icon(
                  Icons.restaurant,
                  size: 16,
                  color: AppColors.mainOrange,
                ),
                const SizedBox(width: 4),
                Text(
                  item['restaurantName'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.mainOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                // Food Image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: item['imgUrl'].isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item['imgUrl'],
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                  color: AppColors.mainOrange,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.fastfood,
                                color: Colors.grey[400],
                                size: 24,
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.fastfood,
                          color: Colors.grey[400],
                          size: 24,
                        ),
                ),
                
                const SizedBox(width: 12),
                
                // Food Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['foodname'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '฿${item['price']} จำนวน ${item['quantity']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      
                      // Add-ons
                      if (item['addOns'].isNotEmpty) ...[
                        const SizedBox(height: 4),
                        ...item['addOns'].map<Widget>((addon) {
                          return Text(
                            '+ ${addon['name']} (เธฟ${addon['price']})',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          );
                        }).toList(),
                      ],
                      
                      // Special Request
                      if (item['specialRequest'].isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                           'หมายเหตุ: ${item['specialRequest']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Quantity Controls & Price
                Column(
                  children: [
                    Text(
                      '฿${itemTotalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.mainOrange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => _decreaseQuantity(index),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.remove,
                              size: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${item['quantity']}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _increaseQuantity(index),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: AppColors.mainOrange,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _editItem(index),
                    icon: const Icon(Icons.edit, size: 16),
                     label: const Text('แก้ไข'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _removeItem(index),
                    icon: const Icon(Icons.delete, size: 16),
                      label: const Text('ลบ'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 8),
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

  Widget _buildBottomSection() {
    return SafeArea(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Order Summary
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
                  '฿${totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.mainOrange,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Checkout Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _addMoreItems(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.mainOrange),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'เพิ่มรายการ',
                      style: TextStyle(
                        color: AppColors.mainOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _proceedToCheckout(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mainOrange,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'ชำระเงิน ($totalItems รายการ)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
           'ไม่มีรายการอาหารในตะกร้า',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'กรุณาเลือกอาหารที่ต้องการสั่ง',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mainOrange,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
               'เลือกอาหาร',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Cart management methods
  void _increaseQuantity(int index) {
    setState(() {
      _cartService.increaseQuantity(index);
    });
  }

  void _decreaseQuantity(int index) {
    setState(() {
      _cartService.decreaseQuantity(index);
    });
  }

  void _removeItem(int index) {
    setState(() {
      _cartService.removeFromCart(index);
    });
    
    NotificationHelper.showSuccess(
      context,
      'ลบรายการออกจากตะกร้าแล้ว',
    );
  }

  void _editItem(int index) {
    // Navigate to edit item screen
    print('Edit item: ${cartItems[index]['foodname']}');
    // Navigator.push(context, MaterialPageRoute(...));
  }

  void _clearAllCart() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
         title: const Text('ล้างตะกร้า'),
          content: const Text('คุณต้องการลบรายการทั้งหมดในตะกร้าใช่หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _cartService.clearCart();
                });
                Navigator.of(context).pop();
                NotificationHelper.showSuccess(
                  context,
                  'ลบรายการทั้งหมดแล้ว',
                );
              },
              child: const Text(
                'ลบทั้งหมด',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _addMoreItems() {
    Navigator.pop(context);
  }

  void _proceedToCheckout() {
    if (cartItems.isEmpty) return;
    
    // Navigate to Payment Screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          totalAmount: totalAmount,
          itemCount: totalItems,
          restaurantId: int.parse(_cartService.currentRestaurantId!),
          restaurantName: _cartService.currentRestaurantName!,
        ),
      ),
    );
  }

}
