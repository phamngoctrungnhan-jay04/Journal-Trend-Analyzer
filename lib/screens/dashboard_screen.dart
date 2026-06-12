import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/analysis_provider.dart';
import '../utils/constants.dart';
import '../utils/text_utils.dart';
import '../widgets/stat_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import 'publication_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Research Dashboard'),
      ),
      body: Consumer<AnalysisProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const LoadingWidget(message: 'Đang tổng hợp dữ liệu...');
          }
          if (provider.isError) {
            return AppErrorWidget(
              message: provider.errorMessage ?? 'Đã xảy ra lỗi.',
              onRetry: () => provider.analyze(provider.currentTopic),
            );
          }
          if (provider.dashboardStats == null) {
            return const EmptyResultWidget(
              message: 'Chưa có dữ liệu. Hãy tìm kiếm một chủ đề trước.',
            );
          }
          return _buildDashboard(context, provider);
        },
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, AnalysisProvider provider) {
    final stats = provider.dashboardStats!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopicHeader(stats.topic),
          const SizedBox(height: 16),

          // Row 1: Total publications + Average citation
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.article_rounded,
                  title: 'Tổng bài báo',
                  value: TextUtils.formatCount(stats.totalPublications),
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.format_quote_rounded,
                  title: 'TB trích dẫn',
                  value: stats.formattedAvgCitation,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Most active year + Top journal count
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.trending_up_rounded,
                  title: 'Năm sôi động nhất',
                  value: stats.mostActiveYear?.toString() ?? 'N/A',
                  subtitle: stats.mostActiveYearCount != null
                      ? '${TextUtils.formatCount(stats.mostActiveYearCount!)} bài'
                      : null,
                  color: const Color(0xFF43A047),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.library_books_rounded,
                  title: 'Số journals',
                  value: provider.topJournals.length.toString(),
                  subtitle: 'trong kết quả',
                  color: const Color(0xFFFB8C00),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Top Journal
          if (stats.topJournal != null) ...[
            _SectionLabel(label: 'Top Journal'),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.library_books_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                title: Text(
                  stats.topJournal!.displayName,
                  style: AppTextStyles.heading3,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${TextUtils.formatCount(stats.topJournal!.worksCount)} bài báo',
                  style: AppTextStyles.bodySecondary,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Top Author
          if (stats.topAuthor != null) ...[
            _SectionLabel(label: 'Top Author'),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                  child: Text(
                    stats.topAuthor!.displayName.isNotEmpty
                        ? stats.topAuthor!.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                title: Text(
                  stats.topAuthor!.displayName,
                  style: AppTextStyles.heading3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${stats.topAuthor!.worksCount} bài báo',
                  style: AppTextStyles.bodySecondary,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Most Influential Paper
          if (stats.mostInfluentialPaper != null) ...[
            _SectionLabel(label: 'Bài báo có ảnh hưởng nhất'),
            const SizedBox(height: 8),
            Card(
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PublicationDetailScreen(
                      work: stats.mostInfluentialPaper!,
                    ),
                  ),
                ),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.emoji_events_rounded,
                              color: AppColors.warning,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${TextUtils.formatCount(stats.mostInfluentialPaper!.citedByCount)} lần trích dẫn',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textHint,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        stats.mostInfluentialPaper!.title,
                        style: AppTextStyles.heading3,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stats.mostInfluentialPaper!.firstAuthorName,
                        style: AppTextStyles.bodySecondary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildTopicHeader(String topic) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tổng quan nghiên cứu',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            topic,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: AppTextStyles.heading3),
      ],
    );
  }
}
