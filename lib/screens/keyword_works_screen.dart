import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/keyword_works_viewmodel.dart';
import '../viewmodels/remote_config_provider.dart';
import '../widgets/publication_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import 'publication_detail_screen.dart';

// Danh sách bài báo khớp 1 filter cụ thể — dùng chung cho "Từ khóa liên
// quan" (matchFilter: keywords.id:X) VÀ chính câu tìm người dùng vừa phân
// tích (matchFilter: resolvedFilter từ KeywordsProvider, có thể là
// keywords.id:X hoặc default.search:X). Không cần scope: matchFilter đã tự
// đủ ràng buộc, giống VolumeWorksScreen.
class KeywordWorksScreen extends StatelessWidget {
  final String matchFilter;
  final String title;

  const KeywordWorksScreen({
    super.key,
    required this.matchFilter,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final papersPerPage = context
        .read<RemoteConfigProvider>()
        .maxPapersDisplayed;
    return ChangeNotifierProvider(
      create: (_) =>
          KeywordWorksViewModel()
            ..load(matchFilter: matchFilter, papersPerPage: papersPerPage),
      child: Scaffold(
        appBar: AppBar(title: Text(title, overflow: TextOverflow.ellipsis)),
        body: Consumer<KeywordWorksViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return const LoadingWidget(message: 'Đang tải bài báo...');
            }
            if (vm.isError) {
              return AppErrorWidget(
                message: vm.errorMessage ?? 'Đã xảy ra lỗi.',
                onRetry: () => vm.load(
                  matchFilter: matchFilter,
                  papersPerPage: papersPerPage,
                ),
              );
            }
            if (vm.works.isEmpty) {
              return const EmptyResultWidget(
                message: 'Không có bài báo nào chứa từ khóa này.',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: vm.works.length,
              itemBuilder: (context, index) {
                final work = vm.works[index];
                return PublicationCard(
                  key: ValueKey('keyword_publication_card_$index'),
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
          },
        ),
      ),
    );
  }
}
