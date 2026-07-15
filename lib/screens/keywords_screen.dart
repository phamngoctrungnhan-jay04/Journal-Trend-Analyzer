import 'package:flutter/material.dart';

import '../widgets/error_widget.dart';

// TODO (Stage 2, phần Keyword): thay bằng danh sách Keyword thật sau khi
// AnalysisProvider.topKeywords được thêm vào.
class KeywordsScreen extends StatelessWidget {
  const KeywordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Keywords')),
      body: const EmptyResultWidget(
        message: 'Tính năng Keywords đang được phát triển.',
      ),
    );
  }
}
