import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  // Detail screens
  static const int journalWorksPerPage = 20;
  static const int keywordAuthorsCount = 10;

  // App info
  static const String appName = 'Journal Trend Analyzer';
  static const String appVersion = '1.0.0';

  // Suggested search topics
  static const List<String> suggestedTopics = [
    'Artificial Intelligence',
    'Software Engineering',
    'Data Science',
    'Cybersecurity',
    'Internet of Things',
    'Blockchain',
    'Machine Learning',
    'Deep Learning',
  ];
}

class AppColors {
  AppColors._();

  // Palette FlutterFlow-style: indigo/violet primary + teal accent + neutral sạch
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryLight = Color(0xFFA29BFE);
  static const Color primaryDark = Color(0xFF4834D4);
  static const Color accent = Color(0xFF00CEC9);

  // Gradient dùng cho header/hero (top-left -> bottom-right)
  static const List<Color> primaryGradient = [
    Color(0xFF7C6CF6),
    Color(0xFF5A4BE0),
  ];

  static const Color background = Color(0xFFF4F5FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  // Nền phụ nhạt cho chip/khối trên card trắng
  static const Color surfaceAlt = Color(0xFFF1F0FC);

  static const Color textPrimary = Color(0xFF1E1B33);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);

  static const Color success = Color(0xFF00B894);
  static const Color error = Color(0xFFFF5A6E);
  static const Color warning = Color(0xFFFDCB6E);

  // Chart colors - bộ màu hiện đại cho biểu đồ
  static const List<Color> chartColors = [
    Color(0xFF6C5CE7),
    Color(0xFF00CEC9),
    Color(0xFFFF6B9D),
    Color(0xFFFDCB6E),
    Color(0xFF0984E3),
    Color(0xFF00B894),
    Color(0xFFE17055),
    Color(0xFFA29BFE),
    Color(0xFFFD79A8),
    Color(0xFF636E72),
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
    BoxShadow(
      color: Color(0x14312B5A),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
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

  static TextStyle get body => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodySecondary => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: AppColors.textSecondary,
      );

  static TextStyle get caption => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        color: AppColors.textSecondary,
      );

  static TextStyle get chip => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      );
}
