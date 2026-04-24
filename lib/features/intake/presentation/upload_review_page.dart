import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_enums.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/mock/mock_app_store.dart';
import '../../../data/mock/mock_repositories.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/status_badge.dart';
import '../domain/upload_job.dart';

final _uploadJobProvider = FutureProvider.family<UploadJob?, String>((
  ref,
  jobId,
) async {
  ref.watch(mockAppStoreProvider);
  final jobs = await ref.read(uploadRepositoryProvider).getJobs();
  return jobs.where((j) => j.id == jobId).cast<UploadJob?>().firstOrNull;
});

class UploadReviewPage extends ConsumerStatefulWidget {
  const UploadReviewPage({required this.jobId, super.key});

  final String jobId;

  @override
  ConsumerState<UploadReviewPage> createState() => _UploadReviewPageState();
}

class _UploadReviewPageState extends ConsumerState<UploadReviewPage> {
  final Map<String, FieldReviewDecision> _decisions = {};

  @override
  Widget build(BuildContext context) {
    final jobAsync = ref.watch(_uploadJobProvider(widget.jobId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('人工确认')),
      body: jobAsync.when(
        data: (job) {
          if (job == null) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.page),
              child: AppEmptyState(
                icon: Icons.assignment_late_outlined,
                title: '任务不存在',
                description: '当前上传任务可能已被处理',
              ),
            );
          }
          return _buildBody(context, job, theme, isDark);
        },
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: AppErrorState(message: '$error'),
        ),
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.page),
          child: SkeletonBlock(height: 200),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    UploadJob job,
    ThemeData theme,
    bool isDark,
  ) {
    final details = job.extractionDetails;

    final conflictFields = details
        .where((d) => d.changeType == FieldChangeType.conflict)
        .toList();
    final updateFields = details
        .where((d) => d.changeType == FieldChangeType.update)
        .toList();
    final fillFields = details
        .where((d) => d.changeType == FieldChangeType.fill)
        .toList();
    final appendFields = details
        .where((d) => d.changeType == FieldChangeType.append)
        .toList();
    final unchangedFields = details
        .where((d) => d.changeType == FieldChangeType.unchanged)
        .toList();

    for (final d in unchangedFields) {
      _decisions.putIfAbsent(d.fieldName, () => FieldReviewDecision.acceptNew);
    }

    final actionableFields = [
      ...conflictFields,
      ...updateFields,
      ...fillFields,
      ...appendFields,
    ];
    final allDecided = actionableFields.every(
      (d) => _decisions.containsKey(d.fieldName),
    );

    final decidedCount = actionableFields
        .where((d) => _decisions.containsKey(d.fieldName))
        .length;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.sm,
              AppSpacing.page,
              AppSpacing.xxl,
            ),
            children: [
              _SourceBar(job: job, isDark: isDark),
              const SizedBox(height: AppSpacing.lg),

              Text(job.documentType, style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(job.description, style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.xl),

              _InfoSection(job: job, isDark: isDark),
              const SizedBox(height: AppSpacing.lg),

              _ChangeTypeSummaryBar(
                conflictCount: conflictFields.length,
                updateCount: updateFields.length,
                fillCount: fillFields.length,
                appendCount: appendFields.length,
                unchangedCount: unchangedFields.length,
                isDark: isDark,
              ),
              const SizedBox(height: AppSpacing.xl),

              if (conflictFields.isNotEmpty || updateFields.isNotEmpty) ...[
                _SectionHeader(
                  title: '需关注',
                  icon: Icons.warning_amber_rounded,
                  color: AppPalette.error,
                  count: conflictFields.length + updateFields.length,
                ),
                const SizedBox(height: AppSpacing.sm),
                ...[...conflictFields, ...updateFields].map(
                  (d) => _ComparisonFieldTile(
                    detail: d,
                    decision: _decisions[d.fieldName],
                    onDecide: (decision) =>
                        setState(() => _decisions[d.fieldName] = decision),
                    onReset: () =>
                        setState(() => _decisions.remove(d.fieldName)),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              if (fillFields.isNotEmpty) ...[
                _SectionHeader(
                  title: '补齐字段',
                  icon: Icons.add_circle_outline_rounded,
                  color: AppPalette.pending,
                  count: fillFields.length,
                ),
                const SizedBox(height: AppSpacing.sm),
                ...fillFields.map(
                  (d) => _ComparisonFieldTile(
                    detail: d,
                    decision: _decisions[d.fieldName],
                    onDecide: (decision) =>
                        setState(() => _decisions[d.fieldName] = decision),
                    onReset: () =>
                        setState(() => _decisions.remove(d.fieldName)),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              if (appendFields.isNotEmpty) ...[
                _SectionHeader(
                  title: '新增数据',
                  icon: Icons.fiber_new_outlined,
                  color: AppPalette.success,
                  count: appendFields.length,
                ),
                const SizedBox(height: AppSpacing.sm),
                ...appendFields.map(
                  (d) => _ComparisonFieldTile(
                    detail: d,
                    decision: _decisions[d.fieldName],
                    onDecide: (decision) =>
                        setState(() => _decisions[d.fieldName] = decision),
                    onReset: () =>
                        setState(() => _decisions.remove(d.fieldName)),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              if (unchangedFields.isNotEmpty) ...[
                _UnchangedSection(fields: unchangedFields, isDark: isDark),
              ],
            ],
          ),
        ),

        _BottomBar(
          allDecided: allDecided,
          actionableCount: actionableFields.length,
          decidedCount: decidedCount,
          onSubmit: () => _submit(job),
        ),
      ],
    );
  }

  Future<void> _submit(UploadJob job) async {
    ref
        .read(mockAppStoreProvider.notifier)
        .confirmUploadReview(job.id, decisions: _decisions);

    if (!mounted) return;

    final details = job.extractionDetails;
    final appendCount = details
        .where(
          (d) =>
              d.changeType == FieldChangeType.append &&
              _decisions[d.fieldName] == FieldReviewDecision.acceptNew,
        )
        .length;
    final updateCount = details
        .where(
          (d) =>
              d.changeType == FieldChangeType.update &&
              _decisions[d.fieldName] == FieldReviewDecision.acceptNew,
        )
        .length;
    final fillCount = details
        .where(
          (d) =>
              d.changeType == FieldChangeType.fill &&
              _decisions[d.fieldName] == FieldReviewDecision.acceptNew,
        )
        .length;

    final summaryParts = <String>[];
    if (appendCount > 0) summaryParts.add('新增 $appendCount 项');
    if (updateCount > 0) summaryParts.add('更新 $updateCount 项');
    if (fillCount > 0) summaryParts.add('补齐 $fillCount 项');
    final summaryText = summaryParts.isEmpty
        ? '已入库'
        : '已入库 · ${summaryParts.join(' · ')}';

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SuccessOverlay(summaryText: summaryText),
    );

    if (mounted) {
      context.pop();
    }
  }
}

// ---------------------------------------------------------------------------
// Source indicator bar
// ---------------------------------------------------------------------------
class _SourceBar extends StatelessWidget {
  const _SourceBar({required this.job, required this.isDark});

  final UploadJob job;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (job.source) {
      UploadSource.camera => AppPalette.pending,
      UploadSource.pdf => AppPalette.secondary,
      UploadSource.voice => AppPalette.conflict,
      UploadSource.gallery => AppPalette.warning,
    };
    final icon = switch (job.source) {
      UploadSource.camera => Icons.camera_alt_outlined,
      UploadSource.pdf => Icons.description_outlined,
      UploadSource.voice => Icons.mic_none_rounded,
      UploadSource.gallery => Icons.photo_library_outlined,
    };

    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: color, width: 3)),
        color: color.withAlpha(isDark ? 12 : 8),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(AppSpacing.radiusSm),
          bottomRight: Radius.circular(AppSpacing.radiusSm),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            job.source.label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          StatusBadge(label: '待人工确认', tone: StatusTone.conflict),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info section
// ---------------------------------------------------------------------------
class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.job, required this.isDark});

  final UploadJob job;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? AppPalette.surfaceVariantDark
            : AppPalette.surfaceVariantLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        children: [
          _KVRow(
            icon: Icons.person_outline_rounded,
            label: '患者',
            value: job.patientName,
            theme: theme,
          ),
          const SizedBox(height: AppSpacing.sm),
          _KVRow(
            icon: Icons.article_outlined,
            label: '文档类型',
            value: job.documentType,
            theme: theme,
          ),
          const SizedBox(height: AppSpacing.sm),
          _KVRow(
            icon: Icons.schedule_rounded,
            label: '创建时间',
            value: job.createdAtLabel,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _KVRow extends StatelessWidget {
  const _KVRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: theme.textTheme.bodySmall?.color),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 64,
          child: Text(label, style: theme.textTheme.labelSmall),
        ),
        Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Change type summary bar (compact)
// ---------------------------------------------------------------------------
class _ChangeTypeSummaryBar extends StatelessWidget {
  const _ChangeTypeSummaryBar({
    required this.conflictCount,
    required this.updateCount,
    required this.fillCount,
    required this.appendCount,
    required this.unchangedCount,
    required this.isDark,
  });

  final int conflictCount;
  final int updateCount;
  final int fillCount;
  final int appendCount;
  final int unchangedCount;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chips = <Widget>[
      if (conflictCount > 0)
        _chip(theme, '$conflictCount 冲突', AppPalette.error),
      if (updateCount > 0) _chip(theme, '$updateCount 更新', AppPalette.warning),
      if (fillCount > 0) _chip(theme, '$fillCount 补齐', AppPalette.pending),
      if (appendCount > 0) _chip(theme, '$appendCount 新增', AppPalette.success),
      if (unchangedCount > 0)
        _chip(
          theme,
          '$unchangedCount 一致',
          isDark ? Colors.white54 : Colors.black45,
        ),
    ];

    return Wrap(spacing: 8, runSpacing: 6, children: chips);
  }

  Widget _chip(ThemeData theme, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withAlpha(60), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
    required this.count,
  });

  final String title;
  final IconData icon;
  final Color color;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(title, style: theme.textTheme.titleSmall?.copyWith(color: color)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Text(
            '$count',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Comparison field tile — the core component
// ---------------------------------------------------------------------------

Color _colorForChangeType(FieldChangeType type) => switch (type) {
  FieldChangeType.conflict => AppPalette.error,
  FieldChangeType.update => AppPalette.warning,
  FieldChangeType.fill => AppPalette.pending,
  FieldChangeType.append => AppPalette.success,
  FieldChangeType.unchanged => AppPalette.muted,
};

StatusTone _toneForChangeType(FieldChangeType type) => switch (type) {
  FieldChangeType.append => StatusTone.success,
  FieldChangeType.fill => StatusTone.pending,
  FieldChangeType.update => StatusTone.warning,
  FieldChangeType.conflict => StatusTone.error,
  FieldChangeType.unchanged => StatusTone.neutral,
};

class _ComparisonFieldTile extends StatelessWidget {
  const _ComparisonFieldTile({
    required this.detail,
    required this.decision,
    required this.onDecide,
    required this.onReset,
    required this.isDark,
  });

  final ExtractionDetail detail;
  final FieldReviewDecision? decision;
  final ValueChanged<FieldReviewDecision> onDecide;
  final VoidCallback onReset;
  final bool isDark;

  bool get _isDecided => decision != null;
  Color get _accentColor => _colorForChangeType(detail.changeType);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasComparison =
        detail.changeType == FieldChangeType.update ||
        detail.changeType == FieldChangeType.conflict;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: _isDecided
                ? AppPalette.success.withAlpha(120)
                : _accentColor.withAlpha(60),
          ),
          color: _isDecided
              ? AppPalette.success.withAlpha(isDark ? 8 : 6)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme),
              if (detail.fieldPath.isNotEmpty ||
                  detail.canonicalImpact != null) ...[
                const SizedBox(height: AppSpacing.sm),
                _buildCrfMapping(theme),
              ],
              const SizedBox(height: AppSpacing.md),

              if (hasComparison) _buildComparisonLayout(theme),
              if (!hasComparison) _buildSingleValueLayout(theme),

              if (detail.sourceLocator != null) ...[
                const SizedBox(height: AppSpacing.sm),
                _buildSourceLink(context, theme),
              ],

              if (!_isDecided) ...[
                const SizedBox(height: AppSpacing.md),
                _buildActions(hasComparison),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Icon(
          _isDecided
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 18,
          color: _isDecided ? AppPalette.success : _accentColor,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(detail.fieldName, style: theme.textTheme.titleSmall),
        ),
        StatusBadge(
          label: detail.changeType.label,
          tone: _toneForChangeType(detail.changeType),
        ),
        if (_isDecided) ...[
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: onReset,
            child: Text(
              '撤回',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppPalette.muted,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCrfMapping(ThemeData theme) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: <Widget>[
        if (detail.fieldPath.isNotEmpty)
          StatusBadge(label: detail.fieldPath.join(' / ')),
        if (detail.fieldCode != null) StatusBadge(label: detail.fieldCode!),
        if (detail.canonicalImpact != null)
          StatusBadge(
            label: '主干回写 ${detail.canonicalImpact}',
            tone: StatusTone.pending,
          ),
      ],
    );
  }

  Widget _buildComparisonLayout(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _CompactValueBox(
            label: '当前值',
            value: detail.existingValue ?? '-',
            icon: Icons.inventory_2_outlined,
            color: isDark ? Colors.white38 : Colors.black38,
            isDark: isDark,
            isHighlighted: decision == FieldReviewDecision.keepOld,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Icon(
            Icons.arrow_forward_rounded,
            size: 16,
            color: _accentColor,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _CompactValueBox(
            label: '新识别',
            value: detail.value,
            icon: Icons.auto_awesome_rounded,
            color: _accentColor,
            isDark: isDark,
            isHighlighted: decision == FieldReviewDecision.acceptNew,
          ),
        ),
      ],
    );
  }

  Widget _buildSingleValueLayout(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? AppPalette.surfaceVariantDark
                : AppPalette.surfaceVariantLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 14, color: _accentColor),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  detail.value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (detail.changeType == FieldChangeType.fill &&
            detail.existingValue != null) ...[
          const SizedBox(height: 4),
          Text(
            '之前：${detail.existingValue}',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: isDark
                  ? AppPalette.textTertiaryDark
                  : AppPalette.textTertiaryLight,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSourceLink(BuildContext context, ThemeData theme) {
    return GestureDetector(
      onTap: () => _showSourceSheet(context, theme),
      child: Row(
        children: [
          Icon(
            Icons.format_quote_rounded,
            size: 13,
            color: AppPalette.primary.withAlpha(180),
          ),
          const SizedBox(width: 4),
          Text(
            '查看原文 · ${detail.sourceLocator}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppPalette.primary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(bool hasComparison) {
    if (hasComparison) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => onDecide(FieldReviewDecision.keepOld),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('保留旧值', style: TextStyle(fontSize: 13)),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: FilledButton(
              onPressed: () => onDecide(FieldReviewDecision.acceptNew),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('采用新值', style: TextStyle(fontSize: 13)),
            ),
          ),
          if (detail.changeType == FieldChangeType.conflict) ...[
            const SizedBox(width: AppSpacing.xs),
            IconButton(
              onPressed: () => onDecide(FieldReviewDecision.markConflict),
              icon: const Icon(Icons.report_outlined, size: 20),
              tooltip: '标记冲突',
              style: IconButton.styleFrom(
                foregroundColor: AppPalette.error,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => onDecide(FieldReviewDecision.acceptNew),
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('确认'),
            style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
        ),
      ],
    );
  }

  void _showSourceSheet(BuildContext context, ThemeData theme) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.lg,
          AppSpacing.page,
          AppSpacing.xl + MediaQuery.paddingOf(ctx).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('原文溯源', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              '${detail.fieldName} · ${detail.sourceLocator}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppPalette.textSecondaryDark
                    : AppPalette.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              decoration: BoxDecoration(
                color: isDark
                    ? AppPalette.surfaceVariantDark
                    : AppPalette.surfaceVariantLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border(
                  left: BorderSide(color: AppPalette.primary, width: 3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 14,
                        color: AppPalette.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'AI 识别值：${detail.value}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppPalette.primary,
                        ),
                      ),
                    ],
                  ),
                  if (detail.sourceExcerpt != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      detail.sourceExcerpt!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Compact value box (used in comparison layout)
// ---------------------------------------------------------------------------
class _CompactValueBox extends StatelessWidget {
  const _CompactValueBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
    this.isHighlighted = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isHighlighted
            ? color.withAlpha(isDark ? 20 : 12)
            : (isDark
                  ? AppPalette.surfaceVariantDark
                  : AppPalette.surfaceVariantLight),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: isHighlighted
            ? Border.all(color: color.withAlpha(80), width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Unchanged section (collapsible)
// ---------------------------------------------------------------------------
class _UnchangedSection extends StatefulWidget {
  const _UnchangedSection({required this.fields, required this.isDark});

  final List<ExtractionDetail> fields;
  final bool isDark;

  @override
  State<_UnchangedSection> createState() => _UnchangedSectionState();
}

class _UnchangedSectionState extends State<_UnchangedSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 18,
                  color: widget.isDark ? Colors.white38 : Colors.black38,
                ),
                const SizedBox(width: 6),
                Text(
                  '无变化',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: widget.isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: (widget.isDark ? Colors.white : Colors.black)
                        .withAlpha(12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    '${widget.fields.length}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: widget.isDark ? Colors.white54 : Colors.black45,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  _expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 20,
                  color: widget.isDark ? Colors.white38 : Colors.black38,
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: AppSpacing.sm),
          ...widget.fields.map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: (widget.isDark ? Colors.white : Colors.black)
                      .withAlpha(6),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: widget.isDark ? Colors.white38 : Colors.black38,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        d.fieldName,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    Text(
                      d.value,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom bar with progress and submit
// ---------------------------------------------------------------------------
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.allDecided,
    required this.actionableCount,
    required this.decidedCount,
    required this.onSubmit,
  });

  final bool allDecided;
  final int actionableCount;
  final int decidedCount;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottom = MediaQuery.paddingOf(context).bottom;

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (actionableCount > 0) ...[
            Row(
              children: [
                for (int i = 0; i < actionableCount; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < decidedCount
                          ? AppPalette.success
                          : (isDark
                                ? AppPalette.borderDark
                                : AppPalette.borderLight),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  '已确认 $decidedCount / $actionableCount 项',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppPalette.textSecondaryDark
                        : AppPalette.textSecondaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: allDecided ? onSubmit : null,
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: const Text('提交确认'),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Success overlay with summary
// ---------------------------------------------------------------------------
class _SuccessOverlay extends StatefulWidget {
  const _SuccessOverlay({required this.summaryText});

  final String summaryText;

  @override
  State<_SuccessOverlay> createState() => _SuccessOverlayState();
}

class _SuccessOverlayState extends State<_SuccessOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 200,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? AppPalette.surfaceDark
                : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withAlpha(30),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppPalette.success,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                widget.summaryText,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
