import 'package:flutter/material.dart';

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

  static const Color primary = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF5E92F3);
  static const Color primaryDark = Color(0xFF003C8F);
  static const Color accent = Color(0xFF00ACC1);

  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);

  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // Chart colors - dùng cho biểu đồ
  static const List<Color> chartColors = [
    Color(0xFF1565C0),
    Color(0xFF00ACC1),
    Color(0xFF43A047),
    Color(0xFFFB8C00),
    Color(0xFFE53935),
    Color(0xFF8E24AA),
    Color(0xFF00897B),
    Color(0xFFD81B60),
    Color(0xFF6D4C41),
    Color(0xFF546E7A),
  ];
}

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  static const TextStyle chip = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
  );
}
