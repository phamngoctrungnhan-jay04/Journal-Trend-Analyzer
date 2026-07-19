import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/research_scope.dart';

class AppConstants {
  AppConstants._();

  // OpenAlex API
  static const String baseUrl = 'https://api.openalex.org';
  static const String worksEndpoint = '/works';
  static const String emailParam = 'mailto=phamngoctrungnhan0901@gmail.com';

  // Pagination
  static const int defaultPerPage = 50;
  static const int maxPerPage = 100;

  // Chart
  static const int topJournalsCount = 10;
  static const int topAuthorsCount = 10;
  static const int topPapersCount = 10;
  static const int topKeywordsCount = 10;
  static const int relatedKeywordsCount = 10;
  // Mẫu nhỏ để tính TB trích dẫn/bài cho phần tổng quan tab Keywords — không
  // cần lấy hết (có thể hàng chục nghìn bài), lấy mẫu bài trích dẫn cao nhất
  // là đủ đại diện, giống cách JournalDetailViewModel.averageCitation tính.
  static const int keywordTopWorksSampleSize = 15;

  // Detail screens
  static const int journalWorksPerPage = 20;
  static const int keywordAuthorsCount = 10;

  // Journal Detail - tab Volumes. Cửa sổ tính từ last_publication_year của
  // CHÍNH journal đó (không phải năm hiện tại) -> journal ngừng xuất bản lâu
  // rồi vẫn ra đúng volume cuối cùng thay vì 0 kết quả.
  static const int recentVolumesWindowYears = 3;
  static const int maxVolumesDisplayed = 12;

  // Home
  static const int homeTopPapersCount = 5;

  // Ô tìm kiếm trong cây phân loại
  static const int topicSuggestionsCount = 8;
  // Chờ user ngừng gõ rồi mới gọi API — mỗi lần gọi tốn quota OpenAlex.
  static const Duration searchDebounce = Duration(milliseconds: 350);
  // Dưới ngưỡng này thì chuỗi quá ngắn, gợi ý ra toàn nhiễu.
  static const int minSearchChars = 3;

  // App info
  static const String appName = 'Journal Trend Analyzer';
  static const String appVersion = '1.0.0';

  // 26 lĩnh vực chính (tầng `fields` của OpenAlex) — viết cứng thay vì gọi
  // /fields vì đây là bộ ĐẦY ĐỦ và gần như bất biến (dẫn xuất từ ASJC), lại
  // giúp Home mở ra là có ngay, không tốn request nào của quota OpenAlex.
  // Lĩnh vực phụ thì ngược lại: nạp từ API khi user mở (xem TaxonomyProvider).
  static const List<ResearchFieldSpec> researchFields = [
    ResearchFieldSpec('17', 'Computer Science', Icons.memory_rounded),
    ResearchFieldSpec('22', 'Engineering', Icons.settings_rounded),
    ResearchFieldSpec('27', 'Medicine', Icons.local_hospital_rounded),
    ResearchFieldSpec('26', 'Mathematics', Icons.functions_rounded),
    ResearchFieldSpec(
      '31',
      'Physics and Astronomy',
      Icons.rocket_launch_rounded,
    ),
    ResearchFieldSpec('16', 'Chemistry', Icons.science_rounded),
    ResearchFieldSpec(
      '13',
      'Biochemistry, Genetics and Molecular Biology',
      Icons.biotech_rounded,
    ),
    ResearchFieldSpec('33', 'Social Sciences', Icons.groups_rounded),
    ResearchFieldSpec('32', 'Psychology', Icons.psychology_rounded),
    ResearchFieldSpec('28', 'Neuroscience', Icons.hub_rounded),
    ResearchFieldSpec(
      '20',
      'Economics, Econometrics and Finance',
      Icons.trending_up_rounded,
    ),
    ResearchFieldSpec(
      '14',
      'Business, Management and Accounting',
      Icons.business_rounded,
    ),
    ResearchFieldSpec('23', 'Environmental Science', Icons.eco_rounded),
    ResearchFieldSpec('21', 'Energy', Icons.bolt_rounded),
    ResearchFieldSpec('25', 'Materials Science', Icons.layers_rounded),
    ResearchFieldSpec(
      '19',
      'Earth and Planetary Sciences',
      Icons.public_rounded,
    ),
    ResearchFieldSpec(
      '11',
      'Agricultural and Biological Sciences',
      Icons.agriculture_rounded,
    ),
    ResearchFieldSpec('12', 'Arts and Humanities', Icons.palette_rounded),
    ResearchFieldSpec('15', 'Chemical Engineering', Icons.propane_tank_rounded),
    ResearchFieldSpec('18', 'Decision Sciences', Icons.account_tree_rounded),
    ResearchFieldSpec(
      '24',
      'Immunology and Microbiology',
      Icons.coronavirus_rounded,
    ),
    ResearchFieldSpec('29', 'Nursing', Icons.medical_services_rounded),
    ResearchFieldSpec(
      '30',
      'Pharmacology, Toxicology and Pharmaceutics',
      Icons.medication_rounded,
    ),
    ResearchFieldSpec('34', 'Veterinary', Icons.pets_rounded),
    ResearchFieldSpec('35', 'Dentistry', Icons.masks_rounded),
    ResearchFieldSpec(
      '36',
      'Health Professions',
      Icons.health_and_safety_rounded,
    ),
  ];
}

