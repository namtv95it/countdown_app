import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/ad_service.dart';

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
  String _selectedEffect = 'none';
  bool _isPremium = false;
  bool _isLoading = true;
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
    });
    
    final effect = await StorageService().getSelectedEffect();
    // Pre-load trạng thái mở khóa
    final storage = StorageService();
    final effectIds = ['bubbles', 'hearts', 'snow', 'stars', 'meteor'];
    final unlockResults = await Future.wait(
      effectIds.map((id) => storage.isFeatureUnlocked('${id}_effect_unlocked')),
    );
    if (mounted) {
      setState(() {
        _selectedEffect = effect;
        _isPremium = AdService.isPremium;
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
    _showMessage(value ? 'Đã bật tài khoản Premium!' : 'Đã tắt tài khoản Premium!');
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
              title: Text('Cấp quyền thông báo', style: GoogleFonts.quicksand(color: Colors.white, fontWeight: FontWeight.bold)),
              content: Text('Ứng dụng cần quyền thông báo để nhắc nhở sự kiện. Vui lòng cấp quyền trong phần Cài đặt của điện thoại.', style: GoogleFonts.quicksand(color: Colors.white70)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Hủy', style: GoogleFonts.quicksand(color: Colors.white54)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    openAppSettings();
                  },
                  child: Text('Mở Cài đặt', style: GoogleFonts.quicksand(color: const Color(0xFF7C3AED), fontWeight: FontWeight.bold)),
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
          'Thời điểm nhắc',
          style: GoogleFonts.quicksand(
              fontWeight: FontWeight.w700, color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogOption('Trước 1 ngày', 1, _reminderDays),
            _buildDialogOption('Trước 3 ngày', 3, _reminderDays),
            _buildDialogOption('Trước 1 tuần', 7, _reminderDays),
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

  Future<void> _selectEffect(String effectId, String effectName) async {
    if (effectId == 'none') {
      setState(() => _selectedEffect = 'none');
      await StorageService().setSelectedEffect('none');
      widget.onEffectChanged?.call('none');
      return;
    }

    final isUnlocked = await StorageService().isFeatureUnlocked('${effectId}_effect_unlocked');
    if (isUnlocked || _isPremium) {
      if (mounted) {
        setState(() => _selectedEffect = effectId);
      }
      await StorageService().setSelectedEffect(effectId);
      widget.onEffectChanged?.call(effectId);
      return;
    }

    // Yêu cầu xem quảng cáo
    if (!mounted) return;
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
            const Icon(Icons.auto_awesome_rounded, color: Colors.amber),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Hiệu ứng $effectName',
                  style: GoogleFonts.quicksand(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ],
        ),
        content: Text(
          'Xem 1 đoạn video quảng cáo ngắn để mở khóa vĩnh viễn hiệu ứng $effectName tuyệt đẹp cho Trang chủ nhé!',
          style: GoogleFonts.quicksand(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: GoogleFonts.quicksand(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.play_circle_filled_rounded),
            label: Text('Xem Video', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context); // Đóng dialog
              AdService.showRewardedAd(
                onEarnedReward: () async {
                  await StorageService().unlockFeature('${effectId}_effect_unlocked');
                  await StorageService().setSelectedEffect(effectId);
                  if (mounted) {
                    setState(() => _selectedEffect = effectId);
                    widget.onEffectChanged?.call(effectId);
                    _showMessage('🎉 Đã mở khóa vĩnh viễn hiệu ứng $effectName!');
                  }
                },
              );
            },
          ),
        ],
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
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            Text(
              'Cài đặt',
              style: GoogleFonts.quicksand(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            
            _buildSectionHeader('💎 Tài khoản Premium'),
            _buildListTile(
              title: 'Nâng cấp Premium',
              subtitle: 'Ẩn tất cả quảng cáo & mở khóa tính năng',
              trailing: Switch(
                value: _isPremium,
                onChanged: _togglePremium,
                activeColor: Colors.amber,
                activeTrackColor: Colors.amber.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('🔔 Thông báo'),
            _buildListTile(
              title: 'Nhắc nhở sự kiện',
              subtitle: 'Nhận thông báo khi sắp đến ngày kỷ niệm',
              trailing: Switch(
                value: _notificationsEnabled,
                onChanged: _toggleNotifications,
                activeColor: const Color(0xFF7C3AED),
              ),
            ),
            if (_notificationsEnabled) ...[
              _buildListTile(
                title: 'Thời điểm nhắc',
                subtitle: _reminderDays == 7
                    ? 'Trước 1 tuần'
                    : 'Trước $_reminderDays ngày',
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: Colors.white54),
                onTap: _selectReminderDays,
              ),
              _buildListTile(
                title: 'Giờ gửi thông báo',
                subtitle: _notificationTime.format(context),
                trailing: const Icon(Icons.access_time_rounded,
                    color: Colors.white54),
                onTap: _selectNotificationTime,
              ),
              _buildListTile(
                title: 'Âm thanh thông báo',
                subtitle: 'Phát âm thanh khi có thông báo',
                trailing: Switch(
                  value: _soundEnabled,
                  onChanged: _toggleSound,
                  activeColor: const Color(0xFF7C3AED),
                ),
              ),
            ],


            const SizedBox(height: 24),
            _buildSectionHeader('🎨 Giao diện'),
            const SizedBox(height: 8),
            Text(
              'Hiệu ứng trang chủ',
              style: GoogleFonts.quicksand(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // Grid 3 cột
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.1,
              children: [
                _buildEffectChip('none', 'Không có', Icons.block),
                _buildEffectChip('bubbles', 'Bong bóng', Icons.bubble_chart),
                _buildEffectChip('hearts', 'Trái tim', Icons.favorite),
                _buildEffectChip('snow', 'Tuyết rơi', Icons.ac_unit),
                _buildEffectChip('stars', 'Ngôi sao', Icons.star),
                _buildEffectChip('meteor', 'Sao băng', Icons.auto_awesome),
              ],
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('🛍️ Quà tặng & Lời chúc'),
            _buildListTile(
              title: 'Cửa hàng của tôi',
              subtitle: _shopUrl,
              trailing: const Icon(Icons.edit_rounded, color: Colors.white54),
              onTap: _editShopUrl,
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('ℹ️ Thông tin'),
            _buildListTile(
              title: 'Đánh giá ứng dụng',
              subtitle: 'Để lại nhận xét trên Store',
              trailing: const Icon(Icons.star_rounded, color: Colors.amber),
              onTap: () => _showMessage('Cảm ơn bạn đã đánh giá!'),
            ),
            _buildListTile(
              title: 'Phiên bản',
              subtitle: '1.0.0',
              trailing: const SizedBox(),
            ),
            
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  await NotificationService().scheduleTestNotification();
                  if (mounted) {
                    _showMessage('Sẽ hiển thị thông báo sau 5 giây!');
                  }
                } catch (e) {
                  if (mounted) {
                    _showMessage('Lỗi: $e', isError: true);
                  }
                }
              },
              icon: const Icon(Icons.timer),
              label: const Text('Thử nghiệm thông báo (5s)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            
            const SizedBox(height: 100), // Khoảng trống cho BottomNav
          ],
        ),
      ),
    );
  }

  Widget _buildEffectChip(String id, String name, IconData icon) {
    final isSelected = _selectedEffect == id;
    final isUnlocked = id == 'none' || (_effectUnlocked[id] ?? false) || _isPremium;
    
    return InkWell(
      onTap: () => _selectEffect(id, name),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF7C3AED).withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF7C3AED) : Colors.white12,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUnlocked ? icon : Icons.lock_rounded,
              color: isSelected ? Colors.white : Colors.white60,
              size: 26,
            ),
            const SizedBox(height: 6),
            Text(
              name,
              textAlign: TextAlign.center,
              style: GoogleFonts.quicksand(
                color: isSelected ? Colors.white : Colors.white60,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
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
