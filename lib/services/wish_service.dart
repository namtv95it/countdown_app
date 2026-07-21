import '../data/wish_templates.dart';

class WishService {
  /// Tạo danh sách lời chúc dựa trên thông tin người gửi, nhận và dịp.
  /// Trả về tối đa [count] lời chúc, shuffle ngẫu nhiên mỗi lần gọi.
  static List<String> generateWishes({
    required String sender,
    required String receiver,
    required String categoryId,
    int count = 5,
  }) {
    final all = WishTemplates.generate(
      sender: sender,
      receiver: receiver,
      categoryId: categoryId,
    );
    return all.take(count).toList();
  }
}
