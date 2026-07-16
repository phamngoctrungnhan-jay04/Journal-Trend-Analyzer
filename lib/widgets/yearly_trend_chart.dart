import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/work.dart';
import '../utils/constants.dart';
import '../utils/text_utils.dart';
import 'error_widget.dart';

// Bar chart số bài báo theo năm + card "năm xuất bản nhiều nhất".
// Tách từ _TrendChartTab (trend_analysis_screen.dart cũ) để dùng chung ở
// Home và Keyword Detail.
class YearlyTrendChart extends StatelessWidget {
  final List<YearlyTrend> trends;

  const YearlyTrendChart({super.key, required this.trends});

  @override
  Widget build(BuildContext context) {
    if (trends.isEmpty) {
      return const EmptyResultWidget(message: 'Không có dữ liệu xu hướng.');
    }

    final maxCount = trends.map((t) => t.count).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.show_chart_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Xu hướng xuất bản theo năm', style: AppTextStyles.heading3),
                  Text(
                    '${trends.length} năm · ${trends.fold(0, (s, t) => s + t.count)} bài báo',
                    style: AppTextStyles.caption,
                  ),
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
              height: 280,
              child: BarChart(
                BarChartData(
                  maxY: maxCount * 1.2,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppColors.primary,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final trend = trends[groupIndex];
                        return BarTooltipItem(
                          '${trend.year}\n${TextUtils.formatCount(trend.count)} bài',
                          const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= trends.length) {
                            return const SizedBox.shrink();
                          }
                          // Chỉ hiển thị tối đa ~7 nhãn để tránh chồng chữ;
                          // luôn hiển thị nhãn năm cuối cùng.
                          final step = (trends.length / 7).ceil();
                          final isLast = idx == trends.length - 1;
                          if (idx % step != 0 && !isLast) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              "'${trends[idx].year.toString().substring(2)}",
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
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
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: Colors.grey.withValues(alpha: 0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: trends.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final trend = entry.value;
                    return BarChartGroupData(
                      x: idx,
                      barRods: [
                        BarChartRodData(
                          toY: trend.count.toDouble(),
                          color: AppColors.primary,
                          width: trends.length > 20 ? 6 : 12,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildPeakYearCard(),
      ],
    );
  }

  Widget _buildPeakYearCard() {
    final peak = trends.reduce((a, b) => a.count > b.count ? a : b);
    return Card(
      color: AppColors.primary.withValues(alpha: 0.05),
      child: ListTile(
        leading: const Icon(Icons.star_rounded, color: AppColors.warning),
        title: const Text('Năm xuất bản nhiều nhất'),
        subtitle: Text('${TextUtils.formatCount(peak.count)} bài báo'),
        trailing: Text(
          peak.year.toString(),
          style: AppTextStyles.heading2.copyWith(color: AppColors.primary),
        ),
      ),
    );
  }
}
