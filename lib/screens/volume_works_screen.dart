import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/volume_works_viewmodel.dart';
import '../viewmodels/remote_config_provider.dart';
import '../widgets/publication_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import 'publication_detail_screen.dart';

// Danh sách bài báo trong 1 volume cụ thể của 1 journal — mở từ tab "Volumes
// gần đây" của JournalDetailScreen. Không cần scope (volume đã tự đủ ràng
// buộc journal + volume, không liên quan lĩnh vực).
class VolumeWorksScreen extends StatelessWidget {
  final String journalId;
  final String journalName;
  final String volume;

  const VolumeWorksScreen({
    super.key,
    required this.journalId,
    required this.journalName,
    required this.volume,
  });

  @override
  Widget build(BuildContext context) {
    final papersPerPage = context
        .read<RemoteConfigProvider>()
        .maxPapersDisplayed;
    return ChangeNotifierProvider(
      create: (_) => VolumeWorksViewModel()
        ..load(
          journalId: journalId,
          volume: volume,
          papersPerPage: papersPerPage,
        ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '$journalName · Volume $volume',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: Consumer<VolumeWorksViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return const LoadingWidget(message: 'Đang tải bài báo...');
            }
            if (vm.isError) {
              return AppErrorWidget(
                message: vm.errorMessage ?? 'Đã xảy ra lỗi.',
                onRetry: () => vm.load(
                  journalId: journalId,
                  volume: volume,
                  papersPerPage: papersPerPage,
                ),
              );
            }
            if (vm.works.isEmpty) {
              return const EmptyResultWidget(
                message: 'Không có bài báo nào trong volume này.',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: vm.works.length,
              itemBuilder: (context, index) {
                final work = vm.works[index];
                return PublicationCard(
                  key: ValueKey('volume_publication_card_$index'),
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
