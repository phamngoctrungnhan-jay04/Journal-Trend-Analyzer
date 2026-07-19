// Lưới lĩnh vực ở Home dựng bằng Row(crossAxisAlignment: stretch) lồng trong
// ListView — thế trận dễ dính lỗi "BoxConstraints forces an infinite height"
// (ListView cho con chiều cao vô hạn, stretch lại ép con cao đúng bằng Row).
// Lỗi này KHÔNG làm build fail và flutter analyze vẫn xanh: nó chỉ nổ lúc
// render, làm cả lưới trắng trơn. Test này là chốt chặn duy nhất bắt được nó.
//
// Viewport TEST mặc định rộng 800px (bằng máy tính bảng) — quá rộng so với
// điện thoại thật (~390-430px) nên nhiều lỗi bố cục chỉ lộ ra ở bề ngang hẹp
// sẽ không bị bắt nếu test chạy ở khổ mặc định. Ép viewport hẹp như điện
// thoại để test gần với điều kiện thật hơn.
//
// Lưu ý: bug "BOTTOM OVERFLOWED BY 20 PIXELS" từng gặp trên máy thật (card
// "Computer Science" xuống 2 dòng cạnh "Engineering" 1 dòng, IntrinsicHeight
// tính thiếu chiều cao) KHÔNG tái hiện được qua test này dù đã ép viewport
// hẹp — vì google_fonts không tải được font Plus Jakarta Sans thật trong môi
// trường test (không có mạng), Flutter dùng font dự phòng có kích thước chữ
// khác hẳn nên "Computer Science" không wrap giống máy thật. Fix ở
// field_grid.dart (SizedBox cố định 2 dòng) loại bỏ hẳn phần đo đạc mơ hồ đó
// nên vẫn đúng bất kể font nào, chỉ là test này không chứng minh được điều
// đó bằng cách tái hiện lỗi cũ.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:journal_trend_analyzer/viewmodels/taxonomy_provider.dart';
import 'package:journal_trend_analyzer/widgets/field_grid.dart';
import 'package:journal_trend_analyzer/utils/constants.dart';

void main() {
  testWidgets('FieldGrid render 26 lĩnh vực không lỗi', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => TaxonomyProvider(),
          child: Scaffold(body: FieldGrid(onSubfieldSelected: (_, _) {})),
        ),
      ),
    );
    await tester.pump();

    // Lỗi render (vd ép chiều cao vô hạn, hoặc overflow ở hàng có card 2
    // dòng cạnh card 1 dòng) sẽ nằm ở đây.
    expect(tester.takeException(), isNull);

    // Lưới phải vẽ được ít nhất card đầu tiên (Computer Science, id 17) —
    // đúng card từng tràn viền trên máy thật, cùng hàng với Engineering
    // (1 dòng).
    expect(find.byKey(const Key('field_card_17')), findsOneWidget);
    expect(find.text('Computer Science'), findsOneWidget);
    expect(find.text('Engineering'), findsOneWidget);
    expect(AppConstants.researchFields.length, 26);
  });
}
