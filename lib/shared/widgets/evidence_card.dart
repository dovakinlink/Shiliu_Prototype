import 'package:flutter/material.dart';

import '../../core/constants/app_enums.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/case_detail/domain/case_models.dart';
import 'info_card.dart';
import 'status_badge.dart';

class EvidenceCard extends StatelessWidget {
  const EvidenceCard({
    required this.document,
    required this.highlighted,
    required this.onTap,
    super.key,
  });

  final EvidenceDocument document;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: highlighted
                ? AppPalette.primary
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      document.title,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  StatusBadge(label: DocumentModalityX(document.modality).label),
                  if (highlighted) ...<Widget>[
                    const SizedBox(width: AppSpacing.xs),
                    const StatusBadge(
                      label: '已定位',
                      tone: StatusTone.pending,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${document.dateLabel} · ${document.source}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(document.summary, style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppPalette.primary.withAlpha(15)
                      : AppPalette.primarySurface.withAlpha(180),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${document.anchor.label} · ${document.anchor.locator}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      document.anchor.excerpt,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
