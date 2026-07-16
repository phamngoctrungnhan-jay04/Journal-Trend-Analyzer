import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/analysis_provider.dart';
import '../viewmodels/remote_config_provider.dart';
import '../models/journal.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../widgets/ranked_bar_list.dart';
import 'journal_detail_screen.dart';

class JournalsScreen extends StatelessWidget {
  const JournalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Journals')),
      body: Consumer<AnalysisProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const LoadingWidget(message: 'Đang tải dữ liệu journal...');
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
          final maxDisplayed =
              context.watch<RemoteConfigProvider>().maxJournalsDisplayed;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: RankedBarList<TopJournal>(
              items: provider.topJournals.take(maxDisplayed).toList(),
              nameOf: (j) => j.displayName,
              countOf: (j) => j.worksCount,
              onTap: (j) {
                provider.logViewJournal(j);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => JournalDetailScreen(
                      journal: j,
                      topic: provider.currentTopic,
                    ),
                  ),
                );
              },
              icon: Icons.library_books_rounded,
              title: 'Top tạp chí nghiên cứu',
              subtitle: 'Xếp hạng theo số bài báo · ${provider.currentTopic}',
              emptyMessage: 'Không có dữ liệu journal.',
            ),
          );
        },
      ),
    );
  }
}
