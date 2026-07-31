import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../firebase_options.dart';
import '../services/ad_service.dart';
import '../services/app_firebase_service.dart';
import '../services/font_service.dart';
import '../services/localization_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  String _statusText = 'Đang khởi động...';

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
    _initializeApp();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    bool isFirstLaunch = false;

    try {
      // 1. Khởi tạo định dạng ngày tháng & Localize (Nhanh)
      if (mounted) setState(() => _statusText = 'Tải cài đặt ứng dụng...');
      await initializeDateFormatting('vi', null);
      await initializeDateFormatting('en', null);
      await LocalizationService.init();
      await FontService.init();

      // 2. Kiểm tra Firebase & Mạng với Timeout 4 giây
      if (mounted) setState(() => _statusText = 'Chuẩn bị dữ liệu...');
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        await AppFirebaseService().init().timeout(
          const Duration(seconds: 4),
          onTimeout: () {
            debugPrint('Firebase init timeout - running in offline mode');
          },
        );
      } catch (e) {
        debugPrint('Firebase init error or offline: $e');
      }

      // 3. Khởi tạo dịch vụ bổ sung (AdMob, Notification, Storage)
      if (mounted) setState(() => _statusText = 'Chuẩn bị dữ liệu...');
      AdService.init();
      NotificationService().initialize().then((_) {
        NotificationService().scheduleNotifications();
      });

      isFirstLaunch = await StorageService().getIsFirstLaunch();
    } catch (e) {
      debugPrint('App initialize error: $e');
    }

    // Đảm bảo SplashScreen hiển thị ít nhất 1.2s để hiệu ứng mượt mà
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    // Chuyển màn hình mượt với PageRouteBuilder
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            isFirstLaunch ? const OnboardingScreen() : const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: Stack(
        children: [
          // Background Gradient Glowing Orbs
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7C3AED).withOpacity(0.25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withOpacity(0.25),
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEC4899).withOpacity(0.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEC4899).withOpacity(0.2),
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          
          // Main Content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo Container
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C3AED).withOpacity(0.4),
                            blurRadius: 25,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.timer_outlined,
                        size: 56,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 28),
                    
                    // App Title
                    Text(
                      'COUNTDOWN',
                      style: GoogleFonts.quicksand(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Đếm ngược sự kiện',
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        color: Colors.white60,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 50),
                    
                    // Loading Indicator & Status
                    const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEC4899)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _statusText,
                      style: GoogleFonts.quicksand(
                        fontSize: 13,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
