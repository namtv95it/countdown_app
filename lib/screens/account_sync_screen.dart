import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/anniversary.dart';
import '../services/app_firebase_service.dart';
import '../services/localization_service.dart';
import '../services/storage_service.dart';

class AccountSyncScreen extends StatefulWidget {
  final Function()? onDataChanged;

  const AccountSyncScreen({super.key, this.onDataChanged});

  @override
  State<AccountSyncScreen> createState() => _AccountSyncScreenState();
}

class _AccountSyncScreenState extends State<AccountSyncScreen> {
  final AppFirebaseService _auth = AppFirebaseService();
  final StorageService _storage = StorageService();

  DateTime? _lastBackupTime;
  bool _isLoading = true;
  bool _isOperating = false;

  @override
  void initState() {
    super.initState();
    _loadBackupInfo();
  }

  Future<void> _loadBackupInfo() async {
    setState(() => _isLoading = true);
    final time = await _auth.getLastBackupTime();
    if (mounted) {
      setState(() {
        _lastBackupTime = time;
        _isLoading = false;
      });
    }
  }

  String t(String key) => LocalizationService.translate(key);

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.quicksand(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Show Confirmation Dialog with Checkbox ──
  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String checkboxLabel,
  }) async {
    bool isChecked = false;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E2E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.quicksand(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: GoogleFonts.quicksand(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isChecked ? const Color(0xFF7C3AED) : Colors.white12,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: CheckboxListTile(
                        value: isChecked,
                        onChanged: (val) {
                          setDialogState(() {
                            isChecked = val ?? false;
                          });
                        },
                        title: Text(
                          checkboxLabel,
                          style: GoogleFonts.quicksand(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        activeColor: const Color(0xFF7C3AED),
                        checkColor: Colors.white,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    t('cancel_btn'),
                    style: GoogleFonts.quicksand(color: Colors.white54, fontWeight: FontWeight.w600),
                  ),
                ),
                ElevatedButton(
                  onPressed: isChecked ? () => Navigator.pop(context, true) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    disabledBackgroundColor: Colors.white10,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    t('confirm_btn'),
                    style: GoogleFonts.quicksand(
                      color: isChecked ? Colors.white : Colors.white38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    return result ?? false;
  }

  // ── Handle Backup ──
  Future<void> _handleBackup() async {
    final confirmed = await _showConfirmDialog(
      title: t('backup_confirm_title'),
      message: t('backup_confirm_msg'),
      checkboxLabel: t('backup_checkbox_agree'),
    );

    if (!confirmed) return;

    setState(() => _isOperating = true);
    try {
      final list = await _storage.getAnniversaries();
      final dataList = list.map((item) => item.toMap()).toList();

      final success = await _auth.backupAnniversariesToCloud(dataList);
      if (success) {
        await _loadBackupInfo();
        _showMessage(t('backup_success'));
      } else {
        _showMessage(t('sign_in_error'), isError: true);
      }
    } catch (e) {
      _showMessage(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isOperating = false);
    }
  }

  // ── Handle Restore ──
  Future<void> _handleRestore() async {
    final confirmed = await _showConfirmDialog(
      title: t('restore_confirm_title'),
      message: t('restore_confirm_msg'),
      checkboxLabel: t('restore_checkbox_agree'),
    );

    if (!confirmed) return;

    setState(() => _isOperating = true);
    try {
      final result = await _auth.restoreAnniversariesFromCloud();
      if (result == null || result['anniversaries'] == null) {
        _showMessage(t('no_cloud_data'), isError: true);
        return;
      }

      final List<Map<String, dynamic>> rawList = List<Map<String, dynamic>>.from(result['anniversaries']);
      final List<Anniversary> restoredList =
          rawList.map<Anniversary>((map) => Anniversary.fromMap(map)).toList();

      await _storage.saveAnniversaries(restoredList);
      widget.onDataChanged?.call();
      await _loadBackupInfo();
      _showMessage(t('restore_success'));
    } catch (e) {
      debugPrint('Error during restore: $e');
      _showMessage(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isOperating = false);
    }
  }

  // ── Handle Sign Out ──
  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          t('sign_out'),
          style: GoogleFonts.quicksand(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          t('sign_out_confirm'),
          style: GoogleFonts.quicksand(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t('cancel_btn'), style: GoogleFonts.quicksand(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(t('sign_out'), style: GoogleFonts.quicksand(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _auth.signOut();
      if (mounted) {
        _showMessage(t('sign_out_success'));
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final photoUrl = _auth.userPhotoUrl;
    final email = _auth.userEmail ?? '';
    final displayName = _auth.userDisplayName ?? email.split('@').first;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t('account_and_backup'),
          style: GoogleFonts.quicksand(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── User Profile Card ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF7C3AED).withOpacity(0.3),
                    const Color(0xFF3B82F6).withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white24,
                    backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                        ? NetworkImage(photoUrl)
                        : null,
                    child: photoUrl == null || photoUrl.isEmpty
                        ? const Icon(Icons.person, color: Colors.white, size: 36)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: GoogleFonts.quicksand(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: GoogleFonts.quicksand(
                            color: Colors.white60,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  color: Color(0xFF10B981), size: 14),
                              const SizedBox(width: 6),
                              Text(
                                t('google_account'),
                                style: GoogleFonts.quicksand(
                                  color: const Color(0xFF10B981),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
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

            const SizedBox(height: 24),

            // ── Backup Info Card ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cloud_sync_rounded,
                        color: Color(0xFF7C3AED), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('last_backup_time'),
                          style: GoogleFonts.quicksand(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        _isLoading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white54),
                              )
                            : Text(
                                _lastBackupTime != null
                                    ? DateFormat('dd/MM/yyyy - HH:mm')
                                        .format(_lastBackupTime!)
                                    : t('no_backup_yet'),
                                style: GoogleFonts.quicksand(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Backup / Restore Action Buttons ──
            if (_isOperating)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
                ),
              )
            else ...[
              ElevatedButton.icon(
                onPressed: _handleBackup,
                icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white),
                label: Text(
                  t('backup_now'),
                  style: GoogleFonts.quicksand(
                      fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: const Color(0xFF7C3AED).withOpacity(0.4),
                ),
              ),

              const SizedBox(height: 14),

              OutlinedButton.icon(
                onPressed: _handleRestore,
                icon: const Icon(Icons.cloud_download_rounded, color: Color(0xFF3B82F6)),
                label: Text(
                  t('restore_now'),
                  style: GoogleFonts.quicksand(
                      fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF3B82F6)),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],

            const SizedBox(height: 40),

            // ── Sign Out Button ──
            Center(
              child: TextButton.icon(
                onPressed: _handleSignOut,
                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                label: Text(
                  t('sign_out'),
                  style: GoogleFonts.quicksand(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
