import 'dart:convert';
import 'package:http/http.dart' as http;

/// TÊN PROJECT FIREBASE CỦA BẠN
const String projectId = 'lovin-c69f3';

/// DANH SÁCH CÁC MÃ BẠN MUỐN THÊM NHANH
final List<Map<String, dynamic>> promosToAdd = [
  {
    "code": "TRUONGAN",
    "type": "premium",
    "description": "Premium vĩnh viễn",
    "maxUsage": 50,
    "expirationDate": "2026-12-31T23:59:59Z",
  }
];

void main() async {
  print('Đang tiến hành đẩy dữ liệu lên Firebase...');
  
  final String url = 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/promo_codes';

  for (var promo in promosToAdd) {
    // Chuyển đổi dữ liệu sang định dạng của Firestore REST API
    final Map<String, dynamic> fields = {
      "code": {"stringValue": promo["code"]},
      "type": {"stringValue": promo["type"]},
      "description": {"stringValue": promo["description"]},
      "usedCount": {"integerValue": 0},
    };

    if (promo.containsKey("maxUsage")) {
      fields["maxUsage"] = {"integerValue": promo["maxUsage"]};
    }
    if (promo.containsKey("unlockedEffectId")) {
      fields["unlockedEffectId"] = {"stringValue": promo["unlockedEffectId"]};
    }
    if (promo.containsKey("expirationDate")) {
      fields["expirationDate"] = {"timestampValue": promo["expirationDate"]};
    }

    final body = jsonEncode({"fields": fields});

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Đã thêm mã: ${promo["code"]}');
      } else {
        print('❌ Lỗi khi thêm mã ${promo["code"]}: ${response.body}');
      }
    } catch (e) {
      print('❌ Không thể kết nối: $e');
    }
  }
  
  print('Hoàn thành!');
}
