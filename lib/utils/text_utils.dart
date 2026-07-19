import 'dart:math' as math;

class TextUtils {
  TextUtils._();

  // Chọn interval "đẹp" (1/2/5 × 10^n, ~4 vạch chia) rồi làm tròn maxY LÊN
  // đúng bội số của interval đó. Lý do: fl_chart tự chèn thêm 1 nhãn NGAY TẠI
  // maxY nếu maxY không trùng đúng 1 mốc chia đều (xem
  // AxisChartHelper.iterateThroughAxis trong fl_chart) — với maxY thô kiểu
  // maxCount*1.2 (số lẻ, vd 83K), nhãn thừa đó luôn đứng sát nhãn mốc cuối
  // (vd 80K), chồng chữ lên nhau. Ép maxY khớp đúng bội interval loại bỏ hẳn
  // nhãn thừa này. Dùng chung cho mọi chart trục Y (bar chart, line chart).
  static ({double maxY, double interval}) niceAxis(num maxCount) {
    if (maxCount <= 0) return (maxY: 1, interval: 1);

    final target = maxCount * 1.2;
    final roughInterval = target / 4;
    final magnitude = math
        .pow(10, (math.log(roughInterval) / math.ln10).floor())
        .toDouble();
    final residual = roughInterval / magnitude;
    final niceResidual = residual <= 1
        ? 1.0
        : residual <= 2
        ? 2.0
        : residual <= 5
        ? 5.0
        : 10.0;
    final interval = niceResidual * magnitude;
    final maxY = interval * (target / interval).ceil();
    return (maxY: maxY, interval: interval);
  }

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
