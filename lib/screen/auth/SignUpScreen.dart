import 'package:flutter/material.dart';
import 'package:eatscikmitl/const/app_color.dart';
import 'package:eatscikmitl/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/notification_helper.dart';

/// หน้าจอสมัครสมาชิกสำหรับนักศึกษา (คณะวิทยาศาสตร์)
/// บังคับกรอก: อีเมล, รหัสผ่าน, ชื่อผู้ใช้, เบอร์โทร
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    const Text(
                      'สมัครสมาชิก',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'กรอกข้อมูลเพื่อสร้างบัญชีผู้ใช้',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ข้อมูลบัญชี
                    _buildSectionTitle('ข้อมูลบัญชี'),
                    const SizedBox(height: 12),

                    // อีเมล
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'อีเมล KMITL *',
                        hintText: '65070001@kmitl.ac.th',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'กรุณากรอกอีเมล';
                        }
                        if (!value.contains('@kmitl.ac.th')) {
                          return 'กรุณาใช้อีเมล KMITL เท่านั้น';
                        }
                        if (!RegExp(r'^[0-9]{8}@kmitl\.ac\.th$')
                            .hasMatch(value)) {
                          return 'รูปแบบอีเมลไม่ถูกต้อง (ตัวอย่าง: 65070001@kmitl.ac.th)';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // รหัสผ่าน
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'รหัสผ่าน *',
                        hintText: 'อย่างน้อย 6 ตัวอักษร',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'กรุณากรอกรหัสผ่าน';
                        }
                        if (value.length < 6) {
                          return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // ยืนยันรหัสผ่าน
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'ยืนยันรหัสผ่าน *',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'กรุณายืนยันรหัสผ่าน';
                        }
                        if (value != _passwordController.text) {
                          return 'รหัสผ่านไม่ตรงกัน';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // ข้อมูลส่วนตัว
                    _buildSectionTitle('ข้อมูลส่วนตัว'),
                    const SizedBox(height: 12),

                    // ชื่อผู้ใช้
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'ชื่อผู้ใช้ *',
                        hintText: 'เช่น somchai_k, alice123',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        helperText: 'จะแสดงในระบบและใช้ติดต่อกับร้านค้า',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'กรุณากรอกชื่อผู้ใช้';
                        }
                        if (value.length < 3) {
                          return 'ชื่อผู้ใช้ต้องมีอย่างน้อย 3 ตัวอักษร';
                        }
                        if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                          return 'ใช้ได้เฉพาะตัวอักษร ตัวเลข และ _ เท่านั้น';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // เบอร์โทร
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'เบอร์โทรศัพท์ *',
                        hintText: '081-234-5678',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        helperText: 'สำหรับติดต่อเรื่องออเดอร์อาหาร',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'กรุณากรอกเบอร์โทรศัพท์';
                        }
                        if (!RegExp(r'^[0-9-]{9,12}$').hasMatch(value)) {
                          return 'รูปแบบเบอร์โทรไม่ถูกต้อง';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),
                    // ปุ่มสมัครสมาชิก
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.mainOrange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
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
                                'สมัครสมาชิก',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ลิงก์ไปหน้า Login
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'มีบัญชีอยู่แล้ว? ',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'เข้าสู่ระบบ',
                              style: TextStyle(
                                color: AppColors.mainOrange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final username = _usernameController.text.trim();
      final phone = _phoneController.text.trim();

      // 1. Sign up ด้วย Supabase Auth พร้อมส่ง username และ phone ใน metadata
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'phone_number': phone,
        },
      );

      if (authResponse.user == null) {
        throw Exception('ไม่สามารถสร้างบัญชีได้');
      }

      final userId = authResponse.user!.id;
      print('✅ Signup สำเร็จ - User ID: $userId');

      // 2. สร้างข้อมูล student โดยตรง (ไม่รอ trigger)
      final studentId = email.split('@')[0]; // 66050713
      final currentYear = DateTime.now().year + 543; // 2568
      final studentYear = int.parse(studentId.substring(0, 2)); // 66
      final year = currentYear - (2500 + studentYear);
      final actualYear = year < 1 ? 1 : (year > 5 ? 5 : year);

      print('📝 Creating student record: $studentId, Year: $actualYear');

      await Supabase.instance.client.from('students').insert({
        'id': userId,
        'student_id': studentId,
        'email': email,
        'username': username,
        'phone_number': phone,
        'faculty': 'วิทยาศาสตร์',
        'year': actualYear,
        'university': 'สถาบันเทคโนโลยีพระจอมเกล้าเจ้าคุณทหารลาดกระบัง',
        'profile_completed': true,
      });

      print('✅ Student record created successfully');

      if (mounted) {
        // แสดงข้อความสำเร็จ
        NotificationHelper.showSuccess(
          context,
          'สมัครสมาชิกสำเร็จ! กำลังเข้าสู่ระบบ...',
        );

        // รอ 1 วินาทีแล้ว navigate
        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          // main.dart StreamBuilder จะจัดการ navigation ให้เอง
          Navigator.pop(context);
        }
      }
    } on AuthException catch (e) {
      String errorMessage = 'เกิดข้อผิดพลาด';
      
      print('❌ AuthException: ${e.message}');
      
      if (e.message.contains('already registered') || e.message.contains('already been registered')) {
        errorMessage = 'อีเมลนี้ถูกใช้งานแล้ว';
      } else if (e.message.contains('Invalid email')) {
        errorMessage = 'รูปแบบอีเมลไม่ถูกต้อง';
      } else if (e.message.contains('Password')) {
        errorMessage = 'รหัสผ่านไม่ปลอดภัยพอ';
      } else {
        errorMessage = 'เกิดข้อผิดพลาด: ${e.message}';
      }

      if (mounted) {
        NotificationHelper.showError(
          context,
          errorMessage,
        );
      }
    } catch (e) {
      print('❌ Error signing up: $e');
      if (mounted) {
        NotificationHelper.showError(
          context,
          'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignUp() async {
    // Google sign-up has been removed. Use Supabase email confirmation flow.
    return;
  }
}
