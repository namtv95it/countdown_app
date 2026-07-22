import 'dart:io';

void main() {
  final file = File('lib/services/localization_service.dart');
  String content = file.readAsStringSync();

  // Thêm keys tiếng việt
  final viInsertStr = '''
      'onboarding_lang_title': 'Chọn Ngôn Ngữ',
      'onboarding_lang_desc': 'Bạn có thể thay đổi sau trong cài đặt.',
      'onboarding_perm_title': 'Cấp Quyền',
      'onboarding_perm_desc': 'Ứng dụng cần một số quyền để hoạt động tốt nhất.',
      'onboarding_perm_notif': 'Thông báo',
      'onboarding_perm_notif_desc': 'Nhắc nhở bạn khi sắp đến ngày kỷ niệm.',
      'onboarding_perm_storage': 'Ảnh & Tệp',
      'onboarding_perm_storage_desc': 'Để bạn có thể chọn ảnh nền cho sự kiện.',
      'onboarding_holidays_title': 'Sự Kiện Nổi Bật',
      'onboarding_holidays_desc': 'Chọn các ngày lễ bạn muốn đếm ngược.',
      'onboarding_next': 'Tiếp tục',
      'onboarding_start': 'Bắt đầu ngay',
      'onboarding_skip': 'Bỏ qua',
      'granted': 'Đã cấp',
      'grant': 'Cấp quyền',
      
      // Các ngày lễ
      'h_lunar_new_year': 'Tết Nguyên Đán',
      'h_hung_kings': 'Giỗ Tổ Hùng Vương',
      'h_womens_day_vn': 'Phụ nữ Việt Nam 20/10',
      'h_teachers_day': 'Ngày Nhà giáo VN 20/11',
      'h_mid_autumn': 'Tết Trung Thu',
      'h_valentine': 'Valentine 14/2',
      'h_womens_day': 'Quốc tế Phụ nữ 8/3',
      'h_christmas': 'Giáng sinh',
      'h_new_year': 'Tết Dương Lịch',
''';

  // Thêm keys tiếng anh
  final enInsertStr = '''
      'onboarding_lang_title': 'Choose Language',
      'onboarding_lang_desc': 'You can change this later in settings.',
      'onboarding_perm_title': 'Permissions',
      'onboarding_perm_desc': 'The app needs a few permissions to work best.',
      'onboarding_perm_notif': 'Notifications',
      'onboarding_perm_notif_desc': 'Remind you when an event is coming.',
      'onboarding_perm_storage': 'Photos & Storage',
      'onboarding_perm_storage_desc': 'So you can set custom background images.',
      'onboarding_holidays_title': 'Popular Events',
      'onboarding_holidays_desc': 'Select holidays you want to countdown to.',
      'onboarding_next': 'Next',
      'onboarding_start': 'Get Started',
      'onboarding_skip': 'Skip',
      'granted': 'Granted',
      'grant': 'Grant',
      
      // Các ngày lễ
      'h_lunar_new_year': 'Lunar New Year',
      'h_hung_kings': 'Hung Kings Commemoration',
      'h_womens_day_vn': 'VN Women\\'s Day',
      'h_teachers_day': 'Teachers\\' Day',
      'h_mid_autumn': 'Mid-Autumn Festival',
      'h_valentine': 'Valentine\\'s Day',
      'h_womens_day': 'Intl. Women\\'s Day',
      'h_christmas': 'Christmas',
      'h_new_year': 'New Year',
''';

  // Tìm vị trí chèn
  content = content.replaceFirst(
      "'app_name': 'Đếm ngược Kỷ niệm',",
      "'app_name': 'Đếm ngược Kỷ niệm',\n" + viInsertStr);
      
  content = content.replaceFirst(
      "'app_name': 'Memory Countdown',",
      "'app_name': 'Memory Countdown',\n" + enInsertStr);

  file.writeAsStringSync(content);
  print('Done adding onboarding keys');
}
