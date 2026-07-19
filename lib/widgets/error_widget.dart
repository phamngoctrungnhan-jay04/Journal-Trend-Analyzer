import 'package:flutter/material.dart';
import '../utils/constants.dart';

class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorWidget({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _ScrollSafeCenter(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Đã xảy ra lỗi',
              style: AppTextStyles.heading3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Widget hiển thị khi search không có kết quả
class EmptyResultWidget extends StatelessWidget {
  final String message;

  const EmptyResultWidget({
    super.key,
    this.message = 'Không tìm thấy kết quả nào.',
  });

  @override
  Widget build(BuildContext context) {
    return _ScrollSafeCenter(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Căn giữa nội dung khi đủ chỗ, nhưng cho phép CUỘN khi chiều cao bị co lại
// (vd header Home cao thêm) — tránh lỗi "BOTTOM OVERFLOWED". minHeight =
// maxHeight của vùng cha để nội dung vẫn nằm giữa khi màn đủ rộng.
class _ScrollSafeCenter extends StatelessWidget {
  final Widget child;

  const _ScrollSafeCenter({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: child),
          ),
        );
      },
    );
  }
}
