import 'dart:io';

void main() {
  for (final path in ['lib/screens/home_screen.dart', 'lib/screens/detail_screen.dart', 'lib/screens/add_event_screen.dart']) {
    final file = File(path);
    final content = file.readAsStringSync();
    
    final RegExp regex = RegExp(r"'([^'\\]*(?:\\.[^'\\]*)*)'");
    final matches = regex.allMatches(content);
    
    print('=== $path ===');
    for (final match in matches) {
      final str = match.group(1)!;
      if (str.codeUnits.any((c) => c > 127)) {
        print('  "$str"');
      }
    }
  }
}
