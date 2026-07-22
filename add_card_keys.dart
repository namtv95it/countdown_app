import 'dart:io';

void main() {
  final file = File('lib/services/localization_service.dart');
  var content = file.readAsStringSync();

  // Add to VI dictionary
  final viInsert = """
      // Countdown Card
      'card_yearly': '↺ năm',
      'card_gift': '🛍️ Quà',
      'card_today': '🎊 Hôm nay!',
      'card_days_left': '⏳ Còn {days} ngày',
      'card_tomorrow': '⏳ Ngày mai',
      'card_days_passed': '✓ Đã qua {days} ngày',
""";

  final enInsert = """
      // Countdown Card
      'card_yearly': '↺ yearly',
      'card_gift': '🛍️ Gift',
      'card_today': '🎊 Today!',
      'card_days_left': '⏳ {days} days left',
      'card_tomorrow': '⏳ Tomorrow',
      'card_days_passed': '✓ Passed {days} days',
""";

  content = content.replaceFirst(
    "      'added': 'Đã thêm',\n    },",
    "      'added': 'Đã thêm',\n$viInsert    },"
  );

  content = content.replaceFirst(
    "      'added': 'Added',\n    }",
    "      'added': 'Added',\n$enInsert    }"
  );

  file.writeAsStringSync(content);
  print('Added keys to dictionary!');
}
