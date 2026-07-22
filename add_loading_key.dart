import 'dart:io';

void main() {
  final file = File('lib/services/localization_service.dart');
  var content = file.readAsStringSync();

  content = content.replaceFirst(
    "      'card_days_passed': '✓ Đã qua {days} ngày',",
    "      'card_days_passed': '✓ Đã qua {days} ngày',\n      'loading_gifts': 'Đang tải danh sách quà...',"
  );

  content = content.replaceFirst(
    "      'card_days_passed': '✓ Passed {days} days',",
    "      'card_days_passed': '✓ Passed {days} days',\n      'loading_gifts': 'Loading gift list...',"
  );

  file.writeAsStringSync(content);
  print('Added loading_gifts key!');
}
