import 'package:flutter/material.dart';
import 'package:eatscikmitl/const/app_color.dart';
import 'package:eatscikmitl/services/supabase_service.dart';
import 'package:eatscikmitl/rootScreen.dart';
//import 'package:eatscikmitl/dashboard/Restuarant_dashboard.dart';
import 'package:eatscikmitl/screen/auth/SignUpScreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/notification_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> 
    with TickerProviderStateMixin {
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _logoController;
  late AnimationController _pulseController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotationAnimation;
  late Animation<double> _pulseAnimation;
  
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = false;
  
  List<String> _savedEmails = []; // เก็บอีเมลที่เคยใช้
  bool _showEmailDropdown = false; // แสดง dropdown

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    _loadSavedEmails(); // โหลดอีเมลที่บันทึกไว้
  }
  
  // โหลดอีเมลที่เคย login
  Future<void> _loadSavedEmails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final emails = prefs.getStringList('saved_emails') ?? [];
      setState(() {
        _savedEmails = emails;
        // ถ้ามีอีเมลที่บันทึกไว้ ใส่ตัวแรกเป็นค่าเริ่มต้น
        if (emails.isNotEmpty) {
          _usernameController.text = emails.first;
        }
      });
    } catch (e) {
      print('❌ Error loading saved emails: $e');
    }
  }
  
  // บันทึกอีเมลหลัง login สำเร็จ
  Future<void> _saveEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> emails = prefs.getStringList('saved_emails') ?? [];
      
      // ลบอีเมลเก่าออก (ถ้ามี) และเพิ่มกลับเป็นตัวแรก
      emails.remove(email);
      emails.insert(0, email);
      
      // เก็บสูงสุด 5 อีเมล
      if (emails.length > 5) {
        emails = emails.sublist(0, 5);
      }
      
      await prefs.setStringList('saved_emails', emails);
      
      setState(() {
        _savedEmails = emails;
      });
    } catch (e) {
      print('❌ Error saving email: $e');
    }
  }

  void _initializeAnimations() {
    // Fade in animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // Slide up animation
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Logo animations
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _logoScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));
    _logoRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));

    // Pulse animation for floating elements
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _logoController.forward();
    
    await Future.delayed(const Duration(milliseconds: 500));
    _fadeController.forward();
    _slideController.forward();
    
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _logoController.dispose();
    _pulseController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.mainOrange.withOpacity(0.1),
              Colors.white,
              AppColors.mainOrange.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 
                          MediaQuery.of(context).padding.top,
              ),
              child: Stack(
                children: [
                  _buildFloatingElements(),
                  _buildMainContent(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingElements() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Stack(
            children: [
              // Top left floating circle
              Positioned(
                top: 50,
                left: -50,
                child: Transform.scale(
                  scale: _pulseAnimation.value * 0.7,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.mainOrange.withOpacity(0.1),
                    ),
                  ),
                ),
              ),
              // Bottom right floating circle
              Positioned(
                bottom: 100,
                right: -30,
                child: Transform.scale(
                  scale: _pulseAnimation.value * 0.8,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.mainOrange.withOpacity(0.08),
                    ),
                  ),
                ),
              ),
              // Middle left small circle
              Positioned(
                top: 300,
                left: 20,
                child: Transform.scale(
                  scale: _pulseAnimation.value * 0.6,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.mainOrange.withOpacity(0.06),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60), // แทน Spacer แรก
          _buildLogo(),
          const SizedBox(height: 40),
          _buildWelcomeText(),
          const SizedBox(height: 40),
          _buildLoginForm(),
          const SizedBox(height: 30),
          _buildLoginButton(),
          const SizedBox(height: 20),
          _buildForgotPassword(),
          const SizedBox(height: 60), // แทน Spacer ท้าย
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScaleAnimation.value,
          child: Transform.rotate(
            angle: _logoRotationAnimation.value * 0.1,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.mainOrange.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // University Logo (using Text as placeholder)
                    Text(
                      'KMITL',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.mainOrange,
                      ),
                    ),
                    SizedBox(height: 2),
                    Icon(
                      Icons.school,
                      color: AppColors.mainOrange,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeText() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            const Text(
              'ยินดีต้อนรับ',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'เข้าสู่ระบบ Eat@Sci KMITL',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'สถาบันเทคโนโลยีพระจอมเกล้าคุณทหารลาดกระบัง',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextField(
                  controller: _usernameController,
                  label: 'อีเมล',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกอีเมล';
                    }
                    if (!value.contains('@')) {
                      return 'รูปแบบอีเมลไม่ถูกต้อง';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _passwordController,
                  label: 'รหัสผ่าน',
                  icon: Icons.lock,
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกรหัสผ่าน';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildRememberMe(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          obscureText: isPassword && !_isPasswordVisible,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 16),
          onTap: () {
            // แสดง dropdown เมื่อกดที่ช่อง email
            if (!isPassword && _savedEmails.isNotEmpty) {
              setState(() {
                _showEmailDropdown = true;
              });
            }
          },
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            prefixIcon: Icon(
              icon,
              color: AppColors.mainOrange,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  )
                : (_savedEmails.isNotEmpty && !isPassword)
                    ? IconButton(
                        icon: Icon(
                          _showEmailDropdown 
                              ? Icons.arrow_drop_up 
                              : Icons.arrow_drop_down,
                          color: Colors.grey[600],
                        ),
                        onPressed: () {
                          setState(() {
                            _showEmailDropdown = !_showEmailDropdown;
                          });
                        },
                      )
                    : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.mainOrange, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        
        // Dropdown แสดงอีเมลที่บันทึกไว้
        if (_showEmailDropdown && _savedEmails.isNotEmpty && !isPassword)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: _savedEmails.map((email) {
                return InkWell(
                  onTap: () {
                    setState(() {
                      controller.text = email;
                      _showEmailDropdown = false;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.history,
                          size: 18,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            email,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildRememberMe() {
    return Row(
      children: [
        Checkbox(
          value: _rememberMe,
          onChanged: (value) {
            setState(() {
              _rememberMe = value ?? false;
            });
          },
          activeColor: AppColors.mainOrange,
        ),
        const Text(
          'จดจำการเข้าสู่ระบบ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mainOrange,
              foregroundColor: Colors.white,
              elevation: 8,
              shadowColor: AppColors.mainOrange.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'เข้าสู่ระบบ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }




  Widget _buildForgotPassword() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // ปุ่มสมัครสมาชิก
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'ยังไม่มีบัญชี? ',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignUpScreen(),
                    ),
                  );
                },
                child: const Text(
                  'สมัครสมาชิก',
                  style: TextStyle(
                    color: AppColors.mainOrange,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _handleForgotPassword,
            child: const Text(
              'ลืมรหัสผ่าน?',
              style: TextStyle(
                color: AppColors.mainOrange,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          Text(
            'EatSci KMITL v1.0',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '© 2024 King Mongkut\'s Institute of Technology Ladkrabang',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[400],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _usernameController.text.trim();
      final password = _passwordController.text;

      print('🔐 กำลัง login ด้วย email: $email');

      // Login ด้วย Supabase Auth
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        print('✅ Login สำเร็จ! User ID: ${response.user!.id}');
        print('📧 Email: ${response.user!.email}');
        
        // บันทึกอีเมลที่ login สำเร็จ
        await _saveEmail(email);

        // ตรวจสอบ email domain
        if (email.endsWith('@kmitl.ac.th')) {
          // นักศึกษา KMITL
          print('👨‍🎓 นักศึกษา KMITL - StreamBuilder จะนำไปหน้า Student App อัตโนมัติ');
        } else {
          // ร้านค้า - หา restaurant_id จาก owner_id
          print('🏪 ร้านค้า - กำลังหา restaurant_id...');
          final restaurants = await SupabaseService.getRestaurants();
          final myRestaurant = restaurants.firstWhere(
            (r) => r['owner_id'] == response.user!.id,
            orElse: () => {},
          );
          
          if (myRestaurant.isEmpty) {
            // ไม่พบร้านที่เชื่อมกับ owner_id นี้
            setState(() {
              _isLoading = false;
            });
            NotificationHelper.showError(
              context,
              'ไม่พบร้านอาหารที่เชื่อมกับบัญชีนี้\nกรุณาติดต่อผู้ดูแลระบบ',
            );
            return;
          }
          
          print('✅ พบร้าน: ${myRestaurant['name']} (ID: ${myRestaurant['id']})');
          print('StreamBuilder จะนำไปหน้า Restaurant Dashboard อัตโนมัติ');
        }
        
        // ปิด loading และให้ StreamBuilder ใน main.dart จัดการ navigation
        setState(() {
          _isLoading = false;
        });
        
        // แสดง SnackBar สั้นๆ เพื่อ feedback
        if (mounted) {
          NotificationHelper.showSuccess(
            context,
            email.endsWith('@kmitl.ac.th') 
              ? 'เข้าสู่ระบบสำเร็จ (นักศึกษา)' 
              : 'เข้าสู่ระบบสำเร็จ (ร้านค้า)',
          );
        }
      }
    } on AuthException catch (e) {
      print('❌ Auth Error: ${e.message}');
      setState(() {
        _isLoading = false;
      });

      String errorMessage = 'เกิดข้อผิดพลาด';
      if (e.message.contains('Invalid login credentials')) {
        errorMessage = 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
      } else if (e.message.contains('Email not confirmed')) {
        errorMessage = 'กรุณายืนยันอีเมลก่อนเข้าสู่ระบบ';
      } else {
        errorMessage = e.message;
      }

      NotificationHelper.showError(
        context,
        errorMessage,
      );
    } catch (e) {
      print('❌ Error: $e');
      setState(() {
        _isLoading = false;
      });

      NotificationHelper.showError(
        context,
        'เกิดข้อผิดพลาดในการเข้าสู่ระบบ',
      );
    }
  }



  void _handleForgotPassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('ลืมรหัสผ่าน'),
        content: const Text(
          'กรุณาติดต่อเจ้าหน้าที่ IT ของมหาวิทยาลัย\n'
          'หรือส่งอีเมลไปที่ it-support@kmitl.ac.th'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'ตกลง',
              style: TextStyle(color: AppColors.mainOrange),
            ),
          ),
        ],
      ),
    );
  }
}