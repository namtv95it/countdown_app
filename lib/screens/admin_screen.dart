import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin/admin_dashboard_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _isUnlocked = false;
  bool _isChecking = false;
  String? _errorMsg;
  final TextEditingController _passController = TextEditingController();

  Future<void> _checkPassword() async {
    final input = _passController.text.trim();
    if (input.isEmpty) return;

    setState(() {
      _isChecking = true;
      _errorMsg = null;
    });

    try {
      // Băm (Hash) mật khẩu bằng SHA-256
      final bytes = utf8.encode(input);
      final hash = sha256.convert(bytes).toString();

      final docRef = FirebaseFirestore.instance.collection('config').doc('admin');
      final docSnap = await docRef.get();

      if (docSnap.exists) {
        final storedHash = docSnap.data()?['passwordHash'] as String?;
        if (storedHash == hash) {
          setState(() => _isUnlocked = true);
        } else {
          setState(() => _errorMsg = 'Mã bảo mật không đúng!');
        }
      } else {
        // Lần đầu tiên: Tạo mật khẩu gốc
        await docRef.set({'passwordHash': hash});
        setState(() => _isUnlocked = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã thiết lập mật khẩu Quản trị viên thành công!'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _errorMsg = 'Lỗi kết nối máy chủ!');
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  void dispose() {
    _passController.dispose();
    super.dispose();
  }

  Widget _buildLockScreen() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFEC4899).withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.lock_rounded,
              size: 64,
              color: Color(0xFFEC4899),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Xác Thực Quản Trị Viên',
            style: GoogleFonts.quicksand(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Vui lòng nhập mã bảo mật (Password) để truy cập hệ thống.',
            style: GoogleFonts.quicksand(
              fontSize: 15,
              color: Colors.white54,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _passController,
            obscureText: true,
            style: GoogleFonts.quicksand(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '••••••••',
              hintStyle: GoogleFonts.quicksand(color: Colors.white24, letterSpacing: 4),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFEC4899), width: 1.5),
              ),
            ),
            onSubmitted: (_) => _checkPassword(),
          ),
          if (_errorMsg != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMsg!,
              style: GoogleFonts.quicksand(
                color: Colors.red.shade400,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isChecking ? null : _checkPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEC4899),
                disabledBackgroundColor: const Color(0xFFEC4899).withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isChecking
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'XÁC NHẬN',
                      style: GoogleFonts.quicksand(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              size: 64,
              color: Color(0xFF7C3AED),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Khu Vực Quản Trị',
            style: GoogleFonts.quicksand(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Mật khẩu đúng. Đang chuyển hướng...',
            style: GoogleFonts.quicksand(
              fontSize: 16,
              color: Colors.white54,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          const CircularProgressIndicator(color: Color(0xFF7C3AED)),
        ],
      ),
    );
  }

  void _navigateToDashboard() {
    Future.microtask(() {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isUnlocked) {
      _navigateToDashboard();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A), // Dark elegant background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isUnlocked ? _buildDashboard() : _buildLockScreen(),
      ),
    );
  }
}
