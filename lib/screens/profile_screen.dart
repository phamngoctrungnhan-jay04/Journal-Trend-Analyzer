import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/analysis_provider.dart';
import '../viewmodels/export_viewmodel.dart';
import '../utils/constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _exportViewModel = ExportViewModel();

  @override
  void dispose() {
    _exportViewModel.dispose();
    super.dispose();
  }

  void _export() {
    final analysis = context.read<AnalysisProvider>();
    final stats = analysis.dashboardStats;
    if (stats == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hãy tìm kiếm một chủ đề ở tab Home trước.'),
        ),
      );
      return;
    }
    _exportViewModel.exportReport(
      stats: stats,
      yearlyTrends: analysis.yearlyTrends,
      topJournals: analysis.topJournals,
      topAuthors: analysis.topAuthors,
      topKeywords: analysis.topKeywords,
    );
  }

  void _copyUrl(String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép URL vào clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ')),
      body: Consumer<AuthViewModel>(
        builder: (context, auth, _) {
          final user = auth.userProfile;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  backgroundImage: (user?.photoUrl != null)
                      ? NetworkImage(user!.photoUrl!)
                      : null,
                  child: user?.photoUrl == null
                      ? Text(
                          (user?.displayName?.isNotEmpty ?? false)
                              ? user!.displayName![0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user?.displayName ?? 'Người dùng',
                style: AppTextStyles.heading2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                user?.email ?? '',
                style: AppTextStyles.bodySecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildExportCard(),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                  title: const Text('Đăng xuất'),
                  onTap: () => context.read<AuthViewModel>().signOut(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExportCard() {
    return ListenableBuilder(
      listenable: _exportViewModel,
      builder: (context, _) {
        final vm = _exportViewModel;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('Xuất báo cáo', style: AppTextStyles.heading3),
                  ],
                ),
                const SizedBox(height: 12),
                if (vm.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (vm.isSuccess && vm.downloadUrl != null) ...[
                  const Text('Xuất báo cáo thành công!'),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _copyUrl(vm.downloadUrl!),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            vm.downloadUrl!,
                            style: const TextStyle(
                              color: AppColors.primary,
                              decoration: TextDecoration.underline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.copy_rounded, size: 18),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(onPressed: _export, child: const Text('Xuất lại')),
                ] else ...[
                  if (vm.isError)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        vm.errorMessage ?? 'Đã xảy ra lỗi.',
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ElevatedButton.icon(
                    onPressed: _export,
                    icon: const Icon(Icons.file_download_rounded),
                    label: const Text('Xuất báo cáo PDF'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
