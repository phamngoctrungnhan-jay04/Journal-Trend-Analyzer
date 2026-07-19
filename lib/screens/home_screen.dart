import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/research_scope.dart';
import '../models/keyword.dart';
import '../models/journal.dart';
import '../models/author.dart';
import '../viewmodels/home_provider.dart';
import '../utils/constants.dart';
import '../utils/text_utils.dart';
import '../widgets/field_grid.dart';
import '../widgets/taxonomy_search_field.dart';
import '../widgets/publication_card.dart';
import '../widgets/error_widget.dart';
import '../widgets/loading_widget.dart';
import '../widgets/stat_card.dart';
import '../widgets/yearly_trend_chart.dart';
import '../widgets/ranked_bar_list.dart';
import '../widgets/author_list_tile.dart';
import 'publication_detail_screen.dart';
import 'journal_detail_screen.dart';
import 'keyword_detail_screen.dart';
import 'author_works_screen.dart';

// Home có 2 trạng thái, phạm vi RIÊNG của tab này (không liên quan
// Journals/Keywords):
//   A. Chưa chọn -> ô tìm kiếm + lưới 26 lĩnh vực chính (bấm để mở lĩnh vực phụ
//      ngay tại chỗ). Ô tìm kiếm là lối tắt xuống thẳng tầng chủ đề (topic).
//   B. Đã chọn -> thanh chip bộ lọc + 3 tab con: Tổng quan / Xu hướng / Bài báo.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<HomeProvider>(
        builder: (context, provider, _) {
          if (!provider.hasScope) {
            return Column(
              children: [
                _Header(provider: provider),
                Expanded(
                  child: FieldGrid(
                    onSubfieldSelected: (subfield, parentLabel) =>
                        provider.load(subfield.toScope(parentLabel)),
                  ),
                ),
              ],
            );
          }
          return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                _Header(provider: provider),
                const Material(
                  color: Colors.white,
                  child: TabBar(
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textHint,
                    indicatorColor: AppColors.primary,
                    tabs: [
                      Tab(text: 'Tổng quan'),
                      Tab(text: 'Xu hướng'),
                      Tab(text: 'Bài báo'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _OverviewTab(provider: provider),
                      _TrendsTab(provider: provider),
                      _PapersTab(provider: provider),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Header gradient: luôn có ô tìm kiếm. Ở trạng thái B thêm thanh chip bộ lọc
// thay cho breadcrumb mũi tên cũ.
class _Header extends StatelessWidget {
  final HomeProvider provider;

  const _Header({required this.provider});

  @override
  Widget build(BuildContext context) {
    final scope = provider.scope;

    return Container(
      width: double.infinity,
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
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              scope == null ? _buildTitle() : _buildAppTitle(),
              const SizedBox(height: 16),
              TaxonomySearchField(
                keyPrefix: 'home_taxonomy',
                hintText: 'Tìm chủ đề nghiên cứu...',
                onSelected: provider.load,
              ),
              if (scope != null) ...[
                const SizedBox(height: 14),
                _FilterChipBar(scope: scope, onClear: provider.clear),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.insights_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chọn lĩnh vực nghiên cứu',
                style: AppTextStyles.heading2.copyWith(color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Tìm chủ đề hoặc chọn lĩnh vực bên dưới',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Ở trạng thái B tiêu đề rút gọn thành tên app — chi tiết phạm vi đang chọn
  // đã chuyển sang _FilterChipBar bên dưới.
  Widget _buildAppTitle() {
    return Text(
      AppConstants.appName,
      style: AppTextStyles.heading3.copyWith(color: Colors.white),
    );
  }
}

// Thanh chip bộ lọc: "Bộ lọc" + 1 chip cho mỗi cấp trong breadcrumb (có nút
// ×) + "Xóa bộ lọc". MVP: bấm bất kỳ đâu trên thanh (kể cả × của riêng 1
// chip) đều quay hẳn về lưới chọn lĩnh vực — không "lùi từng cấp" vì cần lưu
// thêm field-id trên subfield scope mới làm được, để dành sau nếu cần.
class _FilterChipBar extends StatelessWidget {
  final ResearchScope scope;
  final VoidCallback onClear;

  const _FilterChipBar({required this.scope, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final crumbs = [
      if (scope.parentLabel != null && scope.parentLabel!.isNotEmpty)
        ...scope.parentLabel!.split(' › '),
      scope.label,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ActionChip(
            key: const Key('home_open_filter_button'),
            avatar: const Icon(
              Icons.tune_rounded,
              size: 16,
              color: AppColors.primary,
            ),
            label: const Text('Bộ lọc'),
            labelStyle: AppTextStyles.chip,
            backgroundColor: Colors.white,
            side: BorderSide.none,
            onPressed: onClear,
          ),
          const SizedBox(width: 8),
          for (final crumb in crumbs) ...[
            Chip(
              label: Text(crumb),
              labelStyle: AppTextStyles.chip,
              backgroundColor: Colors.white,
              deleteIcon: const Icon(Icons.close_rounded, size: 16),
              onDeleted: onClear,
              side: BorderSide.none,
            ),
            const SizedBox(width: 8),
          ],
          TextButton(
            key: const Key('home_clear_filter_button'),
            onPressed: onClear,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('Xóa bộ lọc'),
          ),
        ],
      ),
    );
  }
}

// Tab 1: tiêu đề + 4 stat card + card tạp chí/tác giả nổi bật + list tác giả +
// breakdown theo chủ đề. Top 5 tạp chí/tác giả đầy đủ nằm ở tab Xu hướng
// (_TrendsTab) — Tổng quan chỉ cần điểm nổi bật (top 1), không lặp lại top 5.
class _OverviewTab extends StatelessWidget {
  final HomeProvider provider;

  const _OverviewTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading) {
      return const LoadingWidget(message: 'Đang tải dữ liệu...');
    }
    if (provider.isError) {
      return AppErrorWidget(
        message: provider.errorMessage ?? 'Đã xảy ra lỗi.',
        onRetry: provider.retry,
      );
    }

    final scope = provider.scope!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        Text(
          'Phân tích xu hướng: "${scope.label}"',
          style: AppTextStyles.heading2,
        ),
        const SizedBox(height: 4),
        Text(
          'Tổng quan thống kê dữ liệu bài báo và trích dẫn theo phân loại '
          'OpenAlex.',
          style: AppTextStyles.bodySecondary,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: StatCard(
                compact: true,
                icon: Icons.article_rounded,
                title: 'Tổng tài liệu',
                value: TextUtils.formatCount(provider.totalResults),
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StatCard(
                compact: true,
                icon: Icons.format_quote_rounded,
                title: 'Trích dẫn TB',
                value: provider.formattedAvgCitation,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: StatCard(
                compact: true,
                icon: Icons.trending_up_rounded,
                title: 'Năm sôi nổi',
                value: provider.peakYear?.year.toString() ?? 'N/A',
                color: const Color(0xFF43A047),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StatCard(
                compact: true,
                icon: Icons.lock_open_rounded,
                title: 'Tỷ lệ OA',
                value: provider.formattedOaRate,
                subtitle: 'Truy cập mở tự do',
                color: const Color(0xFFFB8C00),
              ),
            ),
          ],
        ),
        if (provider.topJournals.isNotEmpty) ...[
          const SizedBox(height: 20),
          _highlightCard(
            context,
            icon: Icons.library_books_rounded,
            color: AppColors.primary,
            label: 'Tạp chí xuất bản nhiều nhất',
            value: provider.topJournals.first.displayName,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => JournalDetailScreen(
                  journal: provider.topJournals.first,
                  scope: scope,
                ),
              ),
            ),
          ),
        ],
        if (provider.topAuthors.isNotEmpty) ...[
          const SizedBox(height: 14),
          _highlightCard(
            context,
            icon: Icons.person_rounded,
            color: AppColors.accent,
            label: 'Tác giả đóng góp nhiều nhất',
            value: provider.topAuthors.first.displayName,
          ),
          const SizedBox(height: 24),
          Text('Top tác giả đóng góp', style: AppTextStyles.heading3),
          const SizedBox(height: 12),
          ...provider.topAuthors
              .take(5)
              .toList()
              .asMap()
              .entries
              .map(
                (e) => AuthorListTile(
                  author: e.value,
                  rank: e.key + 1,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AuthorWorksScreen(
                        authorId: e.value.id,
                        authorName: e.value.displayName,
                      ),
                    ),
                  ),
                ),
              ),
        ],
        if (provider.topKeywords.isNotEmpty) ...[
          const SizedBox(height: 20),
          RankedBarList<Keyword>(
            items: provider.topKeywords.take(8).toList(),
            nameOf: (k) => k.displayName,
            countOf: (k) => k.worksCount,
            onTap: (k) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => KeywordDetailScreen(keyword: k, scope: scope),
              ),
            ),
            icon: Icons.donut_large_rounded,
            title: 'Phân bố theo chủ đề',
            subtitle: 'Các chủ đề liên quan trong ${scope.label}',
            emptyMessage: 'Không có dữ liệu.',
            showChart: false,
          ),
        ],
      ],
    );
  }

  // Card nổi bật 1 dòng dùng chung cho "Tạp chí xuất bản nhiều nhất" và "Tác
  // giả đóng góp nhiều nhất". onTap null -> không có chevron, không bấm được
  // (chưa có màn chi tiết tác giả trong app).
  Widget _highlightCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(label, style: AppTextStyles.caption),
        subtitle: Text(
          value,
          style: AppTextStyles.heading3,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: onTap != null
            ? const Icon(Icons.chevron_right_rounded, color: AppColors.textHint)
            : null,
        onTap: onTap,
      ),
    );
  }
}

