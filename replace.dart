import 'dart:io';

void main() {
  final files = [
    'lib/screens/home_screen.dart',
    'lib/screens/detail_screen.dart',
    'lib/screens/add_event_screen.dart',
    'lib/screens/gift_screen.dart',
    'lib/widgets/time_unit_box.dart',
    'lib/widgets/countdown_card.dart',
    'lib/widgets/premium_dialog.dart',
    'lib/widgets/success_promo_dialog.dart',
    'lib/widgets/theme_picker_sheet.dart',
    'lib/data/preset_holidays.dart',
  ];

  final replacements = {
    "'Cài đặt đếm ngược'": "t('timer_settings')",
    "'Nhập số giây (tối đa 60)'": "t('enter_seconds')",
    "'Hủy'": "t('cancel')",
    "'Bắt đầu'": "t('start')",
    "'Đã lưu ảnh vào thư viện'": "t('screenshot_saved')",
    "'Lỗi khi lưu ảnh: \$e'": "\'\${t('screenshot_error')} \$e\'",
    "'Xóa kỷ niệm?'": "t('delete_event_title')",
    "'Bạn có chắc muốn xóa \"\${event.title}\" không?'": "t('delete_event_desc', params: {'title': event.title})",
    "'Xóa'": "t('delete')",
    "'Thoát ứng dụng'": "t('exit_app_title')",
    "'Bạn có chắc chắn muốn thoát khỏi ứng dụng Đếm ngược Kỷ niệm không?'": "t('exit_app_desc')",
    "'Thoát'": "t('exit')",
    "'Cài đặt bộ đếm'": "t('timer_settings')",
    "_isCapturing ? 'Đang chụp...' : 'Chụp màn hình'": "_isCapturing ? t('capturing') : t('capture_screen')",
    "'Sắp tới'": "t('upcoming')",
    "'Chưa có kỷ niệm nào'": "t('no_events_yet')",
    "'Bấm dấu + để thêm sự kiện đầu tiên'": "t('tap_plus_to_add')",
    "'Thêm kỷ niệm'": "t('add_event')",
    "'Không có sự kiện sắp tới'": "t('no_upcoming_events')",
    "'Các sự kiện của bạn đều đã qua.'": "t('all_events_passed')",
    "'Xem tất cả'": "t('view_all_events')",
    "'Tất cả Kỷ niệm'": "t('all_events')",
    "'Ngày'": "t('days')",
    "'Giờ'": "t('hours')",
    "'Phút'": "t('minutes')",
    "'Giây'": "t('seconds')",
    "'Trang chủ'": "t('home')",
    "'Sự kiện'": "t('events')",
    "'Quà tặng'": "t('gifts')",
    "'Cài đặt'": "t('settings')",
    "'Đã qua'": "t('passed')",
    "'Chi tiết Kỷ niệm'": "t('event_detail')",
    "'Sửa'": "t('edit')",
    "'ngày đã qua'": "t('days_passed')",
    "'ngày nữa'": "t('days_remaining')",
    "'Hôm nay!'": "t('today')",
    "'Chúc mừng!'": "t('congratulations')",
    "'Gửi lời chúc'": "t('send_wish')",
    "'Tìm quà tặng'": "t('find_gifts')",
    "'Thêm Kỷ niệm mới'": "t('add_new_event')",
    "'Sửa Kỷ niệm'": "t('edit_event')",
    "'Tên sự kiện'": "t('event_name')",
    "'VD: Kỷ niệm ngày cưới, Sinh nhật...'": "t('event_name_hint')",
    "'Ngày kỷ niệm'": "t('event_date')",
    "'Chọn ngày'": "t('select_date')",
    "'Biểu tượng'": "t('event_icon')",
    "'Màu sắc'": "t('event_color')",
    "'Vui lòng nhập tên sự kiện'": "t('name_empty_error')",
    "'Khám phá Quà tặng'": "t('discover_gifts')",
    "'Quà tặng Premium bị khóa'": "t('premium_gifts_locked')",
    "'Nâng cấp Premium để mở khóa tất cả quà tặng độc quyền'": "t('unlock_premium_gifts')",
    "'Mở khóa ngay'": "t('unlock_now')",
    "'Đặc quyền Premium'": "t('premium_features')",
    "'Không quảng cáo'": "t('no_ads')",
    "'Mở khóa mọi hiệu ứng nền'": "t('unlock_all_effects')",
    "'Mua Premium - \$2.00'": "t('buy_premium')",
    "'Khôi phục giao dịch'": "t('restore_purchase')",
    "'Hiệu ứng nền'": "t('background_effect')",
    "'Phông chữ'": "t('font_style')",
    "'Không có'": "t('none')",
  };

  for (final filePath in files) {
    final file = File(filePath);
    if (!file.existsSync()) continue;
    
    var content = file.readAsStringSync();
    
    // Add import
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
    
    // Custom pre-replacements for const fixes
    if (filePath == 'lib/screens/home_screen.dart') {
      content = content.replaceAll('const InputDecoration(', 'InputDecoration(');
    }
    if (filePath == 'lib/widgets/theme_picker_sheet.dart') {
      content = content.replaceAll('tabs: const [', 'tabs: [');
    }
    
    // Apply text replacements
    for (final entry in replacements.entries) {
      content = content.replaceAll(entry.key, entry.value);
    }
    
    file.writeAsStringSync(content);
    print('Processed \$filePath');
  }
}
