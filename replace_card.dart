import 'dart:io';

void main() {
  final file = File('lib/widgets/countdown_card.dart');
  var content = file.readAsStringSync();

  content = content.replaceAll("'↺ năm'", "t('card_yearly')");
  content = content.replaceAll("'🛍️ Quà'", "t('card_gift')");
  content = content.replaceAll("'🎊 Hôm nay!'", "t('card_today')");
  content = content.replaceAll("'⏳ Còn \${diff.inDays} ngày'", "t('card_days_left', params: {'days': diff.inDays.toString()})");
  content = content.replaceAll("'⏳ Ngày mai'", "t('card_tomorrow')");
  content = content.replaceAll("'✓ Đã qua \${-calendarDays} ngày'", "t('card_days_passed', params: {'days': (-calendarDays).toString()})");

  file.writeAsStringSync(content);
  print('Updated countdown_card.dart!');
}
