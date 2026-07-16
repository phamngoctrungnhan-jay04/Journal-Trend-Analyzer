import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/work.dart';
import '../utils/constants.dart';
import '../utils/text_utils.dart';

class PublicationDetailScreen extends StatelessWidget {
  final Work work;

  const PublicationDetailScreen({super.key, required this.work});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết bài báo'),
        actions: [
          if (work.landingPageUrl != null)
            IconButton(
              icon: const Icon(Icons.open_in_new_rounded),
              tooltip: 'Xem bài gốc',
              onPressed: () => _openLink(context, work.landingPageUrl!),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitleCard(),
            const SizedBox(height: 14),
            _buildMetaGrid(),
            const SizedBox(height: 14),
            _buildAuthorsCard(),
            if (work.abstractText != null) ...[
              const SizedBox(height: 14),
              _buildAbstractCard(),
            ],
            if (work.landingPageUrl != null) ...[
              const SizedBox(height: 14),
              _buildOriginalLinkCard(context),
            ],
            if (work.doiUrl != null) ...[
              const SizedBox(height: 14),
              _buildDoiCard(context),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Article',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                if (work.publicationYear != null)
                  Text(
                    work.publicationYear.toString(),
                    style: AppTextStyles.bodySecondary,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(work.title, style: AppTextStyles.heading2),
            const SizedBox(height: 8),
            Text(
              work.journalName,
              style: AppTextStyles.bodySecondary.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildMetaCard(
            icon: Icons.format_quote_rounded,
            label: 'Trích dẫn',
            value: TextUtils.formatCount(work.citedByCount),
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetaCard(
            icon: Icons.people_rounded,
            label: 'Tác giả',
            value: work.authorships.length.toString(),
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetaCard(
            icon: Icons.calendar_today_rounded,
            label: 'Năm',
            value: work.publicationYear?.toString() ?? 'N/A',
            color: const Color(0xFF43A047),
          ),
        ),
      ],
    );
  }

  Widget _buildMetaCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(title, style: AppTextStyles.heading3),
      ],
    );
  }

  Widget _buildAuthorsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.people_rounded, 'Tác giả'),
            const SizedBox(height: 14),
            ...work.authorships.asMap().entries.map((entry) {
              final i = entry.key;
              final authorship = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.chartColors[i % AppColors.chartColors.length]
                          .withValues(alpha: 0.15),
                      child: Text(
                        authorship.author.displayName.isNotEmpty
                            ? authorship.author.displayName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.chartColors[i % AppColors.chartColors.length],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        authorship.author.displayName,
                        style: AppTextStyles.body,
                      ),
                    ),
                    if (authorship.authorPosition == 'first')
                      _buildPositionBadge('First', AppColors.primary),
                    if (authorship.authorPosition == 'last')
                      _buildPositionBadge('Last', AppColors.accent),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildAbstractCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.article_rounded, 'Tóm tắt'),
            const SizedBox(height: 14),
            Text(
              work.abstractText!,
              style: AppTextStyles.body.copyWith(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoiCard(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.link_rounded, color: AppColors.primary),
        title: const Text('DOI'),
        subtitle: Text(
          work.doiUrl!,
          style: const TextStyle(
            color: AppColors.primary,
            decoration: TextDecoration.underline,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.copy_rounded, size: 18),
        onTap: () => _copyDoi(context),
      ),
    );
  }

  Widget _buildOriginalLinkCard(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.open_in_new_rounded, color: AppColors.primary),
        title: const Text('Bài báo gốc'),
        subtitle: Text(
          work.landingPageUrl!,
          style: const TextStyle(
            color: AppColors.primary,
            decoration: TextDecoration.underline,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right_rounded, size: 18),
        onTap: () => _openLink(context, work.landingPageUrl!),
      ),
    );
  }

  void _copyDoi(BuildContext context) {
    if (work.doiUrl == null) return;
    Clipboard.setData(ClipboardData(text: work.doiUrl!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép DOI vào clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openLink(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    final opened = uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở liên kết.')),
      );
    }
  }
}
