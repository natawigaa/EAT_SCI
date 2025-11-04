import 'package:flutter/material.dart';
import 'package:eatscikmitl/const/app_color.dart';
import 'package:eatscikmitl/services/supabase_service.dart';
import 'package:eatscikmitl/services/cart_service.dart';
import 'package:eatscikmitl/screen/FoodOrderScreen.dart';
import '../utils/notification_helper.dart';

class DetailRestaurantScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantImage;
  final String restaurantName;
  final String phone;
  final String category;
  final String description;
  final double rating;
  final String openTime;
  final String closeTime;
  final String location;
  final int menuItemsCount;

  const DetailRestaurantScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantImage,
    required this.restaurantName,
    required this.phone,
    required this.category,
    required this.description,
    required this.rating,
    required this.openTime,
    required this.closeTime,
    required this.location,
    required this.menuItemsCount,
  });

  @override
  State<DetailRestaurantScreen> createState() => _DetailRestaurantScreenState();
}

class _DetailRestaurantScreenState extends State<DetailRestaurantScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isFavorite = false;
  List<Map<String, dynamic>> menuItems = [];
  bool isLoadingMenu = true;
  final CartService _cartService = CartService(); // เพิ่มบรรทัดนี้

  // นับเฉพาะเมนูที่พร้อมให้บริการ
  int get availableMenuCount => menuItems.where((item) => item['isAvailable'] == true).length;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMenuItems();
    
    // ฟังการเปลี่ยนแปลงของตะกร้า
    _cartService.cartUpdateNotifier.addListener(_onCartUpdated);
  }
  
  void _onCartUpdated() {
    // Rebuild UI เมื่อตะกร้ามีการเปลี่ยนแปลง
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadMenuItems() async {
    try {
      setState(() {
        isLoadingMenu = true;
      });

      final menuData = await SupabaseService.getMenuItems(int.parse(widget.restaurantId));
      
      setState(() {
        menuItems = menuData.map((item) => {
          'id': item['id']?.toString() ?? '0',
          'name': item['name'] ?? 'ไม่มีชื่อ',
          'description': item['description'] ?? 'ไม่มีรายละเอียด',
          'price': double.tryParse(item['price']?.toString() ?? '0') ?? 0.0,
          'image_url': item['image_url'] ?? '',
          'category': item['category'] ?? 'ทั่วไป',
          'isPopular': false, // ยังไม่มีข้อมูลนี้ใน database
          'isAvailable': item['is_available'] ?? true,
        }).toList();
        isLoadingMenu = false;
      });

      // Debug logging สำหรับดู URL รูปภาพและสถานะ
      for (var item in menuItems) {
        print('🖼️ Menu ${item['name']}: image_url = "${item['image_url']}" | Available: ${item['isAvailable']}');
      }
      
      print('📊 เมนูทั้งหมด: ${menuItems.length} รายการ | เมนูพร้อมให้บริการ: $availableMenuCount รายการ');

      print('✅ โหลดเมนูสำหรับร้าน ${widget.restaurantName} ได้ ${menuItems.length} รายการ');
    } catch (e) {
      print('❌ Error loading menu items: $e');
      setState(() {
        menuItems = [];
        isLoadingMenu = false;
      });
      
      if (mounted) {
        NotificationHelper.showError(
          context,
          'ไม่สามารถโหลดเมนูอาหารได้: $e',
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cartService.cartUpdateNotifier.removeListener(_onCartUpdated); // ลบ listener
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildRestaurantInfo(),
                _buildTabSection(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.black,
            ),
            onPressed: () {
              setState(() {
                isFavorite = !isFavorite;
              });
            },
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
          ),
          child: widget.restaurantImage.isNotEmpty
              ? Image.asset(
                  widget.restaurantImage,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholderImage();
                  },
                )
              : _buildPlaceholderImage(),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant,
            color: Colors.grey[400],
            size: 60,
          ),
          const SizedBox(height: 8),
          Text(
            'ไม่มีรูปภาพ',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.restaurantName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.mainOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        widget.category,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.mainOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusIndicator(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoCard(
                icon: Icons.star,
                iconColor: Colors.amber,
                title: 'คะแนน',
                value: widget.rating.toStringAsFixed(1),
              ),
              const SizedBox(width: 12),
              _buildInfoCard(
                icon: Icons.restaurant_menu,
                iconColor: AppColors.mainOrange,
                title: 'เมนู',
                value: isLoadingMenu ? 'กำลังโหลด...' : '${menuItems.length} รายการ',
              ),
              const SizedBox(width: 12),
              _buildInfoCard(
                icon: Icons.location_on,
                iconColor: Colors.blue,
                title: 'สถานที่',
                value: widget.location,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildOpeningHours(),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpeningHours() {
    bool isOpen = _isRestaurantOpen();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOpen ? Colors.green.withOpacity(0.05) : Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOpen ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            color: isOpen ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'เวลาเปิด-ปิด',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.openTime} - ${widget.closeTime}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isOpen ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isOpen ? 'เปิด' : 'ปิด',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    bool isOpen = _isRestaurantOpen();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isOpen ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOpen ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isOpen ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isOpen ? 'เปิดแล้ว' : 'ปิดแล้ว',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isOpen ? Colors.green[700] : Colors.red[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(25),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.mainOrange,
                borderRadius: BorderRadius.circular(25),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 14,
              ),
              tabs: [
                Tab(text: isLoadingMenu ? 'เมนู' : 'เมนูพร้อมให้บริการ $availableMenuCount รายการ'),
                const Tab(text: 'รีวิว'),
                const Tab(text: 'ข้อมูล'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMenuTab(),
                _buildReviewTab(),
                _buildInfoTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTab() {
    if (isLoadingMenu) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (menuItems.isEmpty) {
      return const Center(
        child: Text(
          'ไม่พบข้อมูลเมนู',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final menuItem = menuItems[index];
        final isPopular = menuItem['isPopular'] ?? false;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 0.5,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              // Menu item image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      // รูปภาพเมนู
                      menuItem['image_url'] != null && menuItem['image_url'].isNotEmpty
                        ? Image.network(
                            menuItem['image_url'],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) {
                                return child;
                              }
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              print('❌ Error loading image: ${menuItem['image_url']} - $error');
                              return Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[100],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      color: Colors.grey[400],
                                      size: 24,
                                    ),
                                    Text(
                                      'รูปไม่แสดง',
                                      style: TextStyle(
                                        fontSize: 8,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                        : Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[100],
                            child: Icon(
                              Icons.fastfood,
                              color: Colors.grey[400],
                              size: 30,
                            ),
                          ),
                      
                      // Overlay สีเทาสำหรับเมนูที่ไม่พร้อมให้บริการ
                      if (menuItem['isAvailable'] != true)
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.block,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'ไม่พร้อม',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Menu item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            menuItem['name'] ?? 'ไม่มีชื่อ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: menuItem['isAvailable'] == true 
                                  ? Colors.black87 
                                  : Colors.grey[500],
                            ),
                          ),
                        ),
                        if (isPopular)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.orange, width: 0.5),
                            ),
                            child: const Text(
                              'ยอดนิยม',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      menuItem['description'],
                      style: TextStyle(
                        fontSize: 12,
                        color: menuItem['isAvailable'] == true 
                            ? Colors.grey[600] 
                            : Colors.grey[400],
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '฿${menuItem['price']}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: menuItem['isAvailable'] == true 
                                ? AppColors.mainOrange 
                                : Colors.grey[400],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: menuItem['isAvailable'] == true 
                                ? AppColors.mainOrange 
                                : Colors.grey[400],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: menuItem['isAvailable'] == true 
                                  ? () {
                                      _addToCart(menuItem);
                                    }
                                  : null, // Disable onTap ถ้าไม่พร้อมให้บริการ
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                child: Text(
                                  menuItem['isAvailable'] == true ? 'เพิ่ม' : 'ไม่พร้อม',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addToCart(Map<String, dynamic> menuItem) {
    // ใช้ CartService เพื่อเพิ่มลงตะกร้าจริงๆ
    final cartService = CartService();
    final menuName = menuItem['name'] ?? 'เมนูนี้';
    
    // ⭐ ตรวจสอบว่ามีสินค้าจากร้านอื่นในตะกร้าหรือไม่
    if (cartService.hasItemsFromDifferentRestaurant(widget.restaurantId)) {
      // แสดง Dialog เตือนและให้เลือก
      _showDifferentRestaurantDialog(menuItem);
      return;
    }
    
    // ถ้าเป็นร้านเดียวกัน หรือตะกร้าว่าง ให้เพิ่มได้เลย
    cartService.addToCart(
      menuItem,
      widget.restaurantId,
      widget.restaurantName,
    );
    
    // แสดง notification
    NotificationHelper.showSuccess(
      context,
      'เพิ่ม $menuName แล้ว',
    );
  }// แสดง Dialog เตือนเมื่อพยายามเพิ่มสินค้าจากร้านอื่น
  void _showDifferentRestaurantDialog(Map<String, dynamic> menuItem) {
    final cartService = CartService();
    final currentRestaurant = cartService.currentRestaurantName ?? 'ร้านอื่น';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Text('สั่งอาหารจากหลายร้าน?'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ตอนนี้ตะกร้าของคุณมีอาหารจาก "$currentRestaurant" อยู่แล้ว',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 แนะนำ:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'ควรสั่งอาหารจากร้านเดียวกันในแต่ละครั้ง เพื่อความสะดวกในการรับอาหารและการจัดการของร้าน',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'ยกเลิก',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // ล้างตะกร้าเดิมและเพิ่มเมนูใหม่
                cartService.clearCart();
                cartService.addToCart(
                  menuItem,
                  widget.restaurantId,
                  widget.restaurantName,
                );
                NotificationHelper.showSuccess(
                  context,
                  'ล้างตะกร้าและเพิ่ม ${menuItem['name']} แล้ว',
                );
              },
              child: Text(
                'ล้างตะกร้าและเพิ่มเมนูนี้',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReviewTab() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.mainOrange,
                    child: Text(
                      'U${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ผู้ใช้ ${index + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Row(
                          children: List.generate(5, (starIndex) {
                            return Icon(
                              Icons.star,
                              size: 14,
                              color: starIndex < (4 - index % 2)
                                  ? Colors.amber
                                  : Colors.grey[300],
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '2 วันที่แล้ว',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'อาหารอร่อยมาก บริการดี บรรยากาศเยี่ยม แนะนำให้มาลอง!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoItem(
            icon: Icons.phone,
            title: 'เบอร์โทรศัพท์',
            value: widget.phone,
          ),
          _buildInfoItem(
            icon: Icons.location_on,
            title: 'ที่อยู่',
            value: 'โรงอาหารคณะวิทยาศาสตร์ ${widget.location}',
          ),
          _buildInfoItem(
            icon: Icons.access_time,
            title: 'เวลาทำการ',
            value: 'จันทร์-ศุกร์: ${widget.openTime} - ${widget.closeTime}',
          ),
          _buildInfoItem(
            icon: Icons.payment,
            title: 'การชำระเงิน',
            value: 'เงินสด, โอนผ่านธนาคาร, PromptPay',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.mainOrange,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final totalItems = _cartService.totalItems;
    final totalAmount = _cartService.totalAmount;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: totalItems > 0
              ? () {
                  // นำไปหน้าตะกร้าสินค้า
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FoodOrderScreen(),
                    ),
                  );
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: totalItems > 0 
                ? AppColors.mainOrange 
                : Colors.grey[300],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: totalItems > 0 ? 2 : 0,
            disabledBackgroundColor: Colors.grey[300],
            disabledForegroundColor: Colors.grey[600],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ไอคอนตะกร้า + Badge จำนวนสินค้า
              Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.shopping_cart,
                    size: 24,
                  ),
                  if (totalItems > 0)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          totalItems.toString(),
                          style: TextStyle(
                            color: AppColors.mainOrange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Text(
                'ดูตะกร้าสินค้า',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: totalItems > 0 ? Colors.white : Colors.grey[600],
                ),
              ),
              if (totalItems > 0) ...[
                const Spacer(),
                Text(
                  '${totalAmount.toStringAsFixed(0)} บาท',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _isRestaurantOpen() {
    final now = TimeOfDay.now();
    final openTimeOfDay = _parseTime(widget.openTime);
    final closeTimeOfDay = _parseTime(widget.closeTime);
    
    return _isTimeInRange(now, openTimeOfDay, closeTimeOfDay);
  }

  TimeOfDay _parseTime(String timeString) {
    // แยกทั้ง : และ . เพื่อรองรับทั้งสองรูปแบบ
    final parts = timeString.contains(':') 
        ? timeString.split(':') 
        : timeString.split('.');
    
    if (parts.length != 2) {
      // ถ้าไม่สามารถแยกได้ ให้ใช้เวลาเริ่มต้น
      return const TimeOfDay(hour: 8, minute: 0);
    }
    
    try {
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      // ถ้า parse ไม่ได้ ให้ใช้เวลาเริ่มต้น
      print('❌ Error parsing time: $timeString - $e');
      return const TimeOfDay(hour: 8, minute: 0);
    }
  }

  bool _isTimeInRange(TimeOfDay current, TimeOfDay start, TimeOfDay end) {
    final currentMinutes = current.hour * 60 + current.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    
    if (startMinutes <= endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  }
}