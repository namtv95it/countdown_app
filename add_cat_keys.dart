import 'dart:io';

void main() {
  final file = File('lib/services/localization_service.dart');
  var content = file.readAsStringSync();

  final viInsert = """
      // Event Categories
      'cat_love': 'Tình yêu',
      'cat_wedding': 'Cưới xin',
      'cat_birthday': 'Sinh nhật',
      'cat_family': 'Gia đình',
      'cat_festival': 'Lễ hội',
      'cat_education': 'Học tập',
      'cat_gratitude': 'Tri ân',
      'cat_achievement': 'Thành tựu',
      'cat_national': 'Quốc gia',
      'cat_profession': 'Nghề nghiệp',
      'cat_awareness': 'Nhận thức',
      'cat_other': 'Khác',
""";

  final enInsert = """
      // Event Categories
      'cat_love': 'Love',
      'cat_wedding': 'Wedding',
      'cat_birthday': 'Birthday',
      'cat_family': 'Family',
      'cat_festival': 'Festival',
      'cat_education': 'Education',
      'cat_gratitude': 'Gratitude',
      'cat_achievement': 'Achievement',
      'cat_national': 'National',
      'cat_profession': 'Profession',
      'cat_awareness': 'Awareness',
      'cat_other': 'Other',
""";

  content = content.replaceFirst(
    "      'card_days_passed': '✓ Đã qua {days} ngày',\n    },",
    "      'card_days_passed': '✓ Đã qua {days} ngày',\n$viInsert    },"
  );

  content = content.replaceFirst(
    "      'card_days_passed': '✓ Passed {days} days',\n    }",
    "      'card_days_passed': '✓ Passed {days} days',\n$enInsert    }"
  );

  file.writeAsStringSync(content);
  print('Added category keys!');
}
