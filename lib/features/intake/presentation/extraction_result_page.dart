import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_enums.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/mock/mock_app_store.dart';
import '../../../data/mock/mock_repositories.dart';
import '../../../shared/widgets/status_badge.dart';
import '../domain/upload_job.dart';

final _extractionJobProvider =
    FutureProvider.family<UploadJob?, String>((ref, jobId) async {
  ref.watch(mockAppStoreProvider);
  final jobs = await ref.read(uploadRepositoryProvider).getJobs();
  return jobs.where((j) => j.id == jobId).cast<UploadJob?>().firstOrNull;
});

class ExtractionResultPage extends ConsumerWidget {
  const ExtractionResultPage({required this.jobId, super.key});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync = ref.watch(_extractionJobProvider(jobId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('抽取结果')),
      body: jobAsync.when(
        data: (job) {
          if (job == null) {
            return const Center(child: Text('任务不存在'));
          }
          return _Body(job: job, isDark: isDark, jobId: jobId);
        },
        error: (e, _) => Center(child: Text('$e')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.job,
    required this.isDark,
    required this.jobId,
  });

  final UploadJob job;
  final bool isDark;
  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final details = job.extractionDetails;

    final appendCount =
        details.where((d) => d.changeType == FieldChangeType.append).length;
    final fillCount =
        details.where((d) => d.changeType == FieldChangeType.fill).length;
    final updateCount =
        details.where((d) => d.changeType == FieldChangeType.update).length;
    final conflictCount =
        details.where((d) => d.changeType == FieldChangeType.conflict).length;
    final unchangedCount =
        details.where((d) => d.changeType == FieldChangeType.unchanged).length;

    final needsManualReview = updateCount + conflictCount;
    final allUnchanged = unchangedCount == details.length;
    final hasOnlyAutoItems =
        needsManualReview == 0 && (appendCount + fillCount) > 0;

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.sm,
              AppSpacing.page,
              AppSpacing.xxl,
            ),
            children: <Widget>[
              _DocumentPreviewCard(job: job, isDark: isDark),
              const SizedBox(height: AppSpacing.xl),
              _ChangeTypeSummary(
                appendCount: appendCount,
                fillCount: fillCount,
                updateCount: updateCount,
                conflictCount: conflictCount,
                unchangedCount: unchangedCount,
                isDark: isDark,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('识别字段', style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.md),
              ...details.map(
                (detail) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _ExtractionFieldTile(
                    detail: detail,
                    isDark: isDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        _BottomCTA(
          jobId: jobId,
          allUnchanged: allUnchanged,
          hasOnlyAutoItems: hasOnlyAutoItems,
          autoItemCount: appendCount + fillCount,
          needsManualReview: needsManualReview,
          ref: ref,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Document preview card (simulated)
// ---------------------------------------------------------------------------
class _DocumentPreviewCard extends StatelessWidget {
  const _DocumentPreviewCard({
    required this.job,
    required this.isDark,
  });

  final UploadJob job;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: isDark
            ? AppPalette.surfaceVariantDark
            : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? AppPalette.borderDark : AppPalette.borderLight,
          width: 0.5,
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _mockTextLine(0.6, isDark),
                  const SizedBox(height: 6),
                  _mockTextLine(0.8, isDark),
                  const SizedBox(height: 6),
                  _mockTextLine(0.5, isDark),
                  const SizedBox(height: 10),
                  _highlightBar(AppPalette.primary, 0.45),
                  const SizedBox(height: 6),
                  _mockTextLine(0.7, isDark),
                  const SizedBox(height: 6),
                  _highlightBar(AppPalette.warning, 0.35),
                  const SizedBox(height: 6),
                  _mockTextLine(0.55, isDark),
                  const SizedBox(height: 6),
                  _highlightBar(AppPalette.success, 0.5),
                ],
              ),
            ),
          ),
          Positioned(
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: (isDark ? AppPalette.surfaceDark : Colors.white)
                    .withAlpha(230),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(
                  color: isDark
                      ? AppPalette.borderDark
                      : AppPalette.borderLight,
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 13,
                    color: AppPalette.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '原文档预览 · AI 标注',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppPalette.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mockTextLine(double widthFraction, bool isDark) {
    return FractionallySizedBox(
      widthFactor: widthFraction,
      child: Container(
        height: 8,
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black)
              .withAlpha(isDark ? 15 : 10),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _highlightBar(Color color, double widthFraction) {
    return FractionallySizedBox(
      widthFactor: widthFraction,
      child: Container(
        height: 10,
        decoration: BoxDecoration(
          color: color.withAlpha(40),
          borderRadius: BorderRadius.circular(3),
          border: Border(left: BorderSide(color: color, width: 2.5)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Change type summary
// ---------------------------------------------------------------------------
class _ChangeTypeSummary extends StatelessWidget {
  const _ChangeTypeSummary({
    required this.appendCount,
    required this.fillCount,
    required this.updateCount,
    required this.conflictCount,
    required this.unchangedCount,
    required this.isDark,
  });

  final int appendCount;
  final int fillCount;
  final int updateCount;
  final int conflictCount;
  final int unchangedCount;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <_ChangeStatItem>[
      if (appendCount > 0)
        _ChangeStatItem(appendCount, '新增', AppPalette.success),
      if (fillCount > 0)
        _ChangeStatItem(fillCount, '补齐', AppPalette.pending),
      if (updateCount > 0)
        _ChangeStatItem(updateCount, '更新', AppPalette.warning),
      if (conflictCount > 0)
        _ChangeStatItem(conflictCount, '冲突', AppPalette.error),
      if (unchangedCount > 0)
        _ChangeStatItem(unchangedCount, '一致', isDark ? Colors.white54 : Colors.black45),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.cardPadding,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppPalette.surfaceVariantDark
            : AppPalette.surfaceVariantLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 28,
                color: (isDark ? Colors.white : Colors.black).withAlpha(15),
              ),
            _buildStatColumn(theme, items[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildStatColumn(ThemeData theme, _ChangeStatItem item) {
    return Column(
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.color,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${item.count}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: item.color,
                fontFeatures: const <FontFeature>[
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(item.label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

class _ChangeStatItem {
  const _ChangeStatItem(this.count, this.label, this.color);
  final int count;
  final String label;
  final Color color;
}

// ---------------------------------------------------------------------------
// Single extraction field tile
// ---------------------------------------------------------------------------

StatusTone _toneForChangeType(FieldChangeType type) => switch (type) {
      FieldChangeType.append => StatusTone.success,
      FieldChangeType.fill => StatusTone.pending,
      FieldChangeType.update => StatusTone.warning,
      FieldChangeType.conflict => StatusTone.error,
      FieldChangeType.unchanged => StatusTone.neutral,
    };

class _ExtractionFieldTile extends StatelessWidget {
  const _ExtractionFieldTile({
    required this.detail,
    required this.isDark,
  });

  final ExtractionDetail detail;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final changeTone = _toneForChangeType(detail.changeType);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? AppPalette.borderDark : AppPalette.borderLight,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.auto_awesome_rounded,
                size: 14,
                color: AppPalette.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  detail.fieldName,
                  style: theme.textTheme.labelMedium,
                ),
              ),
              StatusBadge(
                label: detail.changeType.label,
                tone: changeTone,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            detail.value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          if (detail.existingValue != null &&
              (detail.changeType == FieldChangeType.update ||
                  detail.changeType == FieldChangeType.conflict)) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              '当前值：${detail.existingValue}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: isDark
                    ? AppPalette.textTertiaryDark
                    : AppPalette.textTertiaryLight,
              ),
            ),
          ],
          if (detail.sourceLocator != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: <Widget>[
                Icon(
                  Icons.format_quote_rounded,
                  size: 13,
                  color: isDark
                      ? AppPalette.textTertiaryDark
                      : AppPalette.textTertiaryLight,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${detail.sourceLocator}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: isDark
                          ? AppPalette.textTertiaryDark
                          : AppPalette.textTertiaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom CTA
// ---------------------------------------------------------------------------
class _BottomCTA extends StatelessWidget {
  const _BottomCTA({
    required this.jobId,
    required this.allUnchanged,
    required this.hasOnlyAutoItems,
    required this.autoItemCount,
    required this.needsManualReview,
    required this.ref,
  });

  final String jobId;
  final bool allUnchanged;
  final bool hasOnlyAutoItems;
  final int autoItemCount;
  final int needsManualReview;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottom = MediaQuery.paddingOf(context).bottom;

    String statusText;
    Color statusColor;
    String buttonLabel;
    IconData buttonIcon;
    bool enabled;

    if (allUnchanged) {
      statusText = '全部一致，无需更新';
      statusColor = isDark ? Colors.white54 : Colors.black45;
      buttonLabel = '返回';
      buttonIcon = Icons.check_circle_outline_rounded;
      enabled = true;
    } else if (hasOnlyAutoItems) {
      statusText = '$autoItemCount 项可直接入库';
      statusColor = AppPalette.success;
      buttonLabel = '快速入库';
      buttonIcon = Icons.bolt_rounded;
      enabled = true;
    } else {
      statusText = '$needsManualReview 项需人工确认';
      statusColor = AppPalette.warning;
      buttonLabel = '进入人工确认';
      buttonIcon = Icons.rate_review_outlined;
      enabled = true;
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.md,
        AppSpacing.page,
        AppSpacing.md + bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppPalette.surfaceDark : AppPalette.surfaceLight,
        border: Border(
          top: BorderSide(
            color: isDark ? AppPalette.borderDark : AppPalette.borderLight,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              statusText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: enabled
                ? () {
                    if (allUnchanged) {
                      context.pop();
                    } else if (hasOnlyAutoItems) {
                      ref
                          .read(mockAppStoreProvider.notifier)
                          .confirmUploadReview(jobId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('已入库 · $autoItemCount 项数据'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      context.pop();
                    } else {
                      context.push('/upload-review/$jobId');
                    }
                  }
                : null,
            icon: Icon(buttonIcon, size: 18),
            label: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}
