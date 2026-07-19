import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/journals_provider.dart';
import '../viewmodels/remote_config_provider.dart';
import '../models/journal.dart';
import '../utils/constants.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../widgets/ranked_bar_list.dart';
import '../widgets/taxonomy_search_field.dart';
import '../widgets/journal_search_field.dart';
import 'journal_detail_screen.dart';

// Tab Journals có 2 kiểu tìm, chọn bằng SegmentedButton:
//   - Theo lĩnh vực (FR 4.5): chọn 1 lĩnh vực -> xem xếp hạng journal trong
//     lĩnh vực đó (JournalsProvider.load, hành vi gốc không đổi).
//   - Tìm tạp chí: gõ thẳng tên journal -> mở chi tiết ngay, không qua lĩnh
//     vực nào (JournalDetailScreen với scope: null).
// Mỗi kiểu có ô tìm kiếm RIÊNG và phạm vi RIÊNG — độc lập với Home/Keywords.
class JournalsScreen extends StatelessWidget {
  const JournalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Journals')),
      body: Column(
        children: [
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: const Column(
              children: [_ModeToggle(), SizedBox(height: 12), _SearchField()],
            ),
          ),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Consumer<JournalsProvider>(
      builder: (context, provider, _) {
        if (provider.mode == JournalsSearchMode.byJournal) {
          return const EmptyResultWidget(
            message: 'Tìm tên tạp chí phía trên để xem chi tiết.',
          );
        }

        if (provider.isLoading) {
          return const LoadingWidget(message: 'Đang tải dữ liệu journal...');
        }
        if (provider.isError) {
          return AppErrorWidget(
            message: provider.errorMessage ?? 'Đã xảy ra lỗi.',
            onRetry: provider.retry,
          );
        }
        final scope = provider.scope;
        if (provider.isInitial || scope == null) {
          return const EmptyResultWidget(
            message: 'Tìm một chủ đề phía trên để xem xếp hạng tạp chí.',
          );
        }
        final maxDisplayed = context
            .watch<RemoteConfigProvider>()
            .maxJournalsDisplayed;
        return SingleChildScrollView(
          key: const Key('journals_results_list'),
          padding: const EdgeInsets.all(20),
          child: RankedBarList<TopJournal>(
            items: provider.topJournals.take(maxDisplayed).toList(),
            nameOf: (j) => j.displayName,
            countOf: (j) => j.worksCount,
            onTap: (j) {
              provider.logViewJournal(j);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => JournalDetailScreen(journal: j, scope: scope),
                ),
              );
            },
            icon: Icons.library_books_rounded,
            title: 'Top tạp chí nghiên cứu',
            subtitle: 'Xếp hạng theo số bài báo · ${scope.fullLabel}',
            emptyMessage: 'Không có dữ liệu journal.',
          ),
        );
      },
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JournalsProvider>();
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<JournalsSearchMode>(
        key: const Key('journals_mode_toggle'),
        segments: const [
          ButtonSegment(
            value: JournalsSearchMode.byField,
            label: Text('Theo lĩnh vực'),
          ),
          ButtonSegment(
            value: JournalsSearchMode.byJournal,
            label: Text('Tìm tạp chí'),
          ),
        ],
        selected: {provider.mode},
        onSelectionChanged: (selected) => provider.setMode(selected.first),
        style: SegmentedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.14),
          foregroundColor: Colors.white,
          selectedBackgroundColor: Colors.white,
          selectedForegroundColor: AppColors.primary,
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JournalsProvider>();
    if (provider.mode == JournalsSearchMode.byJournal) {
      return JournalSearchField(
        hintText: 'Tìm tên tạp chí...',
        onSelected: (journal) => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => JournalDetailScreen(journal: journal),
          ),
        ),
      );
    }
    return TaxonomySearchField(
      keyPrefix: 'journals_taxonomy',
      hintText: 'Tìm chủ đề để xem tạp chí...',
      onSelected: (scope) => context.read<JournalsProvider>().load(scope),
    );
  }
}
