// main_screen.dart
import 'package:eatscikmitl/widget/component/CardComponent.dart';
import 'package:eatscikmitl/widget/component/SearchComponent.dart';
import 'package:eatscikmitl/data/DataDemo.dart'; // Import data class
import 'package:flutter/material.dart';
import 'package:eatscikmitl/const/app_color.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

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
    'อาหารตามสั่ง',
    'ก๋วยเตี๋ยว',
    'ข้าวมันไก่',
    'อาหารอีสาน',
    'เครื่องดื่ม',
    'ของหวาน'
  ];

  @override
  void initState() {
    super.initState();
    restaurants = DataDemo.restaurants;
    filteredRestaurants = restaurants;
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
                        restaurantId: restaurant['restaurantId'],
                        restaurantImage: restaurant['restaurantImage'],
                        restaurantName: restaurant['restaurantName'],
                        phone: restaurant['phone'],
                        category: restaurant['category'],
                        description: restaurant['description'],
                        rating: restaurant['rating'].toDouble(),
                        openTime: restaurant['openTime'],
                        closeTime: restaurant['closeTime'],
                        location: restaurant['location'],
                        menuItemsCount: restaurant['menuItems'].length,
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