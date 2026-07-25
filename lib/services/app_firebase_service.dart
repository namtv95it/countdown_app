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
      final features = await getUnlockedFeatures();
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Đồng bộ Premium
      final hasPremium = features.contains('premium');
      await prefs.setBool('is_premium_account', hasPremium);
      AdService.isPremium = hasPremium;
      
      // 2. Đồng bộ Effects
      // Xóa các effect cũ ở local (đề phòng đổi account)
      final allKeys = prefs.getKeys();
      for (String key in allKeys) {
        if (key.endsWith('_effect_unlocked')) {
          await prefs.remove(key);
        }
      }
      
      // Lưu các effect mới từ Firebase
      for (String feature in features) {
        if (feature.endsWith('_effect_unlocked')) {
          await prefs.setBool(feature, true);
        }
      }

      debugPrint('Firebase Auth: Synced status from cloud. Premium: $hasPremium, Features: $features');
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
      debugPrint('Firebase Auth Google Error: ${e.code} - ${e.message}');
      return GoogleSignInResult.error;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      return GoogleSignInResult.error;
    }
  }

  /// Đăng xuất → tạo phiên ẩn danh mới (dữ liệu sạch)
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
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
    } catch (e) {
      debugPrint('Error incrementing promo usage: $e');
    }
  }

  /// Đồng bộ tính năng đã mở khóa lên Cloud cho User hiện tại
  Future<void> syncUnlockedFeature(String featureId) async {
    if (_currentUser == null) return;
    
    try {
      await _firestore.collection('users').doc(_currentUser!.uid).set({
        'unlocked_features': FieldValue.arrayUnion([featureId]),
        'last_active': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error syncing unlocked feature: $e');
    }
  }

  /// Lấy danh sách các tính năng đã mở khóa của User từ Cloud (luôn lấy từ server)
  Future<List<String>> getUnlockedFeatures() async {
    if (_currentUser == null) return [];
    
    // Cố gắng lấy trực tiếp từ server. Nếu rớt mạng sẽ throw Exception
    final doc = await _firestore.collection('users').doc(_currentUser!.uid).get(const GetOptions(source: Source.server));
    
    if (doc.exists && doc.data() != null && doc.data()!.containsKey('unlocked_features')) {
      List<dynamic> features = doc.data()!['unlocked_features'];
      return features.map((e) => e.toString()).toList();
    }
    
    return [];
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
