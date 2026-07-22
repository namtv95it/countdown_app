import 'dart:io';

void main() {
  final file = File('lib/services/localization_service.dart');
  final lines = file.readAsLinesSync();
  
  final linesToRemove = [222, 248, 252, 253, 494, 520, 524, 525];
  
  // 1-indexed to 0-indexed
  final indexesToRemove = linesToRemove.map((l) => l - 1).toList();
  indexesToRemove.sort((a, b) => b.compareTo(a));
  
  for (final idx in indexesToRemove) {
    if (idx >= 0 && idx < lines.length) {
      lines.removeAt(idx);
    }
  }
  
  file.writeAsStringSync(lines.join('\n'));
}
