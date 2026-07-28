import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ad_service.dart';

enum GoogleSignInResult { success, cancelled, error }

class StartupBannerItem {
  final String id;
  final bool isActive;
  final String imageUrl;
  final String title;
  final String actionType; // 'none' | 'gift' | 'url'
  final String? actionUrl;        // for actionType == 'url'
  final String? giftCategoryId;  // for actionType == 'gift', filter by category
  final String? occasionId;      // for actionType == 'gift', go to specific occasion

  StartupBannerItem({
    required this.id,
    required this.isActive,
    required this.imageUrl,
    required this.title,
    required this.actionType,
    this.actionUrl,
    this.giftCategoryId,
    this.occasionId,
  });

  factory StartupBannerItem.fromMap(String id, Map<String, dynamic> data) {
    return StartupBannerItem(
      id: id,
      isActive: data['isActive'] ?? false,
      imageUrl: data['imageUrl'] ?? '',
      title: data['title'] ?? '',
      actionType: data['actionType'] ?? 'none',
      actionUrl: data['actionUrl'],
      giftCategoryId: data['giftCategoryId'],
      occasionId: data['occasionId'],
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'isActive': isActive,
      'imageUrl': imageUrl,
      'title': title,
      'actionType': actionType,
      'actionUrl': actionUrl,
      'giftCategoryId': giftCategoryId,
      'occasionId': occasionId,
    };
  }
}

class StartupBanner {
  final bool isActive;
  final List<StartupBannerItem> items;

  StartupBanner({
    required this.isActive,
    required this.items,
  });

  factory StartupBanner.fromMap(Map<String, dynamic> data) {
    List<StartupBannerItem> parsedItems = [];
    if (data['items'] is List) {
      final list = data['items'] as List;
      for (int i = 0; i < list.length; i++) {
        if (list[i] is Map) {
          final itemData = Map<String, dynamic>.from(list[i]);
          // Use item id if exists, otherwise generate one from index
          final id = itemData['id']?.toString() ?? i.toString();
          parsedItems.add(StartupBannerItem.fromMap(id, itemData));
        }
      }
    }

    return StartupBanner(
      isActive: data['isActive'] ?? false,
      items: parsedItems,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isActive': isActive,
      'items': items.map((e) => e.toMap()).toList(),
    };
  }
}

class AppFirebaseService {
  static final AppFirebaseService _instance = AppFirebaseService._internal();
  factory AppFirebaseService() => _instance;
  AppFirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? _currentUser;
  bool _isInitialized = false;

