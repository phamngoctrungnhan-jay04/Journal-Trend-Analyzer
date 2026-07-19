import 'package:flutter/material.dart';

import '../models/research_field.dart';
import '../models/research_scope.dart';
import '../services/openalex_service.dart';
import '../utils/constants.dart';
import '../utils/text_utils.dart';
import 'entity_search_field.dart';

// Ô tìm kiếm CHỦ ĐỀ trong cây phân loại OpenAlex — KHÔNG phải search full-text
// các bài báo.
//
// Vì sao quan trọng: `search=blockchain` quét full-text toàn OpenAlex ra
// 246.708 bài, gồm cả bài chỉ nhắc thoáng qua chữ đó. Còn chọn đúng topic rồi
// lọc `primary_topic.id:T10270` ra 51.340 bài thực sự về blockchain. Tìm trong
// "bản đồ" thay vì trong "thế giới" giữ cho mọi số liệu đúng phạm vi.
//
// Dùng chung cho cả 3 tab; mỗi tab tự quản scope của mình qua [onSelected].
// Wrapper mỏng quanh EntitySearchField<TopicSuggestion> — phần debounce/race/
// empty-state nằm hết ở đó, ở đây chỉ còn cách gọi API và cách vẽ 1 dòng gợi
// ý chủ đề (breadcrumb field › subfield).
class TaxonomySearchField extends StatelessWidget {
  final String hintText;
  final ValueChanged<ResearchScope> onSelected;
  final OpenAlexService? service;
  // Widget này render đồng thời ở nhiều tab (Home header, Journals byField,
  // Profile export card) — IndexedStack build cả 4 tab cùng lúc nên nếu dùng
  // chung 1 keyPrefix, key 'taxonomy_search_field' sẽ TRÙNG ở 3 nơi, làm
  // finder trong Patrol test nhập nhằng không bấm đúng ô. Mỗi nơi gọi tự đặt
  // keyPrefix riêng; mặc định giữ nguyên 'taxonomy_search' cho chỗ chưa cần
  // phân biệt (vd Profile export card).
  final String keyPrefix;

  const TaxonomySearchField({
    super.key,
    required this.onSelected,
    this.hintText = 'Tìm chủ đề nghiên cứu...',
    this.service,
    this.keyPrefix = 'taxonomy_search',
  });

  @override
  Widget build(BuildContext context) {
    return EntitySearchField<TopicSuggestion>(
      keyPrefix: keyPrefix,
      hintText: hintText,
      service: service,
      onSelected: (suggestion) => onSelected(suggestion.toScope()),
      search: (service, query) async {
        final result = await service.searchTopics(query: query);
        final resultsJson = result['results'] as List<dynamic>? ?? [];
        return resultsJson
            .whereType<Map<String, dynamic>>()
            .map((j) => TopicSuggestion.fromJson(j))
            .where((t) => t.id.isNotEmpty && t.displayName.isNotEmpty)
            .toList();
      },
      emptyMessageBuilder: (query) =>
          'Không tìm thấy chủ đề nào khớp "$query". '
          'OpenAlex chỉ đặt tên chủ đề bằng tiếng Anh — thử '
          'một từ khoá tiếng Anh khác.',
      tileBuilder: (context, s, onSelect) => ListTile(
        key: Key('topic_suggestion_${s.id}'),
        onTap: onSelect,
        title: Text(
          s.displayName,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            // Breadcrumb: cho user thấy chủ đề này nằm ở đâu trong cây.
            Text(
              s.breadcrumb,
              style: AppTextStyles.caption.copyWith(color: AppColors.primary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${TextUtils.formatCount(s.worksCount)} bài',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textHint,
                fontSize: 11,
              ),
            ),
          ],
        ),
        trailing: const Icon(
          Icons.north_east_rounded,
          size: 16,
          color: AppColors.textHint,
        ),
      ),
    );
  }
}
