import 'dart:io';
import 'package:eatscikmitl/data/userdemo.dart';
import 'package:flutter/material.dart';
import 'package:eatscikmitl/const/app_color.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late StudentUser currentUser;
  
  // Form controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  // Form key for validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  bool _isLoading = true;
  bool _hasChanges = false;
  
  // ข้อมูลที่โหลดจาก database
  String? _studentId;
  String? _email;
  String? _faculty;
  int? _year;
  String? _university;
  String? _profileImageUrl;
  
  // สำหรับอัปโหลดรูป
  File? _selectedImageFile;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    currentUser = SampleUserData.getCurrentUser(); // Fallback
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('ไม่พบข้อมูลผู้ใช้');
      }

      print('🔍 Loading profile for edit: $userId');

      final response = await Supabase.instance.client
          .from('students')
          .select()
          .eq('id', userId)
          .single();

      print('✅ Profile loaded: $response');

      setState(() {
        // เก็บข้อมูลที่ไม่ให้แก้ไข
        _studentId = response['student_id'] ?? '';
        _email = response['email'] ?? '';
        _faculty = response['faculty'] ?? 'วิทยาศาสตร์';
        _year = response['year'] ?? 1;
        _university = response['university'] ?? '';
        _profileImageUrl = response['profile_image_url'];
        
        // ตั้งค่าข้อมูลที่แก้ไขได้
        _usernameController.text = response['username'] ?? '';
        _firstNameController.text = response['first_name'] ?? '';
        _lastNameController.text = response['last_name'] ?? '';
        _phoneController.text = response['phone_number'] ?? '';
        
        _isLoading = false;
      });
      
      // Listen for changes
      _usernameController.addListener(_onFormChanged);
      _firstNameController.addListener(_onFormChanged);
      _lastNameController.addListener(_onFormChanged);
      _phoneController.addListener(_onFormChanged);
      
    } catch (e) {
      print('❌ Error loading profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถโหลดข้อมูล: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  void _onFormChanged() {
    // ไม่ต้องเช็ค เพราะจะได้ค่าเดิมมาจาก database แล้ว
    setState(() {
      _hasChanges = true;
    });
  }

  // ฟังก์ชันเลือกวิธีการเปลี่ยนรูป
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'เลือกรูปโปรไฟล์',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.mainOrange),
                title: const Text('ถ่ายรูป'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.mainOrange),
                title: const Text('เลือกจากคลังรูปภาพ'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              if (_profileImageUrl != null || _selectedImageFile != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('ลบรูปโปรไฟล์', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteImage();
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ถ่ายรูปจากกล้อง
  Future<void> _pickImageFromCamera() async {
    try {
      print('📸 Pick image from camera');
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImageFile = File(image.path);
          _hasChanges = true;
        });
        print('✅ Camera image selected: ${image.path}');
      }
    } catch (e) {
      print('❌ Error picking from camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถเปิดกล้องได้: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // เลือกรูปจาก Gallery/File picker
  Future<void> _pickImageFromGallery() async {
    try {
      print('🖼️ Pick image from gallery');
      
      // ใช้ file_picker แทน image_picker สำหรับ desktop
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedImageFile = File(result.files.single.path!);
          _hasChanges = true;
        });
        print('✅ Gallery image selected: ${result.files.single.path}');
      }
    } catch (e) {
      print('❌ Error picking from gallery: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถเลือกรูปภาพได้: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ยืนยันการลบรูป
  void _confirmDeleteImage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบรูปโปรไฟล์'),
        content: const Text('คุณต้องการลบรูปโปรไฟล์หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProfileImage();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
  }

  // ลบรูปโปรไฟล์
  void _deleteProfileImage() {
    setState(() {
      _selectedImageFile = null;
      _profileImageUrl = null;
      _hasChanges = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ลบรูปโปรไฟล์แล้ว กรุณากดบันทึกเพื่อยืนยัน'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => _handleBackPress(),
        ),
        title: const Text(
          'แก้ไขโปรไฟล์',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _hasChanges && !_isLoading ? _saveProfile : null,
            icon: Icon(
              Icons.check,
              color: _hasChanges && !_isLoading 
                  ? AppColors.mainOrange 
                  : Colors.grey[400],
              size: 28,
            ),
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  _buildProfileImageSection(),
                  const SizedBox(height: 40),
                  _buildFormSection(),
                  const SizedBox(height: 20),
                  _buildReadOnlyInfoSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileImageSection() {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 70,
              backgroundColor: Colors.grey[200],
              backgroundImage: _selectedImageFile != null
                  ? FileImage(_selectedImageFile!) as ImageProvider
                  : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty
                      ? NetworkImage(_profileImageUrl!)
                      : null),
              child: (_selectedImageFile == null && 
                     (_profileImageUrl == null || _profileImageUrl!.isEmpty))
                  ? Icon(
                      Icons.person,
                      size: 70,
                      color: Colors.grey[400],
                    )
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.mainOrange,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ข้อมูลส่วนตัว',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            _buildFormField(
              controller: _usernameController,
              label: 'ชื่อผู้ใช้',
              icon: Icons.account_circle,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณากรอกชื่อผู้ใช้';
                }
                if (value.length < 3) {
                  return 'ชื่อผู้ใช้ต้องมีอย่างน้อย 3 ตัวอักษร';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildFormField(
              controller: _firstNameController,
              label: 'ชื่อจริง (ถ้ามี)',
              icon: Icons.person,
            ),
            const SizedBox(height: 16),
            _buildFormField(
              controller: _lastNameController,
              label: 'นามสกุล (ถ้ามี)',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildFormField(
              controller: _phoneController,
              label: 'เบอร์โทรศัพท์',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณากรอกเบอร์โทรศัพท์';
                }
                if (!RegExp(r'^[0-9]{10}$').hasMatch(value.replaceAll('-', ''))) {
                  return 'รูปแบบเบอร์โทรไม่ถูกต้อง (10 หลัก)';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 15, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: 15,
        ),
        prefixIcon: Icon(
          icon,
          color: AppColors.mainOrange,
          size: 22,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.mainOrange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Colors.grey[200],
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _buildReadOnlyInfoSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ข้อมูลการศึกษา',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          _buildReadOnlyField(
            label: 'รหัสนักศึกษา',
            value: _studentId ?? '-',
            icon: Icons.badge,
          ),
          const SizedBox(height: 16),
          _buildReadOnlyField(
            label: 'อีเมล',
            value: _email ?? '-',
            icon: Icons.email,
          ),
          const SizedBox(height: 16),
          _buildReadOnlyField(
            label: 'คณะ',
            value: _faculty ?? '-',
            icon: Icons.school,
          ),
          const SizedBox(height: 16),
          _buildReadOnlyField(
            label: 'ชั้นปี',
            value: 'ปี $_year',
            icon: Icons.calendar_today,
          ),
          const SizedBox(height: 16),
          _buildReadOnlyField(
            label: 'มหาวิทยาลัย',
            value: _university ?? '-',
            icon: Icons.location_city,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.mainOrange,
            size: 22,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
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

  void _handleBackPress() {
    if (_hasChanges) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('บันทึกการเปลี่ยนแปลง?'),
          content: const Text('คุณมีการเปลี่ยนแปลงที่ยังไม่ได้บันทึก ต้องการบันทึกก่อนออกหรือไม่?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text(
                'ไม่บันทึก',
                style: TextStyle(color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _saveProfile();
              },
              child: const Text('บันทึก'),
            ),
          ],
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('ไม่พบข้อมูลผู้ใช้ กรุณาเข้าสู่ระบบใหม่');
      }

      String? uploadedImageUrl = _profileImageUrl;

      // จัดการรูปภาพ
      if (_selectedImageFile != null) {
        // อัปโหลดรูปใหม่
        print('📤 Uploading profile image...');
        
        final fileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final filePath = 'profile_images/$fileName';
        
        try {
          // อัปโหลดไปยัง Supabase Storage bucket 'profile_images'
          await Supabase.instance.client.storage
              .from('profile_images')
              .upload(
                filePath,
                _selectedImageFile!,
                fileOptions: const FileOptions(
                  cacheControl: '3600',
                  upsert: true,
                ),
              );

          // ดึง public URL
          uploadedImageUrl = Supabase.instance.client.storage
              .from('profile_images')
              .getPublicUrl(filePath);
          
          print('✅ Image uploaded: $uploadedImageUrl');
          
          // ลบรูปเก่าออกจาก storage (ถ้ามี)
          if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
            try {
              final oldPath = _profileImageUrl!.split('/profile_images/').last;
              await Supabase.instance.client.storage
                  .from('profile_images')
                  .remove(['profile_images/$oldPath']);
              print('🗑️ Old image deleted');
            } catch (e) {
              print('⚠️ Could not delete old image: $e');
            }
          }
        } catch (e) {
          print('❌ Error uploading image: $e');
          throw Exception('ไม่สามารถอัปโหลดรูปภาพได้: $e');
        }
      } else if (_profileImageUrl == null && _selectedImageFile == null) {
        // ผู้ใช้ลบรูปโปรไฟล์
        if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
          try {
            final oldPath = _profileImageUrl!.split('/profile_images/').last;
            await Supabase.instance.client.storage
                .from('profile_images')
                .remove(['profile_images/$oldPath']);
            print('🗑️ Profile image deleted');
          } catch (e) {
            print('⚠️ Could not delete image: $e');
          }
        }
        uploadedImageUrl = null;
      }

      // Update student profile in Supabase
      await Supabase.instance.client
          .from('students')
          .update({
            'username': _usernameController.text.trim(),
            'first_name': _firstNameController.text.trim().isEmpty 
                ? null 
                : _firstNameController.text.trim(),
            'last_name': _lastNameController.text.trim().isEmpty 
                ? null 
                : _lastNameController.text.trim(),
            'phone_number': _phoneController.text.trim(),
            'profile_image_url': uploadedImageUrl,
          })
          .eq('id', userId);

      print('✅ Profile updated successfully for user: $userId');
      print('Username: ${_usernameController.text}');
      print('First Name: ${_firstNameController.text}');
      print('Last Name: ${_lastNameController.text}');
      print('Phone: ${_phoneController.text}');
      print('Profile Image: $uploadedImageUrl');

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกข้อมูลเรียบร้อยแล้ว'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        setState(() {
          _hasChanges = false;
          _profileImageUrl = uploadedImageUrl;
          _selectedImageFile = null;
        });
        
        Navigator.of(context).pop(true); // Return true to indicate changes were saved
      }
    } catch (e) {
      print('❌ Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
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