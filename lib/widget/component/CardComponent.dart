import 'package:eatscikmitl/screen/DetailRestuarantScreen.dart';
import 'package:flutter/material.dart';
import 'package:eatscikmitl/const/app_color.dart';

class CardComponent extends StatelessWidget {
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
  final VoidCallback? onTap;

  const CardComponent({
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
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context)=> 
      DetailRestaurantScreen(restaurantId: restaurantId, restaurantImage: restaurantImage, restaurantName: restaurantName,phone: phone, category: category, description: description, rating: rating, openTime: openTime, closeTime: closeTime, location: location, menuItemsCount: menuItemsCount))),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Restaurant image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: restaurantImage.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          restaurantImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderImage();
                          },
                        ),
                      )
                    : _buildPlaceholderImage(),
              ),
              const SizedBox(width: 12),
              // Restaurant details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Restaurant name
                    Text(
                      restaurantName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Category
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.mainOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.mainOrange,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Description
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Rating and menu count
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 14,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• $menuItemsCount เมนู',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Right section with status and arrow
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Status indicator
                  _buildStatusIndicator(),
                  const SizedBox(height: 20),
                  // Location and arrow
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        location,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey[400],
                        size: 12,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant,
            color: Colors.grey[400],
            size: 30,
          ),
          const SizedBox(height: 4),
          Icon(
            Icons.image,
            color: Colors.grey[400],
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    final now = TimeOfDay.now();
    final openTimeOfDay = _parseTime(openTime);
    final closeTimeOfDay = _parseTime(closeTime);
    
    bool isOpen = _isTimeInRange(now, openTimeOfDay, closeTimeOfDay);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isOpen ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOpen ? Colors.green : Colors.red,
          width: 0.5,
        ),
      ),
      child: Text(
        isOpen ? 'เปิด' : 'ปิด',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: isOpen ? Colors.green[700] : Colors.red[700],
        ),
      ),
    );
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
      // Same day
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      // Crosses midnight
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  }
}

// Alternative simplified version for basic restaurant list
class SimpleRestaurantCard extends StatelessWidget {
  final String restaurantImage;
  final String restaurantName;
  final String category;
  final double rating;
  final String location;
  final VoidCallback? onTap;

  const SimpleRestaurantCard({
    super.key,
    required this.restaurantImage,
    required this.restaurantName,
    required this.category,
    required this.rating,
    required this.location,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Restaurant image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: restaurantImage.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          restaurantImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.restaurant,
                              color: Colors.grey[400],
                              size: 24,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.restaurant,
                        color: Colors.grey[400],
                        size: 24,
                      ),
              ),
              const SizedBox(width: 12),
              // Restaurant details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurantName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          category,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.mainOrange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Location and arrow
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    location,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}