// Tab 2: YearlyTrendChart (line chart theo năm) + top 5 tạp chí + top 5 tác
// giả đóng góp nhiều nhất — đặt cùng "Xu hướng" vì cả 3 đều là các góc nhìn
// xếp hạng/biến động theo thời gian của cùng phạm vi đang chọn.
class _TrendsTab extends StatelessWidget {
  final HomeProvider provider;

  const _TrendsTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading) {
      return const LoadingWidget(message: 'Đang tải dữ liệu...');
    }
    if (provider.isError) {
      return AppErrorWidget(
        message: provider.errorMessage ?? 'Đã xảy ra lỗi.',
        onRetry: provider.retry,
      );
    }

    final scope = provider.scope!;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        YearlyTrendChart(trends: provider.yearlyTrends),
        if (provider.topJournals.isNotEmpty) ...[
          const SizedBox(height: 24),
          RankedBarList<TopJournal>(
            items: provider.topJournals.take(5).toList(),
            nameOf: (j) => j.displayName,
            countOf: (j) => j.worksCount,
            onTap: (j) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => JournalDetailScreen(journal: j, scope: scope),
              ),
            ),
            icon: Icons.library_books_rounded,
            title: 'Top 5 tạp chí đóng góp nhiều nhất',
            subtitle: 'Xếp hạng theo số bài báo trong ${scope.label}',
            emptyMessage: 'Không có dữ liệu.',
            showChart: false,
          ),
        ],
        if (provider.topAuthors.isNotEmpty) ...[
          const SizedBox(height: 20),
          RankedBarList<TopAuthor>(
            items: provider.topAuthors.take(5).toList(),
            nameOf: (a) => a.displayName,
            countOf: (a) => a.worksCount,
            // Chưa có màn chi tiết tác giả trong app -> không bấm được.
            icon: Icons.person_rounded,
            title: 'Top 5 tác giả đóng góp nhiều nhất',
            subtitle: 'Xếp hạng theo số bài báo trong ${scope.label}',
            emptyMessage: 'Không có dữ liệu.',
            showChart: false,
          ),
        ],
      ],
    );
  }
}

// Tab 3: danh sách bài báo đầy đủ + cuộn vô hạn — nội dung dời từ
// publications_screen.dart (đã xoá) vào thẳng đây, không còn push màn riêng.
class _PapersTab extends StatefulWidget {
  final HomeProvider provider;

  const _PapersTab({required this.provider});

  @override
  State<_PapersTab> createState() => _PapersTabState();
}

class _PapersTabState extends State<_PapersTab> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      widget.provider.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;

    if (provider.works.isEmpty && provider.isError) {
      return AppErrorWidget(
        message: provider.errorMessage ?? 'Đã xảy ra lỗi.',
        onRetry: provider.retry,
      );
    }
    if (provider.works.isEmpty && provider.isLoading) {
      return ListView.builder(
        itemCount: 6,
        itemBuilder: (_, _) => const SkeletonCard(),
      );
    }
    if (provider.works.isEmpty) {
      return const EmptyResultWidget(message: 'Không có bài báo nào.');
    }

    return ListView.builder(
      key: const Key('publications_list'),
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
          key: ValueKey('publication_card_$index'),
          work: work,
          rank: index + 1,
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
    );
  }
}