// Một lĩnh vực chính trên lưới Home. Để ở constants (không ở models/) vì mang
// IconData — models/ hiện thuần Dart, không phụ thuộc Flutter.
class ResearchFieldSpec {
  final String id;
  final String label;
  final IconData icon;

  const ResearchFieldSpec(this.id, this.label, this.icon);

  ResearchScope get scope => ResearchScope.field(id: id, label: label);

  // Màu lấy xoay vòng từ bảng màu biểu đồ để 26 card không bị đơn sắc mà vẫn
  // nằm trong palette chung của app.
  Color get color =>
      AppColors.chartColors[int.parse(id) % AppColors.chartColors.length];
}

class AppColors {
  AppColors._();

  // Palette học thuật: navy đậm (tin cậy, tri thức) làm primary + vàng đồng
  // (thành tựu, trích dẫn) làm accent — thay cho tím/teal kiểu giải trí cũ,
  // phù hợp hơn với đối tượng nhà nghiên cứu.
  static const Color primary = Color(0xFF1B3A6B);
  static const Color primaryLight = Color(0xFF5B7FB5);
  static const Color primaryDark = Color(0xFF12294D);
  static const Color accent = Color(0xFFC99A3C);

  // Gradient dùng cho header/hero (top-left -> bottom-right)
  static const List<Color> primaryGradient = [
    Color(0xFF2C4F82),
    Color(0xFF14315C),
  ];

  static const Color background = Color(0xFFF5F6F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  // Nền phụ nhạt cho chip/khối trên card trắng
  static const Color surfaceAlt = Color(0xFFE8ECF3);

  static const Color textPrimary = Color(0xFF1A2233);
  static const Color textSecondary = Color(0xFF5B6472);
  static const Color textHint = Color(0xFF8A93A3);

  static const Color success = Color(0xFF2E9E6D);
  static const Color error = Color(0xFFC0392B);
  static const Color warning = Color(0xFFE0A63E);

  // Chart colors - bộ màu trầm, chuyên nghiệp cho biểu đồ báo cáo học thuật
  static const List<Color> chartColors = [
    Color(0xFF1B3A6B),
    Color(0xFFC99A3C),
    Color(0xFF2E7D6B),
    Color(0xFF8B4A62),
    Color(0xFF4A6FA5),
    Color(0xFFA97C50),
    Color(0xFF6B7280),
    Color(0xFF3F5B7A),
    Color(0xFFB0562D),
    Color(0xFF7A8B99),
  ];
}

// Bo góc & khoảng cách chuẩn để đồng bộ toàn app (phong cách FlutterFlow)
class AppRadius {
  AppRadius._();
  static const double card = 20;
  static const double field = 16;
  static const double chip = 30;
  static const double sheet = 28;
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

// Shadow mềm tông tím cho card nổi (phong cách FlutterFlow)
class AppShadows {
  AppShadows._();
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x14312B5A), blurRadius: 18, offset: Offset(0, 6)),
  ];
}

// Text styles dùng font Plus Jakarta Sans (google_fonts). Là getter (không
// const) vì google_fonts tạo TextStyle lúc chạy -> nơi dùng phải bỏ 'const'
// khi truyền trực tiếp vào widget const.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get heading1 => GoogleFonts.plusJakartaSans(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle get heading2 => GoogleFonts.plusJakartaSans(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static TextStyle get heading3 => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle get body =>
      GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.textPrimary);

  static TextStyle get bodySecondary =>
      GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.textSecondary);

  static TextStyle get caption =>
      GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary);

  static TextStyle get chip => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );
}
