import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';

enum StatusTone { neutral, success, warning, error, pending, conflict }

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.label,
    this.tone = StatusTone.neutral,
    super.key,
  });

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alpha = isDark ? 25 : 18;

    final (bg, fg) = switch (tone) {
      StatusTone.success => (
          AppPalette.success.withAlpha(alpha),
          isDark ? const Color(0xFF4ADE80) : AppPalette.success,
        ),
      StatusTone.warning => (
          AppPalette.warning.withAlpha(alpha),
          isDark ? AppPalette.warning : const Color(0xFFB45309),
        ),
      StatusTone.error => (
          AppPalette.error.withAlpha(alpha),
          isDark ? const Color(0xFFFCA5A5) : AppPalette.error,
        ),
      StatusTone.pending => (
          AppPalette.pending.withAlpha(alpha),
          isDark ? const Color(0xFF93C5FD) : AppPalette.pending,
        ),
      StatusTone.conflict => (
          AppPalette.conflict.withAlpha(alpha),
          isDark ? const Color(0xFFC4B5FD) : AppPalette.conflict,
        ),
      StatusTone.neutral => (
          isDark ? Colors.white.withAlpha(12) : AppPalette.primary.withAlpha(14),
          isDark ? AppPalette.textSecondaryDark : AppPalette.textSecondaryLight,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
          height: 1.4,
        ),
      ),
    );
  }
}
