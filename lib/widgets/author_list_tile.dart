import 'package:flutter/material.dart';
import '../models/author.dart';
import '../utils/constants.dart';

class AuthorListTile extends StatelessWidget {
  final TopAuthor author;
  final int rank;

  const AuthorListTile({
    super.key,
    required this.author,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final barFraction = _getBarFraction();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: rank <= 3 ? AppColors.primary : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.chartColors[(rank - 1) % AppColors.chartColors.length]
                .withValues(alpha: 0.15),
            child: Text(
              author.displayName.isNotEmpty
                  ? author.displayName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.chartColors[(rank - 1) % AppColors.chartColors.length],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  author.displayName,
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: barFraction,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.chartColors[(rank - 1) % AppColors.chartColors.length],
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${author.worksCount} bài',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // Top 1 luôn = 1.0, các hạng sau tỷ lệ so với top 1
  // Nhưng vì không biết top 1 có bao nhiêu, dùng công thức đơn giản theo rank
  double _getBarFraction() {
    if (rank == 1) return 1.0;
    return (1.0 - (rank - 1) * 0.08).clamp(0.2, 1.0);
  }
}
