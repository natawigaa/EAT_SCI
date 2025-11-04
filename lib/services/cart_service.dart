import 'package:flutter/foundation.dart';

/// Service สำหรับจัดการตะกร้าสินค้า (Cart)
/// ใช้ Singleton Pattern เพื่อแชร์ข้อมูลระหว่างหน้าต่างๆ
class CartService {
  // Singleton instance
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  // รายการสินค้าในตะกร้า
  final List<Map<String, dynamic>> _cartItems = [];
  
  // ValueNotifier สำหรับแจ้งเตือนการเปลี่ยนแปลง
  final ValueNotifier<int> cartUpdateNotifier = ValueNotifier<int>(0);

  /// ดึงรายการสินค้าทั้งหมดในตะกร้า
  List<Map<String, dynamic>> get cartItems => List.unmodifiable(_cartItems);

  /// จำนวนรายการในตะกร้า
  int get totalItems => _cartItems.fold(0, (sum, item) => sum + (item['quantity'] as int));

  /// ยอดรวมทั้งหมด
  double get totalAmount {
    return _cartItems.fold(0.0, (sum, item) {
      double itemTotal = (item['price'] * item['quantity']).toDouble();
      // Add add-ons price
      if (item['addOns'] != null) {
        for (var addon in item['addOns']) {
          itemTotal += addon['price'] * item['quantity'];
        }
      }
      return sum + itemTotal;
    });
  }

  /// ดึงชื่อร้านปัจจุบันในตะกร้า (ถ้ามี)
  String? get currentRestaurantName {
    if (_cartItems.isEmpty) return null;
    return _cartItems.first['restaurantName'];
  }

  /// ดึง ID ร้านปัจจุบันในตะกร้า (ถ้ามี)
  String? get currentRestaurantId {
    if (_cartItems.isEmpty) return null;
    return _cartItems.first['restaurantId'];
  }

  /// ตรวจสอบว่ามีสินค้าจากร้านอื่นในตะกร้าหรือไม่
  bool hasItemsFromDifferentRestaurant(String restaurantId) {
    if (_cartItems.isEmpty) return false;
    return currentRestaurantId != restaurantId;
  }

  /// เพิ่มรายการลงตะกร้า
  void addToCart(Map<String, dynamic> menuItem, String restaurantId, String restaurantName) {
    // ตรวจสอบว่ามีรายการนี้อยู่แล้วหรือไม่
    final existingIndex = _cartItems.indexWhere(
      (item) => item['itemId'] == menuItem['id'] && item['restaurantId'] == restaurantId,
    );

    if (existingIndex != -1) {
      // ถ้ามีอยู่แล้ว เพิ่มจำนวน
      _cartItems[existingIndex]['quantity']++;
      print('🔄 เพิ่มจำนวน ${_cartItems[existingIndex]['foodname']} เป็น ${_cartItems[existingIndex]['quantity']}');
    } else {
      // ถ้ายังไม่มี เพิ่มรายการใหม่
      _cartItems.add({
        'studentId': '65070001', // TODO: ดึงจาก user ที่ล็อกอินจริง
        'itemId': menuItem['id'],
        'restaurantName': restaurantName,
        'restaurantId': restaurantId,
        'imgUrl': menuItem['image_url'] ?? '',
        'foodname': menuItem['name'] ?? 'ไม่มีชื่อ',
        'price': menuItem['price'] ?? 0.0,
        'quantity': 1,
        'specialRequest': '',
        'addOns': [],
      });
      print('✅ เพิ่มรายการใหม่: ${menuItem['name']} (฿${menuItem['price']})');
    }

    print('🛒 ตะกร้าตอนนี้มี ${_cartItems.length} รายการ | รวม $totalItems ชิ้น | ยอดรวม ฿$totalAmount');
    
    // แจ้งเตือนการเปลี่ยนแปลง
    cartUpdateNotifier.value++;
  }

  /// ลบรายการออกจากตะกร้า
  void removeFromCart(int index) {
    if (index >= 0 && index < _cartItems.length) {
      final removedItem = _cartItems.removeAt(index);
      print('🗑️ ลบ ${removedItem['foodname']} ออกจากตะกร้า');
      cartUpdateNotifier.value++; // แจ้งเตือนการเปลี่ยนแปลง
    }
  }

  /// เพิ่มจำนวนสินค้า
  void increaseQuantity(int index) {
    if (index >= 0 && index < _cartItems.length) {
      _cartItems[index]['quantity']++;
      print('➕ เพิ่มจำนวน ${_cartItems[index]['foodname']} เป็น ${_cartItems[index]['quantity']}');
      cartUpdateNotifier.value++; // แจ้งเตือนการเปลี่ยนแปลง
    }
  }

  /// ลดจำนวนสินค้า
  void decreaseQuantity(int index) {
    if (index >= 0 && index < _cartItems.length) {
      if (_cartItems[index]['quantity'] > 1) {
        _cartItems[index]['quantity']--;
        print('➖ ลดจำนวน ${_cartItems[index]['foodname']} เป็น ${_cartItems[index]['quantity']}');
        cartUpdateNotifier.value++; // แจ้งเตือนการเปลี่ยนแปลง
      } else {
        // ถ้าเหลือ 1 ให้ลบออกเลย
        removeFromCart(index);
      }
    }
  }

  /// ล้างตะกร้าทั้งหมด
  void clearCart() {
    _cartItems.clear();
    print('🧹 ล้างตะกร้าเรียบร้อย');
    cartUpdateNotifier.value++; // แจ้งเตือนการเปลี่ยนแปลง
  }

  /// อัพเดทคำขอพิเศษ
  void updateSpecialRequest(int index, String request) {
    if (index >= 0 && index < _cartItems.length) {
      _cartItems[index]['specialRequest'] = request;
      print('📝 อัพเดทคำขอพิเศษ: $request');
      cartUpdateNotifier.value++; // แจ้งเตือนการเปลี่ยนแปลง
    }
  }
}
