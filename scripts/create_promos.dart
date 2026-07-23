import 'dart:convert';
import 'package:http/http.dart' as http;

/// TÊN PROJECT FIREBASE CỦA BẠN
const String projectId = 'lovin-c69f3';

/// DANH SÁCH CÁC MÃ BẠN MUỐN THÊM NHANH
final List<Map<String, dynamic>> promosToAdd = [
  {
    "code": "X9F4L2K8",
    "type": "premium",
    "description": "Premium vĩnh viễn",
    "maxUsage": 50,
    "expirationDate": "2026-12-31T23:59:59Z",
  },
  {
    "code": "M3N7B1V5",
    "type": "giftEffect",
    "unlockedEffectId": "hearts",
    "description": "Hiệu ứng Trái tim",
    "maxUsage": 999,
  },
  {
    "code": "Q8W2E6R4",
    "type": "giftEffect",
    "unlockedEffectId": "bubbles",
    "description": "Hiệu ứng Bong bóng",
    "maxUsage": 999,
  },
  {
    "code": "T5Y9U1I3",
    "type": "giftEffect",
    "unlockedEffectId": "snow",
    "description": "Hiệu ứng Tuyết rơi",
    "maxUsage": 999,
  },
  {
    "code": "O2P6A4S8",
    "type": "giftEffect",
    "unlockedEffectId": "stars",
    "description": "Hiệu ứng Ngôi sao",
    "maxUsage": 999,
  },
  {
    "code": "D7F1G5H9",
    "type": "giftEffect",
    "unlockedEffectId": "meteor",
    "description": "Hiệu ứng Sao băng",
    "maxUsage": 999,
  },
  {
    "code": "J3K8L2Z6",
    "type": "giftEffect",
    "unlockedEffectId": "rain",
    "description": "Hiệu ứng Mưa rơi",
    "maxUsage": 999,
  },
  {
    "code": "X1C5V9B4",
    "type": "giftEffect",
    "unlockedEffectId": "rain_ripple",
    "description": "Hiệu ứng Mưa gợn sóng",
    "maxUsage": 999,
  },
  {
    "code": "N6M2Q8W5",
    "type": "giftEffect",
    "unlockedEffectId": "rainbow",
    "description": "Hiệu ứng Cầu vồng",
    "maxUsage": 999,
  },
  {
    "code": "E3R7T1Y9",
    "type": "giftEffect",
    "unlockedEffectId": "waves",
    "description": "Hiệu ứng Sóng biển",
    "maxUsage": 999,
  },
  {
    "code": "U4I8O2P6",
    "type": "giftEffect",
    "unlockedEffectId": "leaves",
    "description": "Hiệu ứng Lá rơi",
    "maxUsage": 999,
  },
  {
    "code": "A5S9D3F7",
    "type": "giftEffect",
    "unlockedEffectId": "sunset_birds",
    "description": "Hiệu ứng Hoàng hôn",
    "maxUsage": 999,
  },
  {
    "code": "G1H5J9K4",
    "type": "giftEffect",
    "unlockedEffectId": "aurora",
    "description": "Hiệu ứng Cực quang",
    "maxUsage": 999,
  },
  {
    "code": "L8Z2X6C3",
    "type": "giftEffect",
    "unlockedEffectId": "fireflies",
    "description": "Hiệu ứng Đom đóm",
    "maxUsage": 999,
  },
  {
    "code": "V7B1N5M9",
    "type": "giftEffect",
    "unlockedEffectId": "fireworks",
    "description": "Hiệu ứng Pháo hoa",
    "maxUsage": 999,
  },
  {
    "code": "Q2W6E4R8",
    "type": "giftEffect",
    "unlockedEffectId": "cherry_blossom",
    "description": "Hiệu ứng Hoa anh đào",
    "maxUsage": 999,
  },
  {
    "code": "T9Y3U7I1",
    "type": "giftEffect",
    "unlockedEffectId": "galaxy",
    "description": "Hiệu ứng Ngân hà",
    "maxUsage": 999,
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
