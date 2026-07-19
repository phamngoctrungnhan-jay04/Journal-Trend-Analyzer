import 'package:flutter/material.dart';

import '../models/journal.dart';
import '../services/openalex_service.dart';
import '../utils/constants.dart';
import '../utils/text_utils.dart';
import 'entity_search_field.dart';

// Ô tìm kiếm JOURNAL trực tiếp theo tên — khác với chọn lĩnh vực rồi xem xếp
// hạng journal (FR 4.5, JournalsProvider.load). Wrapper mỏng quanh
// EntitySearchField<JournalSuggestion>, cùng khuôn với TaxonomySearchField.
class JournalSearchField extends StatelessWidget {
  final String hintText;
  final ValueChanged<TopJournal> onSelected;
  final OpenAlexService? service;

  const JournalSearchField({
    super.key,
    required this.onSelected,
    this.hintText = 'Tìm tên tạp chí...',
    this.service,
  });

  @override
  Widget build(BuildContext context) {
    return EntitySearchField<JournalSuggestion>(
      keyPrefix: 'journal_search',
      hintText: hintText,
      service: service,
      onSelected: (suggestion) => onSelected(suggestion.toTopJournal()),
      search: (service, query) async {
        final result = await service.searchJournals(query: query);
        final resultsJson = result['results'] as List<dynamic>? ?? [];
        return resultsJson
            .whereType<Map<String, dynamic>>()
            .map((j) => JournalSuggestion.fromJson(j))
            .where((j) => j.id.isNotEmpty && j.displayName.isNotEmpty)
            .toList();
      },
      emptyMessageBuilder: (query) =>
          'Không tìm thấy tạp chí nào khớp "$query". '
          'Thử tên tiếng Anh đầy đủ của tạp chí (vd "Nature" thay vì viết '
          'tắt).',
      tileBuilder: (context, j, onSelect) => ListTile(
        key: Key('journal_suggestion_${j.id}'),
        onTap: onSelect,
        title: Text(
          j.displayName,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            if (j.publisherName.isNotEmpty)
              Text(
                j.publisherName,
                style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              '${TextUtils.formatCount(j.worksCount)} bài',
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
