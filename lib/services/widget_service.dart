import 'package:home_widget/home_widget.dart';
import '../models/anniversary.dart';

class WidgetService {
  static const String appGroupId = 'group.countdown_app'; // Thường dùng cho iOS, nhưng khai báo luôn
  static const String androidWidgetName = 'CountdownWidgetProvider';

  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId(appGroupId);
  }

  static Future<bool> requestPinWidget() async {
    try {
      await HomeWidget.requestPinWidget(name: androidWidgetName);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> updateWidgetWithClosestEvent(List<Anniversary> anniversaries) async {
    if (anniversaries.isEmpty) {
      await HomeWidget.saveWidgetData<String>('widget_title', 'Chưa có sự kiện');
      await HomeWidget.saveWidgetData<String>('widget_countdown', 'Mở app để thêm');
      await HomeWidget.updateWidget(name: androidWidgetName);
      return;
    }

    // Tìm sự kiện gần nhất (chưa diễn ra hoặc đang diễn ra)
    final upcomingEvents = anniversaries.where((e) => e.daysRemaining >= 0).toList();
    upcomingEvents.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));

    if (upcomingEvents.isEmpty) {
      await HomeWidget.saveWidgetData<String>('widget_title', 'Không có sự kiện sắp tới');
      await HomeWidget.saveWidgetData<String>('widget_countdown', '--');
    } else {
      final closest = upcomingEvents.first;
      await HomeWidget.saveWidgetData<String>('widget_title', closest.title);
      
      final days = closest.daysRemaining;
      final countdownText = days == 0 ? 'Hôm nay!' : 'Còn $days ngày';
      await HomeWidget.saveWidgetData<String>('widget_countdown', countdownText);
    }

    await HomeWidget.updateWidget(name: androidWidgetName);
  }
}
