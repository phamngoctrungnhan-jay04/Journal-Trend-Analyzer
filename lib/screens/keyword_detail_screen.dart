import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/keyword.dart';
import '../viewmodels/keyword_detail_viewmodel.dart';
import '../utils/constants.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../widgets/author_list_tile.dart';
import '../widgets/yearly_trend_chart.dart';

class KeywordDetailScreen extends StatelessWidget {
  final Keyword keyword;
  final String topic;

  const KeywordDetailScreen({
    super.key,
    required this.keyword,
    required this.topic,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => KeywordDetailViewModel()
        ..load(query: topic, keywordId: keyword.id),
      child: Scaffold(
        appBar: AppBar(
          title: Text(keyword.displayName, overflow: TextOverflow.ellipsis),
        ),
        body: Consumer<KeywordDetailViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return const LoadingWidget(message: 'Đang tải dữ liệu keyword...');
            }
            if (vm.isError) {
              return AppErrorWidget(
                message: vm.errorMessage ?? 'Đã xảy ra lỗi.',
                onRetry: () => vm.load(query: topic, keywordId: keyword.id),
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                YearlyTrendChart(trends: vm.yearlyTrends),
                const SizedBox(height: 24),
                _buildAuthorsHeader(),
                const SizedBox(height: 8),
                if (vm.topAuthors.isEmpty)
                  const EmptyResultWidget(message: 'Không có dữ liệu tác giả.')
                else
                  ...vm.topAuthors.asMap().entries.map(
                        (entry) => AuthorListTile(
                          author: entry.value,
                          rank: entry.key + 1,
                        ),
                      ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAuthorsHeader() {
    return Row(
      children: [
        const Icon(Icons.person_rounded, color: AppColors.primary, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Top tác giả đóng góp nhiều nhất', style: AppTextStyles.heading3),
              Text('Xếp hạng theo số bài báo · $topic', style: AppTextStyles.caption),
            ],
          ),
        ),
      ],
    );
  }
}
