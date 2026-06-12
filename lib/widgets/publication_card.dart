import 'package:flutter/material.dart';
import '../models/work.dart';
import '../utils/constants.dart';
import '../utils/text_utils.dart';

class PublicationCard extends StatelessWidget {
  final Work work;
  final VoidCallback? onTap;
  final int? rank; // hiển thị số thứ tự (dùng ở Top Papers)

  const PublicationCard({
    super.key,
    required this.work,
    this.onTap,
    this.rank,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (rank != null) _buildRankBadge(),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankBadge() {
    return Container(
      width: 36,
      height: 36,
      margin: const EdgeInsets.only(right: 12, top: 2),
      decoration: BoxDecoration(
        color: _getRankColor(),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '#$rank',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getRankColor() {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // gold
      case 2:
        return const Color(0xFFC0C0C0); // silver
      case 3:
        return const Color(0xFFCD7F32); // bronze
      default:
        return AppColors.primary;
    }
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          work.title,
          style: AppTextStyles.heading3,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Text(
          work.firstAuthorName,
          style: AppTextStyles.bodySecondary,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildChip(
              icon: Icons.calendar_today_rounded,
              label: work.publicationYear?.toString() ?? 'N/A',
            ),
            const SizedBox(width: 8),
            _buildChip(
              icon: Icons.format_quote_rounded,
              label: TextUtils.formatCount(work.citedByCount),
              color: AppColors.accent,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildJournalChip(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    Color color = AppColors.primary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.book_rounded, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              TextUtils.truncate(work.journalName, 20),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
