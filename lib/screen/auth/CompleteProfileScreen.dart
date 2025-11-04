import 'package:flutter/material.dart';
import 'package:eatscikmitl/const/app_color.dart';
import 'package:eatscikmitl/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// หน้าจอให้นักศึกษากรอกข้อมูลครั้งแรกหลังสมัคร
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String? _selectedFaculty;
  String? _selectedDepartment;
  
  bool _isLoading = false;
  bool _isLoadingFaculties = true;
  
  List<Map<String, dynamic>> _faculties = [];
  List<Map<String, dynamic>> _departments = [];
  
  String? _studentId;
  String? _email;
  int? _year;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
    _loadFaculties();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    
    // ดึงข้อมูลจาก students table ที่ถูกสร้างโดย trigger
    final studentData = await SupabaseService.getStudentProfile(user.id);
    
    if (studentData != null) {
      setState(() {
        _studentId = studentData['student_id'];
        _email = studentData['email'];
        _year = studentData['year'];
      });
    }
  }

  Future<void> _loadFaculties() async {
    try {
      // ดึงรายชื่อคณะจาก database
      final response = await Supabase.instance.client
          .from('faculties')
          .select()
          .order('name', ascending: true);
      
      setState(() {
        _faculties = List<Map<String, dynamic>>.from(response);
        _isLoadingFaculties = false;
      });
    } catch (e) {
      print('❌ Error loading faculties: $e');
      setState(() {
        _isLoadingFaculties = false;
      });
    }
  }

  Future<void> _loadDepartments(int facultyId) async {
    try {
      // ดึงสาขาวิชาตามคณะที่เลือก
      final response = await Supabase.instance.client
          .from('departments')
          .select()
          .eq('faculty_id', facultyId)
          .order('name', ascending: true);
      
      setState(() {
        _departments = List<Map<String, dynamic>>.from(response);
        _selectedDepartment = null; // รีเซ็ตการเลือกสาขา
      });
    } catch (e) {
      print('❌ Error loading departments: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColors.mainOrange,
        elevation: 0,
        automaticallyImplyLeading: false, // ไม่มีปุ่มย้อนกลับ
        title: const Text(
          'กรอกข้อมูลเพิ่มเติม',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoadingFaculties
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.account_circle,
                            size: 60,
                            color: AppColors.mainOrange,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'ยินดีต้อนรับสู่ EatSci!',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'กรุณากรอกข้อมูลเพื่อใช้งานแอปพลิเคชัน',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // ข้อมูลจากระบบ (อ่านอย่างเดียว)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, 
                                color: Colors.blue[700], 
                                size: 20
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'ข้อมูลจากระบบ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildReadOnlyField('รหัสนักศึกษา', _studentId ?? '-'),
                          const SizedBox(height: 8),
                          _buildReadOnlyField('อีเมล', _email ?? '-'),
                          const SizedBox(height: 8),
                          _buildReadOnlyField('ชั้นปี', _year != null ? 'ปี $_year' : '-'),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // ฟอร์มกรอกข้อมูล
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ข้อมูลส่วนตัว',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // ชื่อ
                          TextFormField(
                            controller: _firstNameController,
                            decoration: InputDecoration(
                              labelText: 'ชื่อ *',
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'กรุณากรอกชื่อ';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // นามสกุล
                          TextFormField(
                            controller: _lastNameController,
                            decoration: InputDecoration(
                              labelText: 'นามสกุล *',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'กรุณากรอกนามสกุล';
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
                              prefixIcon: const Icon(Icons.phone),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              hintText: '081-234-5678',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'กรุณากรอกเบอร์โทรศัพท์';
                              }
                              if (!RegExp(r'^[0-9-]+$').hasMatch(value)) {
                                return 'รูปแบบเบอร์โทรไม่ถูกต้อง';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // คณะ
                          DropdownButtonFormField<String>(
                            value: _selectedFaculty,
                            decoration: InputDecoration(
                              labelText: 'คณะ *',
                              prefixIcon: const Icon(Icons.school),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: _faculties.map((faculty) {
                              return DropdownMenuItem<String>(
                                value: faculty['id'].toString(),
                                child: Text(faculty['name']),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedFaculty = value;
                                _loadDepartments(int.parse(value!));
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'กรุณาเลือกคณะ';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // สาขาวิชา
                          DropdownButtonFormField<String>(
                            value: _selectedDepartment,
                            decoration: InputDecoration(
                              labelText: 'สาขาวิชา *',
                              prefixIcon: const Icon(Icons.subject),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: _departments.map((dept) {
                              return DropdownMenuItem<String>(
                                value: dept['name'],
                                child: Text(dept['name']),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedDepartment = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'กรุณาเลือกสาขาวิชา';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // ปุ่มบันทึก
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _completeProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.mainOrange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'เริ่มใช้งาน',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _completeProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('ไม่พบข้อมูลผู้ใช้');

      // อัปเดตข้อมูลโปรไฟล์
      final success = await SupabaseService.updateStudentProfile(
        userId: user.id,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );

      if (success && mounted) {
        // แสดงข้อความสำเร็จ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.check_circle, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('บันทึกข้อมูลเรียบร้อยแล้ว!'),
                ],
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // รอ 1 วินาทีแล้ว navigate ไปหน้าหลัก
        await Future.delayed(const Duration(seconds: 1));
        
        if (mounted) {
          // Navigator จะถูกจัดการโดย main.dart StreamBuilder
          // เพียงแค่รีเฟรช state
          setState(() {});
        }
      }
    } catch (e) {
      print('❌ Error completing profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง'),
            backgroundColor: Colors.red,
          ),
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
}
