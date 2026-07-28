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
  String _filterType = 'all'; // 'all', 'premium', 'free', 'blocked'

  @override
  void dispose() {
    _searchController.dispose();
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
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: AppFirebaseService().getUsersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final errStr = snapshot.error.toString();
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
                      isPermissionDenied ? 'Chưa Cấu Hình Quyền Firestore (Rules)' : 'Lỗi Tải Dữ Liệu',
                      style: GoogleFonts.quicksand(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isPermissionDenied
                          ? 'Firebase đang chặn quyền đọc danh sách user trong collection "users". Bạn cần cập nhật Firestore Rules trên Firebase Console.'
                          : 'Chi tiết lỗi: $errStr',
                      style: GoogleFonts.quicksand(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    if (isPermissionDenied) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: Text('Sao Chép Rules Chuẩn', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          const rulesText = '''rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Tự động kiểm tra quyền Quản trị (Super Admin / Admin / Manager) từ trường 'role'
    function isAdmin() {
      return request.auth != null && 
        (get(/databases/\$(database)/documents/users/\$(request.auth.uid)).data.role in ['super_admin', 'admin', 'manager'] ||
         get(/databases/\$(database)/documents/users/\$(request.auth.uid)).data.is_admin == true);
    }

    match /config/{document} {
      allow read: if true;
      allow write: if isAdmin();
    }
    
    match /gifts/{document} {
      allow read: if true;
      allow write: if isAdmin();
    }
    match /gift_categories/{document} {
      allow read: if true;
      allow write: if isAdmin();
    }
    match /special_occasions/{document} {
      allow read: if true;
      allow write: if isAdmin();
    }
    match /settings/{document} {
      allow read: if true;
      allow write: if isAdmin();
    }

    match /promo_codes/{document} {
      allow read: if true;
      allow write: if isAdmin();
      allow update: if request.resource.data.diff(resource.data).affectedKeys().hasOnly(['usedCount']);
    }
    
    // User tự quản lý dữ liệu cá nhân, Admin có toàn quyền quản lý
    match /users/{userId} {
      allow read, write: if (request.auth != null && request.auth.uid == userId) || isAdmin();
    }
  }
}''';
                          Clipboard.setData(const ClipboardData(text: rulesText));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đã sao chép Rules! Hãy dán vào Firebase Console ➔ Firestore Database ➔ Rules.', style: GoogleFonts.quicksand()),
                              backgroundColor: const Color(0xFF10B981),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          final allUsers = snapshot.data ?? [];

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
            if (isBlocked) blockedUsers++;
            if (unlocked.contains('premium')) premiumUsers++;
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

            // Manager chỉ có thể xem được người dùng đã đăng nhập (ẩn người dùng ẩn danh)
            if (AppFirebaseService().isManager && !AppFirebaseService().isSuperAdmin && isAnon) {
              return false;
            }

            if (_filterType == 'google') return !isAnon;
            if (_filterType == 'anonymous') return isAnon;
            if (_filterType == 'premium') return isPremium;
            if (_filterType == 'free') return !isPremium && !u.containsKey('is_premium_account');
            if (_filterType == 'blocked') return isBlocked;
            return true;
          }).toList();

          return Column(
            children: [
              // 1. Stat Cards Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    _buildStatCard('Tổng User', '$totalUsers', const Color(0xFF3B82F6), Icons.people_alt_rounded),
                    const SizedBox(width: 8),
                    _buildStatCard('VIP Premium', '$premiumUsers', const Color(0xFFF59E0B), Icons.workspace_premium_rounded),
                    const SizedBox(width: 8),
                    _buildStatCard('Miễn Phí', '$freeUsers', const Color(0xFF10B981), Icons.person_outline_rounded),
                  ],
                ),
              ),

              // 2. Search Box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: GoogleFonts.quicksand(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo Name, Email hoặc UID...',
                    hintStyle: GoogleFonts.quicksand(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: Colors.white54),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF1A1A2E),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                    ),
                  ),
                ),
              ),

              // 3. Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    _buildFilterChip(isManagerOnly ? 'Tất cả ($googleUsers)' : 'Tất cả ($totalUsers)', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Google ($googleUsers)', 'google'),
                    if (!isManagerOnly) ...[
                      const SizedBox(width: 8),
                      _buildFilterChip('Ẩn danh ($anonymousUsers)', 'anonymous'),
                    ],
                    const SizedBox(width: 8),
                    _buildFilterChip('Premium ($premiumUsers)', 'premium'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Miễn phí ($freeUsers)', 'free'),
                    if (blockedUsers > 0 && !isManagerOnly) ...[
                      const SizedBox(width: 8),
                      _buildFilterChip('Đã khóa ($blockedUsers)', 'blocked'),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 4. User List
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
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          return _buildUserTile(user);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Text(
                  count,
                  style: GoogleFonts.quicksand(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.quicksand(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterType == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _filterType = value),
      selectedColor: const Color(0xFF3B82F6),
      backgroundColor: const Color(0xFF1A1A2E),
      labelStyle: GoogleFonts.quicksand(
        color: isSelected ? Colors.white : Colors.white60,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFF3B82F6) : Colors.white12,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if ((user['role'] ?? '').toString().toLowerCase() != 'admin' && (user['role'] ?? '').toString().toLowerCase() != 'super_admin')
                                  _buildActionBtn('Cấp Quyền Admin', Icons.shield_rounded, const Color(0xFF10B981), () async {
                                    final navigator = Navigator.of(context);
                                    try {
                                      await AppFirebaseService().adminSetUserRole(uid, 'admin');
                                      navigator.pop();
                                      _showSnackBar('Đã cấp quyền Admin cho User!');
                                    } catch (e) {
                                      _showSnackBar('Lỗi phân quyền: $e');
                                    }
                                  }),
                                if ((user['role'] ?? '').toString().toLowerCase() != 'manager' && (user['role'] ?? '').toString().toLowerCase() != 'super_admin')
                                  _buildActionBtn('Cấp Quyền Manager', Icons.badge_rounded, const Color(0xFF3B82F6), () async {
                                    final navigator = Navigator.of(context);
                                    try {
                                      await AppFirebaseService().adminSetUserRole(uid, 'manager');
                                      navigator.pop();
                                      _showSnackBar('Đã cấp quyền Manager cho User!');
                                    } catch (e) {
                                      _showSnackBar('Lỗi phân quyền: $e');
                                    }
                                  }),
                                if ((user['role'] ?? '').toString().toLowerCase() == 'admin' || (user['role'] ?? '').toString().toLowerCase() == 'manager')
                                  _buildActionBtn('Thu Hồi Vai Trò (Về User)', Icons.no_encryption_rounded, Colors.orangeAccent, () async {
                                    final navigator = Navigator.of(context);
                                    try {
                                      await AppFirebaseService().adminSetUserRole(uid, 'user');
                                      navigator.pop();
                                      _showSnackBar('Đã thu hồi vai trò về User thông thường!');
                                    } catch (e) {
                                      _showSnackBar('Lỗi thu hồi quyền: $e');
                                    }
                                  }),
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
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (!isPremium || (!AppFirebaseService().isManager || AppFirebaseService().isSuperAdmin))
                                  _buildActionBtn('Cấp 30 Ngày VIP', Icons.add_moderator_rounded, const Color(0xFF3B82F6), () async {
                                    final navigator = Navigator.of(context);
                                    final expiry = DateTime.now().add(const Duration(days: 30));
                                    await AppFirebaseService().adminSetUserPremium(uid, true, expiry);
                                    navigator.pop();
                                    _showSnackBar('Đã cấp 30 Ngày VIP Premium cho User!');
                                  }),
                                if (!AppFirebaseService().isManager || AppFirebaseService().isSuperAdmin) ...[
                                  _buildActionBtn('Cấp 1 Năm VIP', Icons.workspace_premium_rounded, const Color(0xFF10B981), () async {
                                    final navigator = Navigator.of(context);
                                    final expiry = DateTime.now().add(const Duration(days: 365));
                                    await AppFirebaseService().adminSetUserPremium(uid, true, expiry);
                                    navigator.pop();
                                    _showSnackBar('Đã cấp 1 Năm VIP Premium cho User!');
                                  }),
                                  _buildActionBtn('Cấp VIP Vĩnh Viễn', Icons.star_rounded, const Color(0xFFF59E0B), () async {
                                    final navigator = Navigator.of(context);
                                    await AppFirebaseService().adminSetUserPremium(uid, true, null);
                                    navigator.pop();
                                    _showSnackBar('Đã cấp VIP Vĩnh Viễn cho User!');
                                  }),
                                  if (isPremium)
                                    _buildActionBtn('Hủy Quyền VIP', Icons.remove_moderator_rounded, Colors.redAccent, () async {
                                      final navigator = Navigator.of(context);
                                      await AppFirebaseService().adminSetUserPremium(uid, false);
                                      navigator.pop();
                                      _showSnackBar('Đã hủy quyền VIP Premium của User!');
                                    }),
                                ],
                              ],
                            ),
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
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              'hearts', 'bubbles', 'snow', 'stars', 'meteor', 'rain',
                              'rain_ripple', 'rainbow', 'waves', 'leaves', 'sunset_birds',
                              'aurora', 'fireflies', 'fireworks', 'cherry_blossom', 'galaxy'
                            ].map((effectId) {
                              final featureKey = '${effectId}_effect_unlocked';
                              final isEffectUnlocked = unlocked.contains(featureKey);
                              final effectName = _getEffectName(effectId);

                              return FilterChip(
                                label: Text(effectName),
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
                                ),
                                side: BorderSide(
                                  color: isEffectUnlocked ? const Color(0xFFA78BFA) : Colors.white12,
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
