import 'work.dart';
import 'author.dart';
import 'journal.dart';
import 'keyword.dart';

// Tổng hợp tất cả insights cho FR 4.7 Research Trend Dashboard
class DashboardStats {
  final String topic;
  final int totalPublications;
  final double averageCitationCount;
  final int? mostActiveYear;
  final int? mostActiveYearCount;
  final TopJournal? topJournal;
  final TopAuthor? topAuthor;
  final Keyword? topKeyword;
  final Work? mostInfluentialPaper;

  const DashboardStats({
    required this.topic,
    required this.totalPublications,
    required this.averageCitationCount,
    this.mostActiveYear,
    this.mostActiveYearCount,
    this.topJournal,
    this.topAuthor,
    this.topKeyword,
    this.mostInfluentialPaper,
  });

  // Factory để tổng hợp từ các dữ liệu đã fetch riêng lẻ
  factory DashboardStats.fromAnalysisData({
    required String topic,
    required int totalPublications,
    required List<YearlyTrend> yearlyTrends,
    required List<TopJournal> topJournals,
    required List<TopAuthor> topAuthors,
    required List<Keyword> topKeywords,
    required List<Work> topCitedWorks,
    required double averageCitationCount,
  }) {
    // Tìm năm có nhiều bài nhất
    YearlyTrend? mostActiveYearTrend;
    if (yearlyTrends.isNotEmpty) {
      mostActiveYearTrend = yearlyTrends.reduce(
        (a, b) => a.count > b.count ? a : b,
      );
    }

    return DashboardStats(
      topic: topic,
      totalPublications: totalPublications,
      averageCitationCount: averageCitationCount,
      mostActiveYear: mostActiveYearTrend?.year,
      mostActiveYearCount: mostActiveYearTrend?.count,
      topJournal: topJournals.isNotEmpty ? topJournals.first : null,
      topAuthor: topAuthors.isNotEmpty ? topAuthors.first : null,
      topKeyword: topKeywords.isNotEmpty ? topKeywords.first : null,
      mostInfluentialPaper: topCitedWorks.isNotEmpty
          ? topCitedWorks.first
          : null,
    );
  }

  // Format average citation để hiển thị (làm tròn 1 chữ số thập phân)
  String get formattedAvgCitation => averageCitationCount.toStringAsFixed(1);
}
