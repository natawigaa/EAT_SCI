import 'package:flutter/material.dart';

/// Helper class สำหรับแสดง notification/snackbar แบบ custom
class NotificationHelper {
  /// แสดง notification แบบสำเร็จ (พื้นขาว + ไอคอนส้ม)
  static void showSuccess(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
    _showCustomSnackBar(
      context,
      message: message,
      icon: Icons.check_circle,
      backgroundColor: Colors.white,
      iconColor: const Color(0xFFFF6F00), // สีส้มเข้ม
      textColor: const Color(0xFF424242), // สีเทาเข้ม
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// แสดง notification แบบข้อมูล (พื้นขาว + ไอคอนส้ม)
  static void showInfo(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
    _showCustomSnackBar(
      context,
      message: message,
      icon: Icons.info,
      backgroundColor: Colors.white,
      iconColor: const Color(0xFFF57C00), // สีส้ม
      textColor: const Color(0xFF424242),
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// แสดง notification แบบเตือน (พื้นขาว + ไอคอนส้มเข้ม)
  static void showWarning(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
    _showCustomSnackBar(
      context,
      message: message,
      icon: Icons.warning_amber_rounded,
      backgroundColor: Colors.white,
      iconColor: const Color(0xFFE65100), // สีส้มเข้ม
      textColor: const Color(0xFF424242),
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// แสดง notification แบบผิดพลาด (พื้นขาว + ไอคอนแดง-ส้ม)
  static void showError(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
    _showCustomSnackBar(
      context,
      message: message,
      icon: Icons.error,
      backgroundColor: Colors.white,
      iconColor: const Color(0xFFD84315), // สีแดง-ส้ม
      textColor: const Color(0xFF424242),
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// แสดง custom snackbar
  static void _showCustomSnackBar(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    required Color textColor,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            // Icon ทางซ้าย
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // ข้อความ
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // ปุ่ม Action (ถ้ามี)
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  onAction();
                },
                style: TextButton.styleFrom(
                  backgroundColor: iconColor.withOpacity(0.1),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: backgroundColor.withOpacity(0.95), // เพิ่มความโปร่งแสง
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: iconColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 100), // ปรับให้สูงขึ้นไม่บัง bottom nav
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(milliseconds: 1500), // ลดเวลาจาก 3 วิ เหลือ 1.5 วิ
        elevation: 4, // เพิ่มเงาให้ดูมีมิติ
      ),
    );
  }
}
