import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'common/pump_app.dart';

// Build PDF + upload Storage thật (mạng), cần timeout rộng hơn.
const _exportTimeout = Duration(seconds: 45);

void main() {
  appTest('TC9 - Xuất báo cáo PDF và nhận URL tải về', ($) async {
    await pumpAuthenticatedApp($);
    // Cấp phiên Firebase thật (anonymous) để Storage getDownloadURL() có token
    // hợp lệ - FakeAuth chỉ fake tầng UI, không tạo phiên Firebase thật.
    await signInFirebaseAnon();

    // searchTopic chờ tới khi 'Tổng bài báo' hiện = AnalysisProvider.dashboardStats
    // đã sẵn sàng, điều kiện bắt buộc để ExportViewModel export được.
    await searchTopic($);

    await $(const Key('nav_profile')).tap();
    await $(const Key('export_pdf_button')).waitUntilVisible();
    // noSettle: ngay khi bấm, ExportViewModel hiện CircularProgressIndicator
    // (animation vô hạn) trong lúc build PDF + upload Storage. tap mặc định
    // (trySettle -> pumpAndTrySettle) sẽ cố pump tới khi cây widget đứng yên,
    // nhưng spinner không bao giờ đứng yên nên treo dưới LiveTestBinding của
    // Patrol. noSettle chỉ pump 1 frame rồi trả về; waitUntilVisible bên dưới
    // tự poll (pump 100ms/lần) nên vẫn bắt được dòng thành công khi upload xong.
    await $(const Key('export_pdf_button')).tap(
      settlePolicy: SettlePolicy.noSettle,
    );

    await $('Xuất báo cáo thành công!').waitUntilVisible(timeout: _exportTimeout);
    expect($('Xuất báo cáo thành công!'), findsOneWidget);
  });
}
