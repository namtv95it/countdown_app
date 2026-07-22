import 'dart:io';

void main() {
  replaceInFile('lib/screens/home_screen.dart', {
    "'Nâng cấp Premium (\\\$2.00)'": "t('upgrade_premium_btn')",
  });
}

void replaceInFile(String path, Map<String, String> replacements) {
  final file = File(path);
  if (!file.existsSync()) return;
  var content = file.readAsStringSync();
  
  replacements.forEach((key, value) {
    content = content.replaceAll(key, value);
  });
  file.writeAsStringSync(content);
  print('Replaced in \$path');
}
