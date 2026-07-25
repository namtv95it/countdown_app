import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event_category.dart';
import '../models/gift_product.dart';
import '../models/special_occasion.dart';
import '../services/app_firebase_service.dart';

/// SyncService – Trung tâm điều phối dữ liệu theo chiến lược 2 lớp:
///
/// 1. Phát dữ liệu từ Cache (SharedPreferences) nếu có
/// 2. Ngầm gọi Firebase, nếu thành công → lưu Cache + cập nhật UI
/// 3. Nếu không có Cache và mạng lỗi → Báo lỗi 'no_internet' để UI xử lý
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  static const _giftsKey = 'cache_gifts_v1';
  static const _occasionsKey = 'cache_occasions_v1';
  static const _bannerKey = 'cache_banner_v1';
  static const _categoriesKey = 'cache_categories_v1';
  static const _giftsVersionKey = 'cache_gifts_version';
  static const _occasionsVersionKey = 'cache_occasions_version';
  static const _bannerVersionKey = 'cache_banner_version';
  static const _categoriesVersionKey = 'cache_categories_version';

  Future<int> _fetchRemoteDataVersion() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('data_version')
          .get(const GetOptions(source: Source.server));
      if (doc.exists && doc.data() != null) {
        return doc.data()!['version'] as int? ?? 1;
      }
    } catch (e) {
      debugPrint('[SyncService] Failed to fetch data_version: $e');
    }
    return 1;
  }

  // ─────────────────────────────────────────────────────────────────
  // GIFTS
  // ─────────────────────────────────────────────────────────────────

  /// Stream 2 lớp cho Danh sách Quà tặng
  Stream<List<GiftProduct>> giftsStream() async* {
    final prefs = await SharedPreferences.getInstance();

    // Lớp 1: Đọc Cache
    final cached = _loadGiftsFromPrefs(prefs);
    if (cached.isNotEmpty) {
      yield cached;
    }

    // Lớp 2: Kiểm tra phiên bản dữ liệu
    final localVersion = prefs.getInt(_giftsVersionKey) ?? 0;
    final remoteVersion = await _fetchRemoteDataVersion();

    if (cached.isNotEmpty && localVersion >= remoteVersion) {
      debugPrint('[SyncService] Gifts cache is up to date (v$localVersion), skipping Firebase.');
      return;
    }

    // Lớp 2: Gọi Firebase ở nền
    try {
      final snap = await FirebaseFirestore.instance
          .collection('gifts')
          .orderBy('order')
          .get(const GetOptions(source: Source.server));

      final fresh = snap.docs
          .map((d) => GiftProduct.fromFirestore(d.id, d.data()))
          .toList();

      if (fresh.isNotEmpty) {
        await _saveGiftsToPrefs(prefs, fresh, remoteVersion);
        yield fresh;
        debugPrint('[SyncService] Gifts updated from Firebase (${fresh.length} items to v$remoteVersion).');
      }
    } catch (e) {
      debugPrint('[SyncService] Gifts fetch error (offline?): $e');
      // Nếu không có cache và không có mạng -> Báo lỗi
      if (cached.isEmpty) {
        yield* Stream.error('no_internet');
      }
    }
  }

  List<GiftProduct> _loadGiftsFromPrefs(SharedPreferences prefs) {
    try {
      final raw = prefs.getString(_giftsKey);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => GiftProduct.fromFirestore(
              e['id'] as String, Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveGiftsToPrefs(
      SharedPreferences prefs, List<GiftProduct> gifts, int version) async {
    final list = gifts.map((g) => g.toFirestore()..['id'] = g.id).toList();
    await prefs.setString(_giftsKey, jsonEncode(list));
    await prefs.setInt(_giftsVersionKey, version);
  }

  // ─────────────────────────────────────────────────────────────────
  // SPECIAL OCCASIONS
  // ─────────────────────────────────────────────────────────────────

  /// Stream 2 lớp cho Danh sách Sự kiện đặc biệt
  Stream<List<SpecialOccasion>> occasionsStream() async* {
    final prefs = await SharedPreferences.getInstance();

    // Lớp 1: Cache
    final cached = _loadOccasionsFromPrefs(prefs);
    if (cached.isNotEmpty) {
      yield cached;
    }

    // Kiểm tra phiên bản dữ liệu
    final localVersion = prefs.getInt(_occasionsVersionKey) ?? 0;
    final remoteVersion = await _fetchRemoteDataVersion();

    if (cached.isNotEmpty && localVersion >= remoteVersion) {
      debugPrint('[SyncService] Occasions cache is up to date (v$localVersion), skipping Firebase.');
      return;
    }

    // Lớp 2: Firebase
    try {
      final snap = await FirebaseFirestore.instance
          .collection('special_occasions')
          .get(const GetOptions(source: Source.server));

      final fresh = snap.docs
          .map((d) => SpecialOccasion.fromFirestore(d.id, d.data()))
          .toList()
        ..sort((a, b) {
          if (a.month != b.month) return a.month.compareTo(b.month);
          return a.day.compareTo(b.day);
        });

      if (fresh.isNotEmpty) {
        await _saveOccasionsToPrefs(prefs, fresh, remoteVersion);
        yield fresh;
        debugPrint('[SyncService] Occasions updated from Firebase (${fresh.length} items to v$remoteVersion).');
      }
    } catch (e) {
      debugPrint('[SyncService] Occasions fetch error (offline?): $e');
      if (cached.isEmpty) {
        yield* Stream.error('no_internet');
      }
    }
  }

  List<SpecialOccasion> _loadOccasionsFromPrefs(SharedPreferences prefs) {
    try {
      final raw = prefs.getString(_occasionsKey);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) =>
              SpecialOccasion.fromFirestore(
                  e['id'] as String, Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveOccasionsToPrefs(
      SharedPreferences prefs, List<SpecialOccasion> occasions, int version) async {
    final list = occasions
        .map((o) => o.toFirestore()..['id'] = o.id)
        .toList();
    await prefs.setString(_occasionsKey, jsonEncode(list));
    await prefs.setInt(_occasionsVersionKey, version);
  }

  // ─────────────────────────────────────────────────────────────────
  // STARTUP BANNER
  // ─────────────────────────────────────────────────────────────────

  /// Stream 2 lớp cho Startup Banner
  Stream<StartupBanner?> bannerStream() async* {
    final prefs = await SharedPreferences.getInstance();

    // Lớp 1: Cache
    final cached = _loadBannerFromPrefs(prefs);
    if (cached != null) {
      yield cached;
    }

    // Kiểm tra phiên bản dữ liệu
    final localVersion = prefs.getInt(_bannerVersionKey) ?? 0;
    final remoteVersion = await _fetchRemoteDataVersion();

    if (cached != null && localVersion >= remoteVersion) {
      debugPrint('[SyncService] Banner cache is up to date (v$localVersion), skipping Firebase.');
      return;
    }

    // Lớp 2: Firebase
    try {
      final snap = await FirebaseFirestore.instance
          .collection('settings')
          .doc('startup_banner')
          .get(const GetOptions(source: Source.server));

      if (snap.exists && snap.data() != null) {
        final fresh = StartupBanner.fromMap(snap.data()!);
        await _saveBannerToPrefs(prefs, fresh, remoteVersion);
        yield fresh;
        debugPrint('[SyncService] Banner updated from Firebase (to v$remoteVersion).');
      } else {
        yield null;
      }
    } catch (e) {
      debugPrint('[SyncService] Banner fetch error: $e');
      if (cached == null) {
        yield* Stream.error('no_internet');
      }
    }
  }

  StartupBanner? _loadBannerFromPrefs(SharedPreferences prefs) {
    try {
      final raw = prefs.getString(_bannerKey);
      if (raw == null) return null;
      return StartupBanner.fromMap(
          Map<String, dynamic>.from(jsonDecode(raw)));
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveBannerToPrefs(
      SharedPreferences prefs, StartupBanner banner, int version) async {
    await prefs.setString(_bannerKey, jsonEncode(banner.toMap()));
    await prefs.setInt(_bannerVersionKey, version);
  }

  // ─────────────────────────────────────────────────────────────────
  // CATEGORIES
  // ─────────────────────────────────────────────────────────────────

  /// Stream cho Danh mục Quà tặng (gift_categories collection)
  Stream<List<EventCategory>> categoriesStream() async* {
    final prefs = await SharedPreferences.getInstance();

    // Lớp 1: Cache local
    final cached = _loadCategoriesFromPrefs(prefs);
    if (cached.isNotEmpty) {
      yield cached;
    } else {
      // Fallback ngay lập tức với danh sách mặc định
      yield EventCategory.defaultCategories;
    }

    // Lớp 2: Kiểm tra phiên bản
    final localVersion = prefs.getInt(_categoriesVersionKey) ?? 0;
    int remoteVersion;
    try {
      remoteVersion = await _fetchRemoteDataVersion();
    } catch (_) {
      return; // offline, dùng cache/default
    }

    if (cached.isNotEmpty && localVersion >= remoteVersion) {
      debugPrint('[SyncService] Categories cache up to date (v$localVersion).');
      return;
    }

    // Lớp 3: Gọi Firebase
    try {
      final snap = await FirebaseFirestore.instance
          .collection('gift_categories')
          .orderBy('order')
          .get(const GetOptions(source: Source.server));

      final fresh = snap.docs
          .map((d) => EventCategory.fromJson({'id': d.id, ...d.data()}))
          .toList();

      if (fresh.isNotEmpty) {
        await _saveCategoriesToPrefs(prefs, fresh, remoteVersion);
        yield fresh;
        debugPrint('[SyncService] Categories updated from Firebase (${fresh.length} items, v$remoteVersion).');
      }
    } catch (e) {
      debugPrint('[SyncService] Categories fetch error (offline?): $e');
      // giữ cache/default hiện tại, không throw
    }
  }

  /// Seed dữ liệu mặc định lên Firebase (chỉ chạy một lần khi chưa có dữ liệu)
  Future<String> seedDefaultCategories() async {
    try {
      final col = FirebaseFirestore.instance.collection('gift_categories');
      final existing = await col.limit(1).get();
      if (existing.docs.isNotEmpty) {
        return 'already_seeded';
      }
      final batch = FirebaseFirestore.instance.batch();
      for (final cat in EventCategory.defaultCategories) {
        if (cat.id == 'other') continue; // bỏ 'other' khỏi seed
        final ref = col.doc(cat.id);
        batch.set(ref, cat.toJson());
      }
      await batch.commit();
      debugPrint('[SyncService] Seeded ${EventCategory.defaultCategories.length - 1} categories to Firebase.');
      return 'success';
    } catch (e) {
      debugPrint('[SyncService] Seed error: $e');
      return 'error: $e';
    }
  }

  List<EventCategory> _loadCategoriesFromPrefs(SharedPreferences prefs) {
    try {
      final raw = prefs.getString(_categoriesKey);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => EventCategory.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveCategoriesToPrefs(
      SharedPreferences prefs, List<EventCategory> categories, int version) async {
    final list = categories.map((c) => c.toJson()).toList();
    await prefs.setString(_categoriesKey, jsonEncode(list));
    await prefs.setInt(_categoriesVersionKey, version);
  }

  // ─────────────────────────────────────────────────────────────────
  // UTILITIES
  // ─────────────────────────────────────────────────────────────────

  /// Xóa toàn bộ cache (dùng khi force-refresh)
  Future<void> clearAllCaches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_giftsKey);
    await prefs.remove(_occasionsKey);
    await prefs.remove(_bannerKey);
    await prefs.remove(_categoriesKey);
    await prefs.remove(_giftsVersionKey);
    await prefs.remove(_occasionsVersionKey);
    await prefs.remove(_bannerVersionKey);
    await prefs.remove(_categoriesVersionKey);
    debugPrint('[SyncService] All caches cleared.');
  }
}
