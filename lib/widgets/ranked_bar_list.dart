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
  // Journals/Keywords tab cần biểu đồ (nội dung chính của màn). Home chỉ cần
  // danh sách xếp hạng gọn cho tab Tổng quan, không cần lặp lại chart.
  final bool showChart;

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
    this.showChart = true,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return EmptyResultWidget(message: emptyMessage);
    }

    final maxCount = countOf(items.first);
    final axis = TextUtils.niceAxis(maxCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
        if (showChart) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 20, 20, 8),
              child: SizedBox(
                height: (items.length * 48).toDouble().clamp(200, 400),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.center,
                    maxY: axis.maxY,
                    // Xoay CẢ khối chart (kể cả trục) 90° thuận chiều kim
                    // đồng hồ — đây là cách CHÍNH THỐNG của fl_chart để có
                    // horizontal bar chart (đối chiếu BarChartSample7 "Horizontal
                    // Bar Chart" trong repo mẫu chính thức), khác hẳn cách vẽ
                    // BarChart bình thường (luôn là cột dọc). Sau khi xoay: cạnh
                    // TRÁI trước khi xoay thành cạnh TRÊN, cạnh DƯỚI trước khi
                    // xoay thành cạnh TRÁI — vì vậy tên (muốn đọc được ở bên
                    // trái) phải khai ở bottomTitles, giá trị (muốn ở trên) khai
                    // ở leftTitles — ngược với một BarChart dọc thông thường.
                    rotationQuarterTurns: 1,
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
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 120,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= items.length) {
                              return const SizedBox.shrink();
                            }
                            // SideTitleWidget tự bù lại góc xoay của chart để
                            // chữ đứng thẳng, đọc được bình thường — thiếu
                            // nó thì text sẽ nằm nghiêng 90° theo chart.
                            return SideTitleWidget(
                              meta: meta,
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
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: axis.interval,
                          getTitlesWidget: (value, meta) => SideTitleWidget(
                            meta: meta,
                            child: Text(
                              TextUtils.formatCount(value.toInt()),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
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
                          AppColors.chartColors[entry.key %
                              AppColors.chartColors.length];
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: countOf(entry.value).toDouble(),
                            color: color,
                            width: 16,
                            // Bo góc cạnh TRÊN trước khi xoay -> sau khi xoay
                            // 90° CW trở thành đầu mút bên PHẢI của thanh
                            // ngang (đúng chỗ cần bo tròn).
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
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
        ],
        ...items.asMap().entries.map(
          (entry) => _buildListItem(entry.key + 1, entry.value, maxCount),
        ),
      ],
    );
  }

  Widget _buildListItem(int rank, T item, int maxCount) {
    final count = countOf(item);
    final fraction = (count / maxCount).clamp(0.0, 1.0);
    final color =
        AppColors.chartColors[(rank - 1) % AppColors.chartColors.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          key: ValueKey('ranked_item_$rank'),
          onTap: onTap != null ? () => onTap!(item) : null,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _rankBadge(rank, color),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nameOf(item),
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: fraction,
                          backgroundColor: color.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${TextUtils.formatCount(count)} bài báo',
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

  // Badge hạng hình tròn: top 3 màu huy chương vàng/bạc/đồng, còn lại theo màu
  // biểu đồ của hàng.
  Widget _rankBadge(int rank, Color color) {
    final Color bg;
    switch (rank) {
      case 1:
        bg = const Color(0xFFF5B301); // vàng
        break;
      case 2:
        bg = const Color(0xFF9AA5B1); // bạc
        break;
      case 3:
        bg = const Color(0xFFC77B3B); // đồng
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
}
