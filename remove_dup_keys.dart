import 'dart:io';

void main() {
  final file = File('lib/services/localization_service.dart');
  var content = file.readAsStringSync();
  
  // Find all map entries in vi and en and remove duplicates by keeping the last one
  // Since it's just a file, I can use a simple script to parse and rebuild, or just use regex to remove earlier duplicates.
  // Wait, I can just find the keys that are warned about.
  // warning - lib\services\localization_service.dart:222:7
  
  final lines = content.split('\n');
  
  // Let's just read and find the duplicates.
  final Map<String, int> viKeys = {};
  final Map<String, int> enKeys = {};
  
  bool inVi = false;
  bool inEn = false;
  
  final List<int> linesToRemove = [];
  
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.contains('static const Map<String, String> vi = {')) {
      inVi = true;
      continue;
    }
    if (inVi && line.contains('};')) {
      inVi = false;
      continue;
    }
    
    if (line.contains('static const Map<String, String> en = {')) {
      inEn = true;
      continue;
    }
    if (inEn && line.contains('};')) {
      inEn = false;
      continue;
    }
    
    final RegExp keyRegex = RegExp(r"^\s*'([^']+)'\s*:");
    final match = keyRegex.firstMatch(line);
    if (match != null) {
      final key = match.group(1)!;
      if (inVi) {
        if (viKeys.containsKey(key)) {
          linesToRemove.add(viKeys[key]!);
        }
        viKeys[key] = i;
      } else if (inEn) {
        if (enKeys.containsKey(key)) {
          linesToRemove.add(enKeys[key]!);
        }
        enKeys[key] = i;
      }
    }
  }
  
  // Remove lines from bottom to top so indices don't shift
  linesToRemove.sort((a, b) => b.compareTo(a));
  for (final index in linesToRemove) {
    lines.removeAt(index);
  }
  
  file.writeAsStringSync(lines.join('\n'));
  print('Removed \${linesToRemove.length} duplicate keys');
}
