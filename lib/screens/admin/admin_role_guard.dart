import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/app_firebase_service.dart';

/// Widget bảo vệ quyền truy cập admin.
/// Kiểm tra role Firebase khi màn hình mở, hiển thị nội dung nếu đủ quyền,
/// hiển thị màn hình "Không có quyền" nếu không.
class AdminRoleGuard extends StatefulWidget {
  /// Widget nội dung khi đã xác thực đủ quyền
  final Widget child;

  /// Tiêu đề màn hình (dùng trong AppBar của trang lỗi)
  final String screenTitle;

  const AdminRoleGuard({
    super.key,
    required this.child,
    required this.screenTitle,
  });

  @override
  State<AdminRoleGuard> createState() => _AdminRoleGuardState();
}

class _AdminRoleGuardState extends State<AdminRoleGuard> {
  bool _isChecking = true;
  bool _isAuthorized = false;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final isAdmin = await AppFirebaseService().checkIsCurrentUserAdmin();
    if (mounted) {
      setState(() {
        _isAuthorized = isAdmin;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F1A),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isAuthorized) {
      return widget.child;
    }

    // Màn hình "Không có quyền"
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.screenTitle,
          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3), width: 1.5),
                ),
                child: const Icon(Icons.lock_outline_rounded, color: Colors.redAccent, size: 40),
              ),
              const SizedBox(height: 20),
              Text(
                'Không có quyền truy cập',
                style: GoogleFonts.quicksand(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Tài khoản của bạn không có quyền Admin để truy cập khu vực này.\n'
                'Vui lòng đăng nhập bằng tài khoản quản trị viên.',
                style: GoogleFonts.quicksand(
                  color: Colors.white54,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70, size: 18),
                label: Text(
                  'Quay lại',
                  style: GoogleFonts.quicksand(color: Colors.white70, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
