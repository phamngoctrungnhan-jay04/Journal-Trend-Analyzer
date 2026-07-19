import 'dart:async';

import 'package:flutter/material.dart';

import '../services/openalex_service.dart';
import '../utils/constants.dart';

// Ô tìm kiếm generic: debounce, chống race giữa các lần gõ, và 3 trạng thái
// phản hồi bắt buộc (gõ dưới ngưỡng ký tự / đã tìm mà rỗng / có lỗi mạng).
// Tách ra từ TaxonomySearchField để dùng chung cho cả tìm CHỦ ĐỀ
// (TaxonomySearchField) lẫn tìm JOURNAL trực tiếp (JournalSearchField) — hai
// nơi giống hệt nhau ở phần debounce/race/empty-state, chỉ khác API gọi và
// cách vẽ từng dòng gợi ý.
//
// [search] chịu trách nhiệm vừa gọi service vừa parse+lọc JSON thành List<T>
// sẵn sàng hiển thị — widget này không biết gì về shape JSON trả về.
// [tileBuilder] tự dựng cả dòng gợi ý (kể cả Key riêng) và nhận [onSelect] để
// gắn vào onTap của chính nó, thay vì bọc thêm 1 lớp InkWell ở đây (tránh
// ripple lồng ripple khi tileBuilder đã dùng ListTile.onTap sẵn).
class EntitySearchField<T> extends StatefulWidget {
  final String hintText;
  // Tiền tố Key cho từng phần: '${keyPrefix}_field', '_hint', '_empty',
  // '_error' — giữ đúng key cũ 'taxonomy_search_*' để không phá patrol tests.
  final String keyPrefix;
  final ValueChanged<T> onSelected;
  final Future<List<T>> Function(OpenAlexService service, String query) search;
  final Widget Function(BuildContext context, T item, VoidCallback onSelect)
  tileBuilder;
  final String Function(String query) emptyMessageBuilder;
  // Cho phép inject service (test dùng MockClient thay vì gọi mạng thật).
  // null ở app thật -> tự tạo OpenAlexService() mặc định.
  final OpenAlexService? service;

  const EntitySearchField({
    super.key,
    required this.keyPrefix,
    required this.onSelected,
    required this.search,
    required this.tileBuilder,
    required this.emptyMessageBuilder,
    this.hintText = 'Tìm kiếm...',
    this.service,
  });

  @override
  State<EntitySearchField<T>> createState() => _EntitySearchFieldState<T>();
}

class _EntitySearchFieldState<T> extends State<EntitySearchField<T>> {
  final _controller = TextEditingController();
  late final OpenAlexService _service = widget.service ?? OpenAlexService();

  Timer? _debounce;
  List<T> _suggestions = [];
  bool _isLoading = false;
  String? _error;

  // Chuỗi của lần gọi API gần nhất. Dùng để bỏ qua kết quả về muộn của lần gõ
  // cũ (race): user gõ "blo" rồi "blockchain", nếu response "blo" về sau thì
  // không được phép ghi đè gợi ý của "blockchain".
  String _latestQuery = '';

  // Chuỗi của lần tìm kiếm ĐÃ HOÀN TẤT gần nhất (thành công, không lỗi). So
  // sánh với query hiện tại để phân biệt "chưa tìm" với "đã tìm và rỗng" —
  // thiếu cờ này thì không thể hiện thông báo "không tìm thấy" đúng lúc.
  String? _lastSearchedQuery;

  String get _trimmedQuery => _controller.text.trim();

  bool get _showsShortHint =>
      _trimmedQuery.isNotEmpty &&
      _trimmedQuery.length < AppConstants.minSearchChars;

  bool get _showsEmptyResult =>
      !_isLoading &&
      _error == null &&
      _trimmedQuery.length >= AppConstants.minSearchChars &&
      _suggestions.isEmpty &&
      _lastSearchedQuery == _trimmedQuery;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _service.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();

    if (query.length < AppConstants.minSearchChars) {
      setState(() {
        _suggestions = [];
        _isLoading = false;
        _error = null;
      });
      return;
    }

    // Debounce: mỗi phím gõ mà gọi API thì cạn quota OpenAlex rất nhanh.
    _debounce = Timer(AppConstants.searchDebounce, () => _search(query));
  }

  Future<void> _search(String query) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    _latestQuery = query;

    try {
      final items = await widget.search(_service, query);
      if (!mounted || _latestQuery != query) return;

      setState(() {
        _suggestions = items;
        _isLoading = false;
        _lastSearchedQuery = query;
      });
    } on ApiException catch (e) {
      if (!mounted || _latestQuery != query) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || _latestQuery != query) return;
      setState(() {
        _error = 'Đã xảy ra lỗi không mong đợi. Vui lòng thử lại.';
        _isLoading = false;
      });
    }
  }

  void _select(T item) {
    FocusScope.of(context).unfocus();
    _controller.clear();
    setState(() {
      _suggestions = [];
      _error = null;
    });
    widget.onSelected(item);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: Key('${widget.keyPrefix}_field'),
          controller: _controller,
          onChanged: _onChanged,
          style: const TextStyle(color: Colors.black87),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _buildSuffix(),
          ),
        ),
        if (_error != null ||
            _suggestions.isNotEmpty ||
            _showsShortHint ||
            _showsEmptyResult)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _buildResults(),
          ),
      ],
    );
  }

  Widget? _buildSuffix() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_controller.text.isEmpty) return null;
    return IconButton(
      icon: const Icon(Icons.clear_rounded),
      onPressed: () {
        _controller.clear();
        _onChanged('');
        setState(() {});
      },
    );
  }

  Widget _buildResults() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      // Material trung gian: nếu thiếu, tile bên trong vẽ ripple lên Material
      // tổ tiên (vd Scaffold) — bị Container nền trắng này che mất, bấm
      // không thấy hiệu ứng gì (Flutter cảnh báo assertion lúc debug).
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(AppRadius.card),
        clipBehavior: Clip.antiAlias,
        child: _error != null
            ? _buildMessage(
                key: Key('${widget.keyPrefix}_error'),
                text: _error!,
                color: AppColors.error,
              )
            : _showsShortHint
            ? _buildMessage(
                key: Key('${widget.keyPrefix}_hint'),
                text: 'Nhập thêm ký tự để tìm...',
                color: AppColors.textHint,
              )
            : _showsEmptyResult
            ? _buildMessage(
                key: Key('${widget.keyPrefix}_empty'),
                text: widget.emptyMessageBuilder(_trimmedQuery),
                color: AppColors.textHint,
              )
            : ConstrainedBox(
                // Giới hạn chiều cao để danh sách gợi ý không đẩy hết nội
                // dung bên dưới ra khỏi màn hình.
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) => widget.tileBuilder(
                    context,
                    _suggestions[index],
                    () => _select(_suggestions[index]),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildMessage({
    required Key key,
    required String text,
    required Color color,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.all(16),
      child: Text(text, style: AppTextStyles.caption.copyWith(color: color)),
    );
  }
}
