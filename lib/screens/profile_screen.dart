import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/export_viewmodel.dart';
import '../viewmodels/notification_viewmodel.dart';
import '../viewmodels/bookmark_provider.dart';
import '../viewmodels/remote_config_provider.dart';
import '../models/app_notification.dart';
import '../models/work.dart';
import '../firebase/crash_service.dart';
import '../utils/constants.dart';
import '../widgets/taxonomy_search_field.dart';
import 'publication_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _exportViewModel = ExportViewModel();
  final _crashService = CrashService();

  @override
  void dispose() {
    _exportViewModel.dispose();
    super.dispose();
  }

  void _export() {
    if (!_exportViewModel.hasScope) return;
    _exportViewModel.exportReport();
  }

  Future<void> _triggerHandledException() async {
    try {
      throw Exception('Lỗi thử nghiệm (handled exception)');
    } catch (e, st) {
      await _crashService.recordHandledException(e, st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã ghi nhận lỗi lên Crashlytics')),
      );
    }
  }

  Future<void> _triggerTestCrash() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test crash Crashlytics'),
        content: const Text(
          'Ứng dụng sẽ crash và đóng ngay lập tức để test Crashlytics. Tiếp tục?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Crash ngay'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _crashService.triggerTestCrash();
    }
  }

  void _copyText(String text, String confirmMessage) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(confirmMessage)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthViewModel>(
        builder: (context, auth, _) {
          final user = auth.userProfile;
          return Column(
            children: [
              _buildProfileHeader(
                user?.displayName,
                user?.email,
                user?.photoUrl,
              ),
              Expanded(
                child: ListView(
                  key: const Key('profile_list'),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  children: [
                    _buildBookmarksCard(),
                    const SizedBox(height: 14),
                    _buildExportCard(),
                    const SizedBox(height: 14),
                    _buildNotificationCard(),
                    const SizedBox(height: 14),
                    _buildDisplaySettingsCard(),
                    const SizedBox(height: 14),
                    _buildDebugCard(),
                    const SizedBox(height: 14),
                    _buildLogoutCard(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Header gradient chứa avatar + tên + email.
  Widget _buildProfileHeader(String? name, String? email, String? photoUrl) {
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Hồ sơ',
                  style: AppTextStyles.heading3.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: Colors.white.withValues(alpha: 0.22),
                  backgroundImage: (photoUrl != null)
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl == null
                      ? Text(
                          (name?.isNotEmpty ?? false)
                              ? name![0].toUpperCase()
                              : '?',
                          style: AppTextStyles.heading1.copyWith(
                            color: Colors.white,
                            fontSize: 32,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                name ?? 'Người dùng',
                style: AppTextStyles.heading2.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                email ?? '',
                style: AppTextStyles.bodySecondary.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Header nhất quán cho các card: icon trong ô bo tròn màu + tiêu đề.
  Widget _cardHeader(
    IconData icon,
    String title, {
    Color color = AppColors.primary,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(title, style: AppTextStyles.heading3),
      ],
    );
  }

  Widget _buildLogoutCard() {
    return Card(
      child: ListTile(
        key: const Key('logout_button'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.logout_rounded,
            color: AppColors.error,
            size: 20,
          ),
        ),
        title: Text(
          'Đăng xuất',
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textHint,
        ),
        onTap: () => context.read<AuthViewModel>().signOut(),
      ),
    );
  }

  Widget _buildBookmarksCard() {
    return Consumer<BookmarkProvider>(
      builder: (context, bookmarks, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cardHeader(Icons.bookmark_rounded, 'Bài báo đã lưu'),
                const SizedBox(height: 12),
                if (bookmarks.bookmarks.isEmpty)
                  Text(
                    'Chưa lưu bài báo nào. Mở 1 bài báo và bấm dấu bookmark để lưu.',
                    style: AppTextStyles.bodySecondary,
                  )
                else
                  ...bookmarks.bookmarks.map(
                    (work) => _buildBookmarkTile(context, work),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookmarkTile(BuildContext context, Work work) {
    return Padding(
      key: ValueKey('bookmark_tile_${work.id}'),
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PublicationDetailScreen(work: work),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      work.title,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      work.firstAuthorName,
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                key: ValueKey('bookmark_remove_${work.id}'),
                icon: const Icon(
                  Icons.bookmark_rounded,
                  color: AppColors.primary,
                ),
                onPressed: () =>
                    context.read<BookmarkProvider>().remove(work.id),
              ),
            ],
          ),
        ),
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
                _cardHeader(Icons.picture_as_pdf_rounded, 'Xuất báo cáo'),
                const SizedBox(height: 6),
                Text(
                  'Chọn chủ đề muốn xuất báo cáo:',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 10),
                // Ô chọn phạm vi riêng cho việc xuất — không phụ thuộc tab nào.
                TaxonomySearchField(
                  hintText: 'Tìm chủ đề để xuất...',
                  onSelected: vm.selectScope,
                ),
                if (vm.hasScope) ...[
                  const SizedBox(height: 12),
                  _buildSelectedScope(vm),
                ],
                const SizedBox(height: 14),
                if (vm.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (vm.isSuccess && vm.downloadUrl != null) ...[
                  const Text('Xuất báo cáo thành công!'),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _copyText(
                      vm.downloadUrl!,
                      'Đã sao chép URL vào clipboard',
                    ),
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
                    key: const Key('export_pdf_button'),
                    // Khoá khi chưa chọn chủ đề — không còn gì để xuất.
                    onPressed: vm.hasScope ? _export : null,
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

  // Chip hiển thị chủ đề đang chọn để xuất, kèm breadcrumb nhánh cha.
  Widget _buildSelectedScope(ExportViewModel vm) {
    final scope = vm.scope!;
    return Container(
      key: const Key('export_selected_scope'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.topic_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scope.label,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (scope.parentLabel != null && scope.parentLabel!.isNotEmpty)
                  Text(
                    scope.parentLabel!,
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard() {
    return Consumer<NotificationViewModel>(
      builder: (context, vm, _) {
        return Card(
          key: const Key('notification_card'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cardHeader(Icons.notifications_rounded, 'Trung tâm thông báo'),
                const SizedBox(height: 14),
                if (vm.fcmToken != null) ...[
                  Text(
                    'FCM token (dùng để gửi test message từ Firebase Console):',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () => _copyText(
                      vm.fcmToken!,
                      'Đã sao chép FCM token vào clipboard',
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            vm.fcmToken!,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.copy_rounded, size: 18),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (vm.history.isEmpty)
                  Text(
                    'Chưa có thông báo nào. Gửi thử từ Firebase Console.',
                    style: AppTextStyles.bodySecondary,
                  )
                else
                  ...vm.history.map((n) => _buildNotificationTile(n)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationTile(AppNotification notification) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            notification.title,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
          if (notification.body.isNotEmpty)
            Text(notification.body, style: AppTextStyles.bodySecondary),
          Text(
            _formatTime(notification.receivedAt),
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  // Cho phép chỉnh max_papers_displayed NGAY trong app (override cục bộ trên
  // máy, lưu qua SharedPreferences trong RemoteConfigProvider) — không cần
  // vào Firebase Console. Override luôn thắng giá trị fetch từ Remote
  // Config; "Khôi phục mặc định" xoá override, quay lại giá trị Remote
  // Config thật.
  Widget _buildDisplaySettingsCard() {
    return Consumer<RemoteConfigProvider>(
      builder: (context, config, _) {
        final value = config.maxPapersDisplayed;
        return Card(
          key: const Key('display_settings_card'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cardHeader(Icons.tune_rounded, 'Cài đặt hiển thị'),
                const SizedBox(height: 10),
                Text(
                  'Số bài báo hiển thị tối đa: $value',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Áp dụng cho danh sách bài nổi bật của journal, volume, '
                  'tác giả và từ khoá liên quan.',
                  style: AppTextStyles.caption,
                ),
                Slider(
                  key: const Key('max_papers_slider'),
                  value: value.toDouble().clamp(5, 50),
                  min: 5,
                  max: 50,
                  divisions: 9,
                  label: '$value',
                  onChanged: (v) => context
                      .read<RemoteConfigProvider>()
                      .setMaxPapersDisplayedOverride(v.round()),
                ),
                if (config.hasMaxPapersOverride)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      key: const Key('reset_max_papers_button'),
                      onPressed: () => context
                          .read<RemoteConfigProvider>()
                          .resetMaxPapersDisplayedOverride(),
                      child: const Text('Khôi phục mặc định'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDebugCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeader(
              Icons.bug_report_rounded,
              'Công cụ debug (Crashlytics)',
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: _triggerHandledException,
              child: const Text('Trigger handled exception'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _triggerTestCrash,
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Trigger test crash'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime d) {
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    final mo = d.month.toString().padLeft(2, '0');
    return '$hh:$mm $dd/$mo/${d.year}';
  }
}
