import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/localization_service.dart';
import '../services/storage_service.dart';
import '../models/anniversary.dart';
import '../data/preset_holidays.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 2; // Bước 1: Ngôn ngữ, Bước 2: Ngày lễ

  // Danh sách ngày lễ đã chọn (dùng title làm key vì PresetHoliday dùng title)
  final List<PresetHoliday> _selectedHolidays = [];

  @override
  void initState() {
    super.initState();
    // Tự động xin quyền ngay khi vào onboarding
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await Permission.notification.request();
    // Android 13+ dùng photos, cũ hơn dùng storage
    final photosStatus = await Permission.photos.request();
    if (photosStatus.isDenied) {
      await Permission.storage.request();
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    if (_selectedHolidays.isNotEmpty) {
      final storage = StorageService();
      final existingEvents = await storage.getAnniversaries();
      final now = DateTime.now();
      final random = Random();

      for (final holiday in _selectedHolidays) {
        DateTime targetDate;
        if (holiday.isLunar) {
          // Với ngày âm lịch, giữ nguyên tháng/ngày âm, dùng năm hiện tại làm proxy
          targetDate = DateTime(now.year, holiday.month, holiday.day);
        } else {
          targetDate = DateTime(now.year, holiday.month, holiday.day);
          if (targetDate.isBefore(DateTime(now.year, now.month, now.day))) {
            targetDate = DateTime(now.year + 1, holiday.month, holiday.day);
          }
        }

        final newEvent = Anniversary(
          id: '${now.millisecondsSinceEpoch}${random.nextInt(9999)}',
          title: t(holiday.title), // Store localized title initially
          date: targetDate,
          emoji: holiday.emoji,
          colorValue: holiday.colorValue,
          isYearly: true,
          isLunar: holiday.isLunar,
          categoryId: holiday.categoryId,
        );
        existingEvents.add(newEvent);
      }

      await storage.saveAnniversaries(existingEvents);
    }

    await StorageService().setFirstLaunchCompleted();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  // Sắp xếp: Luôn xếp Quốc tế lên trước, Việt Nam sau, sau đó sắp xếp theo ngày tháng
  List<PresetHoliday> get _sortedHolidays {
    final all = List<PresetHoliday>.from(PresetHolidays.all);
    all.sort((a, b) {
      final aInt = a.badge == 'intl' ? 0 : 1;
      final bInt = b.badge == 'intl' ? 0 : 1;
      
      if (aInt != bInt) {
        return aInt.compareTo(bInt);
      }
      
      if (a.month != b.month) {
        return a.month.compareTo(b.month);
      }
      
      return a.day.compareTo(b.day);
    });
    return all;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Column(
          children: [
            // Thanh tiến trình
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: List.generate(_totalPages, (index) {
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: index <= _currentPage
                            ? const Color(0xFF7C3AED)
                            : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Nội dung
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                children: [
                  _buildLanguageStep(),
                  _buildHolidaysStep(),
                ],
              ),
            ),

            // Nút điều hướng
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage == 0)
                    TextButton(
                      onPressed: _finishOnboarding,
                      child: Text(
                        t('onboarding_skip'),
                        style: GoogleFonts.quicksand(
                          color: Colors.white54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else if (_currentPage > 0)
                    TextButton.icon(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      icon: const Icon(Icons.arrow_back_rounded, size: 18, color: Colors.white54),
                      label: Text(
                        t('back'),
                        style: GoogleFonts.quicksand(
                          color: Colors.white54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),

                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentPage == _totalPages - 1
                              ? t('onboarding_start')
                              : t('onboarding_next'),
                          style: GoogleFonts.quicksand(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentPage == _totalPages - 1
                              ? Icons.check
                              : Icons.arrow_forward_rounded,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bước 1: Chọn Ngôn ngữ ──────────────────────────────────────
  Widget _buildLanguageStep() {
    final currentLang = LocalizationService.languageNotifier.value;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 1),
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.language_rounded, size: 50, color: Color(0xFF7C3AED)),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            t('onboarding_lang_title'),
            style: GoogleFonts.quicksand(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t('onboarding_lang_desc'),
            style: GoogleFonts.quicksand(
              fontSize: 16,
              color: Colors.white54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),
          _buildOptionCard(
            title: 'English',
            subtitle: 'International',
            flag: '🇬🇧',
            isSelected: currentLang == 'en',
            onTap: () {
              LocalizationService.changeLanguage('en');
              setState(() {});
            },
          ),
          const SizedBox(height: 16),
          _buildOptionCard(
            title: 'Tiếng Việt',
            subtitle: 'Ngôn ngữ chính',
            flag: '🇻🇳',
            isSelected: currentLang == 'vi',
            onTap: () {
              LocalizationService.changeLanguage('vi');
              setState(() {});
            },
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  // ── Bước 2: Chọn Ngày Lễ ────────────────────────────────────────
  Widget _buildHolidaysStep() {
    final holidays = _sortedHolidays;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            t('onboarding_holidays_title'),
            style: GoogleFonts.quicksand(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t('onboarding_holidays_desc'),
            style: GoogleFonts.quicksand(
              fontSize: 15,
              color: Colors.white54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: holidays.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final holiday = holidays[index];
                final isSelected = _selectedHolidays.any((h) => h.title == holiday.title);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedHolidays.removeWhere((h) => h.title == holiday.title);
                      } else {
                        _selectedHolidays.add(holiday);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Color(holiday.colorValue).withValues(alpha: 0.15)
                          : const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? Color(holiday.colorValue) : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(holiday.emoji, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t(holiday.title),
                                style: GoogleFonts.quicksand(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.white : Colors.white70,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    holiday.isLunar
                                        ? '${holiday.day}/${holiday.month} âm'
                                        : '${holiday.day}/${holiday.month}',
                                    style: GoogleFonts.quicksand(
                                      fontSize: 12,
                                      color: Colors.white38,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: holiday.badge == 'vn'
                                          ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                                          : const Color(0xFF3B82F6).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      t('badge_${holiday.badge}'),
                                      style: GoogleFonts.quicksand(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: holiday.badge == 'vn'
                                            ? const Color(0xFFEF4444)
                                            : const Color(0xFF3B82F6),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? Color(holiday.colorValue) : Colors.transparent,
                            border: Border.all(
                              color: isSelected ? Color(holiday.colorValue) : Colors.white24,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, size: 15, color: Colors.white)
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Widget Option Card ──────────────────────────────────────────
  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required String flag,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF7C3AED).withValues(alpha: 0.15)
              : const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF7C3AED) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.quicksand(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.quicksand(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF7C3AED), size: 28),
          ],
        ),
      ),
    );
  }
}
