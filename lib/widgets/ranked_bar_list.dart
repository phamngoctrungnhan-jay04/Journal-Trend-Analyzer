import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../utils/constants.dart';
import '../utils/text_utils.dart';
import 'error_widget.dart';

// Horizontal bar chart + danh sách xếp hạng dùng chung cho Journals và
// Keywords (cả 2 đều có hình dạng {id, displayName, worksCount}).
// Tách từ _TopJournalsTab (trend_analysis_screen.dart cũ), generic hóa qua
// nameOf/countOf/onTap thay vì hardcode TopJournal.
class RankedBarList<T> extends StatelessWidget {
  final List<T> items;
  final String Function(T item) nameOf;
  final int Function(T item) countOf;
  final void Function(T item)? onTap;
  final IconData icon;
  final String title;
  final String subtitle;
  final String emptyMessage;

  const RankedBarList({
    super.key,
    required this.items,
    required this.nameOf,
    required this.countOf,
    this.onTap,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.emptyMessage = 'Không có dữ liệu.',
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return EmptyResultWidget(message: emptyMessage);
    }

    final maxCount = countOf(items.first);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.heading3),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 20, 20, 8),
            child: SizedBox(
              height: (items.length * 48).toDouble().clamp(200, 400),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.center,
                  maxY: maxCount * 1.2,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppColors.primary,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${TextUtils.formatCount(countOf(items[groupIndex]))} bài',
                          const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 120,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= items.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              TextUtils.truncate(nameOf(items[idx]), 16),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Text(
                          TextUtils.formatCount(value.toInt()),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    drawHorizontalLine: false,
                    getDrawingVerticalLine: (_) => FlLine(
                      color: Colors.grey.withValues(alpha: 0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: items.asMap().entries.map((entry) {
                    final color =
                        AppColors.chartColors[entry.key % AppColors.chartColors.length];
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: countOf(entry.value).toDouble(),
                          color: color,
                          width: 16,
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
                duration: const Duration(milliseconds: 400),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...items.asMap().entries.map(
              (entry) => _buildListItem(entry.key + 1, entry.value, maxCount),
            ),
      ],
    );
  }

  Widget _buildListItem(int rank, T item, int maxCount) {
    final count = countOf(item);
    final fraction = (count / maxCount).clamp(0.0, 1.0);
    final color = AppColors.chartColors[(rank - 1) % AppColors.chartColors.length];

    return InkWell(
      onTap: onTap != null ? () => onTap!(item) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
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
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nameOf(item),
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: fraction,
                      backgroundColor: color.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${TextUtils.formatCount(count)} bài',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}
