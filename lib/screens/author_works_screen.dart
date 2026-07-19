import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/author_works_viewmodel.dart';
import '../viewmodels/remote_config_provider.dart';
import '../widgets/publication_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import 'publication_detail_screen.dart';

// Danh sách bài báo của 1 tác giả cụ thể — mở từ mục "Top tác giả đóng góp"
// (AuthorListTile) ở Home/Keywords/KeywordDetailScreen. Không cần scope:
// authorId đã tự đủ ràng buộc, giống KeywordWorksScreen.
class AuthorWorksScreen extends StatelessWidget {
  final String authorId;
  final String authorName;

  const AuthorWorksScreen({
    super.key,
    required this.authorId,
    required this.authorName,
  });

  @override
  Widget build(BuildContext context) {
    final papersPerPage = context
        .read<RemoteConfigProvider>()
        .maxPapersDisplayed;
    return ChangeNotifierProvider(
      create: (_) =>
          AuthorWorksViewModel()
            ..load(authorId: authorId, papersPerPage: papersPerPage),
      child: Scaffold(
        appBar: AppBar(
          title: Text(authorName, overflow: TextOverflow.ellipsis),
        ),
        body: Consumer<AuthorWorksViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return const LoadingWidget(message: 'Đang tải bài báo...');
            }
            if (vm.isError) {
              return AppErrorWidget(
                message: vm.errorMessage ?? 'Đã xảy ra lỗi.',
                onRetry: () =>
                    vm.load(authorId: authorId, papersPerPage: papersPerPage),
              );
            }
            if (vm.works.isEmpty) {
              return const EmptyResultWidget(
                message: 'Không có bài báo nào của tác giả này.',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: vm.works.length,
              itemBuilder: (context, index) {
                final work = vm.works[index];
                return PublicationCard(
                  key: ValueKey('author_publication_card_$index'),
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
