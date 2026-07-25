import 'package:shared_preferences/shared_preferences.dart';
import 'package:countdown_app/services/app_firebase_service.dart';
import '../models/anniversary.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _key = 'anniversaries_list_v2';
  static const String _oldKey = 'anniversaries_list';
  static const String _bubbleEffectKey = 'bubble_effect_enabled';
  static const String _premiumKey = 'is_premium_account';
  static const String _firstLaunchKey = 'is_first_launch';
  static const String _tutorialShownKey = 'is_tutorial_shown';
  static const String _musicEnabledKey = 'is_music_enabled';
  static const String _selectedMusicIdKey = 'selected_music_id';
  static const String _customMusicPathKey = 'custom_music_path';

  Future<String> getSelectedMusicId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedMusicIdKey) ?? 'none';
  }

  Future<void> setSelectedMusicId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedMusicIdKey, id);
  }

  Future<String?> getCustomMusicPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_customMusicPathKey);
  }

  Future<void> setCustomMusicPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customMusicPathKey, path);
  }

  Future<bool> getIsMusicEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_musicEnabledKey) ?? true;
  }

  Future<void> setMusicEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_musicEnabledKey, value);
  }

  Future<bool> getIsTutorialShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tutorialShownKey) ?? false;
  }

  Future<void> setTutorialShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialShownKey, true);
  }

  Future<bool> getIsFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstLaunchKey) ?? true;
  }

  Future<void> setFirstLaunchCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLaunchKey, false);
  }

  Future<bool> getIsPremium() async {
    final prefs = await SharedPreferences.getInstance();
    final isPremium = prefs.getBool(_premiumKey) ?? false;
    if (isPremium) {
      final expiryStr = prefs.getString('${_premiumKey}_expiry');
      if (expiryStr != null) {
        final expiry = DateTime.tryParse(expiryStr);
        if (expiry != null && DateTime.now().isAfter(expiry)) {
          // Hết hạn -> hủy
          await prefs.remove(_premiumKey);
          await prefs.remove('${_premiumKey}_expiry');
          try {
            await AppFirebaseService().removeUnlockedFeature('premium');
          } catch (_) {}
          return false;
        }
      }
    }
    return isPremium;
  }

  Future<void> setPremium(bool value, [DateTime? expiry]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, value);
    if (expiry != null) {
      await prefs.setString('${_premiumKey}_expiry', expiry.toIso8601String());
    } else {
      await prefs.remove('${_premiumKey}_expiry');
    }

    if (value) {
      // Đồng bộ lên Firebase
      try {
        if (AppFirebaseService().currentUser != null) {
          await AppFirebaseService().syncUnlockedFeature('premium', expiry);
        }
      } catch (e) {
        // Bỏ qua lỗi
      }
    }
  }

  // --- SESSION-ONLY FLAGS (reset khi tắt app) ---
  static bool _sessionTestModeUnlocked = false;
  static bool _sessionAdminUnlocked = false;

  bool getIsTestModeUnlocked() => _sessionTestModeUnlocked;
  Future<void> setTestModeUnlocked(bool value) async {
    _sessionTestModeUnlocked = value;
  }

  bool getIsAdminUnlocked() => _sessionAdminUnlocked;
  Future<void> setIsAdminUnlocked(bool value) async {
    _sessionAdminUnlocked = value;
  }


  Future<List<Anniversary>> getAnniversaries() async {
    final prefs = await SharedPreferences.getInstance();

    // Migrate: xóa key cũ nếu còn tồn tại
    if (prefs.containsKey(_oldKey)) {
      await prefs.remove(_oldKey);
    }

    final List<String>? data = prefs.getStringList(_key);
    if (data == null) return [];

    return data.map((item) => Anniversary.fromJson(item)).toList();
  }

  Future<void> saveAnniversaries(List<Anniversary> anniversaries) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> data =
        anniversaries.map((item) => item.toJson()).toList();
    await prefs.setStringList(_key, data);
  }

  Future<void> deleteAnniversary(String id) async {
    final list = await getAnniversaries();
    list.removeWhere((a) => a.id == id);
    await saveAnniversaries(list);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static const String _effectKey = 'selected_effect_id';

  Future<String> getSelectedEffect() async {
    final prefs = await SharedPreferences.getInstance();
    // Default fallback logic for old users
    if (prefs.containsKey(_bubbleEffectKey)) {
      bool oldBubble = prefs.getBool(_bubbleEffectKey) ?? false;
      if (oldBubble) {
        prefs.remove(_bubbleEffectKey);
        await setSelectedEffect('bubbles');
        return 'bubbles';
      }
    }
    return prefs.getString(_effectKey) ?? 'none';
  }

  Future<void> setSelectedEffect(String effect) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_effectKey, effect);
  }

  Future<bool> isFeatureUnlocked(String featureKey) async {
    final prefs = await SharedPreferences.getInstance();
    final isUnlocked = prefs.getBool(featureKey) ?? false;
    if (isUnlocked) {
      final expiryStr = prefs.getString('${featureKey}_expiry');
      if (expiryStr != null) {
        final expiry = DateTime.tryParse(expiryStr);
        if (expiry != null && DateTime.now().isAfter(expiry)) {
          // Hết hạn -> hủy
          await prefs.remove(featureKey);
          await prefs.remove('${featureKey}_expiry');
          try {
            await AppFirebaseService().removeUnlockedFeature(featureKey);
          } catch (_) {}
          return false;
        }
      }
    }
    return isUnlocked;
  }

  Future<void> unlockFeature(String featureKey, [DateTime? expiry]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(featureKey, true);
    if (expiry != null) {
      await prefs.setString('${featureKey}_expiry', expiry.toIso8601String());
    } else {
      await prefs.remove('${featureKey}_expiry');
    }

    // Đồng bộ lên Firebase (nếu đã init)
    try {
      if (AppFirebaseService().currentUser != null) {
        await AppFirebaseService().syncUnlockedFeature(featureKey, expiry);
      }
    } catch (e) {
      // Bỏ qua lỗi nếu chưa setup Firebase
    }
  }

  Future<bool> isPromoCodeUsed(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final usedCodes = prefs.getStringList('used_promo_codes') ?? [];
    return usedCodes.contains(code.toUpperCase());
  }

  Future<void> markPromoCodeAsUsed(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final usedCodes = prefs.getStringList('used_promo_codes') ?? [];
    if (!usedCodes.contains(code.toUpperCase())) {
      usedCodes.add(code.toUpperCase());
      await prefs.setStringList('used_promo_codes', usedCodes);
    }
  }

  // --- ANTI SPAM PROMO CODE ---
  Future<int> getFailedPromoAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('promo_failed_attempts') ?? 0;
  }

  Future<void> setFailedPromoAttempts(int attempts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('promo_failed_attempts', attempts);
  }

  Future<DateTime?> getPromoLockUntil() async {
    final prefs = await SharedPreferences.getInstance();
    final lockStr = prefs.getString('promo_lock_until');
    if (lockStr == null) return null;
    return DateTime.tryParse(lockStr);
  }

  Future<void> setPromoLockUntil(DateTime? time) async {
    final prefs = await SharedPreferences.getInstance();
    if (time == null) {
      await prefs.remove('promo_lock_until');
    } else {
      await prefs.setString('promo_lock_until', time.toIso8601String());
    }
  }
}
