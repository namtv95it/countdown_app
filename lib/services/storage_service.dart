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
    return prefs.getBool(_premiumKey) ?? false;
  }

  Future<void> setPremium(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, value);

    if (value) {
      // Đồng bộ lên Firebase
      try {
        if (AppFirebaseService().currentUser != null) {
          await AppFirebaseService().syncUnlockedFeature('premium');
        }
      } catch (e) {
        // Bỏ qua lỗi
      }
    }
  }

  Future<bool> getIsTestModeUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('test_mode_unlocked') ?? false;
  }

  Future<void> setTestModeUnlocked(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('test_mode_unlocked', value);
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
    return prefs.getBool(featureKey) ?? false;
  }

  Future<void> unlockFeature(String featureKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(featureKey, true);

    // Đồng bộ lên Firebase (nếu đã init)
    try {
      if (AppFirebaseService().currentUser != null) {
        await AppFirebaseService().syncUnlockedFeature(featureKey);
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
