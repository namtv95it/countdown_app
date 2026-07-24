import 'dart:convert';
import 'package:http/http.dart' as http;

const String projectId = 'lovin-c69f3';

final List<Map<String, dynamic>> occasions = [
    { 'id': 'valentine',      'nameVi': 'Valentine',               'nameEn': 'Valentine\'s Day',       'dateLabelVi': '14 tháng 2',   'dateLabelEn': 'Feb 14',  'emoji': '💝', 'month': 2,  'day': 14, 'gradient': 'linear-gradient(135deg, #EC4899, #BE185D)', 'categoryId': 'love' },
    { 'id': 'womens_day',     'nameVi': 'Ngày Quốc tế Phụ nữ',    'nameEn': 'Int\'l Women\'s Day',    'dateLabelVi': '8 tháng 3',    'dateLabelEn': 'Mar 8',   'emoji': '🌸', 'month': 3,  'day': 8,  'gradient': 'linear-gradient(135deg, #F472B6, #A855F7)', 'categoryId': 'love' },
    { 'id': 'mothers_day',    'nameVi': 'Ngày của Mẹ',             'nameEn': 'Mother\'s Day',          'dateLabelVi': '12 tháng 5',   'dateLabelEn': 'May 12',  'emoji': '💐', 'month': 5,  'day': 12, 'gradient': 'linear-gradient(135deg, #F59E0B, #EF4444)', 'categoryId': 'birthday' },
    { 'id': 'children_day',   'nameVi': 'Tết Thiếu nhi',           'nameEn': 'Children\'s Day',        'dateLabelVi': '1 tháng 6',    'dateLabelEn': 'Jun 1',   'emoji': '🎈', 'month': 6,  'day': 1,  'gradient': 'linear-gradient(135deg, #3B82F6, #06B6D4)', 'categoryId': 'birthday' },
    { 'id': 'fathers_day',    'nameVi': 'Ngày của Bố',             'nameEn': 'Father\'s Day',          'dateLabelVi': '21 tháng 6',   'dateLabelEn': 'Jun 21',  'emoji': '👔', 'month': 6,  'day': 21, 'gradient': 'linear-gradient(135deg, #1D4ED8, #3B82F6)', 'categoryId': 'birthday' },
    { 'id': 'tet_trung_thu',  'nameVi': 'Tết Trung Thu',           'nameEn': 'Mid-Autumn Festival',   'dateLabelVi': '17 tháng 9',   'dateLabelEn': 'Sep 17',  'emoji': '🥮', 'month': 9,  'day': 17, 'gradient': 'linear-gradient(135deg, #F59E0B, #D97706)', 'categoryId': 'mid_autumn' },
    { 'id': 'womens_day_vn',  'nameVi': 'Ngày Phụ nữ Việt Nam',   'nameEn': 'Vietnamese Women\'s Day', 'dateLabelVi': '20 tháng 10', 'dateLabelEn': 'Oct 20',  'emoji': '🌺', 'month': 10, 'day': 20, 'gradient': 'linear-gradient(135deg, #EC4899, #7C3AED)', 'categoryId': 'love' },
    { 'id': 'teachers_day',   'nameVi': 'Ngày Nhà giáo VN',        'nameEn': 'Teachers\' Day',         'dateLabelVi': '20 tháng 11', 'dateLabelEn': 'Nov 20',  'emoji': '📚', 'month': 11, 'day': 20, 'gradient': 'linear-gradient(135deg, #10B981, #0EA5E9)', 'categoryId': 'birthday' },
    { 'id': 'christmas',      'nameVi': 'Giáng Sinh',              'nameEn': 'Christmas',              'dateLabelVi': '25 tháng 12', 'dateLabelEn': 'Dec 25',  'emoji': '🎄', 'month': 12, 'day': 25, 'gradient': 'linear-gradient(135deg, #EF4444, #16A34A)', 'categoryId': 'holiday' },
    { 'id': 'noel_eve',       'nameVi': 'Tất niên',                'nameEn': 'New Year\'s Eve',        'dateLabelVi': '31 tháng 12', 'dateLabelEn': 'Dec 31',  'emoji': '🥂', 'month': 12, 'day': 31, 'gradient': 'linear-gradient(135deg, #7C3AED, #0EA5E9)', 'categoryId': 'holiday' },
    { 'id': 'new_year',       'nameVi': 'Năm Mới',                 'nameEn': 'New Year',               'dateLabelVi': '1 tháng 1',   'dateLabelEn': 'Jan 1',   'emoji': '🎆', 'month': 1,  'day': 1,  'gradient': 'linear-gradient(135deg, #7C3AED, #EC4899)', 'categoryId': 'holiday' },
    { 'id': 'tet',            'nameVi': 'Tết Nguyên Đán',          'nameEn': 'Lunar New Year',         'dateLabelVi': '29 tháng 1',  'dateLabelEn': 'Jan 29',  'emoji': '🧧', 'month': 1,  'day': 29, 'gradient': 'linear-gradient(135deg, #EF4444, #F59E0B)', 'categoryId': 'holiday' },
];

void main() async {
  print('Đang tiến hành đẩy dữ liệu specialOccasions lên Firebase...');

  for (var occ in occasions) {
    final String url = 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/special_occasions?documentId=${occ["id"]}';
    
    final Map<String, dynamic> fields = {
      "nameVi": {"stringValue": occ["nameVi"]},
      "nameEn": {"stringValue": occ["nameEn"]},
      "dateLabelVi": {"stringValue": occ["dateLabelVi"]},
      "dateLabelEn": {"stringValue": occ["dateLabelEn"]},
      "emoji": {"stringValue": occ["emoji"]},
      "month": {"integerValue": occ["month"]},
      "day": {"integerValue": occ["day"]},
      "gradient": {"stringValue": occ["gradient"]},
      "categoryId": {"stringValue": occ["categoryId"]},
    };

    final body = jsonEncode({"fields": fields});

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 409) {
          // If 409 (ALREADY_EXISTS), we can PATCH it instead
          if (response.statusCode == 409) {
            final patchUrl = 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/special_occasions/${occ["id"]}';
            final patchResponse = await http.patch(
              Uri.parse(patchUrl),
              headers: {'Content-Type': 'application/json'},
              body: body,
            );
            if (patchResponse.statusCode == 200) {
              print('PATCH Thành công: ${occ["id"]}');
            } else {
              print('PATCH Lỗi ${occ["id"]}: ${patchResponse.body}');
            }
          } else {
            print('POST Thành công: ${occ["id"]}');
          }
      } else {
        print('Lỗi ${occ["id"]}: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Ngoại lệ khi đẩy ${occ["id"]}: $e');
    }
  }
}
