import 'dart:io';

void main() {
  final file = File('lib/services/localization_service.dart');
  var content = file.readAsStringSync();

  // Add to VI dictionary
  final viInsert = """
      // Home Screen - additional
      'nearest': 'Gần nhất',
      'yearly': '↺ hàng năm',
      'lunar_date': '(Ngày {day} tháng {month} Âm lịch)',
      'gift_suggestions': 'Gợi ý quà',
      'view_detail': 'Xem chi tiết',
      'view_fullscreen': 'Xem Toàn Màn Hình',
      'fullscreen_ad_desc': 'Xem 1 đoạn video quảng cáo ngắn hoặc Nâng cấp Premium để thưởng thức chế độ toàn màn hình tuyệt đẹp!',
      'upgrade_premium_price': 'Nâng cấp Premium (\$2.00)',
      'watch_ad_free': 'Xem Quảng Cáo (Miễn phí)',
      'watch_fullscreen': 'Xem toàn màn hình',
      'all_events_tab': 'Tất cả sự kiện',
      'empty_state_desc': 'Hãy thêm những ngày quan trọng\\ncủa bạn để không bao giờ quên!',
      'add_now': '+ Thêm ngay',
      'no_upcoming_desc': 'Tất cả sự kiện đã diễn ra.\\nThêm sự kiện mới hoặc xem tab Tất cả.',
      'view_all_events_arrow': 'Xem tất cả sự kiện →',

      // Detail Screen - additional
      'today_is_anniversary': '🎊 Hôm nay là ngày kỷ niệm!',
      'days_ago': '✓ Đã diễn ra {days} ngày trước',
      'days_left': '⏳ Còn {days} ngày nữa',
      'countdown_label': 'ĐẾM NGƯỢC',
      'position_in_year': 'Vị trí trong năm {year}',
      'jan_1': '1 tháng 1',
      'dec_31': '31 tháng 12',
      'category': 'Danh mục',
      'original_date': 'Ngày gốc',
      'next_occurrence': 'Lần kế tiếp',
      'gift_suggestions_detail': 'Gợi ý quà tặng',
      'find_meaningful_gift': 'Tìm món quà ý nghĩa nhất',
      'custom_icon': 'Biểu tượng tùy chỉnh',
      'custom_icon_ad_desc': 'Xem 1 đoạn video quảng cáo ngắn hoặc Nâng cấp Premium để sử dụng biểu tượng tuyệt đẹp nhé!',
      'congrats_desc': 'Chúc bạn một ngày thật ý nghĩa và tràn đầy niềm vui.',

      // Add Event Screen - additional
      'custom_icon_add_desc': 'Xem 1 đoạn video quảng cáo ngắn hoặc Nâng cấp Premium để lưu lại thay đổi biểu tượng tuyệt đẹp nhé!',
      'add_anniversary': 'Thêm Kỷ niệm',
      'anniversary_name': 'Tên kỷ niệm',
      'anniversary_name_hint': 'VD: Sinh nhật vợ yêu...',
      'please_enter_name': 'Vui lòng nhập tên',
      'event_category': 'Danh mục sự kiện',
      'need_ad_for_icon': '💡 Cần xem quảng cáo để thay đổi biểu tượng',
      'notes': 'Ghi chú (tùy chọn)',
      'notes_hint': 'Thêm ghi chú cho kỷ niệm này...',
      'select_date_hint': 'Chọn ngày...',
      'change_icon': 'Thay đổi biểu tượng',
      'auto_update_yearly': 'Tự động cập nhật sang năm tiếp theo',
      'for_traditional_holidays': 'Dành cho ngày lễ truyền thống',
      'save_anniversary': 'Lưu Kỷ niệm ✨',
      'select_from_presets': 'Chọn từ ngày lễ có sẵn',
      'popular_holidays': 'Ngày lễ phổ biến',
      'vietnam': 'Việt Nam',
      'international': 'Quốc tế',
      'all_holidays': 'Tất cả ngày lễ',
      'selected_count': 'Đã chọn: {count}',
      'add_count_days': 'Thêm {count} ngày',
      'lunar_date_display': '{day}/{month} (Âm lịch)',
      'added': 'Đã thêm',
""";

  final enInsert = """
      // Home Screen - additional
      'nearest': 'Nearest',
      'yearly': '↺ yearly',
      'lunar_date': '(Day {day} Month {month} Lunar)',
      'gift_suggestions': 'Gift Ideas',
      'view_detail': 'View Detail',
      'view_fullscreen': 'View Fullscreen',
      'fullscreen_ad_desc': 'Watch a short ad or Upgrade Premium to enjoy the beautiful fullscreen mode!',
      'upgrade_premium_price': 'Upgrade Premium (\$2.00)',
      'watch_ad_free': 'Watch Ad (Free)',
      'watch_fullscreen': 'View fullscreen',
      'all_events_tab': 'All Events',
      'empty_state_desc': 'Add your important dates\\nso you never forget!',
      'add_now': '+ Add Now',
      'no_upcoming_desc': 'All events have passed.\\nAdd a new event or view All tab.',
      'view_all_events_arrow': 'View all events →',

      // Detail Screen - additional
      'today_is_anniversary': '🎊 Today is the anniversary!',
      'days_ago': '✓ Happened {days} days ago',
      'days_left': '⏳ {days} days to go',
      'countdown_label': 'COUNTDOWN',
      'position_in_year': 'Position in {year}',
      'jan_1': 'Jan 1',
      'dec_31': 'Dec 31',
      'category': 'Category',
      'original_date': 'Original Date',
      'next_occurrence': 'Next Occurrence',
      'gift_suggestions_detail': 'Gift Suggestions',
      'find_meaningful_gift': 'Find the most meaningful gift',
      'custom_icon': 'Custom Icon',
      'custom_icon_ad_desc': 'Watch a short ad or Upgrade Premium to use beautiful icons!',
      'congrats_desc': 'Wishing you a meaningful and joyful day.',

      // Add Event Screen - additional
      'custom_icon_add_desc': 'Watch a short ad or Upgrade Premium to save beautiful icon changes!',
      'add_anniversary': 'Add Anniversary',
      'anniversary_name': 'Anniversary Name',
      'anniversary_name_hint': "e.g.: Wife's Birthday...",
      'please_enter_name': 'Please enter a name',
      'event_category': 'Event Category',
      'need_ad_for_icon': '💡 Need to watch an ad to change icon',
      'notes': 'Notes (optional)',
      'notes_hint': 'Add notes for this anniversary...',
      'select_date_hint': 'Select date...',
      'change_icon': 'Change Icon',
      'auto_update_yearly': 'Automatically update to next year',
      'for_traditional_holidays': 'For traditional holidays',
      'save_anniversary': 'Save Anniversary ✨',
      'select_from_presets': 'Select from preset holidays',
      'popular_holidays': 'Popular Holidays',
      'vietnam': 'Vietnam',
      'international': 'International',
      'all_holidays': 'All Holidays',
      'selected_count': 'Selected: {count}',
      'add_count_days': 'Add {count} days',
      'lunar_date_display': '{day}/{month} (Lunar)',
      'added': 'Added',
""";

  // Insert into VI block - before the closing '    },' of vi
  content = content.replaceFirst(
    "      'effect_prefix': 'Hiệu ứng {effect}',\n    },",
    "      'effect_prefix': 'Hiệu ứng {effect}',\n$viInsert    },"
  );

  // Insert into EN block - before the closing '    }' of en
  content = content.replaceFirst(
    "      'effect_prefix': '{effect} Effect',\n    }\n  };",
    "      'effect_prefix': '{effect} Effect',\n$enInsert    }\n  };"
  );

  file.writeAsStringSync(content);
  print('Done!');
}
