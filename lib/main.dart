import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/home_screen.dart';
import 'services/ad_service.dart';
import 'services/notification_service.dart';
import 'services/font_service.dart';
import 'services/localization_service.dart';
import 'services/storage_service.dart';
import 'screens/onboarding_screen.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/app_firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await AppFirebaseService().init();
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  await initializeDateFormatting('vi', null);
  await initializeDateFormatting('en', null);
  
  await LocalizationService.init();
  
  // FontService lấy từ SharedPreferences nên load cực nhanh và cần thiết để render UI không bị giật font
  await FontService.init();

  // Các service nặng như AdMob, Widget, Notification có thể load song song 
  // và không nhất thiết phải block quá trình vẽ frame đầu tiên của app.
  AdService.init(); 
  NotificationService().initialize();

  bool isFirstLaunch = await StorageService().getIsFirstLaunch();

  runApp(MyApp(isFirstLaunch: isFirstLaunch));
}

class MyApp extends StatelessWidget {
  final bool isFirstLaunch;
  const MyApp({super.key, required this.isFirstLaunch});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.languageNotifier,
      builder: (context, lang, child) {
        return MaterialApp(
          title: t('app_name'),
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(),
          home: isFirstLaunch ? const OnboardingScreen() : const HomeScreen(),
        );
      },
    );
  }

  ThemeData _buildTheme() {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF0D0D1A),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF7C3AED),
        secondary: Color(0xFFEC4899),
        surface: Color(0xFF1A1A2E),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
      ),
      textTheme: GoogleFonts.quicksandTextTheme(base.textTheme).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.quicksand(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF7C3AED),
        foregroundColor: Colors.white,
      ),
    );
  }
}
