import 'dart:io';

void main() {
  final file = File('lib/services/localization_service.dart');
  var lines = file.readAsLinesSync();
  
  Map<String, int> viKeys = {};
  Map<String, int> enKeys = {};
  
  bool inVi = false;
  bool inEn = false;
  
  List<int> toRemove = [];
  
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.contains('static const Map<String, String> vi = {')) {
      inVi = true;
      continue;
    }
    if (inVi && line.trim() == '};') {
      inVi = false;
      continue;
    }
    
    if (line.contains('static const Map<String, String> en = {')) {
      inEn = true;
      continue;
    }
    if (inEn && line.trim() == '};') {
      inEn = false;
      continue;
    }
    
    final RegExp keyRegex = RegExp(r"^\s*'([^']+)'\s*:");
    final match = keyRegex.firstMatch(line);
    if (match != null) {
      final key = match.group(1)!;
      if (inVi) {
        if (viKeys.containsKey(key)) {
          toRemove.add(viKeys[key]!);
        }
        viKeys[key] = i;
      } else if (inEn) {
        if (enKeys.containsKey(key)) {
          toRemove.add(enKeys[key]!);
        }
        enKeys[key] = i;
      }
    }
  }
  
  toRemove.sort((a, b) => b.compareTo(a));
  for (final idx in toRemove) {
    lines.removeAt(idx);
  }
  
  file.writeAsStringSync(lines.join('\n'));
  print('Removed \${toRemove.length} duplicates');
}
