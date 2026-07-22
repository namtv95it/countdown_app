import 'dart:io';

void main() {
  replaceInFile('lib/services/notification_service.dart', {
    "'Sắp tới: \${event.title} \${event.emoji}'": "t('upcoming_event', params: {'title': event.title, 'emoji': event.emoji})",
    "'Hôm nay là ngày kỷ niệm của bạn!'": "t('anniversary_today')",
    "'Còn \$reminderDays ngày nữa là tới ngày \${event.title}.'": "t('reminder_days_left', params: {'days': reminderDays.toString(), 'title': event.title})",
    "'NotificationService: Bắt đầu hẹn giờ test thông báo sau 5 giây...'": "'''NotificationService: Test notification in 5s...'''", // just console logs
    "'Sự kiện đếm ngược'": "t('event_countdown')",
    "'Nhắc nhở sự kiện sắp tới'": "t('upcoming_reminder')",
    "'Thông báo thử nghiệm'": "t('test_notification_title')",
    "'Cấu hình thông báo của bạn đã hoạt động tốt trên Status Bar!'": "t('test_notification_body')",
    "'NotificationService: Đã đăng ký hẹn giờ (chờ 5s nữa sẽ nổ)...'": "'''NotificationService: Registered test (5s)...'''",
    "'NotificationService: BOOM! Thông báo đáng lẽ đã xuất hiện trên màn hình khóa/status bar lúc này!'": "'''NotificationService: BOOM!'''",
    "'Hôm nay là ngày kỷ niệm!'": "t('today_is_anniversary')",
    "'Còn \$daysDiff ngày nữa'": "t('days_left_notif', params: {'days': daysDiff.toString()})",
    "'Đã qua \${daysDiff.abs()} ngày'": "t('days_passed_notif', params: {'days': daysDiff.abs().toString()})",
    "'Sự kiện được ghim'": "t('pinned_event')",
    "'Thông báo cố định trên thanh trạng thái'": "t('pinned_notif_body')",
  });

  replaceInFile('lib/widgets/premium_dialog.dart', {
    "'Vui lòng nhập gift code!'": "t('please_enter_gift_code')",
    "'TÀI KHOẢN VIP PREMIUM'": "t('vip_account_premium')",
    "'Đã kích hoạt • Bản quyền Vĩnh viễn'": "t('activated_lifetime')",
    "'Cảm ơn bạn đã ủng hộ ứng dụng Đếm ngược Kỷ niệm! Bạn đang tận hưởng 100% các đặc quyền VIP cao cấp nhất:'": "t('thanks_vip')",
    "'Đã Ẩn 100% Quảng cáo'": "t('ads_hidden')",
    "'Không bao giờ xuất hiện banner hay video làm phiền'": "t('no_ads_desc')",
    "'Đã Mở khóa Tất cả Hiệu ứng Nền'": "t('effects_unlocked')",
    "'Thỏa sức chọn hiệu ứng hình nền độc quyền'": "t('effects_unlocked_desc')",
    "'BẠN ĐANG LÀ THÀNH VIÊN VIP ✨'": "t('you_are_vip')",
    "'MỞ KHÓA PREMIUM VIP'": "t('unlock_premium_vip')",
    "'Giá ưu đãi: \$2.00 / Sở hữu vĩnh viễn'": "t('discount_price')",
    "'Ẩn 100% Quảng cáo'": "t('hide_ads_title')",
    "'Trải nghiệm ứng dụng mượt mà không bị gián đoạn'": "t('hide_ads_desc')",
    "'Mở khóa Tất cả Hiệu ứng Nền'": "t('unlock_effects_title')",
    "'Tự do chọn hiệu ứng hình nền độc quyền'": "t('unlock_effects_desc')",
    "'Huy hiệu VIP Đặc biệt'": "t('special_vip_badge')",
    "'Tài khoản Premium vĩnh viễn không tính phí hàng tháng'": "t('no_monthly_fee')",
    "'🎉 Bạn đã nâng cấp Premium thành công!'": "t('upgrade_success')",
    "'NÂNG CẤP NGAY (\$2.00)'": "t('upgrade_now')",
    "'Bạn có mã kích hoạt hoặc Gift Code?'": "t('have_gift_code')",
    "'Nhập gift code'": "t('enter_gift_code')",
    "'Áp dụng'": "t('apply')",
  });

  replaceInFile('lib/widgets/ad_premium_dialog.dart', {
    "'Nâng cấp Premium (\$2.00)'": "t('upgrade_premium_btn')",
    "'Xem Quảng Cáo (Miễn phí)'": "t('watch_ad_free')",
    "'Hủy'": "t('cancel')",
  });

  replaceInFile('lib/widgets/success_promo_dialog.dart', {
    "'🎉 CHÚC MỪNG BẠN!'": "t('congrats_title')",
    "'Kích Hoạt Tài Khoản VIP Thành Công'": "t('vip_activated_success')",
    "'Kích Hoạt Gift Code Thành Công'": "t('gift_activated_success')",
    "'Chào mừng bạn gia nhập thành viên VIP Premium! Từ bây giờ, ứng dụng của bạn đã sẵn sàng với 100% tính năng cao cấp không có quảng cáo.'": "t('welcome_vip_desc')",
    "'Chúc mừng bạn đã mở khóa thành công \${promoCode.description}! Hiệu ứng mới đã được áp dụng và sẵn sàng để sử dụng.'": "t('unlock_success_desc', params: {'promo': promoCode.description})",
    "'Gói kích hoạt:'": "t('activation_package')",
    "'Mã sử dụng:'": "t('usage_code')",
    "'Thời hạn sử dụng:'": "t('expiration_date')",
    "'Vĩnh viễn ✨'": "t('lifetime')",
    "'KHÁM PHÁ NGAY'": "t('explore_now')",
  });
}

void replaceInFile(String path, Map<String, String> replacements) {
  final file = File(path);
  if (!file.existsSync()) return;
  var content = file.readAsStringSync();
  
  // Need to handle imports if using t()
  if (!content.contains('localization_service.dart')) {
    content = "import '../services/localization_service.dart';\n" + content;
  }
  
  replacements.forEach((key, value) {
    content = content.replaceAll(key, value);
  });
  file.writeAsStringSync(content);
  print('Replaced in \$path');
}
