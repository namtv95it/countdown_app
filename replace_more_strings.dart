import 'dart:io';

void main() {
  replaceInFile('lib/widgets/theme_picker_sheet.dart', {
    "'Xem 1 đoạn video quảng cáo ngắn hoặc Nâng cấp Premium để sở hữu ngay hiệu ứng \$effectName tuyệt đẹp nhé!'": "t('unlock_effect_msg', params: {'effect': effectName})",
    "'Bong bóng'": "t('effect_bubbles')",
    "'Trái tim'": "t('effect_hearts')",
    "'Tuyết rơi'": "t('effect_snow')",
    "'Ngôi sao'": "t('effect_stars')",
    "'Sao băng'": "t('effect_meteor')",
    "'Mưa rơi'": "t('effect_rain')",
    "'Mặt nước'": "t('effect_rain_ripple')",
    "'Cầu vồng'": "t('effect_rainbow')",
    "'Sóng biển'": "t('effect_waves')",
    "'Lá rơi'": "t('effect_leaves')",
    "'Hoàng hôn'": "t('effect_sunset_birds')",
    "'Cực quang'": "t('effect_aurora')",
    "'Đom đóm'": "t('effect_fireflies')",
    "'Pháo hoa'": "t('effect_fireworks')",
    "'Hoa đào'": "t('effect_cherry_blossom')",
    "'Ngân hà'": "t('effect_galaxy')",
  });

  replaceInFile('lib/screens/gift_screen.dart', {
    "'Lời chúc'": "t('wish_button_short')",
    "'💌 Tạo lời chúc'": "t('wish_button')",
    "'✨ Lời chúc gợi ý'": "t('suggested_wishes')",
    "'Tạo lại lời chúc khác'": "t('regenerate_wish')",
    "'VD: Nam, Lan, anh Hùng...'": "t('sender_hint')",
    "'VD: em Hoa, vợ yêu, mẹ...'": "t('receiver_hint')",
    "'Tạo lời chúc'": "t('create_wish')",
    "'✨ Tạo lời chúc'": "t('create_wish_action')",
  });

  replaceInFile('lib/screens/detail_screen.dart', {
    "'🎉'": "t('congratulation_word') // I should check detail_screen.dart manually for this one",
    "'Chúc mừng'": "t('congratulation_word')",
  });

  replaceInFile('lib/screens/home_screen.dart', {
    "'Không tìm thấy RenderRepaintBoundary'": "t('err_no_repaint_boundary')",
    "'Lỗi khi chuyển đổi ảnh (ByteData null)'": "t('err_convert_image')",
    "'Bạn chưa cấp quyền lưu ảnh. Vui lòng cấp quyền trong Cài đặt.'": "t('err_permission_denied')",
    "'Đang chụp...'": "t('capturing')",
  });
}

void replaceInFile(String path, Map<String, String> replacements) {
  final file = File(path);
  if (!file.existsSync()) return;
  var content = file.readAsStringSync();
  
  if (!content.contains('localization_service.dart')) {
    content = "import '../services/localization_service.dart';\n" + content;
  }
  
  replacements.forEach((key, value) {
    if (key.contains('🎉')) return; // skip for now
    content = content.replaceAll(key, value);
  });
  file.writeAsStringSync(content);
  print('Replaced in \$path');
}
