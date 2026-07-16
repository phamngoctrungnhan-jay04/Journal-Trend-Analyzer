import 'work.dart';
import 'journal.dart';

// Alias thay vì rename toàn bộ class, để giảm rủi ro breaking khi chuyển
// sang thuật ngữ Lab 03 (Publication/Journal) mà không phải sửa lại mọi
// import/reference đang dùng Work/TopJournal trong toàn bộ codebase Lab 02.
typedef Publication = Work;
typedef Journal = TopJournal;

// KHÔNG alias TopAuthor -> Author ở đây: lib/models/author.dart đã có sẵn
// class Author (đại diện 1 tác giả trong Authorship của 1 Work), nên alias
// sẽ đụng tên. Việc đặt lại tên cho TopAuthor (nếu cần) sẽ quyết định ở
// Stage 2 khi xây Keyword Detail (màn hình dùng lại logic rank tác giả).
