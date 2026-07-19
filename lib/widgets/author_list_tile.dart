import 'package:flutter/material.dart';
import '../models/author.dart';
import '../utils/constants.dart';

class AuthorListTile extends StatelessWidget {
  final TopAuthor author;
  final int rank;
  final VoidCallback? onTap;

  const AuthorListTile({
    super.key,
    required this.author,
    required this.rank,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final barFraction = _getBarFraction();
    final color =
        AppColors.chartColors[(rank - 1) % AppColors.chartColors.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          key: ValueKey('author_tile_${author.id}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _rankBadge(color),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author.displayName,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: barFraction,
                          backgroundColor: color.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${author.worksCount} bài báo',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textHint,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _rankBadge(Color color) {
    final Color bg;
    switch (rank) {
      case 1:
        bg = const Color(0xFFF5B301);
        break;
      case 2:
        bg = const Color(0xFF9AA5B1);
        break;
      case 3:
        bg = const Color(0xFFC77B3B);
        break;
      default:
        bg = color;
    }
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: bg.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$rank',
          style: AppTextStyles.heading3.copyWith(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
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
