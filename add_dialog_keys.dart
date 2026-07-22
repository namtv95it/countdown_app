import 'dart:io';

void main() {
  final locFile = File('lib/services/localization_service.dart');
  var locContent = locFile.readAsStringSync();

  final viKeys = """
      // Dialogs & Notifications
      'upcoming_event': 'Sắp tới: {title} {emoji}',
      'anniversary_today': 'Hôm nay là ngày kỷ niệm của bạn!',
      'reminder_days_left': 'Còn {days} ngày nữa là tới ngày {title}.',
      'test_notification_title': 'Thông báo thử nghiệm',
      'test_notification_body': 'Cấu hình thông báo của bạn đã hoạt động tốt trên Status Bar!',
      'event_countdown': 'Sự kiện đếm ngược',
      'upcoming_reminder': 'Nhắc nhở sự kiện sắp tới',
      'today_is_anniversary': 'Hôm nay là ngày kỷ niệm!',
      'days_left_notif': 'Còn {days} ngày nữa',
      'days_passed_notif': 'Đã qua {days} ngày',
      'pinned_event': 'Sự kiện được ghim',
      'pinned_notif_body': 'Thông báo cố định trên thanh trạng thái',
      
      'please_enter_gift_code': 'Vui lòng nhập gift code!',
      'vip_account_premium': 'TÀI KHOẢN VIP PREMIUM',
      'activated_lifetime': 'Đã kích hoạt • Bản quyền Vĩnh viễn',
      'thanks_vip': 'Cảm ơn bạn đã ủng hộ ứng dụng Đếm ngược Kỷ niệm! Bạn đang tận hưởng 100% các đặc quyền VIP cao cấp nhất:',
      'ads_hidden': 'Đã Ẩn 100% Quảng cáo',
      'no_ads_desc': 'Không bao giờ xuất hiện banner hay video làm phiền',
      'effects_unlocked': 'Đã Mở khóa Tất cả Hiệu ứng Nền',
      'effects_unlocked_desc': 'Thỏa sức chọn hiệu ứng hình nền độc quyền',
      'you_are_vip': 'BẠN ĐANG LÀ THÀNH VIÊN VIP ✨',
      'unlock_premium_vip': 'MỞ KHÓA PREMIUM VIP',
      'discount_price': 'Giá ưu đãi: \\\$2.00 / Sở hữu vĩnh viễn',
      'hide_ads_title': 'Ẩn 100% Quảng cáo',
      'hide_ads_desc': 'Trải nghiệm ứng dụng mượt mà không bị gián đoạn',
      'unlock_effects_title': 'Mở khóa Tất cả Hiệu ứng Nền',
      'unlock_effects_desc': 'Tự do chọn hiệu ứng hình nền độc quyền',
      'special_vip_badge': 'Huy hiệu VIP Đặc biệt',
      'no_monthly_fee': 'Tài khoản Premium vĩnh viễn không tính phí hàng tháng',
      'upgrade_success': '🎉 Bạn đã nâng cấp Premium thành công!',
      'upgrade_now': 'NÂNG CẤP NGAY (\\\$2.00)',
      'have_gift_code': 'Bạn có mã kích hoạt hoặc Gift Code?',
      'enter_gift_code': 'Nhập gift code',
      'apply': 'Áp dụng',
      
      'upgrade_premium_btn': 'Nâng cấp Premium (\\\$2.00)',
      'watch_ad_free': 'Xem Quảng Cáo (Miễn phí)',
      'cancel': 'Hủy',
      
      'congrats_title': '🎉 CHÚC MỪNG BẠN!',
      'vip_activated_success': 'Kích Hoạt Tài Khoản VIP Thành Công',
      'gift_activated_success': 'Kích Hoạt Gift Code Thành Công',
      'welcome_vip_desc': 'Chào mừng bạn gia nhập thành viên VIP Premium! Từ bây giờ, ứng dụng của bạn đã sẵn sàng với 100% tính năng cao cấp không có quảng cáo.',
      'unlock_success_desc': 'Chúc mừng bạn đã mở khóa thành công {promo}! Hiệu ứng mới đã được áp dụng và sẵn sàng để sử dụng.',
      'activation_package': 'Gói kích hoạt:',
      'usage_code': 'Mã sử dụng:',
      'expiration_date': 'Thời hạn sử dụng:',
      'lifetime': 'Vĩnh viễn ✨',
      'explore_now': 'KHÁM PHÁ NGAY',
""";

  final enKeys = """
      // Dialogs & Notifications
      'upcoming_event': 'Upcoming: {title} {emoji}',
      'anniversary_today': 'Today is your anniversary!',
      'reminder_days_left': '{days} days left until {title}.',
      'test_notification_title': 'Test Notification',
      'test_notification_body': 'Your notification configuration is working fine on Status Bar!',
      'event_countdown': 'Event Countdown',
      'upcoming_reminder': 'Upcoming Event Reminder',
      'today_is_anniversary': 'Today is an anniversary!',
      'days_left_notif': '{days} days left',
      'days_passed_notif': '{days} days passed',
      'pinned_event': 'Pinned Event',
      'pinned_notif_body': 'Sticky notification on status bar',
      
      'please_enter_gift_code': 'Please enter a gift code!',
      'vip_account_premium': 'VIP PREMIUM ACCOUNT',
      'activated_lifetime': 'Activated • Lifetime License',
      'thanks_vip': 'Thank you for supporting Anniversary Countdown! You are enjoying 100% of the premium VIP benefits:',
      'ads_hidden': '100% Ads Hidden',
      'no_ads_desc': 'No more annoying banner or video ads',
      'effects_unlocked': 'All Background Effects Unlocked',
      'effects_unlocked_desc': 'Freely choose exclusive background effects',
      'you_are_vip': 'YOU ARE A VIP MEMBER ✨',
      'unlock_premium_vip': 'UNLOCK PREMIUM VIP',
      'discount_price': 'Discount price: \\\$2.00 / Lifetime',
      'hide_ads_title': 'Hide 100% Ads',
      'hide_ads_desc': 'Smooth app experience without interruption',
      'unlock_effects_title': 'Unlock All Background Effects',
      'unlock_effects_desc': 'Freely choose exclusive background effects',
      'special_vip_badge': 'Special VIP Badge',
      'no_monthly_fee': 'Permanent Premium account with no monthly fees',
      'upgrade_success': '🎉 Premium upgrade successful!',
      'upgrade_now': 'UPGRADE NOW (\\\$2.00)',
      'have_gift_code': 'Have an activation code or Gift Code?',
      'enter_gift_code': 'Enter gift code',
      'apply': 'Apply',
      
      'upgrade_premium_btn': 'Upgrade Premium (\\\$2.00)',
      'watch_ad_free': 'Watch Ad (Free)',
      'cancel': 'Cancel',
      
      'congrats_title': '🎉 CONGRATULATIONS!',
      'vip_activated_success': 'VIP Account Activated Successfully',
      'gift_activated_success': 'Gift Code Activated Successfully',
      'welcome_vip_desc': 'Welcome to VIP Premium membership! From now on, your app is ready with 100% ad-free premium features.',
      'unlock_success_desc': 'Congratulations, you have successfully unlocked {promo}! The new effect has been applied and is ready to use.',
      'activation_package': 'Activation package:',
      'usage_code': 'Usage code:',
      'expiration_date': 'Expiration date:',
      'lifetime': 'Lifetime ✨',
      'explore_now': 'EXPLORE NOW',
""";

  locContent = locContent.replaceFirst(
    "      'loading_gifts': 'Đang tải danh sách quà...',",
    "      'loading_gifts': 'Đang tải danh sách quà...',\n$viKeys"
  );
  locContent = locContent.replaceFirst(
    "      'loading_gifts': 'Loading gift list...',",
    "      'loading_gifts': 'Loading gift list...',\n$enKeys"
  );
  
  locFile.writeAsStringSync(locContent);
  print('Added dialog keys to localization_service.dart');
}
