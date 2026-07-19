import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/keywords_provider.dart';
import '../models/keyword.dart';
import '../utils/constants.dart';
import '../utils/text_utils.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../widgets/stat_card.dart';
import '../widgets/yearly_trend_chart.dart';
import '../widgets/author_list_tile.dart';
import 'keyword_works_screen.dart';
import 'author_works_screen.dart';

// Tab Keywords: gõ MỘT câu tìm tự do rồi Enter là phân tích ngay từ khóa đó
// (không qua bước chọn lĩnh vực nào) — khác Home/Journals ở chỗ không cần
// scope. Xem KeywordsProvider.analyze để biết cách câu tìm được map sang
// filter OpenAlex (khớp entity keywords.id chuẩn, hoặc lùi về full-text nếu
// không khớp — thường là câu tiếng Việt).
class KeywordsScreen extends StatefulWidget {
  const KeywordsScreen({super.key});

  @override
  State<KeywordsScreen> createState() => _KeywordsScreenState();
}

class _KeywordsScreenState extends State<KeywordsScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<KeywordsProvider>().analyze(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phân tích từ khóa')),
      body: Column(
        children: [
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              key: const Key('keyword_search_field'),
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _submit(),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.15),
                hintText: 'Nhập từ khóa, vd: machine learning, nông nghiệp...',
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                suffixIcon: IconButton(
                  key: const Key('keyword_search_button'),
                  icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  onPressed: _submit,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Consumer<KeywordsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const LoadingWidget(message: 'Đang phân tích từ khóa...');
        }
        if (provider.isError) {
          return AppErrorWidget(
            message: provider.errorMessage ?? 'Đã xảy ra lỗi.',
            onRetry: provider.retry,
          );
        }
        if (provider.isInitial) {
          return const EmptyResultWidget(
            message:
                'Nhập một từ khóa để phân tích, vd: machine learning, nông nghiệp...',
          );
        }
        final hasData =
            provider.yearlyTrends.isNotEmpty ||
            provider.relatedKeywords.isNotEmpty ||
            provider.topAuthors.isNotEmpty;
        if (!hasData) {
          return const EmptyResultWidget(
            message: 'Không tìm thấy dữ liệu cho từ khóa này.',
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Kết quả cho: "${provider.resolvedLabel}"',
                      style: AppTextStyles.heading3,
                    ),
                  ),
                  TextButton.icon(
                    key: const Key('view_searched_keyword_works_button'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => KeywordWorksScreen(
                          matchFilter: provider.resolvedFilter,
                          title: provider.resolvedLabel,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.article_outlined, size: 18),
                    label: const Text('Xem bài báo'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      compact: true,
                      icon: Icons.article_rounded,
                      title: 'Tổng số bài báo',
                      value: TextUtils.formatCount(provider.totalWorksCount),
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StatCard(
                      compact: true,
                      icon: Icons.star_rounded,
                      title: 'Điểm đánh giá (TB trích dẫn/bài)',
                      value: provider.averageCitation.toStringAsFixed(1),
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              YearlyTrendChart(trends: provider.yearlyTrends),
              if (provider.relatedKeywords.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Trending Keywords', style: AppTextStyles.heading3),
                const SizedBox(height: 4),
                Text(
                  'Từ khóa xuất hiện nhiều cùng "${provider.resolvedLabel}"',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: provider.relatedKeywords
                      .map(
                        (k) => _TrendingKeywordCard(
                          keyword: k,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => KeywordWorksScreen(
                                matchFilter: 'keywords.id:${k.id}',
                                title: k.displayName,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 24),
              _buildAuthorsHeader(),
              const SizedBox(height: 8),
              if (provider.topAuthors.isEmpty)
                const EmptyResultWidget(message: 'Không có dữ liệu tác giả.')
              else
                ...provider.topAuthors.asMap().entries.map(
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
          ),
        );
      },
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
              Text('Xếp hạng theo số bài báo', style: AppTextStyles.caption),
            ],
          ),
        ),
      ],
    );
  }
}

// Card gọn cho 1 từ khóa liên quan xuất hiện nhiều cùng câu tìm — bấm vào
// mở KeywordWorksScreen (danh sách bài báo chứa đúng từ khóa đó).
class _TrendingKeywordCard extends StatelessWidget {
  final Keyword keyword;
  final VoidCallback onTap;

  const _TrendingKeywordCard({required this.keyword, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        key: ValueKey('trending_keyword_${keyword.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                keyword.displayName,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.trending_up_rounded,
                    size: 14,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Freq: ${TextUtils.formatCount(keyword.worksCount)}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
