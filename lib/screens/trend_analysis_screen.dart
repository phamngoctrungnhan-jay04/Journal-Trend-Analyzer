import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/analysis_provider.dart';
import '../models/journal.dart';
import '../utils/constants.dart';
import '../utils/text_utils.dart';
import '../widgets/publication_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../widgets/author_list_tile.dart';
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
    final trends = provider.yearlyTrends;
    if (trends.isEmpty) {
      return const EmptyResultWidget(message: 'Không có dữ liệu xu hướng.');
    }

    final maxCount = trends.map((t) => t.count).reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.show_chart_rounded,
            title: 'Xu hướng xuất bản theo năm',
            subtitle: '${trends.length} năm · ${trends.fold(0, (s, t) => s + t.count)} bài báo',
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 20, 20, 8),
              child: SizedBox(
                height: 280,
                child: BarChart(
                  BarChartData(
                    maxY: maxCount * 1.2,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => AppColors.primary,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final trend = trends[groupIndex];
                          return BarTooltipItem(
                            '${trend.year}\n${TextUtils.formatCount(trend.count)} bài',
                            const TextStyle(color: Colors.white, fontSize: 12),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= trends.length) {
                              return const SizedBox.shrink();
                            }
                            // Chỉ hiển thị tối đa ~7 nhãn để tránh chồng chữ;
                            // luôn hiển thị nhãn năm cuối cùng.
                            final step = (trends.length / 7).ceil();
                            final isLast = idx == trends.length - 1;
                            if (idx % step != 0 && !isLast) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                "'${trends[idx].year.toString().substring(2)}",
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 44,
                          getTitlesWidget: (value, meta) => Text(
                            TextUtils.formatCount(value.toInt()),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: Colors.grey.withValues(alpha: 0.2),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: trends.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final trend = entry.value;
                      return BarChartGroupData(
                        x: idx,
                        barRods: [
                          BarChartRodData(
                            toY: trend.count.toDouble(),
                            color: AppColors.primary,
                            width: trends.length > 20 ? 6 : 12,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildPeakYearCard(),
        ],
      ),
    );
  }

  Widget _buildPeakYearCard() {
    final peak = provider.yearlyTrends.reduce(
      (a, b) => a.count > b.count ? a : b,
    );
    return Card(
      color: AppColors.primary.withValues(alpha: 0.05),
      child: ListTile(
        leading: const Icon(Icons.star_rounded, color: AppColors.warning),
        title: const Text('Năm xuất bản nhiều nhất'),
        subtitle: Text('${TextUtils.formatCount(peak.count)} bài báo'),
        trailing: Text(
          peak.year.toString(),
          style: AppTextStyles.heading2.copyWith(color: AppColors.primary),
        ),
      ),
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
    final journals = provider.topJournals;
    if (journals.isEmpty) {
      return const EmptyResultWidget(message: 'Không có dữ liệu journal.');
    }

    final maxCount = journals.first.worksCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.library_books_rounded,
            title: 'Top tạp chí nghiên cứu',
            subtitle: 'Xếp hạng theo số bài báo',
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 20, 20, 8),
              child: SizedBox(
                height: (journals.length * 48).toDouble().clamp(200, 400),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.center,
                    maxY: maxCount * 1.2,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => AppColors.primary,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final j = journals[groupIndex];
                          return BarTooltipItem(
                            '${TextUtils.formatCount(j.worksCount)} bài',
                            const TextStyle(color: Colors.white, fontSize: 12),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 120,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= journals.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text(
                                TextUtils.truncate(journals[idx].displayName, 16),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) => Text(
                            TextUtils.formatCount(value.toInt()),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      drawHorizontalLine: false,
                      getDrawingVerticalLine: (_) => FlLine(
                        color: Colors.grey.withValues(alpha: 0.2),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: journals.asMap().entries.map((entry) {
                      final color = AppColors.chartColors[
                          entry.key % AppColors.chartColors.length];
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.worksCount.toDouble(),
                            color: color,
                            width: 16,
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(4),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                  duration: const Duration(milliseconds: 400),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...journals.asMap().entries.map((entry) =>
              _buildJournalListItem(entry.key + 1, entry.value, maxCount)),
        ],
      ),
    );
  }

  Widget _buildJournalListItem(int rank, TopJournal journal, int maxCount) {
    final fraction = (journal.worksCount / maxCount).clamp(0.0, 1.0);
    final color = AppColors.chartColors[(rank - 1) % AppColors.chartColors.length];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: rank <= 3 ? AppColors.primary : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  journal.displayName,
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fraction,
                    backgroundColor: color.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${TextUtils.formatCount(journal.worksCount)} bài',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
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
