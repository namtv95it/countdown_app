import 'dart:io';

void main() {
  final files = [
    'lib/screens/home_screen.dart',
    'lib/screens/detail_screen.dart',
    'lib/screens/add_event_screen.dart',
    'lib/screens/gift_screen.dart',
    'lib/widgets/theme_picker_sheet.dart',
    'lib/widgets/ad_premium_dialog.dart',
  ];

  final replacements = {
    "'Font chữ'": "t('font_style')",
    "'Chọn ảnh nền'": "t('select_bg_image')",
    "'Xóa ảnh nền'": "t('remove_bg_image')",
    "'📌 Đã ghim sự kiện lên thanh thông báo!'": "t('event_pinned')",
    "'Lặp lại hàng năm'": "t('repeat_yearly')",
    "'Tính theo Âm lịch'": "t('use_lunar_calendar')",
    "'Đổi tên sự kiện'": "t('rename_event')",
    "'Lưu'": "t('save')",
    "'Chọn danh mục'": "t('select_category')",
    "'Chọn màu sắc'": "t('select_color')",
    "'Vui lòng chọn ngày!'": "t('select_date_warning')",
    "'🇻🇳 Chọn Việt Nam'": "t('select_vn')",
    "'🌍 Chọn Quốc tế'": "t('select_intl')",
    "'✕ Bỏ chọn tất cả'": "t('deselect_all')",
    "'Vui lòng nhập tên người gửi và người nhận'": "t('enter_sender_receiver')",
    "'Đã copy lời chúc!'": "t('wish_copied')",
    "'Tên bạn (xưng)'": "t('your_name')",
    "'Tên người nhận'": "t('receiver_name')",
    "'Dịp kỷ niệm'": "t('anniversary_occasion')",
    "'Copy'": "t('copy')",
    "'Hiệu ứng \$effectName'": "t('effect_prefix', params: {'effect': effectName})",
    "'🎉 Đã mở khóa vĩnh viễn hiệu ứng \$effectName!'": "t('premium_effect_unlocked', params: {'effect': effectName})",
  };

  for (final filePath in files) {
    final file = File(filePath);
    if (!file.existsSync()) continue;
    
    var content = file.readAsStringSync();
    
    // Add import if missing
    if (!content.contains("import '../services/localization_service.dart';") && 
        !content.contains("import 'package:countdown_app/services/localization_service.dart';") &&
        filePath != 'lib/services/localization_service.dart' &&
        filePath.startsWith('lib/')) {
      
      final parts = filePath.split('/');
      final depth = parts.length - 2; 
      final prefix = List.filled(depth, '..').join('/');
      final importPath = depth == 0 ? "import 'services/localization_service.dart';" : "import '$prefix/services/localization_service.dart';";
      
      if (content.contains('import')) {
        content = content.replaceFirst('import', "$importPath\nimport");
      }
    }
    
    for (final entry in replacements.entries) {
      content = content.replaceAll(entry.key, entry.value);
    }
    
    file.writeAsStringSync(content);
    print('Processed \$filePath');
  }
}
