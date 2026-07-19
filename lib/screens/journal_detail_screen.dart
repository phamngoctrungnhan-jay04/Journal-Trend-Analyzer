import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/journal.dart';
import '../models/work.dart';
import '../models/research_scope.dart';
import '../viewmodels/journal_detail_viewmodel.dart';
import '../viewmodels/remote_config_provider.dart';
import '../utils/constants.dart';
import '../utils/text_utils.dart';
import '../widgets/publication_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../widgets/stat_card.dart';
import '../widgets/yearly_trend_chart.dart';
import 'publication_detail_screen.dart';
import 'volume_works_screen.dart';

// scope null khi vào từ JournalSearchField (tìm journal trực tiếp, không qua
// chọn lĩnh vực) -> tab "Bài nổi bật" khi đó là CẢ journal, không giới hạn
// lĩnh vực nào.
class JournalDetailScreen extends StatelessWidget {
  final TopJournal journal;
  final ResearchScope? scope;

  const JournalDetailScreen({super.key, required this.journal, this.scope});

  @override
  Widget build(BuildContext context) {
    final papersPerPage = context
        .read<RemoteConfigProvider>()
        .maxPapersDisplayed;
    return ChangeNotifierProvider(
      create: (_) => JournalDetailViewModel()
        ..load(
          scope: scope,
          journalId: journal.id,
          papersPerPage: papersPerPage,
        ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(journal.displayName, overflow: TextOverflow.ellipsis),
        ),
        body: Consumer<JournalDetailViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return const LoadingWidget(
                message: 'Đang tải thông tin journal...',
              );
            }
            if (vm.isError) {
              return AppErrorWidget(
                message: vm.errorMessage ?? 'Đã xảy ra lỗi.',
                onRetry: () => vm.load(
                  scope: scope,
                  journalId: journal.id,
                  papersPerPage: papersPerPage,
                ),
              );
            }
            return DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  _StatsHeader(vm: vm),
                  const Material(
                    color: Colors.white,
                    child: TabBar(
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textHint,
                      indicatorColor: AppColors.primary,
                      tabs: [
                        Tab(text: 'Xu hướng'),
                        Tab(text: 'Volumes'),
                        Tab(text: 'Bài nổi bật'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _TrendTab(trends: vm.yearlyTrends),
                        _VolumesTab(journal: journal, volumes: vm.volumes),
                        _FeaturedWorksTab(vm: vm),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// Header thống kê: publisher + năm hoạt động (dòng chữ), rồi 2 hàng StatCard
// (tổng bài báo/TB trích dẫn, h-index/OA). detail null hiếm khi xảy ra (chỉ
// null nếu load() chưa xong, nhưng khối này chỉ build ở state success) —
// vẫn thủ optional để không crash nếu getJournalById() trả JSON thiếu field.
class _StatsHeader extends StatelessWidget {
  final JournalDetailViewModel vm;

  const _StatsHeader({required this.vm});

  @override
  Widget build(BuildContext context) {
    final detail = vm.detail;
    final subtitleParts = [
      if (detail != null && detail.publisherName.isNotEmpty)
        detail.publisherName,
      if (detail?.firstPublicationYear != null &&
          detail?.lastPublicationYear != null)
        '${detail!.firstPublicationYear}–${detail.lastPublicationYear}',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtitleParts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                subtitleParts.join(' · '),
                style: AppTextStyles.bodySecondary,
              ),
            ),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  compact: true,
                  icon: Icons.article_rounded,
                  title: 'Tổng bài báo',
                  value: TextUtils.formatCount(
                    detail?.worksCount ?? vm.works.length,
                  ),
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatCard(
                  compact: true,
                  icon: Icons.format_quote_rounded,
                  title: 'TB trích dẫn',
                  value: vm.averageCitation.toStringAsFixed(1),
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          if (detail?.hIndex != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    compact: true,
                    icon: Icons.emoji_events_rounded,
                    title: 'H-index',
                    value: detail!.hIndex.toString(),
                    color: const Color(0xFF43A047),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    compact: true,
                    icon: Icons.lock_open_rounded,
                    title: 'Open Access',
                    value: detail.isOa ? 'Có' : 'Không',
                    color: const Color(0xFFFB8C00),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// Tab "Xu hướng": số bài xuất bản theo năm của CHÍNH journal này (không giới
// hạn lĩnh vực) — tái dùng YearlyTrendChart đang dùng ở Keywords, widget đã
// tự xử lý trường hợp rỗng.
class _TrendTab extends StatelessWidget {
  final List<YearlyTrend> trends;

  const _TrendTab({required this.trends});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: YearlyTrendChart(trends: trends),
    );
  }
}

// Tab: mỗi dòng 1 volume, tap mở VolumeWorksScreen. group_by=biblio.volume
// mặc định xếp theo số bài nhiều nhất chứ không phải mới nhất -> viewmodel
// đã tự lọc theo năm + sắp lại giảm dần, ở đây chỉ hiển thị.
class _VolumesTab extends StatelessWidget {
  final TopJournal journal;
  final List<JournalVolume> volumes;

  const _VolumesTab({required this.journal, required this.volumes});

  @override
  Widget build(BuildContext context) {
    if (volumes.isEmpty) {
      return const EmptyResultWidget(
        message: 'Không có volume nào trong vài năm gần đây.',
      );
    }
    final shown = volumes.take(AppConstants.maxVolumesDisplayed).toList();
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: shown.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final v = shown[index];
        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            key: ValueKey('journal_volume_${v.volume}'),
            leading: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            title: Text(
              'Volume ${v.volume}',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${TextUtils.formatCount(v.worksCount)} bài báo',
              style: AppTextStyles.caption,
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint,
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VolumeWorksScreen(
                  journalId: journal.id,
                  journalName: journal.displayName,
                  volume: v.volume,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Tab 2: danh sách bài nổi bật — nội dung y hệt JournalDetailScreen trước khi
// có tab Volumes, chỉ đổi tên class.
class _FeaturedWorksTab extends StatelessWidget {
  final JournalDetailViewModel vm;

  const _FeaturedWorksTab({required this.vm});

  @override
  Widget build(BuildContext context) {
    if (vm.works.isEmpty) {
      return const EmptyResultWidget(
        message: 'Không có bài báo nào trong journal này.',
      );
    }
    return ListView.builder(
      key: const Key('journal_featured_works_list'),
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: vm.works.length,
      itemBuilder: (context, index) {
        final work = vm.works[index];
        return PublicationCard(
          key: ValueKey('journal_publication_card_$index'),
          work: work,
          rank: index + 1,
          onTap: () {
            vm.logViewPublication(work);
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
