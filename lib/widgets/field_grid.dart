import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/research_field.dart';
import '../viewmodels/taxonomy_provider.dart';
import '../utils/constants.dart';

// Lưới 26 lĩnh vực nghiên cứu chính. Bấm 1 lĩnh vực -> danh sách lĩnh vực phụ
// xổ ra NGAY DƯỚI hàng chứa nó (không phải dưới cùng lưới), để user thấy rõ
// quan hệ cha-con.
//
// Cài bằng ListView các "hàng 2 card" thay vì GridView: GridView không chèn
// được một khối full-width vào giữa lưới, còn cách này thì chèn thoải mái.
class FieldGrid extends StatelessWidget {
  final void Function(Subfield subfield, String parentLabel) onSubfieldSelected;

  const FieldGrid({super.key, required this.onSubfieldSelected});

  static const _columns = 2;

  @override
  Widget build(BuildContext context) {
    final taxonomy = context.watch<TaxonomyProvider>();
    final fields = AppConstants.researchFields;

    // Gom 26 lĩnh vực thành các hàng 2 cột.
    final rows = <List<ResearchFieldSpec>>[];
    for (var i = 0; i < fields.length; i += _columns) {
      rows.add(
        fields.sublist(
          i,
          (i + _columns) > fields.length ? fields.length : i + _columns,
        ),
      );
    }

    return ListView.builder(
      key: const Key('field_grid'),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      itemCount: rows.length,
      itemBuilder: (context, rowIndex) {
        final row = rows[rowIndex];
        // Hàng này có lĩnh vực nào đang mở không? Nếu có, chèn khối lĩnh vực
        // phụ ngay sau hàng.
        final expandedInRow = row
            .where((f) => taxonomy.isExpanded(f.id))
            .firstOrNull;

        return Column(
          children: [
            // IntrinsicHeight cho Row một chiều cao hữu hạn (= card cao nhất
            // trong hàng) để CrossAxisAlignment.stretch dùng được. Thiếu nó thì
            // Row nhận maxHeight vô hạn từ ListView -> stretch ép con cao vô hạn
            // -> lỗi render, cả lưới không vẽ gì.
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < _columns; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(
                      child: i < row.length
                          ? _FieldCard(
                              spec: row[i],
                              isExpanded: taxonomy.isExpanded(row[i].id),
                              onTap: () => taxonomy.toggleField(row[i].id),
                            )
                          // Ô trống giữ cột cuối thẳng hàng khi số lĩnh vực lẻ.
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
            if (expandedInRow != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _SubfieldPanel(
                  spec: expandedInRow,
                  onSubfieldSelected: onSubfieldSelected,
                ),
              ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

class _FieldCard extends StatelessWidget {
  final ResearchFieldSpec spec;
  final bool isExpanded;
  final VoidCallback onTap;

  const _FieldCard({
    required this.spec,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isExpanded ? spec.color.withValues(alpha: 0.10) : Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        key: Key('field_card_${spec.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: isExpanded ? spec.color : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: isExpanded ? null : AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: spec.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(spec.icon, color: spec.color, size: 20),
                  ),
                  const Spacer(),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textHint,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Chiều cao cố định cho đúng 2 dòng: IntrinsicHeight (dùng để 2
              // card trong hàng cao bằng nhau) tính sai chiều cao cần cho Text
              // có thể wrap — nó đo trước ở một bề rộng khác bề rộng thật lúc
              // layout, nên với tên dài phải xuống 2 dòng (vd "Computer
              // Science") thì chiều cao được cấp thiếu, tràn 1 dòng ra ngoài.
              // Ép SizedBox cố định loại bỏ hẳn phép đo mơ hồ đó.
              // Chiều cao cố định cho đúng 2 dòng: IntrinsicHeight (dùng để 2
              // card trong hàng cao bằng nhau) tính chiều cao dựa trên phép đo
              // Text có thể wrap — với tên dài phải xuống 2 dòng (vd "Computer
              // Science") trong khi card cùng hàng chỉ 1 dòng (vd
              // "Engineering"), phép đo đó từng ra thiếu, tràn 1 dòng ra ngoài
              // trên máy thật ("BOTTOM OVERFLOWED BY 20 PIXELS"). Ép SizedBox
              // cố định loại bỏ hẳn phần phụ thuộc vào đo đạc đó.
              SizedBox(
                height: 38,
                child: Text(
                  spec.label,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Khối lĩnh vực phụ xổ ra dưới lĩnh vực chính đang mở. Ba trạng thái: đang tải
// / lỗi (có nút thử lại) / danh sách chip.
class _SubfieldPanel extends StatelessWidget {
  final ResearchFieldSpec spec;
  final void Function(Subfield subfield, String parentLabel) onSubfieldSelected;

  const _SubfieldPanel({required this.spec, required this.onSubfieldSelected});

  @override
  Widget build(BuildContext context) {
    final taxonomy = context.watch<TaxonomyProvider>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: spec.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: spec.color.withValues(alpha: 0.25)),
      ),
      child: _buildContent(context, taxonomy),
    );
  }

  Widget _buildContent(BuildContext context, TaxonomyProvider taxonomy) {
    if (taxonomy.isLoadingSubfields(spec.id)) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    final error = taxonomy.errorOf(spec.id);
    if (error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            error,
            style: AppTextStyles.caption.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            key: Key('subfield_retry_${spec.id}'),
            onPressed: () => taxonomy.retry(spec.id),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Thử lại'),
          ),
        ],
      );
    }

    final subfields = taxonomy.subfieldsOf(spec.id) ?? const <Subfield>[];
    if (subfields.isEmpty) {
      return Text(
        'Không có lĩnh vực phụ nào.',
        style: AppTextStyles.bodySecondary,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chọn lĩnh vực phụ',
          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: subfields.map((s) {
            return ActionChip(
              key: Key('subfield_${s.id}'),
              label: Text(s.displayName),
              labelStyle: AppTextStyles.chip.copyWith(color: spec.color),
              backgroundColor: Colors.white,
              side: BorderSide(color: spec.color.withValues(alpha: 0.3)),
              onPressed: () => onSubfieldSelected(s, spec.label),
            );
          }).toList(),
        ),
      ],
    );
  }
}
