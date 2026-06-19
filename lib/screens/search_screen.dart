import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/search_provider.dart';
import '../providers/analysis_provider.dart';
import '../utils/constants.dart';
import '../widgets/publication_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import 'publication_detail_screen.dart';
import 'trend_analysis_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
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
  }

  void _navigateToAnalysis(String topic) {
    context.read<AnalysisProvider>().analyze(topic);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrendAnalysisScreen(topic: topic),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          Consumer<SearchProvider>(
            builder: (context, provider, _) {
              if (!provider.isSuccess || provider.currentQuery.isEmpty) {
                return const SizedBox.shrink();
              }
              return TextButton.icon(
                onPressed: () => _navigateToAnalysis(provider.currentQuery),
                icon: const Icon(Icons.bar_chart_rounded, color: Colors.white),
                label: const Text(
                  'Phân tích',
                  style: TextStyle(color: Colors.white),
                ),
              );
            },
          ),
        ],
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

  Widget _buildResultsList(SearchProvider provider) {
    return Column(
      children: [
        _buildResultsHeader(provider),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: provider.works.length + (provider.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == provider.works.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final work = provider.works[index];
              return PublicationCard(
                work: work,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PublicationDetailScreen(work: work),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultsHeader(SearchProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.surface,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Tìm thấy ${_formatCount(provider.totalResults)} bài báo cho "${provider.currentQuery}"',
              style: AppTextStyles.bodySecondary,
            ),
          ),
          TextButton.icon(
            onPressed: () => _navigateToAnalysis(provider.currentQuery),
            icon: const Icon(Icons.insights_rounded, size: 16),
            label: const Text('Xem phân tích'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
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
