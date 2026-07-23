import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AppFirebaseService {
  static final AppFirebaseService _instance = AppFirebaseService._internal();
  factory AppFirebaseService() => _instance;
  AppFirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _currentUser;
  bool _isInitialized = false;

  User? get currentUser => _currentUser;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      // Đăng nhập ẩn danh tự động nếu chưa có tài khoản
      UserCredential userCredential = await _auth.signInAnonymously();
      _currentUser = userCredential.user;
      _isInitialized = true;
      debugPrint('Firebase Auth: Signed in anonymously as ${_currentUser?.uid}');
    } catch (e) {
      debugPrint('Firebase Auth Error: $e');
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

  /// Lấy danh sách các tính năng đã mở khóa của User từ Cloud
  Future<List<String>> getUnlockedFeatures() async {
    if (_currentUser == null) return [];
    
    try {
      final doc = await _firestore.collection('users').doc(_currentUser!.uid).get();
      if (doc.exists && doc.data()!.containsKey('unlocked_features')) {
        List<dynamic> features = doc.data()!['unlocked_features'];
        return features.map((e) => e.toString()).toList();
      }
    } catch (e) {
      debugPrint('Error getting unlocked features: $e');
    }
    return [];
  }
}
