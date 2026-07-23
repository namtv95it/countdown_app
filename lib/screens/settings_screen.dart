import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/ad_service.dart';
import '../services/promo_service.dart';
import '../services/localization_service.dart';
import '../widgets/premium_dialog.dart';
import '../widgets/success_promo_dialog.dart';
import '../widgets/theme_picker_sheet.dart';

class SettingsScreen extends StatefulWidget {
  final ValueChanged<String>? onEffectChanged;
  final ValueChanged<bool>? onPremiumChanged;
  const SettingsScreen({super.key, this.onEffectChanged, this.onPremiumChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  int _reminderDays = 1; // 1, 3, 7
  TimeOfDay _notificationTime = const TimeOfDay(hour: 8, minute: 0);
  bool _soundEnabled = true;

  String _shopUrl = 'https://shopee.vn/';
  bool _isPremium = false;
  bool _isLoading = true;
  String _language = 'vi'; // 'vi' or 'en'
  bool _isTestModeUnlocked = false;

  // Lưu trạng thái mở khóa của từng hiệu ứng để tránh FutureBuilder gây flicker
  final Map<String, bool> _effectUnlocked = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _reminderDays = prefs.getInt('reminder_days') ?? 1;
      
      final hour = prefs.getInt('notification_hour') ?? 8;
      final minute = prefs.getInt('notification_minute') ?? 0;
      _notificationTime = TimeOfDay(hour: hour, minute: minute);
      
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _shopUrl = prefs.getString('shop_url') ?? 'https://shopee.vn/';
      _language = prefs.getString('language') ?? 'vi';
    });

    
    final effect = await StorageService().getSelectedEffect();
    // Pre-load trạng thái mở khóa
    final effectIds = [
      'bubbles',
      'hearts',
      'snow',
      'stars',
      'meteor',
      'rain',
      'rain_ripple',
      'rainbow',
      'waves',
      'leaves',
      'sunset_birds',
      'aurora',
      'fireflies',
      'fireworks',
      'cherry_blossom',
      'galaxy',
    ];
    final storage = StorageService();
    final unlockResults = await Future.wait(
      effectIds.map((id) => storage.isFeatureUnlocked('${id}_effect_unlocked')),
    );
    final testModeUnlocked = await storage.getIsTestModeUnlocked();
    
