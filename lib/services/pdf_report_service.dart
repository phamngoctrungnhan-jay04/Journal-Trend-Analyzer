import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/dashboard_stats.dart';
import '../models/work.dart';
import '../models/journal.dart';
import '../models/author.dart';
import '../models/keyword.dart';

// Sinh PDF report từ dữ liệu đã có sẵn trong AnalysisProvider sau khi
// search ở Home - không gọi thêm API nào.
class PdfReportService {
  Future<Uint8List> buildReport({
    required DashboardStats stats,
    required List<YearlyTrend> yearlyTrends,
    required List<TopJournal> topJournals,
    required List<TopAuthor> topAuthors,
    required List<Keyword> topKeywords,
  }) async {
    // Font Base14 mặc định của package pdf không hỗ trợ dấu tiếng Việt -
    // phải nhúng font Unicode riêng, nếu không chữ có dấu sẽ hiện ô vuông.
    final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final font = pw.Font.ttf(fontData);
    final theme = pw.ThemeData.withFont(base: font, bold: font);

    final doc = pw.Document(theme: theme);

    doc.addPage(
      pw.MultiPage(
        theme: theme,
        build: (context) => [
          pw.Text(
            'Journal Trend Analyzer',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            'Báo cáo phân tích xu hướng nghiên cứu',
            style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 12),
          pw.Text('Chủ đề: ${stats.topic}'),
          pw.Text('Ngày tạo: ${_formatDate(DateTime.now())}'),
          pw.SizedBox(height: 20),
          pw.Header(level: 1, text: 'Tổng quan'),
          pw.TableHelper.fromTextArray(
            headers: const ['Chỉ số', 'Giá trị'],
            data: [
              ['Tổng bài báo', stats.totalPublications.toString()],
              ['TB trích dẫn (ước lượng)', stats.formattedAvgCitation],
              [
                'Năm sôi động nhất',
                stats.mostActiveYear?.toString() ?? 'N/A',
              ],
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Header(level: 1, text: 'Top tạp chí'),
          _buildRankTable(
            topJournals.map((j) => (j.displayName, j.worksCount)).toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Header(level: 1, text: 'Top tác giả'),
          _buildRankTable(
            topAuthors.map((a) => (a.displayName, a.worksCount)).toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Header(level: 1, text: 'Top từ khoá'),
          _buildRankTable(
            topKeywords.map((k) => (k.displayName, k.worksCount)).toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Header(level: 1, text: 'Xu hướng xuất bản theo năm'),
          pw.TableHelper.fromTextArray(
            headers: const ['Năm', 'Số bài'],
            data: yearlyTrends
                .map((t) => [t.year.toString(), t.count.toString()])
                .toList(),
          ),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _buildRankTable(List<(String, int)> items) {
    if (items.isEmpty) {
      return pw.Text('Không có dữ liệu.');
    }
    return pw.TableHelper.fromTextArray(
      headers: const ['#', 'Tên', 'Số bài'],
      data: items
          .asMap()
          .entries
          .map((e) => [
                (e.key + 1).toString(),
                e.value.$1,
                e.value.$2.toString(),
              ])
          .toList(),
    );
  }

  String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }
}
