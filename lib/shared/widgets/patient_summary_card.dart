import 'package:flutter/material.dart';

import '../../core/constants/app_enums.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/case_detail/domain/case_models.dart';
import 'status_badge.dart';

class PatientSummaryCard extends StatelessWidget {
  const PatientSummaryCard({
    required this.summary,
    this.onTap,
    this.showDivider = false,
    super.key,
  });

  final CaseSummary summary;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.cardPadding,
          vertical: 12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppPalette.primarySurface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              alignment: Alignment.center,
              child: Text(
                summary.patientName.isNotEmpty ? summary.patientName[0] : '?',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.primary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          summary.patientName,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      StatusBadge(
                        label: ScreeningStatusX(summary.screeningStatus).label,
                        tone: switch (summary.screeningStatus) {
                          ScreeningStatus.ready => StatusTone.success,
                          ScreeningStatus.partial => StatusTone.warning,
                          ScreeningStatus.notReady => StatusTone.error,
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${summary.patientCode} · ${summary.tumorType} · ${summary.stage}',
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${summary.lineOfTherapy} 线 · ${summary.currentRegimen}',
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: <Widget>[
                      StatusBadge(
                        label:
                            '${summary.diseaseGroupCode} ${summary.crfTemplateVersion}',
                        tone: StatusTone.pending,
                      ),
                      StatusBadge(
                        label:
                            'CRF ${(summary.crfCompletionRate * 100).round()}%',
                        tone: summary.crfCompletionRate >= 0.8
                            ? StatusTone.success
                            : StatusTone.warning,
                      ),
                      if (summary.crfBlockingMissingCount > 0)
                        StatusBadge(
                          label: '缺 ${summary.crfBlockingMissingCount} 项关键',
                          tone: StatusTone.error,
                        ),
                    ],
                  ),
                  if (summary.tags.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: summary.tags
                          .take(3)
                          .map((tag) => StatusBadge(label: tag))
                          .toList(growable: false),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
