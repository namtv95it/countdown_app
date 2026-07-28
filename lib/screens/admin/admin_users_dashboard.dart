import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/app_firebase_service.dart';

class AdminUsersDashboard extends StatefulWidget {
  const AdminUsersDashboard({super.key});

  @override
  State<AdminUsersDashboard> createState() => _AdminUsersDashboardState();
}

class _AdminUsersDashboardState extends State<AdminUsersDashboard> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterType = 'all';
  String _roleFilter = 'all';
  bool _filterExpanded = false;

  // Stream data cached — tránh rebuild StreamBuilder khi setState UI
  List<Map<String, dynamic>> _allUsers = [];
  bool _isLoading = true;
  String? _errorStr;
  StreamSubscription<List<Map<String, dynamic>>>? _usersSub;

  @override
  void initState() {
    super.initState();
    _usersSub = AppFirebaseService().getUsersStream().listen(
      (users) {
        if (mounted) {
          setState(() {
            _allUsers = users;
            _isLoading = false;
            _errorStr = null;
          });
        }
      },
      onError: (err) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorStr = err.toString();
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _usersSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Quản Lý Người Dùng',
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Builder(builder: (context) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_errorStr != null) {
            final errStr = _errorStr!;
            final isPermissionDenied = errStr.contains('PERMISSION_DENIED') || errStr.contains('permission');

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_outlined, color: Colors.amber, size: 56),
                    const SizedBox(height: 16),
                    Text(
                      isPermissionDenied ? 'Không có quyền truy cập' : 'Lỗi Tải Dữ Liệu',
                      style: GoogleFonts.quicksand(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isPermissionDenied
                          ? 'Tài khoản của bạn không có quyền truy cập vào hệ thống Quản trị.'
                          : 'Chi tiết lỗi: $errStr',
                      style: GoogleFonts.quicksand(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final allUsers = _allUsers;


          final isManagerOnly = AppFirebaseService().isManager && !AppFirebaseService().isSuperAdmin;

          // Nếu là Manager, danh sách phân tích stats chỉ bao gồm các tài khoản đã đăng nhập (Google)
          final targetUsers = isManagerOnly
              ? allUsers.where((u) {
                  final email = (u['email'] ?? '').toString();
                  final isAnon = u['isAnonymous'] == true || email.isEmpty;
                  return !isAnon;
                }).toList()
              : allUsers;

          int totalUsers = targetUsers.length;
          int premiumUsers = 0;
          int blockedUsers = 0;
          int googleUsers = 0;
          int anonymousUsers = 0;
          int cntSuperAdmin = 0;
          int cntAdmin = 0;
          int cntManager = 0;
          int cntUser = 0;

          for (var u in allUsers) {
            final email = (u['email'] ?? '').toString();
            final isAnon = u['isAnonymous'] == true || email.isEmpty;
            if (isAnon) {
              anonymousUsers++;
            } else {
              googleUsers++;
            }
          }

          for (var u in targetUsers) {
            final unlocked = List<String>.from(u['unlocked_features'] ?? []);
            final isBlocked = u['is_blocked'] == true;
            final role = (u['role'] ?? 'user').toString().toLowerCase();
            if (isBlocked) blockedUsers++;
            if (unlocked.contains('premium')) premiumUsers++;
            if (role == 'super_admin') { cntSuperAdmin++; }
            else if (role == 'admin') { cntAdmin++; }
            else if (role == 'manager') { cntManager++; }
            else { cntUser++; }
          }
          int freeUsers = totalUsers - premiumUsers;

          // Lọc danh sách theo tìm kiếm và bộ lọc tab
          final filteredUsers = targetUsers.where((u) {
            final uid = (u['uid'] ?? '').toString().toLowerCase();
            final email = (u['email'] ?? '').toString().toLowerCase();
            final name = (u['displayName'] ?? '').toString().toLowerCase();
            final q = _searchQuery.toLowerCase().trim();

            final matchesSearch = q.isEmpty ||
                uid.contains(q) ||
                email.contains(q) ||
                name.contains(q);

            if (!matchesSearch) return false;

            final unlocked = List<String>.from(u['unlocked_features'] ?? []);
            final isPremium = unlocked.contains('premium');
            final isBlocked = u['is_blocked'] == true;
            final isAnon = u['isAnonymous'] == true || email.isEmpty;
            final role = (u['role'] ?? 'user').toString().toLowerCase();

            // Manager chỉ có thể xem được người dùng đã đăng nhập (ẩn người dùng ẩn danh)
            if (AppFirebaseService().isManager && !AppFirebaseService().isSuperAdmin && isAnon) {
              return false;
            }

            // Lọc theo loại tài khoản
            bool matchesType = true;
            if (_filterType == 'google') { matchesType = !isAnon; }
            else if (_filterType == 'anonymous') { matchesType = isAnon; }
            else if (_filterType == 'premium') { matchesType = isPremium; }
            else if (_filterType == 'free') { matchesType = !isPremium; }
            else if (_filterType == 'blocked') { matchesType = isBlocked; }

            // Lọc theo vai trò
            bool matchesRole = true;
            if (_roleFilter == 'super_admin') { matchesRole = role == 'super_admin'; }
            else if (_roleFilter == 'admin') { matchesRole = role == 'admin'; }
            else if (_roleFilter == 'manager') { matchesRole = role == 'manager'; }
            else if (_roleFilter == 'user') { matchesRole = role != 'super_admin' && role != 'admin' && role != 'manager'; }

            return matchesType && matchesRole;
          }).toList();

          final activeFilterCount = (_filterType != 'all' ? 1 : 0) + (_roleFilter != 'all' ? 1 : 0);
          final hasActiveFilter = activeFilterCount > 0;

          // ─ Search Row + Filter Toggle Button ─────────────────────────────────
          final searchRow = Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: GoogleFonts.quicksand(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Tìm theo Name, Email, UID...',
                      hintStyle: GoogleFonts.quicksand(color: Colors.white38, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: Colors.white54, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFF1A1A2E),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.white12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.white12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _filterExpanded = !_filterExpanded),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _filterExpanded || hasActiveFilter
                          ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
                          : const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _filterExpanded || hasActiveFilter ? const Color(0xFF3B82F6) : Colors.white12,
                        width: _filterExpanded || hasActiveFilter ? 1.5 : 1,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          _filterExpanded ? Icons.filter_list_off_rounded : Icons.filter_list_rounded,
                          color: _filterExpanded || hasActiveFilter ? const Color(0xFF60A5FA) : Colors.white54,
                          size: 20,
                        ),
                        if (hasActiveFilter)
                          Positioned(
                            top: 6, right: 6,
                            child: Container(
                              width: 14, height: 14,
                              decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle),
                              child: Center(
                                child: Text('$activeFilterCount',
                                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );

          // ─ Filter Panel ─────────────────────────────────────────────────────
          final filterPanel = Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.tune_rounded, color: Color(0xFF60A5FA), size: 12),
                  const SizedBox(width: 5),
                  Text('Loại:', style: GoogleFonts.quicksand(color: const Color(0xFF60A5FA), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                ]),
                const SizedBox(height: 7),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    _buildFilterChip(isManagerOnly ? 'Tất cả ($googleUsers)' : 'Tất cả ($totalUsers)', 'all', const Color(0xFF3B82F6)),
                    const SizedBox(width: 6),
                    _buildFilterChip('Google ($googleUsers)', 'google', const Color(0xFF3B82F6)),
                    if (!isManagerOnly) ...[
                      const SizedBox(width: 6),
                      _buildFilterChip('Ẩn danh ($anonymousUsers)', 'anonymous', const Color(0xFF3B82F6)),
                    ],
                    const SizedBox(width: 6),
                    _buildFilterChip('Premium ($premiumUsers)', 'premium', const Color(0xFFF59E0B)),
                    const SizedBox(width: 6),
                    _buildFilterChip('Miễn phí ($freeUsers)', 'free', const Color(0xFF10B981)),
                    if (blockedUsers > 0 && !isManagerOnly) ...[
                      const SizedBox(width: 6),
                      _buildFilterChip('Đã khóa ($blockedUsers)', 'blocked', Colors.redAccent),
                    ],
                  ]),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: Colors.white10, height: 1),
                ),
                Row(children: [
                  const Icon(Icons.shield_rounded, color: Color(0xFFA78BFA), size: 12),
                  const SizedBox(width: 5),
                  Text('Vai trò:', style: GoogleFonts.quicksand(color: const Color(0xFFA78BFA), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                ]),
                const SizedBox(height: 7),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    _buildRoleChip('Tất cả', 'all', null),
                    if (AppFirebaseService().isSuperAdmin) ...[
                      const SizedBox(width: 6),
                      _buildRoleChip('👑 Super Admin ($cntSuperAdmin)', 'super_admin', const Color(0xFFF59E0B)),
                    ],
                    const SizedBox(width: 6),
                    _buildRoleChip('🛡️ Admin ($cntAdmin)', 'admin', const Color(0xFF10B981)),
                    const SizedBox(width: 6),
                    _buildRoleChip('👔 Manager ($cntManager)', 'manager', const Color(0xFF3B82F6)),
                    const SizedBox(width: 6),
                    _buildRoleChip('👤 User ($cntUser)', 'user', Colors.white60),
                  ]),
                ),
              ],
            ),
          );

          return Column(
            children: [
              // ─ Stats: Luôn hiển thị cố định ──────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    _buildStatCard('Tổng', '$totalUsers', const Color(0xFF3B82F6), Icons.people_alt_rounded),
                    const SizedBox(width: 8),
                    _buildStatCard('Premium', '$premiumUsers', const Color(0xFFF59E0B), Icons.workspace_premium_rounded),
                    const SizedBox(width: 8),
                    _buildStatCard('Miễn Phí', '$freeUsers', const Color(0xFF10B981), Icons.person_outline_rounded),
                  ],
                ),
              ),

              // ─ Search Row + Filter Button (always visible) ────────────────
              searchRow,

              // ─ Filter Panel (toggle by button) ────────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: _filterExpanded ? filterPanel : const SizedBox.shrink(),
              ),

              // ─ User List ────────────────────────────────────────────
              Expanded(
                child: filteredUsers.isEmpty
                    ? Center(
                        child: Text(
                          'Không tìm thấy người dùng phù hợp',
                          style: GoogleFonts.quicksand(color: Colors.white38, fontSize: 15),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) => _buildUserTile(filteredUsers[index]),
                      ),
              ),
            ],
          );
        }),
    );
  }


  Widget _buildFilterChip(String label, String value, Color accentColor) {
    final isSelected = _filterType == value;
    return GestureDetector(
      onTap: () => setState(() => _filterType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : Colors.white10,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.quicksand(
            color: isSelected ? accentColor : Colors.white54,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildRoleChip(String label, String value, Color? accentColor) {
    final isSelected = _roleFilter == value;
    final color = accentColor ?? const Color(0xFFA78BFA);
    return GestureDetector(
      onTap: () => setState(() => _roleFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.white10,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.quicksand(
            color: isSelected ? color : Colors.white54,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  String _getEffectName(String id) {
    switch (id) {
      case 'hearts': return 'Trái tim';
      case 'bubbles': return 'Bóng bóng';
      case 'snow': return 'Tuyết rơi';
      case 'stars': return 'Sao đêm';
      case 'meteor': return 'Sao băng';
      case 'rain': return 'Mưa rơi';
      case 'rain_ripple': return 'Gợn sóng mưa';
      case 'rainbow': return 'Cầu vồng';
      case 'waves': return 'Sóng biển';
      case 'leaves': return 'Lá rơi';
      case 'sunset_birds': return 'Chim hoàng hôn';
      case 'aurora': return 'Cực quang';
      case 'fireflies': return 'Đom đốm';
      case 'fireworks': return 'Pháo hoa';
      case 'cherry_blossom': return 'Hoa đào';
      case 'galaxy': return 'Thiên hà';
      default: return id;
    }
  }

  Widget _buildAvatarWithRoleFrame({
    required Map<String, dynamic> user,
    required bool isBlocked,
    required bool isPremium,
    required String photoUrl,
    required String displayName,
  }) {
    final role = (user['role'] ?? '').toString().toLowerCase();

    Color borderColor = Colors.white24;
    Color glowColor = Colors.transparent;
    String emoji = '👤';

    if (isBlocked) {
      borderColor = Colors.redAccent;
      glowColor = Colors.redAccent.withValues(alpha: 0.4);
      emoji = '🚫';
    } else if (role == 'super_admin') {
      borderColor = const Color(0xFFA78BFA);
      glowColor = const Color(0xFF8B5CF6).withValues(alpha: 0.5);
      emoji = '👑';
    } else if (role == 'admin') {
      borderColor = const Color(0xFF34D399);
      glowColor = const Color(0xFF10B981).withValues(alpha: 0.5);
      emoji = '🛡️';
    } else if (role == 'manager') {
      borderColor = const Color(0xFF60A5FA);
      glowColor = const Color(0xFF3B82F6).withValues(alpha: 0.5);
      emoji = '👔';
    } else if (isPremium) {
      borderColor = const Color(0xFFF59E0B);
      glowColor = const Color(0xFFF59E0B).withValues(alpha: 0.4);
      emoji = '👤';
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Avatar với Khung Viền & Hào Quang (Glow)
        Container(
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 2.0),
            boxShadow: [
              if (glowColor != Colors.transparent)
                BoxShadow(
                  color: glowColor,
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: isPremium ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6),
            backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
            child: photoUrl.isEmpty
                ? Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                    style: GoogleFonts.quicksand(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  )
                : null,
          ),
        ),
        // Huy hiệu Emoji nhỏ góc dưới bên phải Avatar
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    final uid = user['uid'] ?? '';
    final email = (user['email'] ?? '').toString();
    final displayName = (user['displayName'] ?? '').toString();
    final photoUrl = (user['photoUrl'] ?? '').toString();
    final isAnonymous = user['isAnonymous'] == true || email.isEmpty;
    final isBlocked = user['is_blocked'] == true;

    final unlocked = List<String>.from(user['unlocked_features'] ?? []);
    final isPremium = unlocked.contains('premium');

    // Parse expiry date if available
    String premiumLabel = 'Miễn phí';
    if (isPremium) {
      if (user['expirations'] is Map && user['expirations']['premium'] != null) {
        final exp = user['expirations']['premium'];
        DateTime? expiryDate;
        if (exp is Timestamp) {
          expiryDate = exp.toDate();
        } else if (exp is String) {
          expiryDate = DateTime.tryParse(exp);
        }
        if (expiryDate != null) {
          premiumLabel = 'VIP đến ${expiryDate.day}/${expiryDate.month}/${expiryDate.year}';
        } else {
          premiumLabel = 'VIP Vĩnh viễn';
        }
      } else {
        premiumLabel = 'VIP Vĩnh viễn';
      }
    }

    // Anniversaries count
    final anniversaries = user['anniversaries'] is List ? (user['anniversaries'] as List).length : 0;

    return Card(
      color: const Color(0xFF1A1A2E),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isBlocked
              ? Colors.redAccent.withValues(alpha: 0.5)
              : isPremium
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                  : Colors.white12,
          width: isPremium || isBlocked ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: () => _showUserManagementDialog(user),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildAvatarWithRoleFrame(
                    user: user,
                    isBlocked: isBlocked,
                    isPremium: isPremium,
                    photoUrl: photoUrl,
                    displayName: displayName,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          email.isNotEmpty ? email : (isAnonymous ? 'Tài khoản ẩn danh' : 'Người dùng'),
                          style: GoogleFonts.quicksand(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (displayName.isNotEmpty &&
                            displayName != 'Người dùng' &&
                            displayName != 'User Ẩn Danh' &&
                            displayName != 'User Ẩn danh') ...[
                          const SizedBox(height: 2),
                          Text(
                            displayName,
                            style: GoogleFonts.quicksand(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 10),
              // Hàng 1: Trạng thái Premium (50% rộng) + Bộ đếm sự kiện (50% rộng)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isPremium
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isPremium ? const Color(0xFFF59E0B).withValues(alpha: 0.6) : Colors.white12,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isPremium ? Icons.workspace_premium_rounded : Icons.person_outline_rounded,
                            color: isPremium ? const Color(0xFFF59E0B) : Colors.white54,
                            size: 15,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              premiumLabel,
                              style: GoogleFonts.quicksand(
                                color: isPremium ? const Color(0xFFF59E0B) : Colors.white60,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4), width: 0.8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.event_note_rounded, color: Color(0xFF60A5FA), size: 15),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '$anniversaries sự kiện',
                              style: GoogleFonts.quicksand(color: const Color(0xFF60A5FA), fontSize: 12, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Hàng 2: UID hiển thị riêng 1 dòng ở dưới (Bấm để sao chép)
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: uid));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã sao chép UID: $uid', style: GoogleFonts.quicksand()),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
                  child: Row(
                    children: [
                      const Icon(Icons.fingerprint_rounded, color: Colors.white38, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'UID: ',
                        style: GoogleFonts.quicksand(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      Expanded(
                        child: Text(
                          uid,
                          style: GoogleFonts.quicksand(color: Colors.white54, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.copy_rounded, color: Colors.white38, size: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserManagementDialog(Map<String, dynamic> user) {
    final uid = user['uid'] ?? '';
    final email = (user['email'] ?? '').toString();
    final displayName = (user['displayName'] ?? '').toString();
    final unlocked = List<String>.from(user['unlocked_features'] ?? []);
    final isPremium = unlocked.contains('premium');
    final isBlocked = user['is_blocked'] == true;
    final anniversaries = user['anniversaries'] is List ? (user['anniversaries'] as List) : [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A2E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                    child: Row(
                      children: [
                        Text(
                          'Chi Tiết & Quản Lý User',
                          style: GoogleFonts.quicksand(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white70),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white12),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User Header Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF14142B),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: isPremium ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6),
                                  child: Text(
                                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                                    style: GoogleFonts.quicksand(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayName.isNotEmpty ? displayName : 'User Ẩn danh',
                                        style: GoogleFonts.quicksand(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        email.isNotEmpty ? email : 'Không có Email',
                                        style: GoogleFonts.quicksand(color: Colors.white70, fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      SelectableText(
                                        'UID: $uid',
                                        style: GoogleFonts.quicksand(color: Colors.white38, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Section 0: Phân Vai Trò Quản Trị (Chỉ hiển thị cho Super Admin)
                          if (AppFirebaseService().isSuperAdmin) ...[
                            Text(
                              'Phân Vai Trò Quản Trị System',
                              style: GoogleFonts.quicksand(color: const Color(0xFFA78BFA), fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                if ((user['role'] ?? '').toString().toLowerCase() != 'admin' && (user['role'] ?? '').toString().toLowerCase() != 'super_admin')
                                  Expanded(
                                    child: _buildActionBtn('Quyền Admin', Icons.shield_rounded, const Color(0xFF10B981), () async {
                                      final navigator = Navigator.of(context);
                                      try {
                                        await AppFirebaseService().adminSetUserRole(uid, 'admin');
                                        navigator.pop();
                                        _showSnackBar('Đã cấp quyền Admin cho User!');
                                      } catch (e) {
                                        _showSnackBar('Lỗi phân quyền: $e');
                                      }
                                    }),
                                  ),
                                if ((user['role'] ?? '').toString().toLowerCase() != 'admin' && (user['role'] ?? '').toString().toLowerCase() != 'super_admin' && (user['role'] ?? '').toString().toLowerCase() != 'manager')
                                  const SizedBox(width: 8),
                                if ((user['role'] ?? '').toString().toLowerCase() != 'manager' && (user['role'] ?? '').toString().toLowerCase() != 'super_admin')
                                  Expanded(
                                    child: _buildActionBtn('Quyền Manager', Icons.badge_rounded, const Color(0xFF3B82F6), () async {
                                      final navigator = Navigator.of(context);
                                      try {
                                        await AppFirebaseService().adminSetUserRole(uid, 'manager');
                                        navigator.pop();
                                        _showSnackBar('Đã cấp quyền Manager cho User!');
                                      } catch (e) {
                                        _showSnackBar('Lỗi phân quyền: $e');
                                      }
                                    }),
                                  ),
                                if ((user['role'] ?? '').toString().toLowerCase() == 'admin' || (user['role'] ?? '').toString().toLowerCase() == 'manager')
                                  Expanded(
                                    child: _buildActionBtn('Thu Hồi Vai Trò', Icons.no_encryption_rounded, Colors.orangeAccent, () async {
                                      final navigator = Navigator.of(context);
                                      try {
                                        await AppFirebaseService().adminSetUserRole(uid, 'user');
                                        navigator.pop();
                                        _showSnackBar('Đã thu hồi vai trò về User thông thường!');
                                      } catch (e) {
                                        _showSnackBar('Lỗi thu hồi quyền: $e');
                                      }
                                    }),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Section 1: Quản lý Quyền Premium
                          Text(
                            'Quyền Cấp VIP Premium',
                            style: GoogleFonts.quicksand(color: const Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 10),
                          if (isPremium && (AppFirebaseService().isManager && !AppFirebaseService().isSuperAdmin))
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFF59E0B), width: 0.8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.workspace_premium_rounded, color: Color(0xFFF59E0B), size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Tài khoản hiện đang có VIP Premium (Chỉ được cấp 1 lần. Cấp tiếp khi hết hạn).',
                                      style: GoogleFonts.quicksand(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: _buildActionBtn('30 Ngày VIP', Icons.add_moderator_rounded, const Color(0xFF3B82F6), () async {
                                    final navigator = Navigator.of(context);
                                    final expiry = DateTime.now().add(const Duration(days: 30));
                                    await AppFirebaseService().adminSetUserPremium(uid, true, expiry);
                                    navigator.pop();
                                    _showSnackBar('Đã cấp 30 Ngày VIP Premium cho User!');
                                  }),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildActionBtn('1 Năm VIP', Icons.workspace_premium_rounded, const Color(0xFF10B981), () async {
                                    final navigator = Navigator.of(context);
                                    final expiry = DateTime.now().add(const Duration(days: 365));
                                    await AppFirebaseService().adminSetUserPremium(uid, true, expiry);
                                    navigator.pop();
                                    _showSnackBar('Đã cấp 1 Năm VIP Premium cho User!');
                                  }),
                                ),
                              ],
                            ),
                            if (!AppFirebaseService().isManager || AppFirebaseService().isSuperAdmin) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildActionBtn('VIP Vĩnh Viễn', Icons.star_rounded, const Color(0xFFF59E0B), () async {
                                      final navigator = Navigator.of(context);
                                      await AppFirebaseService().adminSetUserPremium(uid, true, null);
                                      navigator.pop();
                                      _showSnackBar('Đã cấp VIP Vĩnh Viễn cho User!');
                                    }),
                                  ),
                                  if (isPremium) ...[
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildActionBtn('Hủy Quyền VIP', Icons.remove_moderator_rounded, Colors.redAccent, () async {
                                        final navigator = Navigator.of(context);
                                        await AppFirebaseService().adminSetUserPremium(uid, false);
                                        navigator.pop();
                                        _showSnackBar('Đã hủy quyền VIP Premium của User!');
                                      }),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ],
                          const SizedBox(height: 24),

                          // Section 2: Trạng thái tài khoản (Block / Unblock) - Chỉ Admin / Super Admin mới có quyền thực hiện
                          if (!AppFirebaseService().isManager || AppFirebaseService().isSuperAdmin) ...[
                            Text(
                              'Trạng Thái Tài Khoản',
                              style: GoogleFonts.quicksand(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF14142B),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isBlocked ? Colors.redAccent : Colors.white12),
                              ),
                              child: SwitchListTile(
                                title: Text(
                                  'Khóa Tài Khoản (Block User)',
                                  style: GoogleFonts.quicksand(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  isBlocked ? 'Tài khoản đang bị khóa khỏi hệ thống' : 'Tài khoản hoạt động bình thường',
                                  style: GoogleFonts.quicksand(color: isBlocked ? Colors.redAccent : Colors.white54, fontSize: 12),
                                ),
                                value: isBlocked,
                                activeTrackColor: Colors.redAccent,
                                onChanged: (val) async {
                                  final navigator = Navigator.of(context);
                                  await AppFirebaseService().adminToggleBlockUser(uid, val);
                                  navigator.pop();
                                  _showSnackBar(val ? 'Đã khóa tài khoản thành công!' : 'Đã mở khóa tài khoản thành công!');
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Section 3: Quản lý mở khóa hiệu ứng nền
                          Text(
                            'Quản Lý Hiệu Ứng Mở Khóa',
                            style: GoogleFonts.quicksand(color: const Color(0xFFA78BFA), fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 10),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 3,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 2.5,
                            children: [
                              'hearts', 'bubbles', 'snow', 'stars', 'meteor', 'rain',
                              'rain_ripple', 'rainbow', 'waves', 'leaves', 'sunset_birds',
                              'aurora', 'fireflies', 'fireworks', 'cherry_blossom', 'galaxy'
                            ].map((effectId) {
                              final featureKey = '${effectId}_effect_unlocked';
                              final isEffectUnlocked = unlocked.contains(featureKey);
                              final effectName = _getEffectName(effectId);

                              return FilterChip(
                                label: SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    effectName,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                selected: isEffectUnlocked,
                                onSelected: (val) async {
                                  final navigator = Navigator.of(context);
                                  await AppFirebaseService().adminToggleUserFeature(uid, featureKey, val);
                                  navigator.pop();
                                  _showSnackBar(val ? 'Đã mở khóa hiệu ứng $effectName!' : 'Đã khóa hiệu ứng $effectName!');
                                },
                                selectedColor: const Color(0xFF7C3AED),
                                backgroundColor: const Color(0xFF14142B),
                                labelStyle: GoogleFonts.quicksand(
                                  color: isEffectUnlocked ? Colors.white : Colors.white54,
                                  fontWeight: isEffectUnlocked ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 11,
                                ),
                                side: BorderSide(
                                  color: isEffectUnlocked ? const Color(0xFFA78BFA) : Colors.white12,
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: EdgeInsets.zero,
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),

                          // Section 4: Danh sách sự kiện kỷ niệm đã đồng bộ
                          Text(
                            'Sự Kiện Đã Đồng Bộ (${anniversaries.length})',
                            style: GoogleFonts.quicksand(color: const Color(0xFF60A5FA), fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 10),
                          if (anniversaries.isEmpty)
                            Text('Chưa có sự kiện nào được sao lưu trên Cloud.', style: GoogleFonts.quicksand(color: Colors.white38))
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: anniversaries.length,
                              itemBuilder: (ctx, idx) {
                                final ann = Map<String, dynamic>.from(anniversaries[idx]);
                                final title = ann['title'] ?? 'Chưa đặt tên';
                                final dateStr = ann['date'] ?? '';
                                final category = ann['category'] ?? '';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF14142B),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.favorite_rounded, color: Color(0xFFEC4899), size: 18),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(title, style: GoogleFonts.quicksand(color: Colors.white, fontWeight: FontWeight.bold)),
                                            Text('$dateStr  •  $category', style: GoogleFonts.quicksand(color: Colors.white54, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label, style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.2),
        foregroundColor: color,
        side: BorderSide(color: color, width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      onPressed: onTap,
    );
  }

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.quicksand()),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }
}

  Widget _buildStatCard(String title, String count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 15),
                const SizedBox(width: 4),
                Text(count, style: GoogleFonts.quicksand(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 2),
            Text(title, style: GoogleFonts.quicksand(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