  User? get currentUser => _currentUser;
  bool get isAnonymous => _currentUser?.isAnonymous ?? true;
  bool get isSignedInWithGoogle => !isAnonymous && _currentUser != null;
  String? get userEmail => _currentUser?.email;
  String? get userDisplayName => _currentUser?.displayName;
  String? get userPhotoUrl => _currentUser?.photoURL;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      // Nếu đã có session (Google hoặc anonymous), dùng lại
      final existing = _auth.currentUser;
      if (existing != null) {
        _currentUser = existing;
        _isInitialized = true;
        debugPrint('Firebase Auth: Reusing existing session uid=${existing.uid} anonymous=${existing.isAnonymous}');
        await syncPremiumStatusOnStartup();
        return;
      }
      // Chưa có session → đăng nhập ẩn danh
      UserCredential userCredential = await _auth.signInAnonymously();
      _currentUser = userCredential.user;
      _isInitialized = true;
      debugPrint('Firebase Auth: Signed in anonymously as ${_currentUser?.uid}');
      await syncPremiumStatusOnStartup();
    } catch (e) {
      debugPrint('Firebase Auth Error: $e');
    }
  }

  /// Đồng bộ trạng thái Premium và Effects từ Firebase về Local Cache
  Future<void> syncPremiumStatusOnStartup() async {
    if (_currentUser == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      bool localPremium = prefs.getBool('is_premium_account') ?? false;
      final featuresMap = await getUnlockedFeatures();
      
      final features = featuresMap.keys.toList();
      bool cloudPremium = false;
      DateTime? premiumExpiry = featuresMap['premium'];

      if (features.contains('premium')) {
        if (premiumExpiry != null && DateTime.now().isAfter(premiumExpiry)) {
          // Đã hết hạn
          await removeUnlockedFeature('premium');
        } else {
          cloudPremium = true;
        }
      }

      // Nếu trước khi đăng nhập local đã có Premium mà Cloud chưa có -> Tích hợp/Đồng bộ lên Cloud
      if (localPremium && !cloudPremium) {
        await syncUnlockedFeature('premium');
        cloudPremium = true;
      }

      bool hasPremium = cloudPremium;

      if (hasPremium) {
        await prefs.setBool('is_premium_account', true);
        if (premiumExpiry != null) {
          await prefs.setString('is_premium_account_expiry', premiumExpiry.toIso8601String());
        }
      } else {
        await prefs.remove('is_premium_account');
        await prefs.remove('is_premium_account_expiry');
      }
      AdService.isPremium = hasPremium;
      
      // 2. Đồng bộ Effects
      // Xóa các effect cũ ở local (đề phòng đổi account)
      final allKeys = prefs.getKeys();
      for (String key in allKeys) {
        if (key.endsWith('_effect_unlocked')) {
          await prefs.remove(key);
          await prefs.remove('${key}_expiry');
        }
      }
      
      // Lưu các effect mới từ Firebase
      for (String feature in features) {
        if (feature.endsWith('_effect_unlocked')) {
          final expiry = featuresMap[feature];
          if (expiry != null && DateTime.now().isAfter(expiry)) {
             await removeUnlockedFeature(feature);
          } else {
            await prefs.setBool(feature, true);
            if (expiry != null) {
              await prefs.setString('${feature}_expiry', expiry.toIso8601String());
            }
          }
        }
      }

      debugPrint('Firebase Auth: Synced status from cloud. Premium: $hasPremium, Features: $featuresMap');
    } catch (e) {
      debugPrint('Error syncing premium on startup (keeping local): $e');
    }
  }

  /// Đăng nhập Google.
  /// - Nếu đang ẩn danh → thử link credential vào UID hiện tại (giữ dữ liệu)
  /// - Nếu Google account đã tồn tại hoặc đang dùng Google khác → đăng nhập thẳng
  ///   (mỗi Google account có dữ liệu riêng, không merge)
  Future<GoogleSignInResult> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return GoogleSignInResult.cancelled;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      if (isAnonymous) {
        // Thử link anonymous → Google để giữ nguyên UID & dữ liệu
        try {
          final linked = await _currentUser!.linkWithCredential(credential);
          _currentUser = linked.user;
          debugPrint('Firebase Auth: Anonymous linked to Google uid=${_currentUser?.uid}');
          await syncPremiumStatusOnStartup();
          return GoogleSignInResult.success;
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use') {
            // Google account đã có UID riêng → đăng nhập vào đó
            // Data isolation: không migrate dữ liệu anonymous sang Google account
            await _auth.signInWithCredential(credential);
            _currentUser = _auth.currentUser;
            debugPrint('Firebase Auth: Signed into existing Google account uid=${_currentUser?.uid}');
            await syncPremiumStatusOnStartup();
            return GoogleSignInResult.success;
          }
          rethrow;
        }
      } else {
        // Đang dùng Google → đăng nhập vào Google account mới
        // Data isolation: không copy dữ liệu từ account cũ
        await _auth.signInWithCredential(credential);
        _currentUser = _auth.currentUser;
        debugPrint('Firebase Auth: Switched Google account uid=${_currentUser?.uid}');
        await syncPremiumStatusOnStartup();
        return GoogleSignInResult.success;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Google Error: [${e.code}] ${e.message}');
      return GoogleSignInResult.error;
    } catch (e, stackTrace) {
      debugPrint('Google Sign-In Exception: $e');
      debugPrint('Google Sign-In StackTrace: $stackTrace');
      return GoogleSignInResult.error;
    }
  }

  /// Đăng xuất → tạo phiên ẩn danh mới (dữ liệu sạch)
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();

      // Reset local cache khi đăng xuất
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('is_premium_account');
      await prefs.remove('is_premium_account_expiry');
      final allKeys = prefs.getKeys();
      for (String key in allKeys) {
        if (key.endsWith('_effect_unlocked')) {
          await prefs.remove(key);
          await prefs.remove('${key}_expiry');
        }
      }
      AdService.isPremium = false;

      // Tạo anonymous session mới — không có dữ liệu cũ
      final cred = await _auth.signInAnonymously();
      _currentUser = cred.user;
      debugPrint('Firebase Auth: Signed out, new anonymous uid=${_currentUser?.uid}');
      await syncPremiumStatusOnStartup();
    } catch (e) {
      debugPrint('Firebase Auth Sign-Out Error: $e');
    }
  }

  /// Kiểm tra Promo Code trên Firestore
  Future<Map<String, dynamic>?> checkPromoCode(String code) async {
    try {
      // Bỏ điều kiện is_active nếu muốn giữ logic cũ hoặc thêm tùy thích
      final querySnapshot = await _firestore
          .collection('promo_codes')
          .where('code', isEqualTo: code)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        data['_docId'] = doc.id; // Chèn docId vào data để xài lại
        return data;
      }
    } catch (e) {
      debugPrint('Error checking promo code: $e');
    }
    return null;
  }

  /// Tăng số lần sử dụng của một Promo Code
  Future<void> incrementPromoUsage(String docId) async {
    try {
      await _firestore.collection('promo_codes').doc(docId).set({
        'usedCount': FieldValue.increment(1),
      }, SetOptions(merge: true));
      debugPrint('Promo usage incremented successfully for docId: $docId');
    } catch (e) {
      debugPrint('Error incrementing promo usage ($docId): $e');
    }
  }

  /// Kiểm tra xem user đã sử dụng mã này chưa (dựa vào Firebase)
  Future<bool> isPromoCodeUsed(String code) async {
    if (_currentUser == null) return false;
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .get(const GetOptions(source: Source.server));
      if (doc.exists && doc.data() != null) {
        final usedCodes = List<String>.from(doc.data()!['used_promo_codes'] ?? []);
        return usedCodes.contains(code.toUpperCase());
      }
    } catch (e) {
      debugPrint('Error checking used promo code on Firebase: $e');
    }
    return false;
  }

  /// Đánh dấu mã đã được sử dụng bởi user này trên Firebase
  Future<void> markPromoCodeAsUsed(String code) async {
    if (_currentUser == null) return;
    try {
      await _firestore.collection('users').doc(_currentUser!.uid).set({
        'used_promo_codes': FieldValue.arrayUnion([code.toUpperCase()]),
        'last_active': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error marking promo code as used on Firebase: $e');
    }
  }

  /// Đồng bộ tính năng đã mở khóa lên Cloud cho User hiện tại
  Future<void> syncUnlockedFeature(String featureId, [DateTime? expiryDate]) async {
    if (_currentUser == null) return;
    
    try {
      Map<String, dynamic> dataToUpdate = {
        'unlocked_features': FieldValue.arrayUnion([featureId]),
        'last_active': FieldValue.serverTimestamp(),
      };
      
      if (expiryDate != null) {
        dataToUpdate['expirations.$featureId'] = Timestamp.fromDate(expiryDate);
      } else {
        dataToUpdate['expirations.$featureId'] = FieldValue.delete();
      }

      await _firestore.collection('users').doc(_currentUser!.uid).update(dataToUpdate);
    } catch (e) {
      debugPrint('Error syncing unlocked feature: $e');
    }
  }

  /// Gỡ bỏ tính năng khi đã hết hạn
  Future<void> removeUnlockedFeature(String featureId) async {
    if (_currentUser == null) return;
    
    try {
      await _firestore.collection('users').doc(_currentUser!.uid).update({
        'unlocked_features': FieldValue.arrayRemove([featureId]),
        'expirations.$featureId': FieldValue.delete(),
      });
    } catch (e) {
      debugPrint('Error removing unlocked feature: $e');
    }
  }

  /// Lấy danh sách các tính năng đã mở khóa kèm thời hạn của User từ Cloud (luôn lấy từ server)
  Future<Map<String, DateTime?>> getUnlockedFeatures() async {
    if (_currentUser == null) return {};
    
    // Cố gắng lấy trực tiếp từ server. Nếu rớt mạng sẽ throw Exception
    final doc = await _firestore.collection('users').doc(_currentUser!.uid).get(const GetOptions(source: Source.server));
    
    Map<String, DateTime?> result = {};
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      if (data.containsKey('unlocked_features')) {
        List<dynamic> features = data['unlocked_features'];
        Map<String, dynamic> expirations = {};
        if (data['expirations'] is Map) {
          expirations = Map<String, dynamic>.from(data['expirations']);
        }
        
        for (var feature in features) {
          final fStr = feature.toString();
          DateTime? expiryDate;
          if (expirations.containsKey(fStr) && expirations[fStr] is Timestamp) {
            expiryDate = (expirations[fStr] as Timestamp).toDate();
          }
          result[fStr] = expiryDate;
        }
      }
    }
    
    return result;
  }

  /// Lấy thời gian sao lưu gần nhất
  Future<DateTime?> getLastBackupTime() async {
    if (_currentUser == null) return null;
    try {
      final doc = await _firestore.collection('users').doc(_currentUser!.uid).get();
      if (doc.exists && doc.data() != null && doc.data()!['last_backup_time'] is Timestamp) {
        return (doc.data()!['last_backup_time'] as Timestamp).toDate();
      }
    } catch (e) {
      debugPrint('Error getting last backup time: $e');
    }
    return null;
  }

  /// Sao lưu mảng các ngày kỷ niệm lên Firestore (gom 1 Document duy nhất)
  Future<bool> backupAnniversariesToCloud(List<Map<String, dynamic>> dataList) async {
    if (_currentUser == null) return false;
    try {
      final now = DateTime.now();
      await _firestore.collection('users').doc(_currentUser!.uid).set({
        'anniversaries': dataList,
        'last_backup_time': Timestamp.fromDate(now),
        'last_active': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('Error backing up anniversaries to cloud: $e');
      return false;
    }
  }

  /// Khôi phục mảng ngày kỷ niệm từ Firestore
  Future<Map<String, dynamic>?> restoreAnniversariesFromCloud() async {
    if (_currentUser == null) return null;
    try {
      final doc = await _firestore.collection('users').doc(_currentUser!.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final list = data['anniversaries'];
        DateTime? lastBackup;
        if (data['last_backup_time'] is Timestamp) {
          lastBackup = (data['last_backup_time'] as Timestamp).toDate();
        }
        if (list is List) {
          final List<Map<String, dynamic>> parsedList = list
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
          return {
            'anniversaries': parsedList,
            'last_backup_time': lastBackup,
          };
        }
      }
    } catch (e) {
      debugPrint('Error restoring anniversaries from cloud: $e');
      rethrow;
    }
    return null;
  }

  /// Lấy cấu hình Startup Banner từ Cloud
  Future<StartupBanner?> getStartupBanner() async {
    try {
      final doc = await _firestore.collection('settings').doc('startup_banner').get();
      if (doc.exists && doc.data() != null) {
        return StartupBanner.fromMap(doc.data()!);
      }
    } catch (e) {
      debugPrint('Error fetching startup banner: $e');
    }
    return null;
  }
}
