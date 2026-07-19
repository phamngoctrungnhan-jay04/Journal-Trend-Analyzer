// rotationQuarterTurns + SideTitleWidget là cấu hình fl_chart đúng theo API,
// nhưng sai tổ hợp tham số (vd thiếu SideTitleWidget, để trục sai) chỉ nổ ra
// lúc RENDER — flutter analyze không bắt được vì đây toàn field hợp lệ về
// kiểu. Test này là chốt chặn duy nhất cho lỗi runtime đó, cùng vai trò với
// field_grid_smoke_test.dart.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/widgets/ranked_bar_list.dart';

void main() {
  testWidgets(
    'RankedBarList (showChart true) render horizontal bar chart không lỗi',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RankedBarList<int>(
              items: const [500, 300, 120],
              nameOf: (i) => 'Item $i',
              countOf: (i) => i,
              icon: Icons.library_books_rounded,
              title: 'Test',
              subtitle: 'Test subtitle',
            ),
          ),
        ),
      );
      await tester.pump();
      // duration: 400ms trong BarChart -> chờ animation chạy xong.
      await tester.pump(const Duration(milliseconds: 500));

      // Không lỗi lúc render là điều quan trọng nhất test này canh giữ; tên
      // "Item 500" khớp cả nhãn trục (chart) lẫn dòng danh sách bên dưới nên
      // dùng key ranked_item_1 (top 1) để khẳng định chắc chắn thay vì
      // find.text mơ hồ.
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('ranked_item_1')), findsOneWidget);
    },
  );
}
