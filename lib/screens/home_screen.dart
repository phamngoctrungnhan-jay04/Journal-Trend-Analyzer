import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/search_provider.dart';
import '../viewmodels/analysis_provider.dart';
import '../utils/constants.dart';
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

  void _search(String query) {
    if (query.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    context.read<SearchProvider>().search(query);
    context.read<AnalysisProvider>().analyze(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    suffixIcon: null,
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: _search,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                key: const Key('home_search_button'),
                onPressed: () => _search(_searchController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                child: const Text('Tìm'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: AppConstants.suggestedTopics.map((topic) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(topic),
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide.none,
                    onPressed: () {
                      _searchController.text = topic;
                      _search(topic);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.science_rounded,
            size: 80,
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Khám phá xu hướng nghiên cứu',
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhập chủ đề hoặc chọn gợi ý phía trên',
            style: AppTextStyles.bodySecondary,
          ),
        ],
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
          padding: const EdgeInsets.all(16),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.surface,
      child: Text(
        'Tìm thấy ${_formatCount(provider.totalResults)} bài báo cho "${provider.currentQuery}"',
        style: AppTextStyles.bodySecondary,
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}
