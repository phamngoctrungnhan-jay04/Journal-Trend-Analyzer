import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/keyword.dart';
import '../models/research_scope.dart';
import '../viewmodels/keyword_detail_viewmodel.dart';
import '../utils/constants.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../widgets/author_list_tile.dart';
import '../widgets/yearly_trend_chart.dart';
import '../widgets/ranked_bar_list.dart';
import 'keyword_works_screen.dart';
import 'author_works_screen.dart';

class KeywordDetailScreen extends StatelessWidget {
  final Keyword keyword;
  final ResearchScope scope;

  const KeywordDetailScreen({
    super.key,
    required this.keyword,
    required this.scope,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => KeywordDetailViewModel()
        ..load(
          scope: scope,
          keywordId: keyword.id,
          keywordName: keyword.displayName,
        ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(keyword.displayName, overflow: TextOverflow.ellipsis),
        ),
        body: Consumer<KeywordDetailViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return const LoadingWidget(
                message: 'Đang tải dữ liệu keyword...',
              );
            }
            if (vm.isError) {
              return AppErrorWidget(
                message: vm.errorMessage ?? 'Đã xảy ra lỗi.',
                onRetry: () => vm.load(
                  scope: scope,
                  keywordId: keyword.id,
                  keywordName: keyword.displayName,
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                YearlyTrendChart(trends: vm.yearlyTrends),
                if (vm.relatedKeywords.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  RankedBarList<Keyword>(
                    items: vm.relatedKeywords,
                    nameOf: (k) => k.displayName,
                    countOf: (k) => k.worksCount,
                    onTap: (k) => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => KeywordWorksScreen(
                          matchFilter: 'keywords.id:${k.id}',
                          title: k.displayName,
                        ),
                      ),
                    ),
                    icon: Icons.label_rounded,
                    title: 'Từ khóa liên quan',
                    subtitle: 'Xếp hạng theo tần suất xuất hiện',
                  ),
                ],
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
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AuthorWorksScreen(
                            authorId: entry.value.id,
                            authorName: entry.value.displayName,
                          ),
                        ),
                      ),
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
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.person_rounded,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Top tác giả đóng góp nhiều nhất',
                style: AppTextStyles.heading3,
              ),
              Text(
                'Xếp hạng theo số bài báo · ${scope.label}',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
