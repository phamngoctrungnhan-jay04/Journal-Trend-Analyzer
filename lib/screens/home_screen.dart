import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/search_provider.dart';
import '../viewmodels/analysis_provider.dart';
import '../utils/constants.dart';
import '../utils/topic_actions.dart';
import '../utils/text_utils.dart';
import '../widgets/publication_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../widgets/stat_card.dart';
import '../widgets/yearly_trend_chart.dart';
import 'publication_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Lắng nghe scroll để load more khi gần cuối
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      context.read<SearchProvider>().loadMore();
    }
  }

  // Định tuyến qua action dùng chung: ghi lại chủ đề + nạp cả SearchProvider
  // lẫn AnalysisProvider, để Journals/Keywords cũng có dữ liệu theo chủ đề này.
  void _search(String query) {
    selectTopic(context, query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // Header gradient bo góc dưới, thay cho AppBar + thanh search phẳng cũ.
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: AppShadows.card,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.insights_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppConstants.appName,
                          style: AppTextStyles.heading2.copyWith(
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Phân tích xu hướng nghiên cứu',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('home_search_field'),
                      controller: _searchController,
                      style: const TextStyle(color: Colors.black87),
                      decoration: const InputDecoration(
                        hintText: 'Nhập chủ đề nghiên cứu...',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: _search,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      key: const Key('home_search_button'),
                      onPressed: () => _search(_searchController.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                      ),
                      child: const Text('Tìm'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: AppConstants.suggestedTopics.map((topic) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _headerChip(topic),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Chip trên header gradient: nền trắng, chữ tím - tương phản rõ.
  Widget _headerChip(String topic, {bool subtle = false}) {
    return ActionChip(
      label: Text(topic),
      labelStyle: AppTextStyles.chip.copyWith(
        color: subtle ? Colors.white : AppColors.primary,
      ),
      backgroundColor:
          subtle ? Colors.white.withValues(alpha: 0.18) : Colors.white,
      side: BorderSide.none,
      onPressed: () {
        _searchController.text = topic;
        _search(topic);
      },
    );
  }

  Widget _buildBody() {
    return Consumer<SearchProvider>(
      builder: (context, provider, _) {
        if (provider.isInitial) return _buildInitialState();
        if (provider.isLoading) return _buildLoadingState();
        if (provider.isError) {
          return AppErrorWidget(
            message: provider.errorMessage ?? 'Đã xảy ra lỗi.',
            onRetry: () => provider.search(provider.currentQuery),
          );
        }
        if (provider.works.isEmpty) {
          return EmptyResultWidget(
            message:
                'Không tìm thấy bài báo nào cho\n"${provider.currentQuery}"',
          );
        }
        return _buildResultsList(provider);
      },
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.science_rounded,
                size: 44,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Khám phá xu hướng nghiên cứu',
              style: AppTextStyles.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Nhập chủ đề hoặc chọn gợi ý phía trên',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (_, index) => const SkeletonCard(),
    );
  }

  // itemCount = 1 header (overview: stat cards + trend chart) + danh sách
  // publication (đã sort theo cited_by_count:desc từ OpenAlexService, nên
  // đóng luôn vai trò "Top Papers" cũ) + 1 loading footer nếu còn trang sau.
  Widget _buildResultsList(SearchProvider provider) {
    return Column(
      children: [
        _buildResultsHeader(provider),
        Expanded(
          child: ListView.builder(
            key: const Key('home_results_list'),
            controller: _scrollController,
            itemCount:
                1 + provider.works.length + (provider.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildOverviewSection();
              }
              final workIndex = index - 1;
              if (workIndex == provider.works.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final work = provider.works[workIndex];
              return PublicationCard(
                key: ValueKey('publication_card_$workIndex'),
                work: work,
                rank: workIndex + 1,
                onTap: () {
                  provider.logViewPublication(work);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PublicationDetailScreen(work: work),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewSection() {
    return Consumer<AnalysisProvider>(
      builder: (context, analysis, _) {
        if (analysis.isLoading) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: LinearProgressIndicator(),
          );
        }
        final stats = analysis.dashboardStats;
        if (!analysis.isSuccess || stats == null) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      value: analysis.topJournals.length.toString(),
                      subtitle: 'trong kết quả',
                      color: const Color(0xFFFB8C00),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              YearlyTrendChart(trends: analysis.yearlyTrends),
              const SizedBox(height: 8),
              const Divider(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResultsHeader(SearchProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Row(
        children: [
          const Icon(Icons.article_rounded,
              size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tìm thấy ${_formatCount(provider.totalResults)} bài báo cho "${provider.currentQuery}"',
              style: AppTextStyles.bodySecondary
                  .copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}
