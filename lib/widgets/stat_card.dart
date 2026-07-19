import 'package:flutter/material.dart';
import '../utils/constants.dart';

// Card hiển thị 1 chỉ số trong Dashboard (total publications, avg citation...)
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  // Bản gọn hơn cho những màn hiện nhiều card cùng lúc (vd 4 card thống kê
  // journal) — cùng bố cục/màu sắc, chỉ giảm padding/font. Mặc định false để
  // không đổi các chỗ đang dùng StatCard cỡ thường (Home...).
  final bool compact;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.color = AppColors.primary,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 10 : 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(compact ? 6 : 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(compact ? 10 : 14),
            ),
            child: Icon(icon, size: compact ? 16 : 22, color: color),
          ),
          SizedBox(height: compact ? 8 : 14),
          Text(
            value,
            style: AppTextStyles.heading1.copyWith(
              color: color,
              fontSize: compact ? 17 : 24,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: compact ? 10.5 : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textHint,
                fontSize: 11,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
