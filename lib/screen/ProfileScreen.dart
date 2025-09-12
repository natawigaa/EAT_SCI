import 'package:eatscikmitl/data/userdemo.dart';
import 'package:eatscikmitl/innnerScreen/EditProfileScreen.dart';
import 'package:eatscikmitl/innnerScreen/WalletScreen.dart';
import 'package:eatscikmitl/screen/auth/LoginScreen.dart';
import 'package:flutter/material.dart';
import 'package:eatscikmitl/const/app_color.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late StudentUser currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = SampleUserData.getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'โปรไฟล์',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black87),
            onPressed: () => _navigateToEditProfile(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            const SizedBox(height: 20),

            _buildProfileHeader(),
            
            const SizedBox(height: 20),
            
            // Wallet & Points Section
            _buildWalletPointsSection(),
            
            const SizedBox(height: 20),
            
            // Menu Options
            _buildMenuSection(),
            
            const SizedBox(height: 20),
            
            // Recent Orders
            _buildRecentOrdersSection(),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile Image
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[200],
                backgroundImage: currentUser.profileImage.isNotEmpty
                    ? AssetImage(currentUser.profileImage)
                    : null,
                child: currentUser.profileImage.isEmpty
                    ? Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.grey[400],
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.mainOrange,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: () => _changeProfileImage(),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Name and Student ID
          Text(
            currentUser.fullName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 4),
          
          Text(
            'รหัสนักศึกษา ${currentUser.studentId}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Faculty and Department
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.mainOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${currentUser.faculty} • ${currentUser.department}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.mainOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          const SizedBox(height: 4),
          
          Text(
            '${currentUser.yearText} • ${currentUser.university}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWalletPointsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      child: Row(
        children: [
          // Wallet Balance
          Expanded(
            child: GestureDetector(
              onTap: () => _navigateToWallet(),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.green,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ยอดเงิน',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '฿${currentUser.walletBalance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Container(
            width: 1,
            height: 60,
            color: Colors.grey[200],
          ),
          
          // Loyalty Points
          Expanded(
            child: GestureDetector(
              onTap: () => _navigateToLoyalty(),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.mainOrange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.stars,
                      color: AppColors.mainOrange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'แต้มสะสม',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${currentUser.loyaltyPoints}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.mainOrange,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    final menuItems = [
      {
        'icon': Icons.history,
        'title': 'ประวัติการสั่งซื้อ',
        'subtitle': 'ดูรายการสั่งซื้อทั้งหมด',
        'onTap': () => _navigateToOrderHistory(),
      },
      {
        'icon': Icons.favorite,
        'title': 'ร้านโปรด',
        'subtitle': '${currentUser.favoriteRestaurants.length} ร้าน',
        'onTap': () => _navigateToFavorites(),
      },
      {
        'icon': Icons.notifications,
        'title': 'การแจ้งเตือน',
        'subtitle': 'จัดการการแจ้งเตือน',
        'onTap': () => _navigateToNotifications(),
      },
      {
        'icon': Icons.settings,
        'title': 'การตั้งค่า',
        'subtitle': 'ตั้งค่าแอปพลิเคชัน',
        'onTap': () => _navigateToSettings(),
      },
      {
        'icon': Icons.help,
        'title': 'ช่วยเหลือ',
        'subtitle': 'คำถามที่พบบ่อยและการสนับสนุน',
        'onTap': () => _navigateToHelp(),
      },
      {
        'icon': Icons.logout,
        'title': 'ออกจากระบบ',
        'subtitle': 'ออกจากบัญชีผู้ใช้',
        'onTap': () => _logout(),
        'isDestructive': true,
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
        children: menuItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == menuItems.length - 1;
          
          return Column(
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (item['isDestructive'] == true 
                        ? Colors.red 
                        : AppColors.mainOrange).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: item['isDestructive'] == true 
                        ? Colors.red 
                        : AppColors.mainOrange,
                    size: 20,
                  ),
                ),
                title: Text(
                  item['title'] as String,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: item['isDestructive'] == true 
                        ? Colors.red 
                        : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  item['subtitle'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
                onTap: item['onTap'] as VoidCallback,
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  color: Colors.grey[200],
                  indent: 16,
                  endIndent: 16,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentOrdersSection() {
    if (currentUser.orderHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'คำสั่งซื้อล่าสุด',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () => _navigateToOrderHistory(),
                  child: const Text(
                    'ดูทั้งหมด',
                    style: TextStyle(
                      color: AppColors.mainOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...currentUser.orderHistory.take(3).map((order) {
            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.restaurant,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              title: Text(
                order['restaurantName'],
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                '฿${order['totalAmount'].toStringAsFixed(2)} • ${_formatDate(order['orderDate'])}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'สำเร็จ',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              onTap: () => _viewOrderDetail(order['orderId']),
            );
          }).toList(),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'วันนี้';
    } else if (difference == 1) {
      return 'เมื่อวาน';
    } else if (difference < 7) {
      return '$difference วันที่แล้ว';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Navigation methods
  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => const EditProfileScreen())
    );
    
    if (result == true) {
      // Refresh current user data if changes were saved
      setState(() {
        currentUser = SampleUserData.getCurrentUser();
      });
    }
}

  void _changeProfileImage() {
    print('Change Profile Image');
  }

  void _navigateToWallet() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WalletScreen()),
    );
  }

  void _navigateToLoyalty() {
    print('Navigate to Loyalty Points');
  }

  void _navigateToOrderHistory() {
    print('Navigate to Order History');
  }

  void _navigateToFavorites() {
    print('Navigate to Favorites');
  }

  void _navigateToNotifications() {
    print('Navigate to Notifications');
  }

  void _navigateToSettings() {
    print('Navigate to Settings');
  }

  void _navigateToHelp() {
    print('Navigate to Help');
  }

  void _viewOrderDetail(String orderId) {
    print('View Order Detail: $orderId');
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ออกจากระบบ'),
          content: const Text('คุณต้องการออกจากระบบใช่หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text(
                'ออกจากระบบ',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}