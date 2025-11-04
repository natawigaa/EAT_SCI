import 'package:eatscikmitl/data/userdemo.dart';
import 'package:eatscikmitl/innnerScreen/EditProfileScreen.dart';
import 'package:eatscikmitl/innnerScreen/HistoryScreen.dart';
import 'package:eatscikmitl/screen/auth/LoginScreen.dart';
import 'package:flutter/material.dart';
import 'package:eatscikmitl/const/app_color.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late StudentUser currentUser;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    currentUser = SampleUserData.getCurrentUser(); // Default fallback
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('ไม่พบข้อมูลผู้ใช้');
      }

      print('🔍 Loading profile for user: $userId');

      final response = await Supabase.instance.client
          .from('students')
          .select()
          .eq('id', userId)
          .maybeSingle();

      print('✅ Profile data response: $response');

      // ถ้าไม่มีข้อมูล = ให้แสดง error แทนที่จะสร้างใหม่
      if (response == null) {
        throw Exception('ไม่พบข้อมูลนักศึกษา กรุณาสมัครสมาชิกใหม่');
      }

      setState(() {
        currentUser = StudentUser(
          userId: userId,
          studentId: response['student_id'] ?? '',
          firstName: response['first_name'] ?? '',
          lastName: response['last_name'] ?? '',
          email: response['email'] ?? '',
          faculty: response['faculty'] ?? 'วิทยาศาสตร์',
          department: response['username'] ?? 'วิทยาการคอมพิวเตอร์', // ใช้ username ชั่วคราว
          year: response['year'] ?? 1,
          university: response['university'] ?? '',
          phoneNumber: response['phone_number'] ?? '',
          profileImage: response['profile_image_url'] ?? '',
          joinDate: response['created_at'] != null 
              ? DateTime.parse(response['created_at']).toLocal() 
              : DateTime.now(),
          orderHistory: [],
          favoriteRestaurants: [],
        );
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading profile: $e');
      setState(() {
        _errorMessage = 'ไม่สามารถโหลดข้อมูลโปรไฟล์: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
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
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('ออกจากระบบและสมัครใหม่'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loadUserProfile,
                child: const Text('ลองอีกครั้ง'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'โปรไฟล์',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.mainOrange, size: 26),
            onPressed: () => _navigateToEditProfile(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100), // เพิ่ม padding ด้านล่าง
        child: Column(
          children: [
            const SizedBox(height: 30),
            _buildProfileHeader(),
            const SizedBox(height: 40),
            _buildMenuSection(),
            const SizedBox(height: 20),
            _buildRecentOrdersSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        // Profile Image
        CircleAvatar(
          radius: 70,
          backgroundColor: Colors.grey[200],
          backgroundImage: currentUser.profileImage.isNotEmpty
              ? NetworkImage(currentUser.profileImage) as ImageProvider
              : null,
          child: currentUser.profileImage.isEmpty
              ? Icon(
                  Icons.person,
                  size: 70,
                  color: Colors.grey[400],
                )
              : null,
        ),
        
        const SizedBox(height: 20),
        
        // Name and Username
        Text(
          currentUser.fullName.isNotEmpty ? currentUser.fullName : currentUser.department,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        
        const SizedBox(height: 6),
        
        Text(
          'รหัสนักศึกษา ${currentUser.studentId}',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Faculty Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.mainOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.mainOrange.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            currentUser.faculty,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.mainOrange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          '${currentUser.yearText} • ${currentUser.university}',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[500],
          ),
          textAlign: TextAlign.center,
        ),
      ],
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: menuItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: item['onTap'] as VoidCallback,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (item['isDestructive'] == true 
                            ? Colors.red 
                            : AppColors.mainOrange).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: item['isDestructive'] == true 
                            ? Colors.red 
                            : AppColors.mainOrange,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'] as String,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: item['isDestructive'] == true 
                                  ? Colors.red 
                                  : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['subtitle'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey[400],
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentOrdersSection() {
    if (currentUser.orderHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'คำสั่งซื้อล่าสุด',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
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
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...currentUser.orderHistory.take(3).map((order) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => _viewOrderDetail(order['orderId']),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.restaurant_menu,
                          color: Colors.green,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order['restaurantName'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '฿${order['totalAmount'].toStringAsFixed(2)} • ${_formatDate(order['orderDate'])}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'สำเร็จ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    // แปลง UTC เป็นเวลาท้องถิ่น (เวลาไทย GMT+7)
    final date = DateTime.parse(dateString).toLocal();
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
      // Refresh profile data from Supabase
      _loadUserProfile();
    }
}

  void _navigateToOrderHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HistoryScreen()),
    );
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

  void _logout() async {
    // แสดง dialog และรอผลตอบ
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('ออกจากระบบ'),
          content: const Text('คุณต้องการออกจากระบบใช่หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'ออกจากระบบ',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
    
    // ถ้ากด "ออกจากระบบ"
    if (shouldLogout == true) {
      try {
        await Supabase.instance.client.auth.signOut();
        print('✅ Logout สำเร็จ - StreamBuilder จะนำไป LoginScreen อัตโนมัติ');
        // ไม่ต้อง navigate เลย - ให้ main.dart StreamBuilder จัดการเอง
      } catch (e) {
        print('❌ Logout error: $e');
      }
    }
  }
}