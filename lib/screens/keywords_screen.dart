import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/analysis_provider.dart';
import '../viewmodels/remote_config_provider.dart';
import '../models/keyword.dart';
import '../utils/constants.dart';
import '../utils/topic_actions.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../widgets/ranked_bar_list.dart';
import 'keyword_detail_screen.dart';

// Keywords có ô search RIÊNG: có thể tìm chủ đề ngay tại đây, không cần quay về
// Home. Gõ tìm ở đây dùng chung action selectTopic() nên cũng cập nhật chủ đề
// toàn cục -> Home/Journals cùng phản chiếu.
class KeywordsScreen extends StatefulWidget {
  const KeywordsScreen({super.key});

  @override
  State<KeywordsScreen> createState() => _KeywordsScreenState();
}

class _KeywordsScreenState extends State<KeywordsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search(String query) => selectTopic(context, query);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Keywords')),
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
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: const Key('keywords_search_field'),
              controller: _searchController,
              style: const TextStyle(color: Colors.black87),
              decoration: const InputDecoration(
                hintText: 'Tìm từ khoá theo chủ đề...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            key: const Key('keywords_search_button'),
            onPressed: () => _search(_searchController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            child: const Text('Tìm'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<AnalysisProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const LoadingWidget(message: 'Đang tải dữ liệu keyword...');
        }
        if (provider.isError) {
          return AppErrorWidget(
            message: provider.errorMessage ?? 'Đã xảy ra lỗi.',
            onRetry: () => provider.analyze(provider.currentTopic),
          );
        }
        if (provider.isInitial) {
          return const EmptyResultWidget(
            message: 'Nhập một chủ đề phía trên để xem từ khoá nghiên cứu.',
          );
        }
        final maxDisplayed =
            context.watch<RemoteConfigProvider>().maxKeywordsDisplayed;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: RankedBarList<Keyword>(
            items: provider.topKeywords.take(maxDisplayed).toList(),
            nameOf: (k) => k.displayName,
            countOf: (k) => k.worksCount,
            onTap: (k) {
              provider.logViewKeyword(k);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => KeywordDetailScreen(
                    keyword: k,
                    topic: provider.currentTopic,
                  ),
                ),
              );
            },
            icon: Icons.label_rounded,
            title: 'Top từ khoá nghiên cứu',
            subtitle:
                'Xếp hạng theo tần suất xuất hiện · ${provider.currentTopic}',
            emptyMessage: 'Không có dữ liệu keyword.',
          ),
        );
      },
    );
  }
}
