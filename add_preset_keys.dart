import 'dart:io';

void main() {
  final viKeys = '''
      'h_solar_new_year': 'Tết Dương lịch',
      'h_students_day': 'Ngày Học sinh - Sinh viên',
      'h_cpv_day': 'Thành lập Đảng',
      'h_vn_doctors_day': 'Thầy thuốc Việt Nam',
      'h_intl_happiness_day': 'Quốc tế Hạnh phúc',
      'h_hcm_youth_union': 'Thành lập Đoàn',
      'h_april_fools': 'Cá tháng Tư',
      'h_earth_day': 'Ngày Trái Đất',
      'h_liberation_day': 'Giải phóng miền Nam',
      'h_labor_day': 'Quốc tế Lao động',
      'h_dien_bien_phu': 'Chiến thắng Điện Biên Phủ',
      'h_ho_chi_minh_birthday': 'Sinh nhật Bác',
      'h_childrens_day': 'Quốc tế Thiếu nhi',
      'h_environment_day': 'Môi trường Thế giới',
      'h_vn_press_day': 'Báo chí Cách mạng',
      'h_invalids_martyrs_day': 'Thương binh Liệt sĩ',
      'h_august_revolution': 'Cách mạng tháng Tám',
      'h_national_day': 'Quốc khánh',
      'h_halloween': 'Halloween',
      'h_mens_day': 'Quốc tế Nam giới',
      'h_vn_peoples_army': 'Quân đội Nhân dân',
      'h_lantern_festival': 'Tết Nguyên tiêu',
      'h_cold_food_festival': 'Tết Hàn thực',
      'h_vesak': 'Lễ Phật Đản',
      'h_duanwu': 'Tết Đoan ngọ',
      'h_ghost_festival': 'Lễ Vu Lan',
      'h_kitchen_gods': 'Ông Công Ông Táo',
      
      'badge_vn': 'Việt Nam',
      'badge_intl': 'Quốc tế',
''';

  final enKeys = '''
      'h_solar_new_year': 'New Year\\'s Day',
      'h_students_day': 'VN Students\\' Day',
      'h_cpv_day': 'CPV Foundation Day',
      'h_vn_doctors_day': 'VN Doctors\\' Day',
      'h_intl_happiness_day': 'Intl. Day of Happiness',
      'h_hcm_youth_union': 'Youth Union Foundation',
      'h_april_fools': 'April Fools\\' Day',
      'h_earth_day': 'Earth Day',
      'h_liberation_day': 'Liberation Day',
      'h_labor_day': 'Labor Day',
      'h_dien_bien_phu': 'Dien Bien Phu Victory',
      'h_ho_chi_minh_birthday': 'President Ho Chi Minh\\'s Birthday',
      'h_childrens_day': 'Children\\'s Day',
      'h_environment_day': 'World Environment Day',
      'h_vn_press_day': 'VN Press Day',
      'h_invalids_martyrs_day': 'Invalids & Martyrs Day',
      'h_august_revolution': 'August Revolution',
      'h_national_day': 'National Day',
      'h_halloween': 'Halloween',
      'h_mens_day': 'Intl. Men\\'s Day',
      'h_vn_peoples_army': 'People\\'s Army Day',
      'h_lantern_festival': 'Lantern Festival',
      'h_cold_food_festival': 'Cold Food Festival',
      'h_vesak': 'Vesak (Buddha\\'s Birthday)',
      'h_duanwu': 'Dragon Boat Festival',
      'h_ghost_festival': 'Ghost Festival',
      'h_kitchen_gods': 'Kitchen Gods\\' Day',
      
      'badge_vn': 'Vietnam',
      'badge_intl': 'International',
''';

  final file = File('lib/services/localization_service.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceFirst(
    "'h_lunar_new_year': 'Tết Nguyên Đán',",
    "'h_lunar_new_year': 'Tết Nguyên Đán',\n$viKeys"
  );
  
  content = content.replaceFirst(
    "'h_lunar_new_year': 'Lunar New Year',",
    "'h_lunar_new_year': 'Lunar New Year',\n$enKeys"
  );
  
  file.writeAsStringSync(content);
}
