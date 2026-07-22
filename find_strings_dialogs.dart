import 'dart:io';

void main() {
  for (final path in [
    'lib/services/notification_service.dart',
    'lib/widgets/premium_dialog.dart',
    'lib/widgets/ad_premium_dialog.dart',
    'lib/widgets/success_promo_dialog.dart'
  ]) {
    final file = File(path);
    if (!file.existsSync()) continue;
    final content = file.readAsStringSync();
    
    final RegExp regex = RegExp(r"'([^'\\]*(?:\\.[^'\\]*)*)'");
    final matches = regex.allMatches(content);
    
    print('--- $path ---');
    for (final match in matches) {
      final str = match.group(1);
      if (str != null && str.isNotEmpty && str.codeUnits.any((c) => c > 127)) {
        print(str);
      }
    }
    
    final RegExp doubleRegex = RegExp(r'"([^"\\]*(?:\\.[^"\\]*)*)"');
    final doubleMatches = doubleRegex.allMatches(content);
    for (final match in doubleMatches) {
      final str = match.group(1);
      if (str != null && str.isNotEmpty && str.codeUnits.any((c) => c > 127)) {
        print('"' + str + '"');
      }
    }
  }
}
