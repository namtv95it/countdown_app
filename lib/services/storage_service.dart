import 'package:shared_preferences/shared_preferences.dart';
import '../models/anniversary.dart';

class StorageService {
  static const String _key = 'anniversaries_list_v2';
  static const String _oldKey = 'anniversaries_list';
  static const String _bubbleEffectKey = 'bubble_effect_enabled';
  static const String _premiumKey = 'is_premium_account';
  static const String _firstLaunchKey = 'is_first_launch';

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
  }
}
