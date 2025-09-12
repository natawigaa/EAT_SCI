import 'package:eatscikmitl/const/app_color.dart';
import 'package:eatscikmitl/screen/FoodOrderScreen.dart';
import 'package:eatscikmitl/screen/HomeScreen.dart';
import 'package:eatscikmitl/screen/ProfileScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'dart:ui' as ui;

class RootScreen extends StatefulWidget {
  const RootScreen({super.key, required this.currentScreens});
  final int currentScreens;

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen>
    with TickerProviderStateMixin {
  late List<Widget> screens;
  late int currentScreen;
  late PageController controller;
  late AnimationController _animationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Bottom navigation animation controllers
  List<AnimationController> _iconAnimationControllers = [];
  List<Animation<double>> _iconScaleAnimations = [];

  @override
  void initState() {
    super.initState();
    currentScreen = widget.currentScreens;
    
    screens = const [
      FoodOrderScreen(),
      HomeScreen(),
      ProfileScreen()
    ];
    
    controller = PageController(initialPage: currentScreen);

    // Initialize main animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Initialize FAB animation controller
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Setup animations
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Initialize icon animation controllers
    for (int i = 0; i < screens.length; i++) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
      _iconAnimationControllers.add(controller);
      
      _iconScaleAnimations.add(
        Tween<double>(begin: 1.0, end: 1.2).animate(
          CurvedAnimation(parent: controller, curve: Curves.elasticOut),
        ),
      );
    }

    // Start initial animations
    _animationController.forward();
    _fabAnimationController.forward();
    _iconAnimationControllers[currentScreen].forward();
  }

  void _onDestinationSelected(int index) {
    if (index == currentScreen) return;

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Reset previous icon animation
    _iconAnimationControllers[currentScreen].reverse();

    setState(() {
      currentScreen = index;
    });

    // Animate new icon
    _iconAnimationControllers[index].forward();

    // Smooth page transition
    controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.orange.shade50,
                  Colors.white,
                ],
                stops: const [0.0, 0.3],
              ),
            ),
          ),
          // Main content
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: PageView(
                  physics: const NeverScrollableScrollPhysics(),
                  controller: controller,
                  children: screens,
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              margin: const EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: 20,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.mainOrange.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.9),
                          Colors.white.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: NavigationBar(
                      selectedIndex: currentScreen,
                      backgroundColor: Colors.transparent,
                      surfaceTintColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      height: 70,
                      indicatorColor: AppColors.mainOrange.withOpacity(0.2),
                      indicatorShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      onDestinationSelected: _onDestinationSelected,
                      destinations: [
                        _buildAnimatedDestination(
                          0,
                          IconlyBold.bag,
                          IconlyLight.bag,
                          "คำสั่งซื้อ",
                        ),
                        _buildAnimatedDestination(
                          1,
                          IconlyBold.home,
                          IconlyLight.home,
                          "หน้าหลัก",
                        ),
                        _buildAnimatedDestination(
                          2,
                          IconlyBold.profile,
                          IconlyLight.profile,
                          "โปรไฟล์",
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  NavigationDestination _buildAnimatedDestination(
    int index,
    IconData selectedIcon,
    IconData unselectedIcon,
    String label,
  ) {
    return NavigationDestination(
      selectedIcon: AnimatedBuilder(
        animation: _iconScaleAnimations[index],
        builder: (context, child) {
          return Transform.scale(
            scale: _iconScaleAnimations[index].value,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: currentScreen == index
                    ? AppColors.mainOrange.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                selectedIcon,
                color: AppColors.mainOrange,
                size: 24,
              ),
            ),
          );
        },
      ),
      icon: AnimatedBuilder(
        animation: _iconScaleAnimations[index],
        builder: (context, child) {
          return Transform.scale(
            scale: currentScreen == index ? 0.8 : 1.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                unselectedIcon,
                color: currentScreen == index
                    ? AppColors.mainOrange
                    : Colors.grey.shade600,
                size: 22,
              ),
            ),
          );
        },
      ),
      label: label,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fabAnimationController.dispose();
    for (var controller in _iconAnimationControllers) {
      controller.dispose();
    }
    controller.dispose();
    super.dispose();
  }
}

// Additional custom widget for enhanced visual effects
class CustomBottomNavPainter extends CustomPainter {
  final Color color;
  final double animationValue;

  CustomBottomNavPainter({
    required this.color,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Create a smooth wave effect
    path.moveTo(0, 20);
    path.quadraticBezierTo(
      size.width * 0.25,
      0,
      size.width * 0.5,
      10,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      20,
      size.width,
      0,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// Import this at the top of your file
// import 'dart:ui' as ui;