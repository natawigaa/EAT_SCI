// models/student_user.dart
class StudentUser {
  final String userId;
  final String studentId;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String profileImage;
  final String faculty;
  final String department;
  final int year;
  final String university;
  final DateTime joinDate;
  final int loyaltyPoints;
  final List<String> favoriteRestaurants;
  final List<Map<String, dynamic>> orderHistory;
  final Map<String, dynamic> preferences;

  StudentUser({
    required this.userId,
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    this.profileImage = '',
    required this.faculty,
    required this.department,
    required this.year,
    required this.university,
    required this.joinDate,
    this.loyaltyPoints = 0,
    this.favoriteRestaurants = const [],
    this.orderHistory = const [],
    this.preferences = const {},
  });

  String get fullName => '$firstName $lastName';
  
  String get yearText {
    switch (year) {
      case 1: return 'ปี 1';
      case 2: return 'ปี 2';
      case 3: return 'ปี 3';
      case 4: return 'ปี 4';
      default: return 'ปี $year';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'studentId': studentId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'profileImage': profileImage,
      'faculty': faculty,
      'department': department,
      'year': year,
      'university': university,
      'joinDate': joinDate.toIso8601String(),
      'loyaltyPoints': loyaltyPoints,
      'favoriteRestaurants': favoriteRestaurants,
      'orderHistory': orderHistory,
      'preferences': preferences,
    };
  }

factory StudentUser.fromJson(Map<String, dynamic> json) {
    return StudentUser(
      userId: json['userId'],
      studentId: json['studentId'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      profileImage: json['profileImage'] ?? '',
      faculty: json['faculty'],
      department: json['department'],
      year: json['year'],
      university: json['university'],
      joinDate: DateTime.parse(json['joinDate']),
      loyaltyPoints: json['loyaltyPoints'] ?? 0,
      favoriteRestaurants: List<String>.from(json['favoriteRestaurants'] ?? []),
      orderHistory: List<Map<String, dynamic>>.from(json['orderHistory'] ?? []),
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
    );
  }
}

// data/sample_user.dart
class SampleUserData {
  static StudentUser getCurrentUser() {
    return StudentUser(
      userId: 'user_001',
      studentId: '65070001',
      firstName: 'สมชาย',
      lastName: 'ใจดี',
      email: 'somchai.jaidee@mail.kmutt.ac.th',
      phoneNumber: '089-123-4567',
      profileImage: 'asset/profile_default.png',
      faculty: 'คณะวิทยาศาสตร์',
      department: 'วิทยาการคอมพิวเตอร์',
      year: 3,
      university: 'สถาบันเทคโนโลยีพระจอมเกล้าคุณทหารลาดกระบัง',
      joinDate: DateTime(2024, 6, 15),
      loyaltyPoints: 850,
      favoriteRestaurants: ['shop_001', 'shop_003', 'shop_005'],
      orderHistory: [], // เริ่มต้นด้วย list ว่าง - ให้ผู้ใช้สั่งอาหารจริงก่อน
      preferences: {
        'notifications': true,
        'language': 'th',
        'theme': 'light',
        'autoReorder': false,
      },
    );
  }
}