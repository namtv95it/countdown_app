import 'package:shared_preferences/shared_preferences.dart';
import '../models/anniversary.dart';
import 'widget_service.dart';

class StorageService {
  static const String _key = 'anniversaries_list_v2';
  static const String _oldKey = 'anniversaries_list';

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
    
    // Update home widget whenever data is saved
    try {
      await WidgetService.updateWidgetWithClosestEvent(anniversaries);
    } catch (e) {
      print('Failed to update widget: $e');
    }
  }

  Future<void> deleteAnniversary(String id) async {
    final list = await getAnniversaries();
    list.removeWhere((a) => a.id == id);
    await saveAnniversaries(list);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    try {
      await WidgetService.updateWidgetWithClosestEvent([]);
    } catch (e) {
      print('Failed to update widget: $e');
    }
  }
}
