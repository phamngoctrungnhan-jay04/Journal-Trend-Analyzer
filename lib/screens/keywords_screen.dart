import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/analysis_provider.dart';
import '../models/keyword.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../widgets/ranked_bar_list.dart';
import 'keyword_detail_screen.dart';

class KeywordsScreen extends StatelessWidget {
  const KeywordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Keywords')),
      body: Consumer<AnalysisProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const LoadingWidget(message: 'Đang tải dữ liệu keyword...');
          }
          if (provider.isError) {
            return AppErrorWidget(
              message: provider.errorMessage ?? 'Đã xảy ra lỗi.',
              onRetry: () => provider.analyze(provider.currentTopic),
            );
          }
          if (provider.isInitial) {
            return const EmptyResultWidget(
              message: 'Chưa có dữ liệu. Hãy tìm kiếm một chủ đề ở tab Home trước.',
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: RankedBarList<Keyword>(
              items: provider.topKeywords,
              nameOf: (k) => k.displayName,
              countOf: (k) => k.worksCount,
              onTap: (k) {
                provider.logViewKeyword(k);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => KeywordDetailScreen(
                      keyword: k,
                      topic: provider.currentTopic,
                    ),
                  ),
                );
              },
              icon: Icons.label_rounded,
              title: 'Top từ khoá nghiên cứu',
              subtitle: 'Xếp hạng theo tần suất xuất hiện · ${provider.currentTopic}',
              emptyMessage: 'Không có dữ liệu keyword.',
            ),
          );
        },
      ),
    );
  }
}