    if (mounted) {
      setState(() {
        _isPremium = AdService.isPremium;
        _isTestModeUnlocked = testModeUnlocked;
        for (int i = 0; i < effectIds.length; i++) {
          _effectUnlocked[effectIds[i]] = unlockResults[i];
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePremium(bool value) async {
    setState(() {
      _isPremium = value;
    });
    AdService.isPremium = value;
    await StorageService().setPremium(value);
    widget.onPremiumChanged?.call(value);
    _showMessage(value ? t('premium_unlocked_desc') : t('premium_locked_desc'));
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (value) {
      final granted = await NotificationService().requestPermissions();
      if (!granted) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1A1A2E),
              title: Text(t('notifications'), style: GoogleFonts.quicksand(color: Colors.white, fontWeight: FontWeight.bold)),
              content: Text(t('event_reminders_desc'), style: GoogleFonts.quicksand(color: Colors.white70)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(t('cancel'), style: GoogleFonts.quicksand(color: Colors.white54)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    openAppSettings();
                  },
                  child: Text(t('settings'), style: GoogleFonts.quicksand(color: const Color(0xFF7C3AED), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
        return;
      }
    }

    setState(() {
      _notificationsEnabled = value;
    });
    
    await prefs.setBool('notifications_enabled', value);
    await NotificationService().scheduleNotifications();
  }

  Future<void> _toggleSound(bool value) async {
    setState(() {
      _soundEnabled = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', value);
    await NotificationService().scheduleNotifications();
  }

  Future<void> _selectReminderDays() async {
    final days = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t('reminder_time'),
          style: GoogleFonts.quicksand(
              fontWeight: FontWeight.w700, color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogOption(t('reminder_time_desc_days', params: {'days': '1'}), 1, _reminderDays),
            _buildDialogOption(t('reminder_time_desc_days', params: {'days': '3'}), 3, _reminderDays),
            _buildDialogOption(t('reminder_time_desc_7'), 7, _reminderDays),
          ],
        ),
      ),
    );

    if (days != null) {
      setState(() {
        _reminderDays = days;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('reminder_days', days);
    }
  }

  Widget _buildDialogOption(String label, int value, int currentValue) {
    final isSelected = value == currentValue;
    return ListTile(
      title: Text(
        label,
        style: GoogleFonts.quicksand(
          color: isSelected ? const Color(0xFF7C3AED) : Colors.white,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF7C3AED))
          : null,
      onTap: () => Navigator.pop(context, value),
    );
  }

  Future<void> _selectNotificationTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF7C3AED),
              onPrimary: Colors.white,
              surface: Color(0xFF1A1A2E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() {
        _notificationTime = time;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('notification_hour', time.hour);
      await prefs.setInt('notification_minute', time.minute);
    }
  }

  Future<void> _editShopUrl() async {
    final controller = TextEditingController(text: _shopUrl);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Link Shop của bạn',
          style: GoogleFonts.quicksand(
              fontWeight: FontWeight.w700, color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          style: GoogleFonts.quicksand(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Nhập link Shopee/Lazada...',
            hintStyle: GoogleFonts.quicksand(color: Colors.white38),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white24),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF7C3AED)),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy',
                style: GoogleFonts.quicksand(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text('Lưu',
                style: GoogleFonts.quicksand(
                    color: const Color(0xFF7C3AED), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      setState(() {
        _shopUrl = result.trim();
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('shop_url', result.trim());
    }
  }

  Future<void> _toggleLanguage(String lang) async {
    await LocalizationService.changeLanguage(lang);
    setState(() {
      _language = lang;
    });
    _showMessage(lang == 'vi' ? t('language_changed_vi') : t('language_changed_en'));
  }

  Widget _buildLanguageToggle() {
    bool isVi = _language == 'vi';
    return GestureDetector(
      onTap: () {
        _toggleLanguage(isVi ? 'en' : 'vi');
      },
      child: Container(
        width: 64,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.1),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Stack(
          children: [
            // Cờ không được chọn
            Positioned(
              left: isVi ? 6 : 36,
              top: 4,
              child: Opacity(
                opacity: 0.5,
                child: Text(
                  isVi ? '🇬🇧' : '🇻🇳',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            // Cờ được chọn (nằm trong hình tròn nổi)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              left: isVi ? 32 : 2,
              top: 1,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF7C3AED),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  isVi ? '🇻🇳' : '🇬🇧',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _showPromoCodeDialog() {
    final controller = TextEditingController();
    bool isChecking = false;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.white12),
          ),
          title: Row(
            children: [
              const Icon(Icons.vpn_key_rounded, color: Colors.amber),
              const SizedBox(width: 10),
              Text(
                t('gift_code_title'),
                style: GoogleFonts.quicksand(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('gift_code_instruction'),
                style: GoogleFonts.quicksand(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                textCapitalization: TextCapitalization.characters,
                style: GoogleFonts.quicksand(color: Colors.white, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: t('enter_gift_code'),
                  hintStyle: GoogleFonts.quicksand(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.amber),
                  ),
                ),
              ),
              if (errorMsg != null) ...[
                const SizedBox(height: 8),
                Text(
                  errorMsg!,
                  style: GoogleFonts.quicksand(
                    color: const Color(0xFFEF4444),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('cancel'), style: GoogleFonts.quicksand(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isChecking
                  ? null
                  : () async {
                      setDialogState(() {
                        isChecking = true;
                        errorMsg = null;
                      });
                      final result = await PromoService.redeemCode(controller.text);
                      if (!context.mounted) return;
                      if (result.success) {
                        Navigator.pop(context);
                        if (result.matchedCode?.type == PromoType.premium) {
                          _togglePremium(true);
                        } else {
                          await _loadSettings();
                          final unlockedEffect = result.matchedCode?.unlockedEffectId;
                          if (unlockedEffect != null) {
                            widget.onEffectChanged?.call(unlockedEffect);
                          }
                        }
                        if (result.matchedCode != null) {
                          SuccessPromoDialog.show(context, result.matchedCode!);
                        }
                      } else {
                        setDialogState(() {
                          isChecking = false;
                          errorMsg = result.message;
                        });
                      }
                    },
              child: isChecking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(t('activate'), style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text(isError ? '⚠️ ' : '✨ ', style: const TextStyle(fontSize: 16)),
            Expanded(
              child: Text(message,
                  style: GoogleFonts.quicksand(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            Text(
              t('settings'),
              style: GoogleFonts.quicksand(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            
            _buildSectionHeader('💎 ${t('premium_account')}'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: _isPremium
                      ? [const Color(0xFF1F2937), const Color(0xFF111827)]
                      : [
                          const Color(0xFF7C3AED).withValues(alpha: 0.3),
                          const Color(0xFFEC4899).withValues(alpha: 0.3),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: _isPremium
                      ? const Color(0xFFFFD700).withValues(alpha: 0.6)
                      : const Color(0xFFEC4899).withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    PremiumDialog.show(
                      context,
                      onPremiumUnlocked: () {
                        _togglePremium(true);
                      },
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFE259), Color(0xFFFF6700)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFA500).withValues(alpha: 0.4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.workspace_premium_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _isPremium ? t('premium_member') : t('upgrade_premium'),
                                    style: GoogleFonts.quicksand(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (_isPremium) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.check_circle_rounded, color: Color(0xFFFFD700), size: 18),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isPremium
                                    ? t('premium_unlocked_desc')
                                    : t('premium_locked_desc'),
                                style: GoogleFonts.quicksand(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Colors.white70),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildListTile(
              title: t('enter_gift_code'),
              subtitle: t('enter_gift_code_desc'),
              trailing: const Icon(Icons.vpn_key_rounded, color: Colors.amber),
              onTap: _showPromoCodeDialog,
            ),
            if (_isTestModeUnlocked) ...[
              const SizedBox(height: 10),
              _buildListTile(
                title: t('test_premium'),
                subtitle: t('test_premium_desc'),
                trailing: Switch(
                  value: _isPremium,
                  onChanged: _togglePremium,
                  activeThumbColor: Colors.amber,
                  activeTrackColor: Colors.amber.withValues(alpha: 0.3),
                ),
              ),
            ],
            const SizedBox(height: 24),

            _buildSectionHeader('🔔 ${t('notifications')}'),
            _buildListTile(
              title: t('event_reminders'),
              subtitle: t('event_reminders_desc'),
              trailing: Switch(
                value: _notificationsEnabled,
                onChanged: _toggleNotifications,
                activeColor: const Color(0xFF7C3AED),
              ),
            ),
            if (_notificationsEnabled) ...[
              _buildListTile(
                title: t('reminder_time'),
                subtitle: _reminderDays == 7
                    ? t('reminder_time_desc_7')
                    : t('reminder_time_desc_days', params: {'days': _reminderDays.toString()}),
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: Colors.white54),
                onTap: _selectReminderDays,
              ),
              _buildListTile(
                title: t('notification_hour'),
                subtitle: _notificationTime.format(context),
                trailing: const Icon(Icons.access_time_rounded,
                    color: Colors.white54),
                onTap: _selectNotificationTime,
              ),
              _buildListTile(
                title: t('notification_sound'),
                subtitle: t('notification_sound_desc'),
                trailing: Switch(
                  value: _soundEnabled,
                  onChanged: _toggleSound,
                  activeColor: const Color(0xFF7C3AED),
                ),
              ),
            ],


            const SizedBox(height: 24),
            _buildSectionHeader('🎨 ${t('ui_and_lang')}'),
            _buildListTile(
              title: t('language'),
              subtitle: _language == 'vi' ? t('vietnamese') : t('english'),
              trailing: _buildLanguageToggle(),
            ),
            _buildListTile(
              title: t('customize_ui'),
              subtitle: t('customize_ui_desc'),
              trailing: const Icon(Icons.palette_rounded, color: Colors.amber),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => ThemePickerSheet(
                    onEffectChanged: widget.onEffectChanged,
                  ),
                );
              },
            ),

            // const SizedBox(height: 24),
            // _buildSectionHeader('🎁 Quà tặng & Lời chúc'),
            // _buildListTile(
            //   title: 'Cửa hàng của tôi',
            //   subtitle: _shopUrl,
            //   trailing: const Icon(Icons.edit_rounded, color: Colors.white54),
            //   onTap: _editShopUrl,
            // ),

            const SizedBox(height: 24),
            _buildSectionHeader('ℹ️ ${t('info')}'),
            _buildListTile(
              title: t('rate_app'),
              subtitle: t('rate_app_desc'),
              trailing: const Icon(Icons.star_rounded, color: Colors.amber),
              onTap: () => _showMessage(t('thank_you_rating')),
            ),
            _buildListTile(
              title: t('version'),
              subtitle: '1.0.0',
              trailing: const SizedBox(),
            ),
            

            const SizedBox(height: 180), // Khoảng trống cho BottomNav và Ad
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.quicksand(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFA78BFA),
        ),
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              title: Text(
                title,
                style: GoogleFonts.quicksand(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              subtitle: Text(
                subtitle,
                style: GoogleFonts.quicksand(
                  fontSize: 13,
                  color: Colors.white54,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: trailing,
              onTap: onTap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ),
    );
  }
}
