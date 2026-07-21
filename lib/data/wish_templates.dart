/// Template lời chúc theo danh mục sự kiện.
/// {sender} = tên người gửi, {receiver} = tên người nhận.
/// Mỗi danh mục có ngôn từ riêng, không lẫn lộn sang nhau.
class WishTemplates {
  static const Map<String, List<String>> _templates = {

    // ── Sinh nhật: tập trung vào ngày sinh, tuổi mới, niềm vui cá nhân ──
    'birthday': [
      '🎂 Chúc mừng sinh nhật {receiver} yêu quý! Hôm nay là ngày của {receiver} — chúc {receiver} luôn rạng rỡ, tràn đầy sức khỏe và mọi điều ước đều thành hiện thực. {sender} yêu {receiver} nhiều lắm! 🎉',
      '🎈 Happy Birthday {receiver}! Chúc {receiver} một ngày sinh nhật thật vui vẻ bên những người thân yêu, nụ cười mãi không tắt và trái tim luôn nhẹ nhàng hạnh phúc! — {sender} 🥳',
      '🕯️ Sinh nhật {receiver} rồi! {sender} chúc {receiver} mỗi ngày trôi qua đều ý nghĩa và tươi đẹp hơn. Chúc {receiver} mạnh khỏe, bình an và luôn được bao quanh bởi những người yêu thương! 🌟',
      '🎁 Nhân ngày đặc biệt này, {sender} gửi đến {receiver} lời chúc từ tận đáy lòng: Chúc {receiver} sinh nhật vui vẻ, sức khỏe dồi dào, cuộc sống ngập tràn niềm vui và may mắn! 🌈',
      '🌺 {receiver} ơi, hôm nay là ngày {receiver} chào đời — một ngày thật đáng để ăn mừng! {sender} chúc {receiver} luôn tươi trẻ, tỏa sáng và được yêu thương mỗi ngày nhé! 💫',
      '🍰 Chúc mừng sinh nhật {receiver}! Mong rằng ngày hôm nay sẽ là một trong những ngày đẹp nhất của {receiver}. {sender} gửi đến {receiver} thật nhiều yêu thương và lời chúc tốt đẹp nhất! 🎊',
      '✨ {receiver} sinh nhật vui nhé! {sender} chúc {receiver} luôn tỏa sáng như ánh nến trên chiếc bánh sinh nhật — ấm áp, lung linh và làm sáng bừng tất cả mọi người xung quanh! 🕯️',
    ],

    // ── Tình yêu: kỷ niệm tình cảm, yêu thương, gắn kết đôi lứa ──
    'love': [
      '❤️ {receiver} yêu ơi, nhân dịp kỷ niệm đặc biệt này, {sender} muốn nói rằng: cảm ơn {receiver} vì đã xuất hiện trong cuộc đời {sender}. Mỗi ngày bên {receiver} là một món quà tuyệt vời! 💕',
      '🌹 Gửi đến {receiver} — người {sender} trân trọng nhất trên đời! Hôm nay đánh dấu một khoảnh khắc thật đẹp trong hành trình yêu thương của chúng mình. {sender} yêu {receiver} mãi mãi! 💞',
      '💝 {receiver} ơi, mỗi khoảnh khắc bên {receiver} đều khiến {sender} trân trọng cuộc sống hơn. Hôm nay {sender} muốn nhắc {receiver} rằng: {receiver} là điều tuyệt vời nhất {sender} có được! 🥰',
      '🌸 Nhân kỷ niệm hôm nay, {sender} muốn nói với {receiver}: {sender} cực kỳ may mắn vì có {receiver} bên cạnh. Chúc tình yêu của chúng mình mãi nồng nàn và bền chặt theo năm tháng! 💑',
      '✨ Gửi {receiver} — người làm tim {sender} luôn đập nhịp yêu. Kỷ niệm hôm nay nhắc {sender} nhớ lại tất cả những khoảnh khắc đẹp bên {receiver}. Cảm ơn {receiver} vì đã là một phần không thể thiếu của {sender}! 🌺',
      '💌 {receiver} yêu dấu! Dù ngày tháng trôi qua, tình cảm {sender} dành cho {receiver} chưa bao giờ vơi đi — mà chỉ thêm sâu đậm hơn. {sender} yêu {receiver} nhiều hơn cả lời nói! 💘',
    ],

    // ── Cưới xin: hôn lễ, hạnh phúc gia đình mới, chúc phúc đôi uyên ương ──
    'wedding': [
      '💒 Chúc mừng hôn lễ của {receiver}! {sender} chân thành chúc đôi uyên ương trăm năm hạnh phúc, gia đình viên mãn, tình yêu mãi bền chặt như ngày đầu bên nhau! 💍',
      '🥂 Hân hạnh chứng kiến ngày trọng đại của {receiver}! {sender} xin gửi ngàn lời chúc phúc: Trăm năm hạnh phúc, gia đình hòa thuận, chung tay xây dựng tổ ấm yêu thương! 🌸',
      '💐 Hôm nay {receiver} bước vào trang mới đẹp nhất của cuộc đời. {sender} chúc đôi uyên ương luôn đồng hành, chia sẻ ngọt bùi, cùng nhau vượt qua mọi sóng gió cuộc đời! 🎊',
      '👫 {receiver} ơi, chúc mừng bạn đã tìm được người bạn đời để cùng đi trọn cuộc hành trình! {sender} cầu chúc đôi bạn mãi nắm tay nhau, yêu thương và vun đắp hạnh phúc mỗi ngày! 🌟',
      '🌺 Hoa cưới nở rộ, tình yêu viên mãn! {sender} kính chúc {receiver} và người bạn đời của mình một cuộc hôn nhân hạnh phúc, gia đình ấm êm và luôn tươi cười bên nhau! 🎉',
    ],

    // ── Gia đình: dịp họp mặt, kỷ niệm gia đình, sum vầy ──
    'family': [
      '👨‍👩‍👧 Nhân dịp đặc biệt của gia đình, {sender} gửi đến {receiver} và tất cả mọi người lời chúc: Gia đình mãi khỏe mạnh, hòa thuận, sum vầy và hạnh phúc bên nhau! 🏠',
      '❤️ {receiver} yêu quý! Gia đình là nơi luôn ấm áp và yêu thương nhất. {sender} chúc {receiver} và cả nhà luôn bình an, sức khỏe và những khoảnh khắc bên nhau thật ý nghĩa! 🌟',
      '🌸 Nhân dịp sum họp gia đình, {sender} gửi đến {receiver} và tất cả mọi người những lời chúc chân thành nhất: Mãi yêu thương, gắn kết và trân trọng từng phút giây bên nhau! 💝',
      '🏡 {receiver} ơi, {sender} chúc {receiver} và gia đình luôn có những bữa cơm ấm áp, những tiếng cười giòn tan và tình thân bền chặt theo năm tháng! 🥰',
      '🌻 Gia đình là kho báu quý giá nhất! {sender} gửi đến {receiver} lời chúc: Chúc gia đình luôn đầy ắp tiếng cười, mọi người mạnh khỏe và hạnh phúc trong từng khoảnh khắc nhỏ! 🍀',
    ],

    // ── Lễ hội: Tết, lễ truyền thống, chúc an khang thịnh vượng ──
    'festival': [
      '🧧 Chúc mừng năm mới! {sender} kính chúc {receiver} và gia đình một năm mới an khang thịnh vượng, vạn sự như ý, mọi điều ước đều thành hiện thực! 🌟',
      '🏮 Tết đến xuân về! {sender} gửi đến {receiver} lời chúc: Năm mới sức khỏe dồi dào, tài lộc phát tài, gia đình hòa thuận và mọi điều thuận lợi đến với {receiver}! 🎊',
      '🌺 Nhân dịp lễ hội đặc biệt, {sender} kính chúc {receiver} vui vẻ, bình an và tận hưởng những khoảnh khắc ý nghĩa bên gia đình và người thân! 🎉',
      '🌈 Mùa lễ hội rộn ràng đã đến! {sender} chúc {receiver} và cả nhà đón lễ thật trọn vẹn, ấm cúng và nhận được thật nhiều điều tốt lành trong dịp đặc biệt này! 💐',
      '🎋 Nhân mùa lễ, {sender} gửi đến {receiver} lời chúc phúc chân thành: Bình an, may mắn, sức khỏe và những điều tốt đẹp nhất trong cuộc sống! 🍀',
    ],

    // ── Học tập: tốt nghiệp, thi đỗ, hoàn thành chương trình học ──
    'education': [
      '🎓 Chúc mừng {receiver} đã tốt nghiệp xuất sắc! {sender} vô cùng tự hào về những nỗ lực không mệt mỏi của {receiver}. Chúc {receiver} mang tấm bằng này mở ra những cánh cửa tươi sáng phía trước! 📚',
      '⭐ {receiver} ơi, bạn đã làm được rồi! Tấm bằng hôm nay là minh chứng cho sự kiên trì và cố gắng của {receiver}. {sender} chúc {receiver} tiếp tục bước trên con đường học vấn và sự nghiệp rực rỡ! 🌟',
      '📖 Chúc mừng {receiver} vượt qua kỳ thi xuất sắc! {sender} ngưỡng mộ sự chăm chỉ của {receiver} và tin rằng đây chỉ là điểm khởi đầu cho những thành công lớn hơn đang chờ đón! 🏆',
      '🌟 Thành tích học tập của {receiver} thật đáng khâm phục! {sender} chúc {receiver} luôn giữ vững ngọn lửa đam mê học hỏi, không ngừng phát triển và chinh phục những đỉnh cao tri thức mới! 💪',
      '🎉 Chúc mừng {receiver} hoàn thành hành trình học tập! {sender} tự hào về {receiver} và mong {receiver} sẽ ứng dụng kiến thức để tạo nên những điều có giá trị cho bản thân và xã hội! 🌈',
    ],

    // ── Tri ân: cảm ơn thầy cô, người đã giúp đỡ, ngày lễ tri ân ──
    'gratitude': [
      '💐 {receiver} kính mến! Nhân ngày đặc biệt này, {sender} muốn bày tỏ lòng biết ơn sâu sắc đối với {receiver}. Những gì {receiver} đã dạy dỗ và dìu dắt {sender} là vô giá. Kính chúc {receiver} luôn mạnh khỏe và hạnh phúc! 🙏',
      '🌸 Gửi đến {receiver} — người {sender} luôn trân trọng và biết ơn! Cảm ơn {receiver} đã luôn tận tụy, hết lòng và là nguồn cảm hứng lớn trong cuộc đời {sender}. Chúc {receiver} mãi bình an và niềm vui! ❤️',
      '✨ {receiver} ơi, lời cảm ơn dù nhiều đến đâu cũng không thể nói hết lòng biết ơn của {sender}. Nhân ngày tri ân, {sender} chúc {receiver} luôn khỏe mạnh, hạnh phúc và nhận được nhiều yêu thương! 💝',
      '🌻 Kính gửi {receiver}! Những công lao và tâm huyết của {receiver} đã để lại dấu ấn sâu đậm trong lòng {sender}. {sender} kính chúc {receiver} sức khỏe dồi dào và luôn được trân trọng xứng đáng! 🌹',
    ],

    // ── Thành tựu: thăng chức, đạt mục tiêu, ăn mừng thành công ──
    'achievement': [
      '🏆 Chúc mừng {receiver} đã đạt được thành công lớn! {sender} thật sự tự hào và ngưỡng mộ sự kiên trì, nỗ lực không ngừng của {receiver}. Đây là phần thưởng xứng đáng cho những cố gắng của bạn! 🌟',
      '🥂 Chúc mừng {receiver}! Thành tích hôm nay là kết quả của bao ngày nỗ lực và cống hiến. {sender} chúc {receiver} tiếp tục gặt hái nhiều thành công hơn nữa trên con đường phía trước! 🚀',
      '🎊 {receiver} đã chinh phục được mục tiêu rồi! {sender} vô cùng tự hào và gửi đến {receiver} lời chúc mừng chân thành nhất. Chúc {receiver} tiếp tục vươn cao, chinh phục những đỉnh cao mới! 💪',
      '⭐ Thành công của {receiver} là nguồn cảm hứng cho tất cả mọi người! {sender} chúc mừng và tin rằng đây chỉ là khởi đầu — {receiver} sẽ còn tiến xa hơn nữa với tài năng và quyết tâm của mình! 🎉',
      '🌟 {receiver} xứng đáng với thành công này! {sender} biết {receiver} đã nỗ lực thế nào để đạt được điều này. Chúc mừng và mong {receiver} tiếp tục sải bước trên hành trình chinh phục ước mơ! 🌈',
    ],

    // ── Khác: dịp chung, không xác định ──
    'other': [
      '🌟 Gửi đến {receiver}, nhân dịp đặc biệt này {sender} xin gửi những lời chúc tốt đẹp nhất. Chúc {receiver} luôn bình an, sức khỏe, vui vẻ và những điều tốt lành nhất! 😊',
      '💐 {receiver} ơi! {sender} muốn gửi đến {receiver} những yêu thương và lời chúc chân thành từ tận đáy lòng. Chúc {receiver} ngày hôm nay và mãi về sau đều tràn đầy hạnh phúc! ✨',
      '🎉 Nhân dịp đặc biệt này, {sender} gửi đến {receiver} niềm vui, may mắn và những điều tuyệt vời nhất. Chúc {receiver} luôn khỏe mạnh và đạt được mọi điều mình mong ước! 🌈',
    ],
  };

  /// Lấy danh sách template theo danh mục, tự điền tên vào.
  static List<String> generate({
    required String sender,
    required String receiver,
    required String categoryId,
  }) {
    final templates = _templates[categoryId] ?? _templates['other']!;
    final senderName = sender.trim().isEmpty ? 'Người gửi' : sender.trim();
    final receiverName = receiver.trim().isEmpty ? 'Bạn' : receiver.trim();

    return templates
        .map((t) => t
            .replaceAll('{sender}', senderName)
            .replaceAll('{receiver}', receiverName))
        .toList()
      ..shuffle();
  }
}
