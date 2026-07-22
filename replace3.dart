import 'dart:io';

void main() {
  final replacements = {
    // home_screen
    "'Gần nhất'": "t('nearest')",
    "'↺ hàng năm'": "t('yearly')",
    "'(Ngày \${item.date.day} tháng \${item.date.month} Âm lịch)'": "t('lunar_date', params: {'day': item.date.day.toString(), 'month': item.date.month.toString()})",
    "'Gợi ý quà'": "t('gift_suggestions')",
    "'Xem chi tiết'": "t('view_detail')",
    "'Xem Toàn Màn Hình'": "t('view_fullscreen')",
    "'Xem 1 đoạn video quảng cáo ngắn hoặc Nâng cấp Premium để thưởng thức chế độ toàn màn hình tuyệt đẹp!'": "t('fullscreen_ad_desc')",
    "'Nâng cấp Premium (\$2.00)'": "t('upgrade_premium_price')",
    "'Xem Quảng Cáo (Miễn phí)'": "t('watch_ad_free')",
    "'Xem toàn màn hình'": "t('watch_fullscreen')",
    "'Tất cả sự kiện'": "t('all_events_tab')",
    "'Hãy thêm những ngày quan trọng\\ncủa bạn để không bao giờ quên!'": "t('empty_state_desc')",
    "'+ Thêm ngay'": "t('add_now')",
    "'Tất cả sự kiện đã diễn ra.\\nThêm sự kiện mới hoặc xem tab Tất cả.'": "t('no_upcoming_desc')",
    "'Xem tất cả sự kiện →'": "t('view_all_events_arrow')",

    // detail_screen
    "'🎊 Hôm nay là ngày kỷ niệm!'": "t('today_is_anniversary')",
    "'✓ Đã diễn ra \${-days} ngày trước'": "t('days_ago', params: {'days': (-days).toString()})",
    "'⏳ Còn \$days ngày nữa'": "t('days_left', params: {'days': days.toString()})",
    "'ĐẾM NGƯỢC'": "t('countdown_label')",
    "'Vị trí trong năm \${displayDate.year}'": "t('position_in_year', params: {'year': displayDate.year.toString()})",
    "'1 tháng 1'": "t('jan_1')",
    "'31 tháng 12'": "t('dec_31')",
    "'Danh mục'": "t('category')",
    "'Ngày gốc'": "t('original_date')",
    "'Lần kế tiếp'": "t('next_occurrence')",
    "'Gợi ý quà tặng'": "t('gift_suggestions_detail')",
    "'Tìm món quà ý nghĩa nhất'": "t('find_meaningful_gift')",
    "'Biểu tượng tùy chỉnh'": "t('custom_icon')",
    "'Xem 1 đoạn video quảng cáo ngắn hoặc Nâng cấp Premium để sử dụng biểu tượng tuyệt đẹp nhé!'": "t('custom_icon_ad_desc')",
    "'Chúc bạn một ngày thật ý nghĩa và tràn đầy niềm vui.'": "t('congrats_desc')",

    // add_event_screen
    "'Xem 1 đoạn video quảng cáo ngắn hoặc Nâng cấp Premium để lưu lại thay đổi biểu tượng tuyệt đẹp nhé!'": "t('custom_icon_add_desc')",
    "'Thêm Kỷ niệm'": "t('add_anniversary')",
    "'Tên kỷ niệm'": "t('anniversary_name')",
    "'VD: Sinh nhật vợ yêu...'": "t('anniversary_name_hint')",
    "'Vui lòng nhập tên'": "t('please_enter_name')",
    "'Danh mục sự kiện'": "t('event_category')",
    "'💡 Cần xem quảng cáo để thay đổi biểu tượng'": "t('need_ad_for_icon')",
    "'Ghi chú (tùy chọn)'": "t('notes')",
    "'Thêm ghi chú cho kỷ niệm này...'": "t('notes_hint')",
    "'Chọn ngày...'": "t('select_date_hint')",
    "'Thay đổi biểu tượng'": "t('change_icon')",
    "'Tự động cập nhật sang năm tiếp theo'": "t('auto_update_yearly')",
    "'Dành cho ngày lễ truyền thống'": "t('for_traditional_holidays')",
    "'Lưu Kỷ niệm ✨'": "t('save_anniversary')",
    "'Chọn từ ngày lễ có sẵn'": "t('select_from_presets')",
    "'Ngày lễ phổ biến'": "t('popular_holidays')",
    "'Việt Nam'": "t('vietnam')",
    "'Quốc tế'": "t('international')",
    "'Tất cả ngày lễ'": "t('all_holidays')",
    "'Đã chọn: \${selectedHolidays.length}'": "t('selected_count', params: {'count': selectedHolidays.length.toString()})",
    "'Thêm \${selectedHolidays.length} ngày'": "t('add_count_days', params: {'count': selectedHolidays.length.toString()})",
    "'\${h.day}/\${h.month} (Âm lịch)'": "t('lunar_date_display', params: {'day': h.day.toString(), 'month': h.month.toString()})",
    "'Đã thêm'": "t('added')",
  };

  final specialReplacementsDetail = {
    "Bạn có chắc muốn xóa \"\${widget.anniversary.title}\" không?": "t('delete_event_desc', params: {'title': widget.anniversary.title})",
  };

  for (final path in ['lib/screens/home_screen.dart', 'lib/screens/detail_screen.dart', 'lib/screens/add_event_screen.dart']) {
    final file = File(path);
    var content = file.readAsStringSync();
    
    for (final entry in replacements.entries) {
      content = content.replaceAll(entry.key, entry.value);
    }
    
    if (path == 'lib/screens/detail_screen.dart') {
        for (final entry in specialReplacementsDetail.entries) {
          content = content.replaceAll("'" + entry.key + "'", entry.value);
        }
    }
    
    file.writeAsStringSync(content);
    print('Updated \$path');
  }
}
