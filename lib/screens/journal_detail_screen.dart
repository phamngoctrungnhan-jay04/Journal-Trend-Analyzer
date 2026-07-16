import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/journal.dart';
import '../viewmodels/journal_detail_viewmodel.dart';
import '../utils/constants.dart';
import '../widgets/publication_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../widgets/stat_card.dart';
import 'publication_detail_screen.dart';

class JournalDetailScreen extends StatelessWidget {
  final TopJournal journal;
  final String topic;

  const JournalDetailScreen({
    super.key,
    required this.journal,
    required this.topic,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => JournalDetailViewModel()
        ..load(query: topic, journalId: journal.id),
      child: Scaffold(
        appBar: AppBar(
          title: Text(journal.displayName, overflow: TextOverflow.ellipsis),
        ),
        body: Consumer<JournalDetailViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return const LoadingWidget(message: 'Đang tải bài báo...');
            }
            if (vm.isError) {
              return AppErrorWidget(
                message: vm.errorMessage ?? 'Đã xảy ra lỗi.',
                onRetry: () => vm.load(query: topic, journalId: journal.id),
              );
            }
            if (vm.works.isEmpty) {
              return const EmptyResultWidget(
                message: 'Không có bài báo nào trong journal này.',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: 1 + vm.works.length,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildStatsHeader(vm);
                }
                final work = vm.works[index - 1];
                return PublicationCard(
                  work: work,
                  rank: index,
                  onTap: () {
                    vm.logViewPublication(work);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PublicationDetailScreen(work: work),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsHeader(JournalDetailViewModel vm) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: StatCard(
              icon: Icons.article_rounded,
              title: 'Số bài báo',
              value: vm.works.length.toString(),
              subtitle: topic,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              icon: Icons.format_quote_rounded,
              title: 'TB trích dẫn',
              value: vm.averageCitation.toStringAsFixed(1),
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}
