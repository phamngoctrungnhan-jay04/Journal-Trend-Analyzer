import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/analysis_provider.dart';
import '../models/journal.dart';
import '../utils/constants.dart';
import '../widgets/publication_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../widgets/author_list_tile.dart';
import '../widgets/yearly_trend_chart.dart';
import '../widgets/ranked_bar_list.dart';
import 'publication_detail_screen.dart';
import 'dashboard_screen.dart';

class TrendAnalysisScreen extends StatefulWidget {
  final String topic;

  const TrendAnalysisScreen({super.key, required this.topic});

  @override
  State<TrendAnalysisScreen> createState() => _TrendAnalysisScreenState();
}

class _TrendAnalysisScreenState extends State<TrendAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Trigger analyze nếu chưa có dữ liệu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AnalysisProvider>();
      if (provider.currentTopic != widget.topic || provider.isInitial) {
        provider.analyze(widget.topic);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.topic,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard_rounded),
            tooltip: 'Dashboard',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Icons.show_chart_rounded, size: 18), text: 'Xu hướng'),
            Tab(icon: Icon(Icons.emoji_events_rounded, size: 18), text: 'Top Papers'),
            Tab(icon: Icon(Icons.library_books_rounded, size: 18), text: 'Journals'),
            Tab(icon: Icon(Icons.person_rounded, size: 18), text: 'Authors'),
          ],
        ),
      ),
      body: Consumer<AnalysisProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const LoadingWidget(message: 'Đang phân tích dữ liệu...');
          }
          if (provider.isError) {
            return AppErrorWidget(
              message: provider.errorMessage ?? 'Đã xảy ra lỗi.',
              onRetry: () => provider.analyze(widget.topic),
            );
          }
          if (provider.isInitial) {
            return const LoadingWidget(message: 'Đang chuẩn bị...');
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _TrendChartTab(provider: provider),
              _TopPapersTab(provider: provider),
              _TopJournalsTab(provider: provider),
              _TopAuthorsTab(provider: provider),
            ],
          );
        },
      ),
    );
  }
}

// ── Tab 1: Publication Trend by Year ────────────────────────────────────────

class _TrendChartTab extends StatelessWidget {
  final AnalysisProvider provider;

  const _TrendChartTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: YearlyTrendChart(trends: provider.yearlyTrends),
    );
  }
}

// ── Tab 2: Top Influential Papers ────────────────────────────────────────────

class _TopPapersTab extends StatelessWidget {
  final AnalysisProvider provider;

  const _TopPapersTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final papers = provider.topCitedWorks;
    if (papers.isEmpty) {
      return const EmptyResultWidget(message: 'Không có dữ liệu bài báo.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: _SectionHeader(
            icon: Icons.emoji_events_rounded,
            title: 'Top bài báo có ảnh hưởng nhất',
            subtitle: 'Xếp hạng theo số lần trích dẫn',
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: papers.length,
            itemBuilder: (context, index) {
              return PublicationCard(
                work: papers[index],
                rank: index + 1,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        PublicationDetailScreen(work: papers[index]),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Tab 3: Top Research Journals ─────────────────────────────────────────────

class _TopJournalsTab extends StatelessWidget {
  final AnalysisProvider provider;

  const _TopJournalsTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: RankedBarList<TopJournal>(
        items: provider.topJournals,
        nameOf: (j) => j.displayName,
        countOf: (j) => j.worksCount,
        icon: Icons.library_books_rounded,
        title: 'Top tạp chí nghiên cứu',
        subtitle: 'Xếp hạng theo số bài báo',
        emptyMessage: 'Không có dữ liệu journal.',
      ),
    );
  }
}

// ── Tab 4: Top Contributing Authors ──────────────────────────────────────────

class _TopAuthorsTab extends StatelessWidget {
  final AnalysisProvider provider;

  const _TopAuthorsTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final authors = provider.topAuthors;
    if (authors.isEmpty) {
      return const EmptyResultWidget(message: 'Không có dữ liệu tác giả.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: _SectionHeader(
            icon: Icons.person_rounded,
            title: 'Top tác giả đóng góp nhiều nhất',
            subtitle: 'Xếp hạng theo số bài báo',
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: authors.length,
            itemBuilder: (_, index) => AuthorListTile(
              author: authors[index],
              rank: index + 1,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.heading3),
              if (subtitle != null)
                Text(subtitle!, style: AppTextStyles.caption),
            ],
          ),
        ),
      ],
    );
  }
}
