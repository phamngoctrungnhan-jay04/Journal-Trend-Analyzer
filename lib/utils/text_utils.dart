class TextUtils {
  TextUtils._();

  // OpenAlex trả abstract dạng inverted index: {"word": [pos1, pos2], ...}
  // Hàm này tái tạo lại thành chuỗi text bình thường
  static String? decodeAbstract(Map<String, dynamic>? invertedIndex) {
    if (invertedIndex == null || invertedIndex.isEmpty) return null;

    final wordPositions = <int, String>{};

    invertedIndex.forEach((word, positions) {
      if (positions is List) {
        for (final pos in positions) {
          if (pos is int) {
            wordPositions[pos] = word;
          }
        }
      }
    });

    if (wordPositions.isEmpty) return null;

    final sortedPositions = wordPositions.keys.toList()..sort();
    return sortedPositions.map((pos) => wordPositions[pos]).join(' ');
  }

  // Rút gọn text dài, thêm "..." nếu vượt quá maxLength
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength).trimRight()}...';
  }

  // Format số lớn: 1500 -> "1.5K", 2000000 -> "2M"
  static String formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  // Làm sạch tên journal từ API (đôi khi có ký tự thừa)
  static String cleanJournalName(String? name) {
    if (name == null || name.trim().isEmpty) return 'Unknown Journal';
    return name.trim();
  }

  // Làm sạch tên tác giả
  static String cleanAuthorName(String? name) {
    if (name == null || name.trim().isEmpty) return 'Unknown Author';
    return name.trim();
  }
}
