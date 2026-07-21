import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  int _reminderDays = 1; // 1, 3, 7
  TimeOfDay _notificationTime = const TimeOfDay(hour: 8, minute: 0);
  bool _soundEnabled = true;

  String _shopUrl = 'https://shopee.vn/';
  bool _isLoading = true;

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
      _isLoading = false;
    });
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
            _buildSectionHeader('🛍️ Quà tặng & Lời chúc'),
            _buildListTile(
              title: 'Cửa hàng của tôi',
              subtitle: _shopUrl,
              trailing: const Icon(Icons.edit_rounded, color: Colors.white54),
              onTap: _editShopUrl,
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('💾 Dữ liệu'),
            _buildListTile(
              title: 'Sao lưu dữ liệu',
              subtitle: 'Lưu các sự kiện ra file (JSON)',
              trailing: const Icon(Icons.download_rounded, color: Colors.white54),
              onTap: () => _showMessage('Đã tải xuống file sao lưu!'),
            ),
            _buildListTile(
              title: 'Khôi phục dữ liệu',
              subtitle: 'Nhập các sự kiện từ file',
              trailing: const Icon(Icons.upload_rounded, color: Colors.white54),
              onTap: () => _showMessage('Đã khôi phục dữ liệu thành công!'),
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
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
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
    );
  }
}
