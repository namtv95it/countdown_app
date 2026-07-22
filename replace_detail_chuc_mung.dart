import 'dart:io';

void main() {
  final file = File('lib/screens/detail_screen.dart');
  var content = file.readAsStringSync();
  content = content.replaceAll("'🎉'", "t('congratulation_word')");
  content = content.replaceAll("'Chúc mừng'", "t('congratulation_word')");
  file.writeAsStringSync(content);
}
