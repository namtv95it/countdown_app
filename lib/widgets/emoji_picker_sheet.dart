import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EmojiPickerSheet extends StatelessWidget {
  static const List<String> commonEmojis = [
    '🎉', '🎂', '❤️', '💍', '👶', '🎓', '🏥', '🛫', '🚗', '🎄',
    '🏆', '⭐', '🔥', '💡', '🎵', '⚽', '🎮', '🍔', '🍺', '💰',
    '🎁', '🎈', '🎊', '👗', '🏠', '🐶', '🐈', '🌍', '🚀', '⏳',
    '👨‍👩‍👧‍👦', '💑', '🥂', '💻', '💼', '🏖️', '🏍️', '🌸', '🥂', '🎤'
  ];

  final Function(String) onEmojiSelected;

  const EmojiPickerSheet({super.key, required this.onEmojiSelected});

  static void show(BuildContext context, {required Function(String) onEmojiSelected}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => EmojiPickerSheet(onEmojiSelected: onEmojiSelected),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Thay đổi biểu tượng',
            style: GoogleFonts.quicksand(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: commonEmojis.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              itemBuilder: (context, index) {
                final emoji = commonEmojis[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onEmojiSelected(emoji);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
