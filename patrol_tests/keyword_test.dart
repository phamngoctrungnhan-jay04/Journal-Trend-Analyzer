import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common/pump_app.dart';

void main() {
  appTest('TC6 - Phân tích từ khoá hiển thị thống kê + danh sách', ($) async {
    await pumpAuthenticatedApp($);

    await $(const Key('nav_keywords')).tap();
    await analyzeKeyword($);

    // Thống kê tổng quan (mốc "đã phân tích xong") + danh sách từ khóa liên
    // quan (thay cho "Top từ khoá nghiên cứu" của luồng theo-lĩnh-vực cũ).
    await $('Tổng số bài báo').waitUntilVisible(timeout: searchTimeout);
    expect($('Tổng số bài báo'), findsOneWidget);
    expect($('Trending Keywords'), findsOneWidget);
  });

  appTest('TC7 - Xem chi tiết 1 từ khoá liên quan (bài báo chứa từ khoá đó)', (
    $,
  ) async {
    await pumpAuthenticatedApp($);

    await $(const Key('nav_keywords')).tap();
    await analyzeKeyword($);

    await waitFirstWithKeyPrefix($, 'trending_keyword_');
    await tapFirstWithKeyPrefix($, 'trending_keyword_');

    // KeywordWorksScreen: danh sách bài báo chứa đúng từ khoá vừa bấm.
    await $(
      const Key('keyword_publication_card_0'),
    ).waitUntilVisible(timeout: searchTimeout);
    expect($(const Key('keyword_publication_card_0')), findsOneWidget);
  });
}
