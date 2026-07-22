import 'dart:io';

void main() {
  var file = File('lib/screens/add_event_screen.dart');
  if (file.existsSync()) {
    var content = file.readAsStringSync();
    content = content.replaceAll("const Text(t('select_vn'))", "Text(t('select_vn'))");
    content = content.replaceAll("const Text(t('select_intl'))", "Text(t('select_intl'))");
    content = content.replaceAll("const Text(t('deselect_all'))", "Text(t('deselect_all'))");
    file.writeAsStringSync(content);
  }

  file = File('lib/screens/detail_screen.dart');
  if (file.existsSync()) {
    var content = file.readAsStringSync();
    content = content.replaceAll("const Text(t('event_pinned'))", "Text(t('event_pinned'))");
    file.writeAsStringSync(content);
  }
}
