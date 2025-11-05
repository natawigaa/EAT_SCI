import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;
  
  
  // ดึงข้อมูลร้านอาหารทั้งหมด
  static Future<List<Map<String, dynamic>>> getRestaurants() async {
    try {
      print('📡 กำลังเรียก API...');
      final response = await _client
          .from('restaurants')
          .select()
          .order('id', ascending: true);
      
      print('📊 Response type: ${response.runtimeType}');
      print('📊 Response: $response');
      
      // แปลงเป็น List อย่างปลอดภัย
      final List<Map<String, dynamic>> result = response
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      print('✅ ดึงข้อมูลร้าน ${result.length} ร้าน');
      return result;
          
      print('⚠️ Response ไม่ใช่ List');
      return [];
    } catch (e) {
      print('❌ Error fetching restaurants: $e');
      return [];
    }
  }
  
  // ดึงข้อมูลเมนูอาหารของร้านหนึ่งๆ
  static Future<List<Map<String, dynamic>>> getMenuItems(int restaurantId) async {
    try {
      final response = await _client
          .from('menu_items')
          .select()
          .eq('restaurant_id', restaurantId)
          .order('category', ascending: true);
      
      print('✅ ดึงเมนูอาหาร ${response.length} รายการ');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching menu items: $e');
      return [];
    }
  }
  
  // ดึงข้อมูลร้านและเมนูพร้อมกัน
  static Future<Map<String, dynamic>?> getRestaurantWithMenus(int restaurantId) async {
    try {
      // ดึงข้อมูลร้าน
      final restaurantResponse = await _client
          .from('restaurants')
          .select()
          .eq('id', restaurantId)
          .single();
      
      // ดึงเมนูของร้าน
      final menuResponse = await _client
          .from('menu_items')
          .select()
          .eq('restaurant_id', restaurantId)
          .order('category', ascending: true);
      
      // รวมข้อมูล
      final result = Map<String, dynamic>.from(restaurantResponse);
      result['menu_items'] = menuResponse;
      
      print('✅ ดึงข้อมูลร้าน + เมนู ${menuResponse.length} รายการ');
      return result;
    } catch (e) {
      print('❌ Error fetching restaurant with menus: $e');
      return null;
    }
  }

  /// อ่านข้อมูลร้านและคำนวณสถานะ "is_open" โดยพิจารณาจาก
  /// 1) manual override (is_open_manual + manual_override_expires)
  /// 2) opening_hour / closing_hour (ถ้ามี)
  /// 3) fallback เป็นคอลัมน์ is_open ที่เก็บใน DB
  /// คืนค่าเป็น Map: { is_open: bool, source: 'manual'|'schedule'|'stored', restaurant: {...} }
  static Future<Map<String, dynamic>?> getRestaurantEffectiveIsOpen(int restaurantId) async {
    try {
      final response = await _client
          .from('restaurants')
          .select()
          .eq('id', restaurantId)
          .single();

      if (response == null) return null;
      final restaurant = Map<String, dynamic>.from(response);

      final bool storedIsOpen = restaurant['is_open'] == true;
      final bool isManual = restaurant['is_open_manual'] == true;

      // Manual override: if merchant has toggled manual flag, respect stored is_open
      // Note: Expiry is intentionally ignored here — manual overrides persist
      // until the merchant toggles them again. This implements the chosen
      // behaviour: manual action has precedence over schedule until changed.
      if (isManual) {
        return {
          'is_open': storedIsOpen,
          'source': 'manual',
          'restaurant': restaurant,
        };
      }

      // If opening_hour/closing_hour exist use them (simple hour-based check)
      try {
        if (restaurant.containsKey('opening_hour') && restaurant.containsKey('closing_hour') && restaurant['opening_hour'] != null && restaurant['closing_hour'] != null) {
          final openingRaw = restaurant['opening_hour'];
          final closingRaw = restaurant['closing_hour'];
          final int opening = openingRaw is int ? openingRaw : int.tryParse(openingRaw.toString()) ?? 0;
          final int closing = closingRaw is int ? closingRaw : int.tryParse(closingRaw.toString()) ?? 23;

          final nowLocal = DateTime.now();
          final hour = nowLocal.hour;

          // Support ranges that cross midnight (e.g., open 18, close 2)
          bool isOpenBySchedule;
          if (opening <= closing) {
            isOpenBySchedule = hour >= opening && hour <= closing;
          } else {
            // crosses midnight
            isOpenBySchedule = hour >= opening || hour <= closing;
          }

          return {
            'is_open': isOpenBySchedule,
            'source': 'schedule',
            'restaurant': restaurant,
          };
        }
      } catch (e) {
        print('⚠️ Error computing schedule-based open: $e');
      }

      // Fallback: return stored value
      return {
        'is_open': storedIsOpen,
        'source': 'stored',
        'restaurant': restaurant,
      };
    } catch (e) {
      print('❌ Error fetching restaurant effective is_open: $e');
      return null;
    }
  }

  /// ดึงประวัติการเปลี่ยนสถานะเปิด/ปิดของร้าน
  static Future<List<Map<String, dynamic>>> getRestaurantOpenHistory(int restaurantId, {int limit = 50}) async {
    try {
      final response = await _client
          .from('restaurant_open_history')
          .select()
          .eq('restaurant_id', restaurantId)
          .order('created_at', ascending: false)
          .limit(limit);

      final List<Map<String, dynamic>> rows = List<Map<String, dynamic>>.from(response);
      print('✅ ดึงประวัติการเปลี่ยนสถานะร้าน $restaurantId: ${rows.length} รายการ');
      return rows;
    } catch (e) {
      print('❌ Error fetching restaurant open history: $e');
      return [];
    }
  }
  
  // ค้นหาร้านอาหารตามชื่อ
  static Future<List<Map<String, dynamic>>> searchRestaurants(String query) async {
    try {
      final response = await _client
          .from('restaurants')
          .select()
          .ilike('name', '%$query%')
          .order('rating', ascending: false);
      
      print('✅ ค้นหาพบ ${response.length} ร้าน');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error searching restaurants: $e');
      return [];
    }
  }
  
  // ทดสอบการเชื่อมต่อด้วยการดึงข้อมูล
  static Future<void> testConnection() async {
    try {
      final restaurants = await getRestaurants();
      print('🔗 Supabase Connection Test: ${restaurants.length} restaurants found');
      
      // แสดงรายละเอียดแต่ละร้าน
      print('🏪 Restaurant List:');
      for (var restaurant in restaurants) {
        print('  - ID:${restaurant['id']} ${restaurant['name']} (${restaurant['category']}) ⭐${restaurant['rating']}');
      }
      
      // ทดสอบดึงเมนูของร้านแรก
      if (restaurants.isNotEmpty) {
        final firstRestaurantId = restaurants[0]['id'];
        final menuItems = await getMenuItems(firstRestaurantId);
        print('\n🍽️ ${restaurants[0]['name']} has ${menuItems.length} menu items:');
        for (var menu in menuItems.take(3)) {
          print('  - ${menu['name']}: ฿${menu['price']} (${menu['category']})');
        }
        if (menuItems.length > 3) {
          print('  ... and ${menuItems.length - 3} more items');
        }
      }
      
      print('\n🎉 Database test completed successfully!');
    } catch (e) {
      print('❌ Connection test failed: $e');
    }
  }

  // ========================================
  // Order Management
  // ========================================

  /// สร้าง order ใหม่หลังจากชำระเงินสำเร็จ
  static Future<Map<String, dynamic>?> createOrder({
    required String studentId,
    required int restaurantId,
    required String restaurantName,
    required double totalAmount,
    required int totalItems,
    required List<Map<String, dynamic>> cartItems,
    String? notes,
  }) async {
    try {
      print('📝 กำลังสร้าง order...');
      
      // 1. สร้าง order หลัก
      final orderResponse = await _client
          .from('orders')
          .insert({
            'student_id': studentId,
            'restaurant_id': restaurantId,
            'restaurant_name': restaurantName,
            'total_amount': totalAmount,
            'total_items': totalItems,
            'status': 'pending',
            'payment_method': 'qr_code',
            'notes': notes,
          })
          .select()
          .single();
      
      final orderId = orderResponse['id'];
      print('✅ สร้าง order #$orderId สำเร็จ');

      // 2. สร้าง order_items (ตาม schema จริงใน database)
      final orderItemsData = cartItems.map((item) {
        return {
          'order_id': orderId,
          'food_name': item['foodname'],
          'price': item['price'],
          'quantity': item['quantity'],
          'special_request': item['specialRequest'],
        };
      }).toList();

      await _client
          .from('order_items')
          .insert(orderItemsData);
      
      print('✅ เพิ่ม ${orderItemsData.length} รายการอาหารสำเร็จ');
      print('🎉 สร้าง order สำเร็จ! Order ID: $orderId');

      return orderResponse;
    } catch (e) {
      print('❌ Error creating order: $e');
      return null;
    }
  }

  /// ดึง orders ของนักศึกษา
  static Future<List<Map<String, dynamic>>> getStudentOrders(String studentId) async {
    try {
      final response = await _client
          .from('orders')
          .select()
          .eq('student_id', studentId)
          .order('created_at', ascending: false);
      
      print('✅ ดึง orders ${response.length} รายการ');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching student orders: $e');
      return [];
    }
  }

  /// ดึง order_items ของ order หนึ่งๆ
  static Future<List<Map<String, dynamic>>> getOrderItems(int orderId) async {
    try {
      final response = await _client
          .from('order_items')
          .select()
          .eq('order_id', orderId)
          .order('created_at', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching order items: $e');
      return [];
    }
  }

  /// อัพเดทสถานะ order (Phase 3 - รองรับทั้งร้านค้าและนักศึกษา)
  static Future<bool> updateOrderStatus(int orderId, String newStatus) async {
    try {
      print('🔄 กำลังอัปเดตสถานะ order $orderId → $newStatus');
      
      final now = DateTime.now().toIso8601String();
      final updateData = <String, dynamic>{
        'status': newStatus,
      };
      
      // เพิ่ม timestamp ตามสถานะ
      switch (newStatus) {
        case 'confirmed':
          updateData['confirmed_at'] = now;
          break;
        case 'preparing':
          updateData['preparing_at'] = now;
          break;
        case 'ready':
          updateData['ready_at'] = now;
          break;
        case 'completed':
          updateData['completed_at'] = now;
          break;
        case 'cancelled':
          updateData['cancelled_at'] = now;
          break;
      }
      
      await _client
          .from('orders')
          .update(updateData)
          .eq('id', orderId);
      
      print('✅ อัปเดตสถานะสำเร็จ: Order #$orderId → $newStatus');
      return true;
    } catch (e) {
      print('❌ Error updating order status: $e');
      return false;
    }
  }

  /// ปฏิเสธ order พร้อมระบุเหตุผล (Phase 3)
  static Future<bool> cancelOrder(int orderId, String reason) async {
    try {
      print('🚫 กำลังยกเลิก order $orderId');
      print('📝 เหตุผล: $reason');
      
      await _client
          .from('orders')
          .update({
            'status': 'cancelled',
            'cancellation_reason': reason,
            'cancelled_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);
      
      print('✅ ยกเลิก order สำเร็จ: Order #$orderId');
      return true;
    } catch (e) {
      print('❌ Error cancelling order: $e');
      return false;
    }
  }

  // ========================================
  // Phase 4: Student Order Tracking
  // ========================================

  /// ดึง orders ที่กำลังดำเนินการของนักศึกษา (Phase 4)
  static Future<List<Map<String, dynamic>>> getStudentActiveOrders(String studentId) async {
    try {
      print('📦 กำลังดึง active orders ของ student $studentId...');
      print('🔍 Query: student_id = $studentId, status NOT IN (completed, cancelled)');
      
      // ดึง orders ที่ยังไม่เสร็จสมบูรณ์ (pending, confirmed, preparing, ready)
      final ordersResponse = await _client
          .from('orders')
          .select('*, order_items(*), restaurants!orders_restaurant_id_fkey(name)')
          .eq('student_id', studentId)
          .inFilter('status', ['pending', 'confirmed', 'preparing', 'ready'])
          .order('created_at', ascending: false);
      
      print('📊 Query result: ${ordersResponse.length} orders');
      
      final List<Map<String, dynamic>> orders = List<Map<String, dynamic>>.from(ordersResponse);
      
      // แปลง order_items และดึงชื่อร้าน
      for (var order in orders) {
        final orderItems = order['order_items'] as List? ?? [];
        
        // แปลงข้อมูล order_items
        final items = orderItems.map((item) {
          return {
            ...item,
            'menu_name': item['food_name'] ?? 'Unknown',
            'price': item['price'] ?? 0,
            'quantity': item['quantity'] ?? 1,
          };
        }).toList();
        
        order['items'] = items;
        order.remove('order_items');
        
        // ดึงชื่อร้าน
        if (order['restaurants'] != null) {
          order['restaurant_name'] = order['restaurants']['name'];
        }
        order.remove('restaurants');
        
        // แปลง payment slip URL เป็น signed URL
        if (order['payment_slip_url'] != null) {
          final oldUrl = order['payment_slip_url'] as String;
          if (oldUrl.contains('/payment-slips/')) {
            final fileName = oldUrl.split('/payment-slips/').last.split('?').first;
            try {
              final signedUrl = await _client.storage
                  .from('payment-slips')
                  .createSignedUrl(fileName, 60 * 60 * 24 * 365);
              order['payment_slip_url'] = signedUrl;
            } catch (e) {
              print('⚠️ ไม่สามารถสร้าง signed URL: $e');
            }
          }
        }
      }
      
      print('✅ ดึง ${orders.length} active orders สำเร็จ');
      return orders;
    } catch (e) {
      print('❌ Error fetching student active orders: $e');
      rethrow;
    }
  }

  /// ดึง orders ที่พร้อมรับของนักศึกษา (status = ready) - Phase 6
  static Future<List<Map<String, dynamic>>> getReadyOrders(String studentId) async {
    try {
      print('📦 กำลังดึง ready orders ของ student $studentId...');
      
      final ordersResponse = await _client
          .from('orders')
          .select('*, order_items(*), restaurants!orders_restaurant_id_fkey(name)')
          .eq('student_id', studentId)
          .eq('status', 'ready')
          .order('updated_at', ascending: false);
      
      final List<Map<String, dynamic>> orders = List<Map<String, dynamic>>.from(ordersResponse);
      
      // แปลงข้อมูลเหมือน getStudentActiveOrders
      for (var order in orders) {
        final orderItems = order['order_items'] as List? ?? [];
        
        final items = orderItems.map((item) {
          return {
            ...item,
            'menu_name': item['food_name'] ?? 'Unknown',
            'price': item['price'] ?? 0,
            'quantity': item['quantity'] ?? 1,
          };
        }).toList();
        
        order['items'] = items;
        order.remove('order_items');
        
        if (order['restaurants'] != null) {
          order['restaurant_name'] = order['restaurants']['name'];
        }
        order.remove('restaurants');
        
        // แปลง payment slip URL
        if (order['payment_slip_url'] != null) {
          final oldUrl = order['payment_slip_url'] as String;
          if (oldUrl.contains('/payment-slips/')) {
            final fileName = oldUrl.split('/payment-slips/').last.split('?').first;
            try {
              final signedUrl = await _client.storage
                  .from('payment-slips')
                  .createSignedUrl(fileName, 60 * 60 * 24 * 365);
              order['payment_slip_url'] = signedUrl;
            } catch (e) {
              print('⚠️ ไม่สามารถสร้าง signed URL: $e');
            }
          }
        }
      }
      
      print('✅ ดึง ${orders.length} ready orders สำเร็จ');
      return orders;
    } catch (e) {
      print('❌ Error fetching ready orders: $e');
      rethrow;
    }
  }

  /// ดึง orders ที่สถานะ completed ของนักศึกษา (ทั้งหมด)
  static Future<List<Map<String, dynamic>>> getCompletedOrders(String studentId) async {
    try {
      print('📦 กำลังดึง completed orders ของ student $studentId...');

      final ordersResponse = await _client
          .from('orders')
          .select('*, order_items(*), restaurants!orders_restaurant_id_fkey(name)')
          .eq('student_id', studentId)
          .eq('status', 'completed')
          .order('completed_at', ascending: false);

      final List<Map<String, dynamic>> orders = List<Map<String, dynamic>>.from(ordersResponse);

      // แปลงข้อมูลเหมือน getReadyOrders
      for (var order in orders) {
        final orderItems = order['order_items'] as List? ?? [];

        final items = orderItems.map((item) {
          return {
            ...item,
            'menu_name': item['food_name'] ?? 'Unknown',
            'price': item['price'] ?? 0,
            'quantity': item['quantity'] ?? 1,
          };
        }).toList();

        order['items'] = items;
        order.remove('order_items');

        if (order['restaurants'] != null) {
          order['restaurant_name'] = order['restaurants']['name'];
        }
        order.remove('restaurants');

        // แปลง payment slip URL
        if (order['payment_slip_url'] != null) {
          final oldUrl = order['payment_slip_url'] as String;
          if (oldUrl.contains('/payment-slips/')) {
            final fileName = oldUrl.split('/payment-slips/').last.split('?').first;
            try {
              final signedUrl = await _client.storage
                  .from('payment-slips')
                  .createSignedUrl(fileName, 60 * 60 * 24 * 365);
              order['payment_slip_url'] = signedUrl;
            } catch (e) {
              print('⚠️ ไม่สามารถสร้าง signed URL: $e');
            }
          }
        }
      }

      print('✅ ดึง ${orders.length} completed orders สำเร็จ');
      return orders;
    } catch (e) {
      print('❌ Error fetching completed orders: $e');
      return [];
    }
  }

  /// ดึงประวัติการสั่งซื้อ 7 วันย้อนหลัง (status = completed) - Phase 6
  static Future<List<Map<String, dynamic>>> getOrderHistory(String studentId, {int days = 7}) async {
    try {
      print('📦 กำลังดึงประวัติ orders $days วันย้อนหลังของ student $studentId...');
      
      // คำนวณวันที่ย้อนหลัง
      final DateTime startDate = DateTime.now().subtract(Duration(days: days));
      final String startDateStr = startDate.toIso8601String();
      
      print('📅 ดึงข้อมูลตั้งแต่: $startDateStr');
      
      final ordersResponse = await _client
          .from('orders')
          .select('*, order_items(*), restaurants!orders_restaurant_id_fkey(name)')
          .eq('student_id', studentId)
          .eq('status', 'completed')
          .gte('created_at', startDateStr)
          .order('completed_at', ascending: false);
      
      final List<Map<String, dynamic>> orders = List<Map<String, dynamic>>.from(ordersResponse);
      
      // แปลงข้อมูลเหมือน getStudentActiveOrders
      for (var order in orders) {
        final orderItems = order['order_items'] as List? ?? [];
        
        final items = orderItems.map((item) {
          return {
            ...item,
            'menu_name': item['food_name'] ?? 'Unknown',
            'price': item['price'] ?? 0,
            'quantity': item['quantity'] ?? 1,
          };
        }).toList();
        
        order['items'] = items;
        order.remove('order_items');
        
        if (order['restaurants'] != null) {
          order['restaurant_name'] = order['restaurants']['name'];
        }
        order.remove('restaurants');
        
        // แปลง payment slip URL
        if (order['payment_slip_url'] != null) {
          final oldUrl = order['payment_slip_url'] as String;
          if (oldUrl.contains('/payment-slips/')) {
            final fileName = oldUrl.split('/payment-slips/').last.split('?').first;
            try {
              final signedUrl = await _client.storage
                  .from('payment-slips')
                  .createSignedUrl(fileName, 60 * 60 * 24 * 365);
              order['payment_slip_url'] = signedUrl;
            } catch (e) {
              print('⚠️ ไม่สามารถสร้าง signed URL: $e');
            }
          }
        }
      }
      
      print('✅ ดึง ${orders.length} completed orders ใน $days วันย้อนหลังสำเร็จ');
      return orders;
    } catch (e) {
      print('❌ Error fetching order history: $e');
      rethrow;
    }
  }

  /// อัปเดตสถานะ order เป็น completed เมื่อนักศึกษารับอาหาร - Phase 6
  static Future<bool> markOrderAsCompleted(int orderId) async {
    try {
      print('✅ กำลังอัปเดต order #$orderId เป็น completed...');
      
      final response = await _client
          .from('orders')
          .update({
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId)
          .select();
      
      if (response.isNotEmpty) {
        print('✅ อัปเดตสถานะเป็น completed สำเร็จ');
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ Error marking order as completed: $e');
      return false;
    }
  }

  /// ตั้งค่า Realtime subscription สำหรับ orders ของนักศึกษา (Phase 4)
  static RealtimeChannel setupStudentOrdersSubscription(
    String studentId, {
    required Function(Map<String, dynamic>) onOrderUpdate,
  }) {
    print('🔔 ตั้งค่า realtime subscription สำหรับ student $studentId');
    
    final channel = _client.channel('student-orders-$studentId');
    
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'student_id',
            value: studentId,
          ),
          callback: (payload) async {
            print('🔔 Student Realtime: order อัปเดต');
            print('📦 Payload: ${payload.newRecord}');
            
            try {
              final orderId = payload.newRecord['id'] as int;
              
              // ดึงข้อมูล order_items
              final itemsResponse = await _client
                  .from('order_items')
                  .select()
                  .eq('order_id', orderId);
              
              // แปลงข้อมูล
              final items = (itemsResponse as List).map((item) {
                return {
                  ...item,
                  'menu_name': item['food_name'] ?? 'Unknown',
                  'price': item['price'] ?? 0,
                  'quantity': item['quantity'] ?? 1,
                };
              }).toList();
              
              final orderData = Map<String, dynamic>.from(payload.newRecord);
              orderData['items'] = items;
              
              // แปลง payment slip URL
              if (orderData['payment_slip_url'] != null) {
                final oldUrl = orderData['payment_slip_url'] as String;
                if (oldUrl.contains('/payment-slips/')) {
                  final fileName = oldUrl.split('/payment-slips/').last.split('?').first;
                  try {
                    final signedUrl = await _client.storage
                        .from('payment-slips')
                        .createSignedUrl(fileName, 60 * 60 * 24 * 365);
                    orderData['payment_slip_url'] = signedUrl;
                  } catch (e) {
                    print('⚠️ Student Realtime: ไม่สามารถสร้าง signed URL: $e');
                  }
                }
              }
              
              print('✅ Student order processed: Order #$orderId → ${orderData['status']}');
              onOrderUpdate(orderData);
            } catch (e) {
              print('❌ Error processing student order update: $e');
            }
          },
        )
        .subscribe((status, error) {
          print('📡 Student subscription status: $status');
          if (error != null) {
            print('❌ Student subscription error: $error');
          }
          if (status == RealtimeSubscribeStatus.subscribed) {
            print('✅ Student realtime subscription สำเร็จ!');
          }
        });
    
    print('📡 Student channel created: student-orders-$studentId');
    return channel;
  }

  // ========================================
  // Restaurant QR Code Functions
  // ========================================

  /// อัปโหลด QR Code ของร้าน
  static Future<String?> uploadRestaurantQrCode(String filePath, int restaurantId) async {
    try {
      final fileName = 'restaurant-$restaurantId-qr.png';
      final storagePath = '$fileName';
      
      print('📤 กำลังอัปโหลด QR Code ร้าน: $storagePath');
      
      // ลบไฟล์เก่า (ถ้ามี)
      try {
        await _client.storage
            .from('restaurant_qrcode')
            .remove([storagePath]);
        print('🗑️ ลบ QR Code เก่า');
      } catch (e) {
        print('⚠️ ไม่มี QR Code เก่า');
      }
      
      // อัปโหลดไฟล์ใหม่ (upsert = true เพื่อบังคับเขียนทับ)
      await _client.storage
          .from('restaurant_qrcode')
          .upload(storagePath, File(filePath), fileOptions: const FileOptions(upsert: true));
      
      // ดึง Public URL พร้อม cache buster (เพิ่ม timestamp เพื่อบังคับโหลดรูปใหม่)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final baseUrl = _client.storage
          .from('restaurant_qrcode')
          .getPublicUrl(storagePath);
      final url = '$baseUrl?t=$timestamp';
      
      print('✅ อัปโหลด QR Code สำเร็จ: $url');
      return url;
    } catch (e) {
      print('❌ Error uploading restaurant QR: $e');
      return null;
    }
  }

  /// อัปโหลดรูปเมนูไปที่ bucket `menu_images` และคืนค่า public URL
  static Future<String?> uploadMenuImage(String filePath, int restaurantId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'restaurant-${restaurantId}-menu-$timestamp.jpg';
      final storagePath = fileName;

      print('📤 กำลังอัปโหลดรูปเมนู: $storagePath');

      // upload (upsert true to overwrite if same name exists)
      await _client.storage
          .from('menu_images')
          .upload(storagePath, File(filePath), fileOptions: const FileOptions(upsert: true));

      final baseUrl = _client.storage.from('menu_images').getPublicUrl(storagePath);
      final url = '$baseUrl?t=$timestamp';
      print('✅ อัปโหลดรูปเมนูสำเร็จ: $url');
      return url;
    } catch (e) {
      print('❌ Error uploading menu image: $e');
      return null;
    }
  }

  /// อัปโหลดรูปโปรไฟล์ร้านไปที่ bucket `profile_images` และคืนค่า public URL
  static Future<String?> uploadRestaurantImage(String filePath, int restaurantId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'restaurant-${restaurantId}-profile-$timestamp.jpg';
      final storagePath = fileName;

      print('📤 กำลังอัปโหลดรูปโปรไฟล์ร้าน: $storagePath');

      await _client.storage
          .from('profile_images')
          .upload(storagePath, File(filePath), fileOptions: const FileOptions(upsert: true));

      final baseUrl = _client.storage.from('profile_images').getPublicUrl(storagePath);
      final url = '$baseUrl?t=$timestamp';
      print('✅ อัปโหลดรูปโปรไฟล์สำเร็จ: $url');
      return url;
    } catch (e) {
      print('❌ Error uploading restaurant profile image: $e');
      return null;
    }
  }

  /// อัปเดตข้อมูลร้าน (name, phone, image_url)
  /// ถ้าต้องการเคี่ยร์ค่า image ให้ส่ง `setImageToNull = true`
  static Future<bool> updateRestaurantDetails(int restaurantId, {String? name, String? phone, String? imageUrl, bool setImageToNull = false}) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (phone != null) updateData['phone'] = phone;
      if (imageUrl != null) updateData['image_url'] = imageUrl;
      if (setImageToNull && imageUrl == null) updateData['image_url'] = null;

      if (updateData.isEmpty) {
        print('⚠️ updateRestaurantDetails called with no changes');
        return true;
      }

      await _client
          .from('restaurants')
          .update(updateData)
          .eq('id', restaurantId);

      print('✅ อัปเดตข้อมูลร้าน #$restaurantId -> $updateData');
      return true;
    } catch (e) {
      print('❌ Error updating restaurant details: $e');
      return false;
    }
  }

  /// สร้างเมนูรายการใหม่ในตาราง `menu_items`
  static Future<Map<String, dynamic>?> createMenuItem(Map<String, dynamic> data) async {
    try {
      print('📤 createMenuItem payload: $data');
      final response = await _client
          .from('menu_items')
          .insert(data)
          .select()
          .single();

      print('✅ สร้างเมนูใหม่สำเร็จ: ${response['id']}');
      return Map<String, dynamic>.from(response);
    } catch (e, st) {
      print('❌ Error creating menu item: $e');
      print('🔎 StackTrace: $st');
      // If PostgrestException-like object contains more fields, they will
      // appear in the printed error. Return null to indicate failure.
      return null;
    }
  }

  /// อัปเดตเมนู (partial update supported)
  static Future<bool> updateMenuItem(int menuItemId, Map<String, dynamic> updateData) async {
    try {
      print('📤 updateMenuItem id=$menuItemId payload: $updateData');
      await _client
          .from('menu_items')
          .update(updateData)
          .eq('id', menuItemId);

      print('✅ อัปเดตเมนู #$menuItemId สำเร็จ');
      return true;
    } catch (e, st) {
      print('❌ Error updating menu item: $e');
      print('🔎 StackTrace: $st');
      return false;
    }
  }

  /// ลบเมนู
  static Future<bool> deleteMenuItem(int menuItemId) async {
    try {
      print('🗑️ deleteMenuItem id=$menuItemId');
      await _client
          .from('menu_items')
          .delete()
          .eq('id', menuItemId);

      print('✅ ลบเมนู #$menuItemId สำเร็จ');
      return true;
    } catch (e, st) {
      print('❌ Error deleting menu item: $e');
      print('🔎 StackTrace: $st');
      return false;
    }
  }

  /// อัปเดต QR Code URL ใน restaurants table
  static Future<bool> updateRestaurantQrCode(int restaurantId, String? qrCodeUrl) async {
    try {
      await _client
          .from('restaurants')
          .update({'qr_code_url': qrCodeUrl})
          .eq('id', restaurantId);
      
      print('✅ อัปเดต QR Code URL ร้าน #$restaurantId');
      return true;
    } catch (e) {
      print('❌ Error updating restaurant QR URL: $e');
      return false;
    }
  }

  /// อัปเดตสถานะเปิด/ปิดของร้าน (is_open)
  /// ถ้า isManual = true แปลว่าผู้ใช้กดเปลี่ยนสถานะด้วยตนเอง (manual override)
  static Future<bool> updateRestaurantIsOpen(int restaurantId, bool isOpen, {bool isManual = true, DateTime? expires}) async {
    try {
      final updateData = <String, dynamic>{
        'is_open': isOpen,
      };

  // เก็บ flag ว่าเป็น manual override
  updateData['is_open_manual'] = isManual;
  // NOTE: expiry support has been disabled by project decision: manual
  // overrides persist until explicitly changed by the merchant. The
  // `manual_override_expires` column was removed by migration, so we do
  // not attempt to write it here.

      await _client
          .from('restaurants')
          .update(updateData)
          .eq('id', restaurantId);

      print('✅ อัปเดต is_open ของร้าน #$restaurantId -> $isOpen (manual=$isManual)');

      // เขียนประวัติการเปลี่ยนแปลงลงตาราง restaurant_open_history (ถ้ามี)
      try {
        await _client.from('restaurant_open_history').insert({
          'restaurant_id': restaurantId,
          'is_open': isOpen,
          'source': isManual ? 'manual' : 'system',
          'changed_by': _client.auth.currentUser?.id,
          'expires_at': null,
        });
        print('📝 บันทึกประวัติการเปลี่ยนแปลงสถานะร้านใน restaurant_open_history');
      } catch (e) {
        // ไม่ต้องล้มถ้า insert audit ล้ม — ปรับ log เท่านั้น
        print('⚠️ ไม่สามารถบันทึกประวัติการเปลี่ยนแปลงสถานะร้าน: $e');
      }
      return true;
    } catch (e) {
      print('❌ Error updating restaurant is_open: $e');
      return false;
    }
  }

  /// อัปเดต opening_hour และ closing_hour ในตาราง restaurants
  static Future<bool> updateRestaurantHours(int restaurantId, int? openingHour, int? closingHour) async {
    try {
      final updateData = <String, dynamic>{};
      if (openingHour != null) updateData['opening_hour'] = openingHour;
      else updateData['opening_hour'] = null;
      if (closingHour != null) updateData['closing_hour'] = closingHour;
      else updateData['closing_hour'] = null;

      await _client
          .from('restaurants')
          .update(updateData)
          .eq('id', restaurantId);

      print('✅ อัปเดต opening_hour/closing_hour สำหรับร้าน #$restaurantId -> $openingHour..$closingHour');
      return true;
    } catch (e) {
      print('❌ Error updating restaurant hours: $e');
      return false;
    }
  }

  // ========================================
  // Payment Slip Functions
  // ========================================

  /// ร้านค้ายืนยันสลิป (รับ order)
  static Future<bool> confirmOrderSlip(int orderId, String restaurantOwnerId) async {
    try {
      await _client
          .from('orders')
          .update({
            'status': 'confirmed',
            'slip_verified_by': restaurantOwnerId,
            'slip_verified_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);
      
      print('✅ ร้านยืนยันสลิป order #$orderId');
      return true;
    } catch (e) {
      print('❌ Error confirming slip: $e');
      return false;
    }
  }

  /// ร้านค้าปฏิเสธสลิป (ยกเลิก order)
  static Future<bool> rejectOrderSlip(int orderId, String reason) async {
    try {
      await _client
          .from('orders')
          .update({
            'status': 'cancelled',
            'rejection_reason': reason,
            'cancelled_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);
      
      print('✅ ร้านปฏิเสธสลิป order #$orderId: $reason');
      return true;
    } catch (e) {
      print('❌ Error rejecting slip: $e');
      return false;
    }
  }

  /// ดึง orders ที่รอตรวจสลิปของร้าน
  static Future<List<Map<String, dynamic>>> getPendingSlipOrders(int restaurantId) async {
    try {
      final response = await _client
          .from('orders')
          .select()
          .eq('restaurant_id', restaurantId)
          .eq('status', 'pending')
          .not('payment_slip_url', 'is', null)
          .order('slip_uploaded_at', ascending: true);
      
      print('✅ ดึง orders รอตรวจสลิป ${response.length} รายการ');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching pending slip orders: $e');
      return [];
    }
  }

  // ========================================
  // Student Profile Management
  // ========================================

  /// ดึงข้อมูลโปรไฟล์นักศึกษา
  static Future<Map<String, dynamic>?> getStudentProfile(String userId) async {
    try {
      final response = await _client
          .from('students')
          .select()
          .eq('id', userId)
          .single();
      
      print('✅ ดึงข้อมูลโปรไฟล์สำเร็จ');
      return response;
    } catch (e) {
      print('❌ Error fetching student profile: $e');
      return null;
    }
  }

  /// อัปเดตข้อมูลโปรไฟล์ (username, phone, ชื่อ-นามสกุล เป็นต้น)
  /// หมายเหตุ: คณะตายตัว = วิทยาศาสตร์, ไม่มีข้อมูลสาขา
  static Future<bool> updateStudentProfile({
    required String userId,
    String? username,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
    int? year,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (username != null) updateData['username'] = username;
      if (firstName != null) updateData['first_name'] = firstName;
      if (lastName != null) updateData['last_name'] = lastName;
      if (email != null) updateData['email'] = email;
      if (phoneNumber != null) updateData['phone_number'] = phoneNumber;
      if (profileImageUrl != null) updateData['profile_image_url'] = profileImageUrl;
      if (year != null) updateData['year'] = year;
      
      await _client
          .from('students')
          .update(updateData)
          .eq('id', userId);
      
      print('✅ อัปเดตโปรไฟล์สำเร็จ');
      return true;
    } catch (e) {
      print('❌ Error updating student profile: $e');
      return false;
    }
  }

  /// อัปโหลดรูปโปรไฟล์
  static Future<String?> uploadProfileImage(String filePath, String userId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$userId/profile-$timestamp.jpg';
      
      print('📤 กำลังอัปโหลดรูปโปรไฟล์: $fileName');
      
      // ลบรูปเก่า (ถ้ามี)
      try {
        final oldFiles = await _client.storage
            .from('student_profile_images')
            .list(path: userId);
        
        for (var file in oldFiles) {
          await _client.storage
              .from('student_profile_images')
              .remove(['$userId/${file.name}']);
        }
        print('🗑️ ลบรูปเก่าแล้ว');
      } catch (e) {
        print('⚠️ ไม่มีรูปเก่า หรือลบไม่สำเร็จ: $e');
      }
      
      // อัปโหลดรูปใหม่
      await _client.storage
          .from('student_profile_images')
          .upload(fileName, File(filePath));
      
      // ดึง Public URL
      final url = _client.storage
          .from('student_profile_images')
          .getPublicUrl(fileName);
      
      print('✅ อัปโหลดรูปโปรไฟล์สำเร็จ: $url');
      return url;
    } catch (e) {
      print('❌ Error uploading profile image: $e');
      return null;
    }
  }

  /// ลบรูปโปรไฟล์
  static Future<bool> deleteProfileImage(String userId) async {
    try {
      final files = await _client.storage
          .from('student_profile_images')
          .list(path: userId);
      
      for (var file in files) {
        await _client.storage
            .from('student_profile_images')
            .remove(['$userId/${file.name}']);
      }
      
      print('✅ ลบรูปโปรไฟล์สำเร็จ');
      return true;
    } catch (e) {
      print('❌ Error deleting profile image: $e');
      return false;
    }
  }

  // ========================================
  // Orders Management
  // ========================================

  /// อัปโหลด payment slip ไป Supabase Storage
  static Future<String?> uploadPaymentSlip(String filePath, int orderId) async {
    try {
      // เช็คว่า user login แล้วหรือยัง
      final user = _client.auth.currentUser;
      if (user == null) {
        print('❌ User not logged in! Cannot upload slip.');
        return null;
      }
      
      print('👤 Current user: ${user.email} (${user.id})');
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'order_slips/order_${orderId}_$timestamp.jpg';
      
      print('📤 อัปโหลดสลิป: $fileName');
      print('📂 Bucket: payment-slips');
      print('📁 File path: $filePath');
      
      // อัปโหลดไฟล์
      final uploadResult = await _client.storage
          .from('payment-slips')
          .upload(fileName, File(filePath), fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: false,
          ));
      
      print('✅ Upload result: $uploadResult');
      
      // สร้าง Signed URL สำหรับ private bucket (อายุ 1 ปี)
      final url = await _client.storage
          .from('payment-slips')
          .createSignedUrl(fileName, 60 * 60 * 24 * 365); // 1 year
      
      print('✅ อัปโหลดสลิปสำเร็จ: $url');
      return url;
    } catch (e) {
      print('❌ Error uploading payment slip: $e');
      return null;
    }
  }

  /// อัปเดต order พร้อม slip URL
  static Future<bool> updateOrderWithSlip(int orderId, String slipUrl) async {
    try {
      print('📝 อัปเดต order $orderId ด้วย slip URL');
      
      await _client.from('orders').update({
        'payment_slip_url': slipUrl,
        'slip_uploaded_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);
      
      print('✅ อัปเดต order สำเร็จ');
      return true;
    } catch (e) {
      print('❌ Error updating order with slip: $e');
      return false;
    }
  }

  /// ดึงรายการ orders ของร้านอาหาร (สำหรับร้านค้า)
  static Future<List<Map<String, dynamic>>> getRestaurantOrders(int restaurantId) async {
    try {
      print('📦 กำลังดึง orders ของร้าน $restaurantId (ยกเว้น ready และ completed)...');
      
      // ดึงเฉพาะ orders ที่ร้านยังต้องทำงาน (ไม่รวม ready และ completed)
      // เมื่อร้านกด "พร้อมรับ" = หมดหน้าที่แล้ว → หายจากหน้านี้
      // ใช้ JOIN กับ students เพื่อดึงเบอร์โทร (ต้องมี foreign key constraint)
      final ordersResponse = await _client
          .from('orders')
          .select('*, order_items(*), students!student_id(phone_number)')
          .eq('restaurant_id', restaurantId)
          .inFilter('status', ['pending', 'confirmed', 'preparing']) // เฉพาะ status ที่ยังต้องทำงาน
          .order('created_at', ascending: false);
      
      final List<Map<String, dynamic>> orders = List<Map<String, dynamic>>.from(ordersResponse);
      
      // แปลง order_items เป็น items array และแปลง payment slip URL
      for (var order in orders) {
        final orderItems = order['order_items'] as List? ?? [];
        
        // แปลงข้อมูล order_items และใช้ food_name ที่มีอยู่แล้ว
        final items = orderItems.map((item) {
          return {
            ...item,
            'menu_name': item['food_name'] ?? 'Unknown', // ใช้ food_name แทน
            'price': item['price'] ?? 0,
            'quantity': item['quantity'] ?? 1,
          };
        }).toList();
        
        order['items'] = items;
        order.remove('order_items'); // ลบ key เดิม
        
        // ดึงเบอร์โทรจาก JOIN students (same pattern as getAllRestaurantOrders)
        if (order['students'] != null && order['students'] is Map) {
          order['customer_phone'] = order['students']['phone_number'];
          print('📞 ดึงเบอร์โทร: ${order['customer_phone']} สำหรับ student ${order['student_id']}');
        }
        order.remove('students'); // ลบ nested object
        
        // แปลง public URL เป็น signed URL สำหรับ private bucket
        if (order['payment_slip_url'] != null) {
          final oldUrl = order['payment_slip_url'] as String;
          // ดึงชื่อไฟล์จาก URL
          if (oldUrl.contains('/payment-slips/')) {
            final fileName = oldUrl.split('/payment-slips/').last.split('?').first;
            print('🔄 แปลง URL สำหรับ: $fileName');
            try {
              final signedUrl = await _client.storage
                  .from('payment-slips')
                  .createSignedUrl(fileName, 60 * 60 * 24 * 365); // 1 year
              order['payment_slip_url'] = signedUrl;
              print('✅ สร้าง signed URL: $signedUrl');
            } catch (e) {
              print('⚠️ ไม่สามารถสร้าง signed URL: $e');
            }
          }
        }
      }
      
      print('✅ ดึง ${orders.length} orders สำเร็จ');
      return orders;
    } catch (e) {
      print('❌ Error fetching restaurant orders: $e');
      rethrow;
    }
  }

  /// ดึง orders ทั้งหมดของร้าน (รวมทุกสถานะ) สำหรับ Reports
  static Future<List<Map<String, dynamic>>> getAllRestaurantOrders(int restaurantId, {bool includeItems = true}) async {
    try {
      print('📊 กำลังดึง orders ทั้งหมดของร้าน $restaurantId (ทุกสถานะยกเว้น cancelled)...');
      
      // ดึง orders ทั้งหมด พร้อม JOIN students เพื่อเอาเบอร์โทร (เร็วกว่าการ query แยก)
      final selectQuery = includeItems 
          ? '*, order_items(*), students!student_id(phone_number)'
          : '*, students!student_id(phone_number)';
      
      final query = _client
          .from('orders')
          .select(selectQuery)
          .eq('restaurant_id', restaurantId)
          .neq('status', 'cancelled')
          .order('created_at', ascending: false);
      
      final ordersResponse = await query;
      final List<Map<String, dynamic>> orders = List<Map<String, dynamic>>.from(ordersResponse);
      
      if (includeItems) {
        // แปลง order_items เป็น items array + ดึงเบอร์โทรจาก students object
        for (var order in orders) {
          final orderItems = order['order_items'] as List? ?? [];
          
          final items = orderItems.map((item) {
            return {
              ...item,
              'menu_name': item['food_name'] ?? 'Unknown',
              'price': item['price'] ?? 0,
              'quantity': item['quantity'] ?? 1,
            };
          }).toList();
          
          order['items'] = items;
          order.remove('order_items');
          
          // ดึงเบอร์โทรจาก students object (ได้จาก JOIN แล้ว - เร็วมาก!)
          if (order['students'] != null && order['students'] is Map) {
            final phoneNumber = order['students']['phone_number'];
            if (phoneNumber != null) {
              order['customer_phone'] = phoneNumber;
              print('✅ เบอร์โทร student ${order['student_id']}: $phoneNumber');
            }
          }
          order.remove('students');
          
          // แปลง payment slip URL
          if (order['payment_slip_url'] != null) {
            final oldUrl = order['payment_slip_url'] as String;
            if (oldUrl.contains('/payment-slips/')) {
              final fileName = oldUrl.split('/payment-slips/').last.split('?').first;
              try {
                final signedUrl = await _client.storage
                    .from('payment-slips')
                    .createSignedUrl(fileName, 60 * 60 * 24 * 365);
                order['payment_slip_url'] = signedUrl;
              } catch (e) {
                print('⚠️ ไม่สามารถสร้าง signed URL: $e');
              }
            }
          }
        }
      }
      
      print('✅ ดึง ${orders.length} orders ทั้งหมด (รวมทุกสถานะ)');
      return orders;
    } catch (e) {
      print('❌ Error fetching all restaurant orders: $e');
      rethrow;
    }
  }

  /// ตั้งค่า Realtime subscription สำหรับ orders ใหม่
  static RealtimeChannel setupOrdersRealtimeSubscription(
    int restaurantId,
    Function(Map<String, dynamic>) onNewOrder,
  ) {
    print('🔔 ตั้งค่า realtime subscription สำหรับร้าน $restaurantId');
    
    final channel = _client.channel('orders-$restaurantId');
    
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'restaurant_id',
            value: restaurantId,
          ),
          callback: (payload) async {
            print('🔔 Realtime: ได้รับ order ใหม่');
            print('📦 Payload: ${payload.newRecord}');
            
            try {
              final orderId = payload.newRecord['id'] as int;
              
              // ดึงข้อมูล order_items (ไม่ต้อง JOIN เพราะมี food_name อยู่แล้ว)
              final itemsResponse = await _client
                  .from('order_items')
                  .select()
                  .eq('order_id', orderId);
              
              // แปลงข้อมูลและใช้ food_name
              final items = (itemsResponse as List).map((item) {
                return {
                  ...item,
                  'menu_name': item['food_name'] ?? 'Unknown', // ใช้ food_name
                  'price': item['price'] ?? 0,
                  'quantity': item['quantity'] ?? 1,
                };
              }).toList();
              
              final orderData = Map<String, dynamic>.from(payload.newRecord);
              orderData['items'] = items;
              
              // แปลง payment slip URL เป็น signed URL
              if (orderData['payment_slip_url'] != null) {
                final oldUrl = orderData['payment_slip_url'] as String;
                if (oldUrl.contains('/payment-slips/')) {
                  final fileName = oldUrl.split('/payment-slips/').last.split('?').first;
                  print('🔄 Realtime: แปลง URL สำหรับ: $fileName');
                  try {
                    final signedUrl = await _client.storage
                        .from('payment-slips')
                        .createSignedUrl(fileName, 60 * 60 * 24 * 365);
                    orderData['payment_slip_url'] = signedUrl;
                    print('✅ Realtime: สร้าง signed URL');
                  } catch (e) {
                    print('⚠️ Realtime: ไม่สามารถสร้าง signed URL: $e');
                  }
                }
              }
              
              print('✅ Order processed: Order #$orderId with ${items.length} items');
              print('📝 Items: ${items.map((i) => i['menu_name']).join(', ')}');
              onNewOrder(orderData);
            } catch (e) {
              print('❌ Error processing new order: $e');
            }
          },
        )
        .subscribe((status, error) {
          print('📡 Subscription status: $status');
          if (error != null) {
            print('❌ Subscription error: $error');
          }
          if (status == RealtimeSubscribeStatus.subscribed) {
            print('✅ Realtime subscription สำเร็จ! กำลังรอ orders ใหม่...');
          }
        });
    
    print('📡 Channel created: orders-$restaurantId');
    return channel;
  }

  // =====================================================
  // 📊 ANALYTICS & REPORTS (Phase 7)
  // =====================================================

  /// ดึงสรุปยอดขายวันนี้
  static Future<Map<String, dynamic>> getTodaySales(int restaurantId) async {
    try {
      print('📊 กำลังดึงยอดขายวันนี้ของร้าน $restaurantId...');
      
      // หาเวลาเริ่มต้นและสิ้นสุดของวันนี้ (Local Time → UTC)
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      // แปลงเป็น UTC สำหรับ query
      final startOfDayUtc = startOfDay.toUtc();
      final endOfDayUtc = endOfDay.toUtc();
      
      // ดึง orders วันนี้ทั้งหมด (ไม่รวม cancelled)
      final response = await _client
          .from('orders')
          .select('id, total_amount, status, created_at')
          .eq('restaurant_id', restaurantId)
          .gte('created_at', startOfDayUtc.toIso8601String())
          .lt('created_at', endOfDayUtc.toIso8601String())
          .neq('status', 'cancelled');
      
      final orders = List<Map<String, dynamic>>.from(response);
      
      // คำนวณสถิติ
      final totalOrders = orders.length;
      final completedOrders = orders.where((o) => o['status'] == 'completed').length;
      final totalRevenue = orders.fold<double>(
        0.0,
        (sum, order) => sum + (order['total_amount'] ?? 0).toDouble(),
      );
      final averageOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;
      
      print('✅ ยอดขายวันนี้: ฿${totalRevenue.toStringAsFixed(0)} จาก $totalOrders ออเดอร์');
      
      return {
        'total_revenue': totalRevenue,
        'total_orders': totalOrders,
        'completed_orders': completedOrders,
        'average_order_value': averageOrderValue,
        'date': startOfDay.toIso8601String(),
      };
    } catch (e) {
      print('❌ Error getting today sales: $e');
      return {
        'total_revenue': 0.0,
        'total_orders': 0,
        'completed_orders': 0,
        'average_order_value': 0.0,
      };
    }
  }

  /// ดึงยอดขายรายวัน (7 วันล่าสุด)
  static Future<List<Map<String, dynamic>>> getWeeklySales(int restaurantId) async {
    try {
      print('📊 กำลังดึงยอดขายรายสัปดาห์ของร้าน $restaurantId...');
      
      final now = DateTime.now();
      final salesData = <Map<String, dynamic>>[];
      
      // วนลูป 7 วันย้อนหลัง
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        
        // แปลงเป็น UTC สำหรับ query
        final startOfDayUtc = startOfDay.toUtc();
        final endOfDayUtc = endOfDay.toUtc();
        
        // ดึง orders ของวันนั้น
        final response = await _client
            .from('orders')
            .select('total_amount')
            .eq('restaurant_id', restaurantId)
            .gte('created_at', startOfDayUtc.toIso8601String())
            .lt('created_at', endOfDayUtc.toIso8601String())
            .neq('status', 'cancelled');
        
        final orders = List<Map<String, dynamic>>.from(response);
        final dailyRevenue = orders.fold<double>(
          0.0,
          (sum, order) => sum + (order['total_amount'] ?? 0).toDouble(),
        );
        
        salesData.add({
          'date': startOfDay.toIso8601String(), // แปลงเป็น String
          'revenue': dailyRevenue,
          'total_sales': dailyRevenue, // เพิ่มชื่อ key ที่ชัดเจน
          'order_count': orders.length,
          'day_name': _getDayName(startOfDay.weekday),
        });
      }
      
      print('✅ ดึงยอดขาย 7 วันสำเร็จ');
      return salesData;
    } catch (e) {
      print('❌ Error getting weekly sales: $e');
      return [];
    }
  }

  /// ดึง Top เมนูขายดี
  static Future<List<Map<String, dynamic>>> getTopMenus(
    int restaurantId, {
    int? days,
    int limit = 5,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      String rangeDesc = '';
      DateTime? queryStart;
      DateTime? queryEnd;
      if (startDate != null && endDate != null) {
        queryStart = startDate;
        queryEnd = endDate;
        rangeDesc = '(${queryStart.toIso8601String()} ถึง ${queryEnd.toIso8601String()})';
      } else {
        final now = DateTime.now();
        final d = days ?? 1;
        queryStart = now.subtract(Duration(days: d));
        queryEnd = now;
        rangeDesc = 'ย้อนหลัง $d วัน';
      }
      print('📊 กำลังดึง Top $limit เมนูขายดี $rangeDesc ของร้าน $restaurantId...');
      final startDateUtc = queryStart.toUtc();
      final endDateUtc = queryEnd.toUtc();
      // ดึง order_items จาก orders ของร้านในช่วงเวลาที่กำหนด
      final response = await _client
          .from('order_items')
          .select('food_name, quantity, price, orders!inner(restaurant_id, created_at, status)')
          .eq('orders.restaurant_id', restaurantId)
          .gte('orders.created_at', startDateUtc.toIso8601String())
          .lte('orders.created_at', endDateUtc.toIso8601String())
          .neq('orders.status', 'cancelled');
      
      final items = List<Map<String, dynamic>>.from(response);
      
      // รวมยอดขายแต่ละเมนู
      final Map<String, Map<String, dynamic>> menuStats = {};
      
      for (var item in items) {
        final menuName = item['food_name'] ?? 'Unknown';
        final quantity = item['quantity'] ?? 0;
        final price = (item['price'] ?? 0).toDouble();
        
        if (!menuStats.containsKey(menuName)) {
          menuStats[menuName] = {
            'menu_name': menuName,
            'total_quantity': 0,
            'total_revenue': 0.0,
          };
        }
        
        menuStats[menuName]!['total_quantity'] += quantity;
        menuStats[menuName]!['total_revenue'] += price * quantity;
      }
      
      // เรียงตามจำนวนขาย
      final topMenus = menuStats.values.toList()
        ..sort((a, b) => (b['total_quantity'] as int).compareTo(a['total_quantity'] as int));
      
      final result = topMenus.take(limit).toList();
      
      print('✅ ดึง Top $limit เมนูสำเร็จ');
      return result;
    } catch (e) {
      print('❌ Error getting top menus: $e');
      return [];
    }
  }

  /// ดึงข้อมูล Peak Hours (ช่วงเวลาขายดี)
  static Future<List<Map<String, dynamic>>> getPeakHours(
    int restaurantId, {
    int days = 7,
  }) async {
    try {
    
      print('📊 กำลังดึง Peak Hours ($days วัน) ของร้าน $restaurantId...');
      
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days));
      
      // แปลงเป็น UTC สำหรับ query
      final startDateUtc = startDate.toUtc();
      
      // ดึง orders ในช่วงเวลาที่กำหนด
      final response = await _client
          .from('orders')
          .select('created_at')
          .eq('restaurant_id', restaurantId)
          .gte('created_at', startDateUtc.toIso8601String())
          .neq('status', 'cancelled');
      
      final orders = List<Map<String, dynamic>>.from(response);
      
      // นับจำนวน orders แต่ละชั่วโมง (8:00-20:00)
      final Map<int, int> hourlyOrders = {};
      for (int hour = 8; hour <= 20; hour++) {
        hourlyOrders[hour] = 0;
      }
      
      // แปลงเวลาเป็น Local Time
      for (var order in orders) {
        final createdAt = DateTime.parse(order['created_at']).toLocal();
        final hour = createdAt.hour;
        if (hour >= 8 && hour <= 20) {
          hourlyOrders[hour] = (hourlyOrders[hour] ?? 0) + 1;
        }
      }

      // ตรวจสอบจำนวนรวม
      final totalOrders = hourlyOrders.values.reduce((a, b) => a + b);
      print('📊 Total orders counted: $totalOrders');
      
      // แปลงเป็น list
      final result = hourlyOrders.entries.map((e) {
        return {
          'hour': e.key,
          'order_count': e.value,
          'hour_label': '${e.key.toString().padLeft(2, '0')}:00',
        };
      }).toList()
        ..sort((a, b) => (a['hour'] as int).compareTo(b['hour'] as int));
      
      print('✅ ดึง Peak Hours สำเร็จ');

      // ตรวจสอบว่ามีข้อมูลหรือไม่
      if (result.isEmpty) {
        print('⚠️ ไม่มีข้อมูลคำสั่งซื้อในช่วงเวลาที่กำหนด');
      }

      return result;
    } catch (e) {
      print('❌ Error getting peak hours: $e');
      return [];
    }
  }

  /// Debug helper: พิมพ์จำนวนออเดอร์ต่อชั่วโมงในช่วง 24 ชั่วโมงเริ่มจาก startDate (local)
  /// ผลลัพธ์จะพิมพ์ลง console (useful when running `flutter run`)
  // (debug helper removed)

  /// ดึงเวลาทำอาหารเฉลี่ย
  static Future<Map<String, dynamic>> getAverageProcessingTime(
    int restaurantId, {
    String period = 'week', // accepted: 'today', 'week', 'month'
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      print('📊 กำลังคำนวณเวลาทำอาหารเฉลี่ยของร้าน $restaurantId (period=$period)...');

      final now = DateTime.now();

      // Determine start/end (local) according to period or explicit dates
      DateTime localStart;
      DateTime localEnd;

      if (startDate != null && endDate != null) {
        localStart = DateTime(startDate.year, startDate.month, startDate.day);
        localEnd = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      } else {
        if (period == 'today') {
          localStart = DateTime(now.year, now.month, now.day);
          localEnd = localStart.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
        } else if (period == 'month') {
          localStart = DateTime(now.year, now.month, 1);
          localEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
        } else {
          // default: last 7 days (week)
          localStart = now.subtract(const Duration(days: 7));
          localEnd = now;
        }
      }

      // Convert to UTC for querying
      final startDateUtc = localStart.toUtc();
      final endDateUtc = localEnd.toUtc();

      print('🔍 AverageProcessingTime Query range (Local): $localStart to $localEnd');
      print('🔍 AverageProcessingTime Query range (UTC): $startDateUtc to $endDateUtc');

    // Query orders that are completed or ready. We require at least ready_at
    // so we can compute some processing-time metrics even if status isn't
    // 'completed' yet.
    final response = await _client
      .from('orders')
      .select('created_at, confirmed_at, preparing_at, ready_at, status')
      .eq('restaurant_id', restaurantId)
      .gte('created_at', startDateUtc.toIso8601String())
      .lte('created_at', endDateUtc.toIso8601String())
      .inFilter('status', ['completed', 'ready'])
      .not('ready_at', 'is', null);
      
      final orders = List<Map<String, dynamic>>.from(response);
      
      if (orders.isEmpty) {
        return {
          'pending_to_confirmed_minutes': 0,
          'confirmed_to_preparing_minutes': 0,
          'preparing_to_ready_minutes': 0,
          'total_minutes': 0,
          'sample_size': 0,
        };
      }
      
      double totalPendingToConfirmed = 0;
      double totalConfirmedToPreparing = 0;
      double totalPreparingToReady = 0;
      
      // We'll compute each segment only for orders that have the two timestamps
      // required for that segment. This makes the function tolerant to orders
      // that are 'ready' but may be missing earlier timestamps.
      int countPendingToConfirmed = 0;
      int countConfirmedToPreparing = 0;
      int countPreparingToReady = 0;

      for (var order in orders) {
        try {
          final created = order['created_at'] != null ? DateTime.parse(order['created_at']) : null;
          final confirmed = order['confirmed_at'] != null ? DateTime.parse(order['confirmed_at']) : null;
          final preparing = order['preparing_at'] != null ? DateTime.parse(order['preparing_at']) : null;
          final ready = order['ready_at'] != null ? DateTime.parse(order['ready_at']) : null;

          if (created != null && confirmed != null) {
            totalPendingToConfirmed += confirmed.difference(created).inMinutes;
            countPendingToConfirmed++;
          }
          if (confirmed != null && preparing != null) {
            totalConfirmedToPreparing += preparing.difference(confirmed).inMinutes;
            countConfirmedToPreparing++;
          }
          if (preparing != null && ready != null) {
            totalPreparingToReady += ready.difference(preparing).inMinutes;
            countPreparingToReady++;
          }
        } catch (e) {
          // Skip malformed dates for a given order
          print('⚠️ Skipping order for avg time due to parse error: $e');
        }
      }

      final avgPendingToConfirmed = countPendingToConfirmed > 0 ? totalPendingToConfirmed / countPendingToConfirmed : 0.0;
      final avgConfirmedToPreparing = countConfirmedToPreparing > 0 ? totalConfirmedToPreparing / countConfirmedToPreparing : 0.0;
      final avgPreparingToReady = countPreparingToReady > 0 ? totalPreparingToReady / countPreparingToReady : 0.0;
      // avgTotal: sum of available segment averages (keeps the same semantics)
      final avgTotal = avgPendingToConfirmed + avgConfirmedToPreparing + avgPreparingToReady;

      // sample size: number of matched orders (those returned by the query)
      final sampleSize = orders.length;

      print('✅ เวลาเฉลี่ย: ${avgTotal.toStringAsFixed(1)} นาที (จาก $sampleSize orders) | segments counts: pendingToConfirmed=$countPendingToConfirmed, confirmedToPreparing=$countConfirmedToPreparing, preparingToReady=$countPreparingToReady');

      return {
        'pending_to_confirmed_minutes': avgPendingToConfirmed,
        'confirmed_to_preparing_minutes': avgConfirmedToPreparing,
        'preparing_to_ready_minutes': avgPreparingToReady,
        'total_minutes': avgTotal,
        'sample_size': sampleSize,
      };
    } catch (e) {
      print('❌ Error getting average processing time: $e');
      return {
        'pending_to_confirmed_minutes': 0,
        'confirmed_to_preparing_minutes': 0,
        'preparing_to_ready_minutes': 0,
        'total_minutes': 0,
        'sample_size': 0,
      };
    }
  }

  /// ดึงสรุปรายได้ตามช่วงเวลา (today, week, month)
  static Future<Map<String, dynamic>> getSalesByPeriod(
    int restaurantId,
    String period, // 'today', 'week', 'month'
  ) async {
    try {
      print('📊 กำลังดึงยอดขาย period: $period ของร้าน $restaurantId...');
      
      // ใช้เวลาท้องถิ่น (Local Time) แล้วแปลงเป็น UTC สำหรับ query
      final now = DateTime.now(); // เวลาท้องถิ่น
      DateTime startDate;
      DateTime endDate;
      
      // กำหนดช่วงเวลาในรูปแบบท้องถิ่น
      if (period == 'today') {
        startDate = DateTime(now.year, now.month, now.day); // 00:00:00 วันนี้
        endDate = DateTime(now.year, now.month, now.day + 1); // 00:00:00 พรุ่งนี้
      } else if (period == 'week') {
        // เริ่มจากจันทร์ของสัปดาห์นี้
        final weekday = now.weekday;
        final monday = now.subtract(Duration(days: weekday - 1));
        startDate = DateTime(monday.year, monday.month, monday.day);
        endDate = DateTime(now.year, now.month, now.day + 1); // พรุ่งนี้
      } else if (period == 'month') {
        // เริ่มจากวันที่ 1 ของเดือนนี้
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month, now.day + 1); // พรุ่งนี้
      } else {
        throw Exception('Invalid period: $period');
      }
      
      // แปลงเป็น UTC สำหรับ query Supabase
      final startDateUtc = startDate.toUtc();
      final endDateUtc = endDate.toUtc();
      
      // ดึง orders ในช่วงเวลา (ทั้งหมดรวม cancelled)
      print('🔍 Query range (Local): $startDate ถึง $endDate');
      print('🔍 Query range (UTC): $startDateUtc ถึง $endDateUtc');
      print('🏪 Restaurant ID: $restaurantId');
      print('📅 Period: $period');
      final response = await _client
          .from('orders')
          .select('id, total_amount, status, created_at, confirmed_at, preparing_at, ready_at, restaurant_id')
          .eq('restaurant_id', restaurantId)
          .gte('created_at', startDateUtc.toIso8601String())
          .lt('created_at', endDateUtc.toIso8601String());
      
      final allOrders = List<Map<String, dynamic>>.from(response);
      final orders = allOrders.where((o) => o['status'] != 'cancelled').toList();
      print('🔍 ดึงได้ ${orders.length} orders ทั้งหมด (ยกเว้น cancelled)');
      if (orders.isNotEmpty) {
        print('� Orders details:');
        for (var o in orders) {
          print('   - Order #${o['id']} | Restaurant: ${o['restaurant_id']} | Status: ${o['status']} | Amount: ฿${o['total_amount']} | Created: ${o['created_at']}');
        }
      } else {
        print('⚠️ ไม่พบ orders ในช่วงเวลานี้!');
      }
      
      // คำนวณสถิติ
      final totalOrders = orders.length;
      final cancelledOrders = allOrders.where((o) => o['status'] == 'cancelled').length;
      final completedOrders = orders.where((o) => o['status'] == 'completed').length;
      final readyOrders = orders.where((o) => o['status'] == 'ready').length;
      final pendingOrders = orders.where((o) => o['status'] == 'pending' || o['status'] == 'confirmed' || o['status'] == 'preparing').length;
      
      print('📊 สถิติ orders:');
      print('   - Total: $totalOrders orders');
      print('   - Cancelled: $cancelledOrders orders');
      print('   - Completed: $completedOrders orders');
      print('   - Ready: $readyOrders orders');
      print('   - Pending/Confirmed/Preparing: $pendingOrders orders');
      
      // คำนวณเวลาเฉลี่ยในการประมวลผล (จาก created_at ถึง ready_at)
      double averageProcessingTime = 0.0;
      int processedCount = 0;
      for (var order in orders.where((o) => o['ready_at'] != null)) {
        try {
          final created = DateTime.parse(order['created_at']);
          final ready = DateTime.parse(order['ready_at']);
          final diff = ready.difference(created).inMinutes;
          averageProcessingTime += diff;
          processedCount++;
        } catch (e) {
          // Skip invalid dates
        }
      }
      if (processedCount > 0) {
        averageProcessingTime = averageProcessingTime / processedCount;
      }
      
      // หาช่วงเวลายอดนิยม (Peak Hours)
      Map<int, int> hourCounts = {};
      for (var order in orders) {
        try {
          final created = DateTime.parse(order['created_at']).toLocal();
          final hour = created.hour;
          hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
        } catch (e) {
          // Skip invalid dates
        }
      }
      String peakHours = '-';
      if (hourCounts.isNotEmpty) {
        final maxCount = hourCounts.values.reduce((a, b) => a > b ? a : b);
        final peakHoursList = hourCounts.entries
            .where((e) => e.value == maxCount)
            .map((e) => '${e.key.toString().padLeft(2, '0')}:00')
            .toList();
        peakHours = peakHoursList.join(', ');
      }
      
      // นับรายได้จาก ready + completed เท่านั้น
      final totalRevenue = orders
          .where((o) => o['status'] == 'ready' || o['status'] == 'completed')
          .fold<double>(0.0, (sum, order) => sum + (order['total_amount'] ?? 0).toDouble());
      
      final completedRevenue = orders
          .where((o) => o['status'] == 'completed')
          .fold<double>(0.0, (sum, order) => sum + (order['total_amount'] ?? 0).toDouble());
      
      final averageOrderValue = (completedOrders + readyOrders) > 0 ? totalRevenue / (completedOrders + readyOrders) : 0.0;
      
      print('💰 รายได้:');
      print('   - Total Revenue (ready + completed): ฿${totalRevenue.toStringAsFixed(2)}');
      print('   - Completed Revenue only: ฿${completedRevenue.toStringAsFixed(2)}');
      print('   - Average Order Value: ฿${averageOrderValue.toStringAsFixed(2)}');
      print('   - Average Processing Time: ${averageProcessingTime.toStringAsFixed(1)} นาที');
      print('   - Peak Hours: $peakHours');
      print('✅ ยอดขาย $period: ฿${totalRevenue.toStringAsFixed(0)} จาก ${completedOrders + readyOrders} ออเดอร์ (ready: $readyOrders, completed: $completedOrders)');
      
      return {
        'period': period,
        'start_date': startDateUtc.toIso8601String(),
        'end_date': endDateUtc.toIso8601String(),
        'total_revenue': totalRevenue,
        'completed_revenue': completedRevenue,
        'total_orders': completedOrders + readyOrders, // เปลี่ยนเป็นนับแค่ ready + completed
        'completed_orders': completedOrders,
        'cancelled_orders': cancelledOrders,
        'pending_orders': pendingOrders,
        'average_order_value': averageOrderValue,
        'average_processing_time': averageProcessingTime,
        'peak_hours': peakHours,
      };
    } catch (e) {
      print('❌ Error getting sales by period: $e');
      return {
        'period': period,
        'total_revenue': 0.0,
        'completed_revenue': 0.0,
        'total_orders': 0,
        'completed_orders': 0,
        'cancelled_orders': 0,
        'pending_orders': 0,
        'average_order_value': 0.0,
        'average_processing_time': 0.0,
        'peak_hours': '-',
      };
    }
  }

  /// ดึงสรุปรายได้ตามช่วงวันที่ที่กำหนดเอง (Custom Date Range)
  static Future<Map<String, dynamic>> getSalesByCustomDateRange(
    int restaurantId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      print('📊 กำลังดึงยอดขายช่วง Custom Date Range ของร้าน $restaurantId...');
      
      // ตั้งเวลาเป็น 00:00:00 สำหรับวันเริ่มต้น และ 23:59:59 สำหรับวันสิ้นสุด
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      
      // แปลงเป็น UTC สำหรับ query
      final startUtc = start.toUtc();
      final endUtc = end.toUtc();
      
      print('🔍 Query range (Local): $start ถึง $end');
      print('🔍 Query range (UTC): $startUtc ถึง $endUtc');
      
      // ดึง orders ในช่วงเวลา (ทั้งหมดรวม cancelled)
      final response = await _client
          .from('orders')
          .select('id, total_amount, status, created_at, confirmed_at, preparing_at, ready_at')
          .eq('restaurant_id', restaurantId)
          .gte('created_at', startUtc.toIso8601String())
          .lte('created_at', endUtc.toIso8601String());
      
      final allOrders = List<Map<String, dynamic>>.from(response);
      final orders = allOrders.where((o) => o['status'] != 'cancelled').toList();
      print('🔍 ดึงได้ ${orders.length} orders ทั้งหมด (ยกเว้น cancelled)');
      
      // คำนวณสถิติ
      final totalOrders = orders.length;
      final cancelledOrders = allOrders.where((o) => o['status'] == 'cancelled').length;
      final completedOrders = orders.where((o) => o['status'] == 'completed').length;
      final readyOrders = orders.where((o) => o['status'] == 'ready').length;
      final pendingOrders = orders.where((o) => 
        o['status'] == 'pending' || o['status'] == 'confirmed' || o['status'] == 'preparing'
      ).length;
      
      // คำนวณเวลาเฉลี่ยในการประมวลผล
      double averageProcessingTime = 0.0;
      int processedCount = 0;
      for (var order in orders.where((o) => o['ready_at'] != null)) {
        try {
          final created = DateTime.parse(order['created_at']);
          final ready = DateTime.parse(order['ready_at']);
          final diff = ready.difference(created).inMinutes;
          averageProcessingTime += diff;
          processedCount++;
        } catch (e) {
          // Skip invalid dates
        }
      }
      if (processedCount > 0) {
        averageProcessingTime = averageProcessingTime / processedCount;
      }
      
      // หาช่วงเวลายอดนิยม
      Map<int, int> hourCounts = {};
      for (var order in orders) {
        try {
          final created = DateTime.parse(order['created_at']).toLocal();
          final hour = created.hour;
          hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
        } catch (e) {
          // Skip invalid dates
        }
      }
      String peakHours = '-';
      if (hourCounts.isNotEmpty) {
        final maxCount = hourCounts.values.reduce((a, b) => a > b ? a : b);
        final peakHoursList = hourCounts.entries
            .where((e) => e.value == maxCount)
            .map((e) => '${e.key.toString().padLeft(2, '0')}:00')
            .toList();
        peakHours = peakHoursList.join(', ');
      }
      
      // นับรายได้จาก ready + completed เท่านั้น
      final totalRevenue = orders
          .where((o) => o['status'] == 'ready' || o['status'] == 'completed')
          .fold<double>(0.0, (sum, order) => sum + (order['total_amount'] ?? 0).toDouble());
      
      final completedRevenue = orders
          .where((o) => o['status'] == 'completed')
          .fold<double>(0.0, (sum, order) => sum + (order['total_amount'] ?? 0).toDouble());
      
      final averageOrderValue = (completedOrders + readyOrders) > 0 
          ? totalRevenue / (completedOrders + readyOrders) 
          : 0.0;
      
      final daysDiff = end.difference(start).inDays + 1;
      
      print('💰 รายได้ช่วง $daysDiff วัน: ฿${totalRevenue.toStringAsFixed(0)} จาก ${completedOrders + readyOrders} ออเดอร์');
      print('   - Average Processing Time: ${averageProcessingTime.toStringAsFixed(1)} นาที');
      print('   - Peak Hours: $peakHours');
      
      return {
        'period': 'custom',
        'start_date': startUtc.toIso8601String(),
        'end_date': endUtc.toIso8601String(),
        'days_count': daysDiff,
        'total_revenue': totalRevenue,
        'completed_revenue': completedRevenue,
        'total_orders': completedOrders + readyOrders,
        'completed_orders': completedOrders,
        'cancelled_orders': cancelledOrders,
        'pending_orders': pendingOrders,
        'average_order_value': averageOrderValue,
        'average_processing_time': averageProcessingTime,
        'peak_hours': peakHours,
      };
    } catch (e) {
      print('❌ Error getting sales by custom date range: $e');
      return {
        'period': 'custom',
        'total_revenue': 0.0,
        'completed_revenue': 0.0,
        'total_orders': 0,
        'completed_orders': 0,
        'cancelled_orders': 0,
        'pending_orders': 0,
        'average_order_value': 0.0,
        'average_processing_time': 0.0,
        'peak_hours': '-',
        'days_count': 0,
      };
    }
  }

  /// เปรียบเทียบยอดขายกับช่วงเวลาก่อนหน้า
  /// คืนค่า % เพิ่ม/ลดของ revenue และ orders
  static Future<Map<String, dynamic>> getPeriodComparison(
    int restaurantId,
    String period, // 'today', 'week', 'month'
  ) async {
    try {
      print('📊 กำลังเปรียบเทียบข้อมูล period: $period ของร้าน $restaurantId...');
      
      final now = DateTime.now();
      DateTime currentStart, currentEnd;
      DateTime previousStart, previousEnd;
      
      // กำหนดช่วงเวลาปัจจุบันและก่อนหน้า
      if (period == 'today') {
        // วันนี้ vs เมื่อวาน
        currentStart = DateTime(now.year, now.month, now.day);
        currentEnd = now.add(const Duration(days: 1));
        previousStart = currentStart.subtract(const Duration(days: 1));
        previousEnd = currentStart;
      } else if (period == 'week') {
        // สัปดาห์นี้ vs สัปดาห์ที่แล้ว
        final weekday = now.weekday;
        currentStart = now.subtract(Duration(days: weekday - 1));
        currentStart = DateTime(currentStart.year, currentStart.month, currentStart.day);
        currentEnd = now.add(const Duration(days: 1));
        previousStart = currentStart.subtract(const Duration(days: 7));
        previousEnd = currentStart;
      } else if (period == 'month') {
        // เดือนนี้ vs เดือนที่แล้ว
        currentStart = DateTime(now.year, now.month, 1);
        currentEnd = now.add(const Duration(days: 1));
        // เดือนก่อน
        final previousMonth = now.month == 1 ? 12 : now.month - 1;
        final previousYear = now.month == 1 ? now.year - 1 : now.year;
        previousStart = DateTime(previousYear, previousMonth, 1);
        previousEnd = currentStart;
      } else {
        throw Exception('Invalid period: $period');
      }
      
      // แปลงเป็น UTC สำหรับ query
      final currentStartUtc = currentStart.toUtc();
      final currentEndUtc = currentEnd.toUtc();
      final previousStartUtc = previousStart.toUtc();
      final previousEndUtc = previousEnd.toUtc();
      
      // ดึงข้อมูลช่วงปัจจุบัน
      final currentResponse = await _client
          .from('orders')
          .select('id, total_amount, status')
          .eq('restaurant_id', restaurantId)
          .gte('created_at', currentStartUtc.toIso8601String())
          .lt('created_at', currentEndUtc.toIso8601String())
          .neq('status', 'cancelled');
      
      // ดึงข้อมูลช่วงก่อนหน้า
      final previousResponse = await _client
          .from('orders')
          .select('id, total_amount, status')
          .eq('restaurant_id', restaurantId)
          .gte('created_at', previousStartUtc.toIso8601String())
          .lt('created_at', previousEndUtc.toIso8601String())
          .neq('status', 'cancelled');
      
      final currentOrders = List<Map<String, dynamic>>.from(currentResponse);
      final previousOrders = List<Map<String, dynamic>>.from(previousResponse);
      
      // คำนวณยอดขายและจำนวนออเดอร์
      final currentRevenue = currentOrders.fold<double>(
        0.0,
        (sum, order) => sum + (order['total_amount'] ?? 0).toDouble(),
      );
      final previousRevenue = previousOrders.fold<double>(
        0.0,
        (sum, order) => sum + (order['total_amount'] ?? 0).toDouble(),
      );
      
      final currentOrderCount = currentOrders.length;
      final previousOrderCount = previousOrders.length;
      
      // คำนวณ % การเปลี่ยนแปลง
      double revenueChangePercent = 0.0;
      double ordersChangePercent = 0.0;
      
      if (previousRevenue > 0) {
        revenueChangePercent = ((currentRevenue - previousRevenue) / previousRevenue) * 100;
      } else if (currentRevenue > 0) {
        revenueChangePercent = 100.0; // เพิ่มขึ้น 100% ถ้าก่อนหน้าไม่มีข้อมูล
      }
      
      if (previousOrderCount > 0) {
        ordersChangePercent = ((currentOrderCount - previousOrderCount) / previousOrderCount) * 100;
      } else if (currentOrderCount > 0) {
        ordersChangePercent = 100.0;
      }
      
      print('✅ เปรียบเทียบ: Revenue ${revenueChangePercent >= 0 ? '+' : ''}${revenueChangePercent.toStringAsFixed(1)}%, Orders ${ordersChangePercent >= 0 ? '+' : ''}${ordersChangePercent.toStringAsFixed(1)}%');
      
      return {
        'period': period,
        'current_revenue': currentRevenue,
        'previous_revenue': previousRevenue,
        'revenue_change_percent': revenueChangePercent,
        'current_orders': currentOrderCount,
        'previous_orders': previousOrderCount,
        'orders_change_percent': ordersChangePercent,
        'is_revenue_increased': revenueChangePercent >= 0,
        'is_orders_increased': ordersChangePercent >= 0,
      };
    } catch (e) {
      print('❌ Error comparing periods: $e');
      return {
        'period': period,
        'current_revenue': 0.0,
        'previous_revenue': 0.0,
        'revenue_change_percent': 0.0,
        'current_orders': 0,
        'previous_orders': 0,
        'orders_change_percent': 0.0,
        'is_revenue_increased': false,
        'is_orders_increased': false,
      };
    }
  }

  /// Helper: แปลงตัวเลขวันเป็นชื่อวัน
  static String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'จ';
      case 2: return 'อ';
      case 3: return 'พ';
      case 4: return 'พฤ';
      case 5: return 'ศ';
      case 6: return 'ส';
      case 7: return 'อา';
      default: return '';
    }
  }

  /// ดึงรายงานยอดขายตามสินค้า (Product Sales Report)
  /// คำนวณจำนวนและรายได้ของแต่ละเมนูในช่วงเวลาที่กำหนด
  static Future<List<Map<String, dynamic>>> getProductSalesReport(
    int restaurantId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // แปลงเป็น UTC ถ้ามีการส่งวันที่มา
      final DateTime start;
      final DateTime end;
      
      if (startDate != null && endDate != null) {
        // ใช้วันที่ที่ส่งมา (แปลงเป็น UTC)
        start = startDate.toUtc();
        end = endDate.toUtc();
      } else {
        // Default: วันนี้ (00:00:00 ถึง 23:59:59)
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        start = today.toUtc();
        end = today.add(const Duration(days: 1)).toUtc();
      }

      print('📊 กำลังดึงรายงานสินค้าของร้าน $restaurantId');
      print('📅 ช่วงเวลา (Local): ${start.toLocal()} ถึง ${end.toLocal()}');
      print('📅 ช่วงเวลา (UTC): ${start.toIso8601String()} ถึง ${end.toIso8601String()}');

      // Query จาก order_items joined กับ orders
      final response = await _client
          .from('order_items')
          .select('*, orders!inner(restaurant_id, status, created_at)')
          .eq('orders.restaurant_id', restaurantId)
          .inFilter('orders.status', ['ready', 'completed'])
          .gte('orders.created_at', start.toIso8601String())
          .lt('orders.created_at', end.toIso8601String());

      print('📦 ได้รับ ${response.length} รายการ order_items');

      if (response.isEmpty) {
        print('ℹ️ ไม่มีข้อมูลการขายในช่วงเวลานี้');
        return [];
      }

      // รวมยอดขายแต่ละเมนู
      final Map<String, Map<String, dynamic>> productMap = {};

      for (var item in response) {
        // ป้องกัน null values - ใช้ food_name (ตาม schema จริงของ order_items)
        final menuName = item['food_name']?.toString() ?? item['menu_name']?.toString();
        if (menuName == null || menuName.isEmpty) {
          print('⚠️ พบ order_item ที่ไม่มี food_name หรือ menu_name: $item');
          continue; // ข้ามรายการที่ไม่มีชื่อเมนู
        }

        final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
        final price = (item['price'] as num?)?.toDouble() ?? 0.0;
        final revenue = price * quantity;

        if (productMap.containsKey(menuName)) {
          productMap[menuName]!['quantity'] += quantity;
          productMap[menuName]!['revenue'] += revenue;
        } else {
          productMap[menuName] = {
            'name': menuName,
            'quantity': quantity,
            'price': price,
            'revenue': revenue,
          };
        }
      }

      // แปลงเป็น List และเรียงตามจำนวนขาย
      final products = productMap.values.toList()
        ..sort((a, b) => (b['quantity'] as int).compareTo(a['quantity'] as int));

      print('✅ ดึงรายงานสินค้า ${products.length} รายการ');
      for (var product in products) {
        print('   - ${product['name']}: ${product['quantity']} ชิ้น = ฿${product['revenue'].toStringAsFixed(0)}');
      }

      return products;
    } catch (e, stackTrace) {
      print('❌ Error getting product sales report: $e');
      print('📍 Stack trace: $stackTrace');
      return [];
    }
  }

  /// ดึงข้อมูล Peak Hours (ช่วงเวลาขายดี) พร้อมเวลาเปิด-ปิดร้าน
  static Future<Map<String, dynamic>> getPeakHoursWithBusinessHours(
    int restaurantId, {
    int days = 1,
  }) async {
    try {
      print('📊 กำลังดึง Peak Hours พร้อมเวลาเปิด-ปิดร้านของร้าน $restaurantId...');

      // พยายามดึงเวลาเปิด-ปิดร้านจากตาราง restaurants
      int openingHour = 8;
      int closingHour = 20;
      try {
        final businessHoursResponse = await _client
            .from('restaurants')
            .select('*')
            .eq('id', restaurantId)
            .single();

        if (businessHoursResponse != null && businessHoursResponse is Map) {
          // Use only the canonical integer columns `opening_hour` and `closing_hour`.
          // Legacy text columns (open_time/close_time) are no longer considered.
          final ohRaw = businessHoursResponse['opening_hour'];
          final chRaw = businessHoursResponse['closing_hour'];

          if (ohRaw != null) {
            openingHour = (ohRaw is int) ? ohRaw : (int.tryParse(ohRaw.toString()) ?? openingHour);
          }
          if (chRaw != null) {
            closingHour = (chRaw is int) ? chRaw : (int.tryParse(chRaw.toString()) ?? closingHour);
          }
        }

        print('🕒 เวลาเปิดร้าน (inferred): ${openingHour.toString().padLeft(2,'0')}:00, เวลาปิดร้าน: ${closingHour.toString().padLeft(2,'0')}:00');
      } catch (e) {
        // ถ้า query คอลัมน์เฉพาะเจาะจงล้มเหลว ให้ fallback เป็นค่า default
        print('⚠️ ไม่สามารถดึงเวลาเปิด-ปิดจาก restaurants: $e — ใช้ค่าเริ่มต้น ${openingHour}:00-${closingHour}:00');
      }

  // ดึง orders ในช่วงเวลาเปิด-ปิดร้าน (ย้อนหลัง `days` วัน)
  final now = DateTime.now();
  final startDate = now.subtract(Duration(days: days));
  final startDateUtc = startDate.toUtc();

  print('🔍 Query range (Local): $startDate ถึง $now');
  print('🔍 Query range (UTC): $startDateUtc ถึง ${now.toUtc()}');

      final response = await _client
          .from('orders')
          .select('created_at')
          .eq('restaurant_id', restaurantId)
          .gte('created_at', startDateUtc.toIso8601String())
          .neq('status', 'cancelled');

      final orders = List<Map<String, dynamic>>.from(response);

      // นับจำนวน orders แต่ละชั่วโมงตามเวลาเปิด-ปิดร้าน
      final Map<int, int> hourlyOrders = {};
      for (int hour = openingHour; hour <= closingHour; hour++) {
        hourlyOrders[hour] = 0;
      }
      
      for (var order in orders) {
        final createdAt = DateTime.parse(order['created_at']).toLocal();
        final hour = createdAt.hour;
        if (hour >= openingHour && hour <= closingHour) {
          hourlyOrders[hour] = (hourlyOrders[hour] ?? 0) + 1;
        }
      }

      // แปลงเป็น list
      final peakList = hourlyOrders.entries.map((e) {
        return {
          'hour': e.key,
          'order_count': e.value,
          'hour_label': '${e.key.toString().padLeft(2, '0')}:00',
        };
      }).toList()
        ..sort((a, b) => (a['hour'] as int).compareTo(b['hour'] as int));

      // ตรวจสอบผลรวมที่นับได้
      final total = hourlyOrders.values.fold<int>(0, (a, b) => a + b);
      print('✅ ดึง Peak Hours พร้อมเวลาเปิด-ปิดร้านสำเร็จ - นับได้ $total ออเดอร์');

      // คืนค่าเป็น Map ที่รวมทั้ง peak_hours และค่า opening/closing hour ที่อนุมานได้
      return {
        'peak_hours': peakList,
        'opening_hour': openingHour,
        'closing_hour': closingHour,
        'total_count': total,
      };
    } catch (e) {
      print('❌ Error getting peak hours with business hours: $e');
      return {
        'peak_hours': <Map<String, dynamic>>[],
        'opening_hour': 8,
        'closing_hour': 20,
        'total_count': 0,
      };
    }
  }
}
