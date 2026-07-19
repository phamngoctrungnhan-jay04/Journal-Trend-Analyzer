import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/work.dart';
import '../utils/constants.dart';
import '../utils/text_utils.dart';
import 'error_widget.dart';

// Line chart số bài báo theo năm + card "năm xuất bản nhiều nhất". Dùng
// đường thay vì cột: dữ liệu là chuỗi liên tục theo thời gian (mỗi năm nối
// tiếp năm trước), line chart thể hiện xu hướng tăng/giảm rõ hơn cột rời rạc.
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
    final axis = TextUtils.niceAxis(maxCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.show_chart_rounded,
              color: AppColors.primary,
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Xu hướng xuất bản theo năm',
                    style: AppTextStyles.heading3,
                  ),
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
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (trends.length - 1).toDouble(),
                  minY: 0,
                  maxY: axis.maxY,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => AppColors.primary,
                      getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                        final trend = trends[s.x.toInt()];
                        return LineTooltipItem(
                          '${trend.year}\n${TextUtils.formatCount(trend.count)} bài',
                          const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      }).toList(),
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
                        interval: axis.interval,
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
                  lineBarsData: [
                    LineChartBarData(
                      spots: trends
                          .asMap()
                          .entries
                          .map(
                            (e) => FlSpot(
                              e.key.toDouble(),
                              e.value.count.toDouble(),
                            ),
                          )
                          .toList(),
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      dotData: FlDotData(
                        // Quá nhiều năm thì chấm dày đặc, rối mắt -> chỉ
                        // hiện chấm khi còn đủ thưa để phân biệt từng điểm.
                        show: trends.length <= 20,
                        getDotPainter: (spot, percent, bar, index) =>
                            FlDotCirclePainter(
                              radius: 4,
                              color: AppColors.primary,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.primary.withValues(alpha: 0.22),
                            AppColors.primary.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
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
