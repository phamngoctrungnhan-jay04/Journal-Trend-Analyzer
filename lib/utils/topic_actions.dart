import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../viewmodels/topic_provider.dart';
import '../viewmodels/search_provider.dart';
import '../viewmodels/analysis_provider.dart';

// Điểm vào DUY NHẤT để chọn/đổi chủ đề phân tích — dùng chung cho ô search ở
// Home lẫn Keywords, cho chip gợi ý và chip chủ đề gần đây. Một lần gọi sẽ:
//   1. ghi lại chủ đề đang chọn + lịch sử (TopicProvider),
//   2. nạp danh sách bài báo (SearchProvider),
//   3. nạp dữ liệu phân tích cho overview/Journals/Keywords (AnalysisProvider).
// Nhờ vậy mọi tab đều có dữ liệu bất kể bạn bấm Tìm từ tab nào — bỏ hẳn ràng
// buộc "phải search ở Home trước thì tab khác mới chạy".
void selectTopic(BuildContext context, String topic) {
  final t = topic.trim();
  if (t.isEmpty) return;
  FocusScope.of(context).unfocus();
  context.read<TopicProvider>().select(t);
  context.read<SearchProvider>().search(t);
  context.read<AnalysisProvider>().analyze(t);
}
