import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
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
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.languageNotifier,
      builder: (context, lang, child) {
        return ValueListenableBuilder<String>(
          valueListenable: FontService.fontNotifier,
          builder: (context, font, child) {
            return MaterialApp(
              title: t('app_name'),
              debugShowCheckedModeBanner: false,
              theme: _buildTheme(),
              home: const SplashScreen(),
            );
          },
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
