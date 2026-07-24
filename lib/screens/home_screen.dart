import '../services/localization_service.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/physics.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gal/gal.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/anniversary.dart';
import '../services/storage_service.dart';
import '../services/font_service.dart';
import '../services/ad_service.dart';
import '../services/notification_service.dart';
import '../services/audio_service.dart';
import '../services/app_firebase_service.dart';
import '../widgets/countdown_card.dart';
import '../widgets/time_unit_box.dart';
import '../widgets/effect_background.dart';
import '../widgets/premium_dialog.dart';
import '../widgets/theme_picker_sheet.dart';
import '../widgets/congratulations_view.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'add_event_screen.dart';
import 'detail_screen.dart';
import 'gift_screen.dart';
import 'settings_screen.dart';
import 'special_occasion_screen.dart';
import '../models/special_occasion.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static bool _hasShownStartupBanner = false;
  final StorageService _storageService = StorageService();
  List<Anniversary> _anniversaries = [];
  bool _isLoading = true;
  int _currentTab = 0;
  bool _hasVisitedGiftTab = false;
  String? _selectedGiftCategory;
  int _featuredIndex = 0;

  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;
  late PageController _pageController;
  final ScrollController _eventsScrollController = ScrollController();
  String _selectedEffect = 'none';
  String? _backgroundImagePath;
  bool _isFullscreenMode = false;
  bool _showFullscreenExitButton = false;
  Timer? _hideExitButtonTimer;
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  final GlobalKey _themeButtonKey = GlobalKey();
  bool _isCapturing = false;
  DateTime? _customCountdownTarget;
  void _showCustomTimerDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          title: Text(t('timer_settings'), style: GoogleFonts.quicksand(color: Colors.white)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: t('enter_seconds'),
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF7C3AED))),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('cancel'), style: GoogleFonts.quicksand(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () {
                final seconds = int.tryParse(controller.text) ?? 0;
                if (seconds > 0) {
                  final s = seconds > 60 ? 60 : seconds;
                  setState(() {
                    _customCountdownTarget = DateTime.now().add(Duration(seconds: s));
                  });
                  Navigator.pop(context);
                }
              },
              child: Text(t('start'), style: GoogleFonts.quicksand(color: const Color(0xFF7C3AED))),
            ),
          ],
        );
      },
    );
  }

  Future<void> _captureAndShareScreenshot() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);
    
    try {
      // Đợi 350ms để hiệu ứng AnimatedOpacity (300ms) mờ hẳn, tránh dính nút vào ảnh
      await Future.delayed(const Duration(milliseconds: 350));
      
      final RenderRepaintBoundary? boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception("Không tìm thấy RenderRepaintBoundary");
      }
      
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception("Lỗi khi chuyển đổi ảnh (ByteData null)");
      }
      
      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final directory = (await getApplicationDocumentsDirectory()).path;
      final imgFile = File('$directory/screenshot.png');
      await imgFile.writeAsBytes(pngBytes);
      
      bool hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        hasAccess = await Gal.requestAccess();
      }
      
      if (!hasAccess) {
        throw Exception("Bạn chưa cấp quyền lưu ảnh. Vui lòng cấp quyền trong Cài đặt.");
      }
      
      await Gal.putImage(imgFile.path);
      
      if (mounted) {
        setState(() {
          _showFullscreenExitButton = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Text(t('screenshot_saved'), style: GoogleFonts.quicksand(fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error capturing screenshot: $e');
      if (mounted) {
        setState(() {
          _showFullscreenExitButton = true;
        });
        _scheduleHideExitButton();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t('screenshot_error')} $e', style: GoogleFonts.quicksand(color: Colors.white)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _checkFirstLaunchPermissions();
    _loadAnniversaries();
    _loadThemeSettings();
    _loadBannerAd();
    
    AudioService().init().then((_) {
      if (mounted) setState(() {});
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkAndShowTutorial();
    });
  }

  Future<void> _checkAndShowTutorial() async {
    final storage = StorageService();
    final isTutorialShown = await storage.getIsTutorialShown();
    if (!isTutorialShown && mounted) {
      _showTutorial();
    } else {
      _checkAndShowStartupBanner();
    }
  }

  Future<void> _checkAndShowStartupBanner() async {
    if (_hasShownStartupBanner || !mounted) return;
    _hasShownStartupBanner = true;

    final banner = await AppFirebaseService().getStartupBanner();
    if (banner != null && banner.isActive && mounted) {
      _showStartupBannerDialog(banner);
    }
  }

  void _showStartupBannerDialog(StartupBanner banner) {
    final activeItems = banner.items.where((item) => item.isActive).toList();
    if (activeItems.isEmpty) return;

    if (activeItems.length == 1) {
      _showSingleBannerDialog(activeItems.first);
    } else {
      _showCarouselBannerDialog(activeItems);
    }
  }

  void _showSingleBannerDialog(StartupBannerItem item) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.title.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Text(
                    item.title,
                    style: GoogleFonts.quicksand(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ClipRRect(
                borderRadius: item.title.isNotEmpty
                    ? const BorderRadius.vertical(bottom: Radius.circular(16))
                    : BorderRadius.circular(16),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _handleBannerAction(item);
                  },
                  child: Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey[800],
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image, color: Colors.white54, size: 50),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FloatingActionButton.small(
                onPressed: () => Navigator.pop(context),
                backgroundColor: Colors.white24,
                elevation: 0,
                child: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleBannerAction(StartupBannerItem item) {
    switch (item.actionType) {
      case 'gift':
        if (item.occasionId != null && item.occasionId!.isNotEmpty) {
          // Navigate to a specific special occasion
          _navigateToOccasion(item.occasionId!);
        } else {
          // Navigate to gift tab (with optional category filter)
          setState(() => _currentTab = 2);
          _pageController.animateToPage(2, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
          // If there's a category filter, we push the gift screen directly with it
          if (item.giftCategoryId != null && item.giftCategoryId!.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GiftScreen(
                      initialCategoryId: item.giftCategoryId,
                      isPremium: false,
                    ),
                  ),
                );
              }
            });
          }
        }
        break;
      case 'url':
        if (item.actionUrl != null && item.actionUrl!.isNotEmpty) {
          final uri = Uri.tryParse(item.actionUrl!);
          if (uri != null) {
            launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
        break;
      case 'none':
      default:
        break;
    }
  }

  Future<void> _navigateToOccasion(String occasionId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('special_occasions')
          .doc(occasionId)
          .get();
      if (doc.exists && mounted) {
        final occasion = SpecialOccasion.fromFirestore(doc.id, doc.data()!);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SpecialOccasionScreen(occasion: occasion),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error navigating to occasion: $e');
    }
  }

  void _showCarouselBannerDialog(List<StartupBannerItem> items) {
    showDialog(
      context: context,
      builder: (context) {
        return _CarouselBannerDialog(
          items: items,
          onAction: (item) {
            Navigator.pop(context);
            _handleBannerAction(item);
          },
        );
      },
    );
  }

  void _showTutorial() {
    TutorialCoachMark(
      targets: [
        TargetFocus(
          identify: "theme_button",
          keyTarget: _themeButtonKey,
          alignSkip: Alignment.topLeft,
          enableOverlayTab: true,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder: (context, controller) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      t('tutorial_theme_btn') == 'tutorial_theme_btn' ? "Bấm vào đây để thay đổi hiệu ứng và phông chữ!" : t('tutorial_theme_btn'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ],
      colorShadow: const Color(0xFF7C3AED),
      textSkip: t('skip') == 'skip' ? "Bỏ qua" : t('skip'),
      alignSkip: Alignment.topLeft,
      paddingFocus: 10,
      opacityShadow: 0.8,
      onFinish: () {
        StorageService().setTutorialShown();
      },
      onClickTarget: (target) {
        StorageService().setTutorialShown();
      },
      onSkip: () {
        StorageService().setTutorialShown();
        return true;
      },
    ).show(context: context);
  }

  Future<void> _loadThemeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _backgroundImagePath = prefs.getString('app_background_image');
    });
  }

  Future<void> _pickBackgroundImage() async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.image);
      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('app_background_image', path);
        setState(() {
          _backgroundImagePath = path;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _clearBackgroundImage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('app_background_image');
    setState(() {
      _backgroundImagePath = null;
    });
  }

  Future<void> _checkFirstLaunchPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasRequested = prefs.getBool('has_requested_notification_permission') ?? false;
    
    if (!hasRequested) {
      await NotificationService().requestPermissions();
      await prefs.setBool('has_requested_notification_permission', true);
    }
  }

  void _loadBannerAd() {
    if (kIsWeb || AdService.isPremium) return;
    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) {
            setState(() {
              _isBannerAdReady = true;
            });
          }
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd failed to load: $err');
          _isBannerAdReady = false;
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _eventsScrollController.dispose();
    _bannerAd?.dispose();
    _hideExitButtonTimer?.cancel();
    AudioService().dispose();
    super.dispose();
  }

  void _scheduleHideExitButton() {
    _hideExitButtonTimer?.cancel();
    _hideExitButtonTimer = Timer(const Duration(milliseconds: 3000), () {
      if (mounted && _isFullscreenMode) {
        setState(() {
          _showFullscreenExitButton = false;
        });
      }
    });
  }

  Future<void> _loadAnniversaries() async {
    try {
      final list = await _storageService.getAnniversaries();
      final effect = await _storageService.getSelectedEffect();
      if (mounted) {
        setState(() {
          _anniversaries = list;
          _selectedEffect = effect;
          _isLoading = false;
          _sortAnniversaries();
        });
      }
    } catch (e) {
      debugPrint('Error loading anniversaries: $e');
      setState(() {
        _anniversaries = [];
        _isLoading = false;
      });
    }
  }

  void _sortAnniversaries() {
    _anniversaries.sort((a, b) {
      final dA = a.daysRemaining;
      final dB = b.daysRemaining;
      if (dA >= 0 && dB >= 0) return dA.compareTo(dB);
      if (dA < 0 && dB < 0) return dB.compareTo(dA);
      return dA >= 0 ? -1 : 1;
    });
  }

  List<Anniversary> get _upcomingList =>
      _anniversaries.where((a) => a.daysRemaining >= 0).toList();

  Anniversary? get _featuredAnniversary {
    final list = _upcomingList;
    if (list.isEmpty) return null;
    return list[_featuredIndex.clamp(0, list.length - 1)];
  }

  Color get _accentColor {
    return _featuredAnniversary?.color ?? const Color(0xFF7C3AED);
  }


  Future<void> _navigateToAdd() async {
    final result = await Navigator.push<dynamic>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a1, a2) => AddEventScreen(existingEvents: _anniversaries),
        transitionsBuilder: (_, anim, _, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: child,
          );
        },
      ),
    );

    if (result != null) {
      setState(() {
        if (result is Anniversary) {
          _anniversaries.add(result);
        } else if (result is List<Anniversary>) {
          _anniversaries.addAll(result);
        }
        _sortAnniversaries();
        _featuredIndex = 0;
      });
      await _storageService.saveAnniversaries(_anniversaries);
    }
  }

  Future<void> _navigateToDetail(Anniversary item) async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(builder: (_) => DetailScreen(anniversary: item)),
    );
    
    if (result == 'deleted') {
      setState(() {
        _anniversaries.removeWhere((a) => a.id == item.id);
        _sortAnniversaries();
        _featuredIndex = 0;
      });
      await _storageService.saveAnniversaries(_anniversaries);
    } else if (result is Anniversary) {
      setState(() {
        final idx = _anniversaries.indexWhere((a) => a.id == result.id);
        if (idx != -1) {
          _anniversaries[idx] = result;
        }
        _sortAnniversaries();
      });
      await _storageService.saveAnniversaries(_anniversaries);
    } else if (result is String && result.startsWith('gift:')) {
      final categoryId = result.substring(5);
      setState(() {
        _currentTab = 2; // Chuyển sang tab Quà tặng
        _hasVisitedGiftTab = true;
        _selectedGiftCategory = categoryId;
      });
    }
  }

  Future<void> _deleteEvent(Anniversary event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.white12),
          ),
          title: Text(
            t('delete_event_title'),
            style: GoogleFonts.quicksand(
                fontWeight: FontWeight.w700, color: Colors.white),
          ),
          content: Text(
            t('delete_event_desc', params: {'title': event.title}),
            style: GoogleFonts.quicksand(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:
                  Text(t('cancel'), style: GoogleFonts.quicksand(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                t('delete'),
                style: GoogleFonts.quicksand(
                    color: Colors.red.shade400, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirm == true) {
      setState(() {
        _anniversaries.removeWhere((a) => a.id == event.id);
        _sortAnniversaries();
        _featuredIndex = 0;
      });
      await _storageService.saveAnniversaries(_anniversaries);
    }
  }

  Future<bool> _showExitConfirmDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white12),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEC4899).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.exit_to_app_rounded,
                color: Color(0xFFEC4899),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              t('exit_app_title'),
              style: GoogleFonts.quicksand(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          t('exit_app_desc'),
          style: GoogleFonts.quicksand(
            color: Colors.white70,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.only(right: 16, bottom: 16, left: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text(
              t('cancel'),
              style: GoogleFonts.quicksand(
                color: Colors.white54,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              t('exit'),
              style: GoogleFonts.quicksand(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        if (_isFullscreenMode) {
          setState(() {
            _isFullscreenMode = false;
          });
          return;
        }
        if (_currentTab != 0) {
          setState(() {
            _currentTab = 0;
          });
          return;
        }
        final shouldExit = await _showExitConfirmDialog();
        if (shouldExit) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        extendBody: true, // Thêm dòng này để body chìm dưới BottomNav trong suốt
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
              )
            : RepaintBoundary(
                key: _repaintBoundaryKey,
                child: Stack(
                  children: [
                    // 1. Lớp Ảnh nền hoặc Gradient
                    if (_backgroundImagePath != null && File(_backgroundImagePath!).existsSync()) ...[
                      Positioned.fill(
                        child: Image.file(
                          File(_backgroundImagePath!),
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.4),
                        ),
                      ),
                    ] else ...[
                      // Gradient mặc định
                      Positioned.fill(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: const Alignment(0, -0.3),
                              radius: 1.2,
                              colors: [
                                _accentColor.withValues(alpha: 0.35),
                                const Color(0xFF0D0D1A),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],

                    // 2. Lớp Hiệu ứng hạt
                    RepaintBoundary(
                      child: EffectBackground(effectType: _selectedEffect),
                    ),

                    // 3. Lớp Nội dung chính (UI)
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        if (_isFullscreenMode) {
                          setState(() {
                            _showFullscreenExitButton = true;
                          });
                          _scheduleHideExitButton();
                        }
                      },
                      child: _buildCurrentTab(),
                    ),
                  if (_isFullscreenMode) ...[
                    Positioned(
                      top: 40,
                      right: 20,
                      child: AnimatedOpacity(
                        opacity: (_showFullscreenExitButton && !_isCapturing) ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: IgnorePointer(
                          ignoring: !_showFullscreenExitButton,
                          child: IconButton(
                            icon: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white, size: 30),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black45,
                            ),
                            onPressed: () {
                              setState(() => _isFullscreenMode = false);
                            },
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      bottom: 40,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: AnimatedOpacity(
                          opacity: (_showFullscreenExitButton && !_isCapturing) ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: IgnorePointer(
                            ignoring: !_showFullscreenExitButton,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: _showCustomTimerDialog,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.black45,
                                      borderRadius: BorderRadius.circular(25),
                                      border: Border.all(color: Colors.white24, width: 1),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.timer_outlined, color: Colors.white, size: 24),
                                        const SizedBox(width: 8),
                                        Text(
                                          t('timer_settings'),
                                          style: GoogleFonts.quicksand(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                GestureDetector(
                                  onTap: _isCapturing ? null : () async {
                                    // Không ẩn nút ngay lập tức để hiển thị chữ "Đang chụp..."
                                    await _captureAndShareScreenshot();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.black45,
                                      borderRadius: BorderRadius.circular(25),
                                      border: Border.all(color: Colors.white24, width: 1),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_isCapturing) ...[
                                          const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          ),
                                        ] else ...[
                                          const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 24),
                                        ],
                                        const SizedBox(width: 8),
                                        Text(
                                          _isCapturing ? t('capturing') : t('capture_screen'),
                                          style: GoogleFonts.quicksand(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  ],
                ),
              ),
        bottomNavigationBar: _isFullscreenMode ? const SizedBox.shrink() : _buildBottomNav(),
      ),
    );
  }

  Widget _buildCurrentTab() {
    return IndexedStack(
      index: _currentTab,
      children: [
        _buildHeroTab(),
        _buildAllEventsTab(),
        _hasVisitedGiftTab ? GiftScreen(
          key: ValueKey('gift_$_selectedGiftCategory'),
          isPremium: AdService.isPremium,
          initialCategoryId: _selectedGiftCategory,
        ) : const SizedBox.shrink(),
        SettingsScreen(
          onEffectChanged: (effect) {
            setState(() => _selectedEffect = effect);
          },
          onPremiumChanged: (isPremium) {
            setState(() {}); // Rebuild để ẩn/hiện banner
          },
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  // TAB 0: Hero — Sự kiện sắp tới nổi bật
  // ─────────────────────────────────────────────────────────
  Widget _buildHeroTab() {
    final featured = _featuredAnniversary;
    final upcoming = _upcomingList;

    if (_anniversaries.isEmpty) return _buildEmptyState();

    if (featured == null) {
      // Chỉ có sự kiện đã qua
      return _buildNoUpcomingState();
    }

    final cardColor = featured.color;
    // cardColor used for background gradient and dot indicator

    return Stack(
      children: [

        // Particle glow top
        Positioned(
          top: -60,
          left: MediaQuery.of(context).size.width / 2 - 150,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  cardColor.withValues(alpha: 0.25),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),


        SafeArea(
          child: Column(
            children: [
              // ── App Bar ──
              if (!_isFullscreenMode)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _accentColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.favorite_rounded,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      t('upcoming'),
                      style: GoogleFonts.quicksand(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
                    const Spacer(),
                    if (upcoming.length > 1)
                      Row(
                        children: [
                          if (_featuredIndex > 0)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                                  setState(() => _featuredIndex = 0);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.refresh_rounded, color: Colors.white, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        t('nearest'),
                                        style: GoogleFonts.quicksand(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Text(
                              '${_featuredIndex + 1} / ${upcoming.length}',
                              style: GoogleFonts.quicksand(fontSize: 13, color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    
                    // Nút Theme
                    PopupMenuButton<String>(
                      key: _themeButtonKey,
                      icon: const Icon(Icons.palette_rounded, color: Colors.amber),
                      color: const Color(0xFF1A1A2E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Colors.white12),
                      ),
                      onSelected: (value) {
                        if (value == 'effect' || value == 'font' || value == 'music') {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => ThemePickerSheet(
                              initialTabIndex: value == 'effect' ? 0 : (value == 'font' ? 1 : 2),
                              onEffectChanged: (effect) {
                                setState(() => _selectedEffect = effect);
                              },
                            ),
                          );
                        } else if (value == 'bg_image') {
                          _pickBackgroundImage();
                        } else if (value == 'bg_clear') {
                          _clearBackgroundImage();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'effect',
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 20),
                              const SizedBox(width: 12),
                              Text(t('background_effect'), style: GoogleFonts.quicksand(color: Colors.white)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'font',
                          child: Row(
                            children: [
                              const Icon(Icons.font_download_rounded, color: Colors.blueAccent, size: 20),
                              const SizedBox(width: 12),
                              Text(t('font_style'), style: GoogleFonts.quicksand(color: Colors.white)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'music',
                          child: Row(
                            children: [
                              const Icon(Icons.library_music_rounded, color: Colors.pinkAccent, size: 20),
                              const SizedBox(width: 12),
                              Text(t('tab_music') == 'tab_music' ? 'Nhạc nền' : t('tab_music'), style: GoogleFonts.quicksand(color: Colors.white)),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(height: 1),
                        PopupMenuItem(
                          value: 'bg_image',
                          child: Row(
                            children: [
                              const Icon(Icons.image_rounded, color: Colors.greenAccent, size: 20),
                              const SizedBox(width: 12),
                              Text(t('select_bg_image'), style: GoogleFonts.quicksand(color: Colors.white)),
                            ],
                          ),
                        ),
                        if (_backgroundImagePath != null)
                          PopupMenuItem(
                            value: 'bg_clear',
                            child: Row(
                              children: [
                                const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 20),
                                const SizedBox(width: 12),
                                Text(t('remove_bg_image'), style: GoogleFonts.quicksand(color: Colors.redAccent)),
                              ],
                            ),
                          ),
                      ],
                    ),

                  ],
                ),
              ),

              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const CustomPageScrollPhysics(parent: BouncingScrollPhysics()),
                  clipBehavior: Clip.none,
                  onPageChanged: (index) {
                    setState(() {
                      _featuredIndex = index;
                    });
                  },
                  itemCount: upcoming.length,
                  itemBuilder: (context, index) {
                    final item = upcoming[index];
                    final itemColor = item.color;
                    final days = item.daysRemaining;
                    final isToday = days == 0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Center(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          clipBehavior: Clip.none,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // ── Emoji lớn với glow ──
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.8, end: 1.0),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.elasticOut,
                            builder: (_, v, child) =>
                                Transform.scale(scale: v, child: child),
                            child: Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: itemColor.withValues(alpha: 0.15),
                                border: Border.all(
                                    color: itemColor.withValues(alpha: 0.5),
                                    width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: itemColor.withValues(alpha: 0.5),
                                    blurRadius: 40,
                                    spreadRadius: 8,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(item.emoji,
                                    style: const TextStyle(fontSize: 52)),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ── Tên sự kiện ──
                          Text(
                            item.title,
                            style: FontService.getStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 8),

                          // ── Ngày ──
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  size: 14, color: Colors.white54),
                              const SizedBox(width: 6),
                              Text(
                                DateFormat('dd MMMM yyyy', LocalizationService.languageNotifier.value)
                                    .format(item.displayDate),
                                style: GoogleFonts.quicksand(
                                    fontSize: 15, color: Colors.white54),
                              ),
                              if (item.isYearly) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: itemColor.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    t('yearly'),
                                    style: GoogleFonts.quicksand(
                                        fontSize: 11,
                                        color: itemColor,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ],
                          ),

                          if (item.isLunar) ...[
                            const SizedBox(height: 4),
                            Text(
                              t('lunar_date', params: {'day': item.date.day.toString(), 'month': item.date.month.toString()}),
                              style: GoogleFonts.quicksand(
                                fontSize: 13,
                                color: Colors.white54,
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),

                          if (isToday && (_customCountdownTarget == null || !_isFullscreenMode))
                            CongratulationsView(title: item.title)
                          else ...[


                            // ── Countdown boxes ──
                            StreamBuilder<DateTime>(
                              stream: Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
                                builder: (context, snapshot) {
                                  final now = DateTime.now();
                                final targetDt = (_isFullscreenMode && _customCountdownTarget != null)
                                    ? _customCountdownTarget!
                                    : DateTime(
                                        item.displayDate.year,
                                        item.displayDate.month,
                                        item.displayDate.day,
                                      );
                                final remaining = targetDt.isAfter(now)
                                    ? targetDt.difference(now)
                                    : Duration.zero;

                                if (remaining == Duration.zero) {
                                  return CongratulationsView(title: item.title);
                                }

                                final int totalSeconds = (remaining.inMilliseconds / 1000).ceil();
                                final daysLeft = totalSeconds ~/ 86400;
                                final hours = (totalSeconds ~/ 3600) % 24;
                                final minutes = (totalSeconds ~/ 60) % 60;
                                final seconds = totalSeconds % 60;
                                
                                final bool showDays = daysLeft > 0;
                                final bool showHours = showDays || hours > 0;
                                final bool showMinutes = showHours || minutes > 0;
                                final bool highlightSeconds = !showMinutes;

                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (showDays) ...[
                                      TimeUnitBox(
                                        value: daysLeft.toString().padLeft(2, '0'),
                                        label: t('days'),
                                        color: itemColor,
                                      ),
                                      _separator(itemColor),
                                    ],
                                    if (showHours) ...[
                                      TimeUnitBox(
                                        value: hours.toString().padLeft(2, '0'),
                                        label: t('hours'),
                                        color: itemColor,
                                      ),
                                      _separator(itemColor),
                                    ],
                                    if (showMinutes) ...[
                                      TimeUnitBox(
                                        value: minutes.toString().padLeft(2, '0'),
                                        label: t('minutes'),
                                        color: itemColor,
                                      ),
                                      _separator(itemColor),
                                    ],
                                    if (highlightSeconds)
                                      TweenAnimationBuilder<double>(
                                        key: ValueKey(seconds),
                                        tween: Tween(begin: 1.3, end: 1.0),
                                        duration: const Duration(milliseconds: 500),
                                        curve: Curves.easeOutBack,
                                        builder: (context, scale, child) {
                                          return Transform.scale(
                                            scale: scale,
                                            child: Text(
                                              seconds.toString(),
                                              style: GoogleFonts.quicksand(
                                                fontSize: 120, // Kích thước chữ rất lớn
                                                fontWeight: FontWeight.w900,
                                                color: itemColor,
                                                height: 1.0,
                                                shadows: [
                                                  Shadow(
                                                    color: itemColor.withValues(alpha: 0.8),
                                                    blurRadius: 30 * scale,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    else
                                      TimeUnitBox(
                                        value: seconds.toString().padLeft(2, '0'),
                                        label: t('seconds'),
                                        color: itemColor,
                                      ),
                                  ],
                                );
                              },
                            ),
                          ],


                          const SizedBox(height: 16),

                          if (!_isFullscreenMode) ...[
                            // ── Các nút hành động ──
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (item.category.canSuggestProducts) ...[
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _currentTab = 2; // Navigate to gift tab
                                        _hasVisitedGiftTab = true;
                                        _selectedGiftCategory = item.categoryId;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981)
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                            color: const Color(0xFF10B981)
                                                .withValues(alpha: 0.5)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text('🛍️', style: TextStyle(fontSize: 14)),
                                          const SizedBox(width: 6),
                                          Text(
                                            t('gift_suggestions'),
                                            style: GoogleFonts.quicksand(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF10B981),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                GestureDetector(
                                  onTap: () => _navigateToDetail(item),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: itemColor.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: itemColor.withValues(alpha: 0.5)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          t('view_detail'),
                                          style: GoogleFonts.quicksand(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Icon(Icons.arrow_forward_ios_rounded,
                                            color: Colors.white, size: 14),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Nút Xem toàn màn hình
                            GestureDetector(
                              onTap: () {
                                if (AdService.isPremium) {
                                  setState(() { _isFullscreenMode = true; _showFullscreenExitButton = false; _customCountdownTarget = null; });
                                  return;
                                }
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: const Color(0xFF1A1A2E),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: const BorderSide(color: Colors.white12),
                                    ),
                                    title: Row(
                                      children: [
                                        const Icon(Icons.fullscreen_rounded, color: Colors.amber),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            t('view_fullscreen'),
                                            style: GoogleFonts.quicksand(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t('fullscreen_ad_desc'),
                                          style: GoogleFonts.quicksand(color: Colors.white70, fontSize: 14),
                                        ),
                                        const SizedBox(height: 16),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            icon: const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 20),
                                            label: Text(
                                              t('upgrade_premium_btn'),
                                              style: GoogleFonts.quicksand(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.amber,
                                                fontSize: 14,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF14142B),
                                              elevation: 0,
                                              side: const BorderSide(color: Colors.amber, width: 1.5),
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                            onPressed: () {
                                              Navigator.pop(context);
                                              PremiumDialog.show(
                                                context,
                                                onPremiumUnlocked: () {
                                                  setState(() {});
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            icon: const Icon(Icons.play_circle_filled_rounded, size: 20),
                                            label: Text(
                                              t('watch_ad_free'),
                                              style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF7C3AED),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                            onPressed: () {
                                              Navigator.pop(context);
                                              AdService.showRewardedAd(
                                                onEarnedReward: () {
                                                  if (mounted) {
                                                    setState(() { _isFullscreenMode = true; _showFullscreenExitButton = false; _customCountdownTarget = null; });
                                                  }
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(t('cancel'), style: GoogleFonts.quicksand(color: Colors.white54)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.play_circle_filled_rounded, color: Color(0xFFF59E0B), size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      t('watch_fullscreen'),
                                      style: GoogleFonts.quicksand(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 120), // space for FAB + nav + banner ad
                        ],
                      ),
                        ),
                      ),
                    );
                  },
                ),
              ),


              // space moved inside PageView
            ],
          ),
        ),
      ],
    );
  }

  Widget _separator(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        ':',
        style: GoogleFonts.quicksand(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }


  // ─────────────────────────────────────────────────────────
  // TAB 1: Tất cả sự kiện
  // ─────────────────────────────────────────────────────────
  Widget _buildAllEventsTab() {
    if (_anniversaries.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            controller: _eventsScrollController,
            slivers: [
        // Đã bỏ SliverAppBar theo yêu cầu
        SliverSafeArea(
          bottom: false,
          sliver: const SliverToBoxAdapter(child: SizedBox.shrink()),
        ),
        // Tiêu đề trang
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  Container(
                    width: 5,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    t('all_events_tab'),
                    style: GoogleFonts.quicksand(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_anniversaries.length}',
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        color: const Color(0xFF7C3AED),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (_upcomingList.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final item = _upcomingList[i];
                    return CountdownCard(
                      anniversary: item,
                      onTap: () => _navigateToDetail(item),
                      onDelete: () => _deleteEvent(item),
                    );
                  },
                  childCount: _upcomingList.length,
                ),
              ),
            ),
          ],

          // Đã qua
          if (_anniversaries.any((a) => a.daysRemaining < 0)) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      t('passed'),
                      style: GoogleFonts.quicksand(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final past =
                        _anniversaries.where((a) => a.daysRemaining < 0).toList();
                    final item = past[i];
                    return CountdownCard(
                      anniversary: item,
                      onTap: () => _navigateToDetail(item),
                      onDelete: () => _deleteEvent(item),
                    );
                  },
                  childCount:
                      _anniversaries.where((a) => a.daysRemaining < 0).length,
                ),
              ),
            ),
          ],
          
          const SliverToBoxAdapter(child: SizedBox(height: 200)), // Tăng khoảng trống tránh đè quảng cáo
        ],
      ),
    ), // End of Expanded
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  // Bottom Navigation Bar
  // ─────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isBannerAdReady && _bannerAd != null && !AdService.isPremium)
          SafeArea(
            top: false,
            bottom: false,
            child: Container(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              alignment: Alignment.center,
              margin: const EdgeInsets.only(top: 4, bottom: 4),
              child: AdWidget(ad: _bannerAd!),
            ),
          ),
        Container(
          color: Colors.transparent,
          height: 110,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                height: 70,
                margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF12122A),
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavIcon(0, Icons.home_rounded, t('home')),
                    _buildNavIcon(1, Icons.event_note_rounded, t('events')),
                    const SizedBox(width: 60), // Không gian cho nút giữa
                    _buildNavIcon(2, Icons.card_giftcard_rounded, t('gifts')),
                    _buildNavIcon(3, Icons.settings_rounded, t('settings')),
                  ],
                ),
              ),
              Positioned(
                bottom: 40,
                child: GestureDetector(
                  onTap: _navigateToAdd,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _accentColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _accentColor.withValues(alpha: 0.5),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavIcon(int index, IconData icon, String label) {
    final isActive = _currentTab == index;
    final accent = _accentColor;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_currentTab == 1 && index == 1) {
          // Nếu đang ở tab Sự kiện và bấm lại, cuộn mượt mà lên đầu
          if (_eventsScrollController.hasClients) {
            _eventsScrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        } else if (index == 1) {
          // Nếu chuyển sang tab Sự kiện từ tab khác, lập tức nhảy lên đầu
          if (_eventsScrollController.hasClients) {
            _eventsScrollController.jumpTo(0);
          }
        }
        
        // Khi quay lại từ Cài đặt hoặc các tab khác, update lại giao diện
        _storageService.getSelectedEffect().then((val) {
          if (mounted && _selectedEffect != val) {
            setState(() => _selectedEffect = val);
          }
        });

        setState(() {
          _currentTab = index;
          if (index == 2) _hasVisitedGiftTab = true;
        });
      },
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? accent : Colors.white38,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.quicksand(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? accent : Colors.white38,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Empty states
  // ─────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF7C3AED).withValues(alpha: 0.3),
                  const Color(0xFFEC4899).withValues(alpha: 0.3),
                ],
              ),
            ),
            child: const Center(
              child: Text('💝', style: TextStyle(fontSize: 44)),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            t('no_events_yet'),
            style: GoogleFonts.quicksand(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t('empty_state_desc'),
            textAlign: TextAlign.center,
            style: GoogleFonts.quicksand(fontSize: 15, color: Colors.white38),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: _navigateToAdd,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Text(
                t('add_now'),
                style: GoogleFonts.quicksand(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoUpcomingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📅', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 20),
          Text(
            t('no_upcoming_events'),
            style: GoogleFonts.quicksand(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t('no_upcoming_desc'),
            textAlign: TextAlign.center,
            style: GoogleFonts.quicksand(fontSize: 14, color: Colors.white38),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => setState(() => _currentTab = 1),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                t('view_all_events_arrow'),
                style: GoogleFonts.quicksand(
                    fontSize: 14, color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomPageScrollPhysics extends ScrollPhysics {
  const CustomPageScrollPhysics({super.parent});

  @override
  CustomPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomPageScrollPhysics(parent: buildParent(ancestor));
  }

  double _getPage(ScrollMetrics position) {
    if (position.viewportDimension == 0.0) return 0.0;
    return position.pixels / position.viewportDimension;
  }

  double _getPixels(ScrollMetrics position, double page) {
    return page * position.viewportDimension;
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }

    final Tolerance tolerance = toleranceFor(position);
    final double page = _getPage(position);
    double targetPage;

    // Giảm ngưỡng vận tốc để fling dễ dàng hơn (nhạy hơn với vận tốc vuốt)
    if (velocity.abs() > tolerance.velocity * 0.5) {
      targetPage = velocity > 0 ? page.ceilToDouble() : page.floorToDouble();
    } else {
      // Giảm ngưỡng vuốt tay từ 50% xuống 20% (chỉ cần vuốt qua 1/5 màn hình là chuyển trang)
      final double fraction = page - page.truncate();
      if (fraction > 0.2) {
        targetPage = page.truncate() + 1.0;
      } else if (fraction < -0.2) {
        targetPage = page.truncate() - 1.0;
      } else {
        targetPage = page.roundToDouble();
      }
    }

    final double targetPixels = _getPixels(position, targetPage);
    if (targetPixels != position.pixels) {
      return SpringSimulation(spring, position.pixels, targetPixels, velocity, tolerance: tolerance);
    }
    return null;
  }

  @override
  bool get allowImplicitScrolling => false;
}

class _CarouselBannerDialog extends StatefulWidget {
  final List<StartupBannerItem> items;
  final Function(StartupBannerItem) onAction;

  const _CarouselBannerDialog({
    required this.items,
    required this.onAction,
  });

  @override
  State<_CarouselBannerDialog> createState() => _CarouselBannerDialogState();
}

class _CarouselBannerDialogState extends State<_CarouselBannerDialog> {
  late PageController _pageController;
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      if (_currentIndex < widget.items.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 350,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemCount: widget.items.length,
                  itemBuilder: (context, index) {
                    final item = widget.items[index];
                    return Column(
                      children: [
                        if (item.title.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1A1A2E),
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            child: Text(
                              item.title,
                              style: GoogleFonts.quicksand(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: item.title.isNotEmpty
                                ? const BorderRadius.vertical(bottom: Radius.circular(16))
                                : BorderRadius.circular(16),
                            child: GestureDetector(
                              onTap: () => widget.onAction(item),
                              child: Image.network(
                                item.imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: Colors.grey[800],
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.broken_image, color: Colors.white54, size: 50),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      widget.items.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentIndex == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentIndex == index ? const Color(0xFFEC4899) : Colors.white38,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.small(
            onPressed: () => Navigator.pop(context),
            backgroundColor: Colors.white24,
            elevation: 0,
            child: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

