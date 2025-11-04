// main_screen.dart
import 'package:eatscikmitl/widget/component/CardComponent.dart';
import 'package:eatscikmitl/widget/component/SearchComponent.dart';
import 'package:eatscikmitl/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:eatscikmitl/const/app_color.dart';
import '../utils/notification_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> restaurants = [];
  List<Map<String, dynamic>> filteredRestaurants = [];
  String selectedCategory = 'ทั้งหมด';
  
  List<String> categories = [
    'ทั้งหมด',
    'อาหารไทย',
    'อาหารฝรั่ง', 
    'อาหารญี่ปุ่น',
    'เครื่องดื่ม',
    'ของหวาน'
  ];

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  // ดึงข้อมูลร้านอาหารจาก Supabase
  Future<void> _loadRestaurants() async {
    try {
      print('🔄 กำลังดึงข้อมูลร้านอาหาร...');
      final data = await SupabaseService.getRestaurants();
      
      // ตรวจสอบข้อมูลที่ได้รับ
      if (data.isEmpty) {
        print('⚠️ ไม่พบข้อมูลร้านอาหาร');
        setState(() {
          restaurants = [];
          filteredRestaurants = [];
        });
        return;
      }
      
      setState(() {
        restaurants = data.map((restaurant) {
          // ป้องกัน null values
          return {
            'restaurantId': (restaurant['id'] ?? 0).toString(),
            'restaurantImage': restaurant['image_url'] ?? 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=300',
            'restaurantName': restaurant['name'] ?? 'ไม่ระบุชื่อ',
            'phone': restaurant['phone'] ?? 'ไม่ระบุ',
            'category': restaurant['category'] ?? 'ทั่วไป',
            'description': restaurant['description'] ?? 'ไม่มีรายละเอียด',
            'rating': double.tryParse(restaurant['rating']?.toString() ?? '0.0') ?? 0.0,
            'openTime': restaurant['open_time'] ?? '08:00',
            'closeTime': restaurant['close_time'] ?? '20:00',
            'location': restaurant['location'] ?? 'ไม่ระบุ',
            'menuItemsCount': 0,
          };
        }).toList();
        filteredRestaurants = List.from(restaurants); // สร้าง copy ใหม่
      });
      
      print('✅ โหลดข้อมูลร้าน ${restaurants.length} ร้านสำเร็จ');
    } catch (e) {
      print('❌ Error loading restaurants: $e');
      setState(() {
        restaurants = [];
        filteredRestaurants = [];
      });
      
      // แสดง error ให้ user ทราบ
      if (mounted) {
        NotificationHelper.showError(
          context,
          'ไม่สามารถโหลดข้อมูลร้านอาหารได้: $e',
        );
      }
    }
  }

  void _filterRestaurants(String query) {
    setState(() {
      if (query.isEmpty && selectedCategory == 'ทั้งหมด') {
        filteredRestaurants = restaurants;
      } else {
        filteredRestaurants = restaurants.where((restaurant) {
          final matchesSearch = query.isEmpty || 
              restaurant['restaurantName'].toLowerCase().contains(query.toLowerCase()) ||
              restaurant['category'].toLowerCase().contains(query.toLowerCase()) ||
              restaurant['description'].toLowerCase().contains(query.toLowerCase());
          
          final matchesCategory = selectedCategory == 'ทั้งหมด' || 
              restaurant['category'] == selectedCategory;
          
          return matchesSearch && matchesCategory;
        }).toList();
      }
    });
  }

  void _filterByCategory(String category) {
    setState(() {
      selectedCategory = category;
      _filterRestaurants(_searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset(
              'asset/logoeatsci.png', // Add your logo here
              height: 150,
              width: 150,
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Component
          SearchComponent(
            controller: _searchController,
            onChanged: _filterRestaurants,
            hintText: 'ค้นหาร้านอาหาร...',
          ),
          
          // Category Filter
          Container(
            height: 50,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategory == category;
                
                return GestureDetector(
                  onTap: () => _filterByCategory(category),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.mainOrange : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.mainOrange : Colors.grey[300]!,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: AppColors.mainOrange.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ] : null,
                    ),
                    child: Center(
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[600],
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Results summary
          if (filteredRestaurants.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Text(
                'พบ ${filteredRestaurants.length} ร้านอาหาร',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          
          // Restaurant Cards List
          Expanded(
            child: filteredRestaurants.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: filteredRestaurants.length,
                    itemBuilder: (context, index) {
                      final restaurant = filteredRestaurants[index];
                      return CardComponent(
                        restaurantId: restaurant['restaurantId'] ?? '0',
                        restaurantImage: restaurant['restaurantImage'] ?? '',
                        restaurantName: restaurant['restaurantName'] ?? 'ไม่มีชื่อ',
                        phone: restaurant['phone'] ?? 'ไม่มีเบอร์',
                        category: restaurant['category'] ?? 'ทั่วไป',
                        description: restaurant['description'] ?? 'ไม่มีรายละเอียด',
                        rating: (restaurant['rating'] ?? 0.0).toDouble(),
                        openTime: restaurant['openTime'] ?? '08:00',
                        closeTime: restaurant['closeTime'] ?? '20:00',
                        location: restaurant['location'] ?? 'ไม่ระบุ',
                        menuItemsCount: restaurant['menuItemsCount'] ?? 0,
                        onTap: () {
                          // Navigate to restaurant detail
                          _navigateToRestaurantDetail(restaurant);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'ไม่พบร้านอาหารที่ค้นหา',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ลองค้นหาด้วยคำอื่น หรือเลือกหมวดหมู่อื่น',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchController.clear();
                selectedCategory = 'ทั้งหมด';
                filteredRestaurants = restaurants;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mainOrange,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'แสดงทั้งหมด',
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

  void _navigateToRestaurantDetail(Map<String, dynamic> restaurant) {
    // Handle navigation to restaurant detail page
    print('Navigate to ${restaurant['restaurantName']}');
    print('Restaurant ID: ${restaurant['restaurantId']}');
    
    // Example: Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => RestaurantDetailScreen(
    //       restaurantData: restaurant,
    //     ),
    //   ),
    // );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}