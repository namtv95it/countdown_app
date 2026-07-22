import 'dart:io';

void main() {
  final locFile = File('lib/services/localization_service.dart');
  var locContent = locFile.readAsStringSync();

  final viKeys = """
      // Theme picker & Effects
      'unlock_effect_msg': 'Xem 1 đoạn video quảng cáo ngắn hoặc Nâng cấp Premium để sở hữu ngay hiệu ứng {effect} tuyệt đẹp nhé!',
      'effect_bubbles': 'Bong bóng',
      'effect_hearts': 'Trái tim',
      'effect_snow': 'Tuyết rơi',
      'effect_stars': 'Ngôi sao',
      'effect_meteor': 'Sao băng',
      'effect_rain': 'Mưa rơi',
      'effect_rain_ripple': 'Mặt nước',
      'effect_rainbow': 'Cầu vồng',
      'effect_waves': 'Sóng biển',
      'effect_leaves': 'Lá rơi',
      'effect_sunset_birds': 'Hoàng hôn',
      'effect_aurora': 'Cực quang',
      'effect_fireflies': 'Đom đóm',
      'effect_fireworks': 'Pháo hoa',
      'effect_cherry_blossom': 'Hoa đào',
      'effect_galaxy': 'Ngân hà',
      
      // Gift screen & wishes
      'wish_button': '💌 Tạo lời chúc',
      'wish_button_short': 'Lời chúc',
      'suggested_wishes': '✨ Lời chúc gợi ý',
      'regenerate_wish': 'Tạo lại lời chúc khác',
      'sender_hint': 'VD: Nam, Lan, anh Hùng...',
      'receiver_hint': 'VD: em Hoa, vợ yêu, mẹ...',
      'create_wish': 'Tạo lời chúc',
      'create_wish_action': '✨ Tạo lời chúc',
      'congratulation_word': '🎉 Chúc mừng',
      
      // Error messages
      'err_no_repaint_boundary': 'Không tìm thấy RenderRepaintBoundary',
      'err_convert_image': 'Lỗi khi chuyển đổi ảnh (ByteData null)',
      'err_permission_denied': 'Bạn chưa cấp quyền lưu ảnh. Vui lòng cấp quyền trong Cài đặt.',
      'capturing': 'Đang chụp...',
""";

  final enKeys = """
      // Theme picker & Effects
      'unlock_effect_msg': 'Watch a short video ad or Upgrade to Premium to immediately own this beautiful {effect} effect!',
      'effect_bubbles': 'Bubbles',
      'effect_hearts': 'Hearts',
      'effect_snow': 'Snow',
      'effect_stars': 'Stars',
      'effect_meteor': 'Meteor',
      'effect_rain': 'Rain',
      'effect_rain_ripple': 'Ripples',
      'effect_rainbow': 'Rainbow',
      'effect_waves': 'Waves',
      'effect_leaves': 'Leaves',
      'effect_sunset_birds': 'Sunset',
      'effect_aurora': 'Aurora',
      'effect_fireflies': 'Fireflies',
      'effect_fireworks': 'Fireworks',
      'effect_cherry_blossom': 'Cherry Blossom',
      'effect_galaxy': 'Galaxy',
      
      // Gift screen & wishes
      'wish_button': '💌 Create wish',
      'wish_button_short': 'Wishes',
      'suggested_wishes': '✨ Suggested wishes',
      'regenerate_wish': 'Regenerate wish',
      'sender_hint': 'Ex: John, Alice...',
      'receiver_hint': 'Ex: my love, mom...',
      'create_wish': 'Create wish',
      'create_wish_action': '✨ Create wish',
      'congratulation_word': '🎉 Congratulations',
      
      // Error messages
      'err_no_repaint_boundary': 'RenderRepaintBoundary not found',
      'err_convert_image': 'Error converting image (ByteData null)',
      'err_permission_denied': 'Storage permission denied. Please grant permission in Settings.',
      'capturing': 'Capturing...',
""";

  locContent = locContent.replaceFirst(
    "      'loading_gifts': 'Đang tải danh sách quà...',",
    "      'loading_gifts': 'Đang tải danh sách quà...',\n\$viKeys"
  );
  locContent = locContent.replaceFirst(
    "      'loading_gifts': 'Loading gift list...',",
    "      'loading_gifts': 'Loading gift list...',\n\$enKeys"
  );
  
  locFile.writeAsStringSync(locContent);
  print('Added more keys to localization_service.dart');
}
