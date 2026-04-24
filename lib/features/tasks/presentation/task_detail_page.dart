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
import '../domain/task_models.dart';

final taskDetailProvider = FutureProvider.family<CompletenessTask?, String>((
  ref,
  taskId,
) async {
  ref.watch(mockAppStoreProvider);
  return ref.read(taskRepositoryProvider).getTask(taskId);
});

class TaskDetailPage extends ConsumerWidget {
  const TaskDetailPage({required this.taskId, super.key});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskAsync = ref.watch(taskDetailProvider(taskId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('任务详情')),
      body: taskAsync.when(
        data: (task) {
          if (task == null) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.page),
              child: AppEmptyState(
                icon: Icons.assignment_late_outlined,
                title: '任务不存在',
                description: '当前任务可能已被处理',
              ),
            );
          }

          final isConflict = task.type == TaskType.conflictReview;
          final accentColor = task.isBlocking
              ? AppPalette.error
              : isConflict
              ? AppPalette.conflict
              : AppPalette.warning;

          final cases = ref.read(mockAppStoreProvider).cases;
          final matchingCases = cases.where(
            (b) => b.detail.summary.id == task.caseId,
          );
          final patientName = matchingCases.isEmpty
              ? '未知患者'
              : matchingCases.first.detail.summary.patientName;
          final patientCode = matchingCases.isEmpty
              ? ''
              : matchingCases.first.detail.summary.patientCode;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.sm,
              AppSpacing.page,
              AppSpacing.xxxxl,
            ),
            children: <Widget>[
              // ── Status indicator bar ──
              _ColorBar(
                icon: isConflict
                    ? Icons.compare_arrows_rounded
                    : Icons.edit_note_rounded,
                label: task.type.label,
                color: accentColor,
                isDark: isDark,
                isBlocking: task.isBlocking,
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Task title ──
              Text(task.title, style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(task.description, style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.xl),

              // ── Detail fields ──
              _DetailSection(
                task: task,
                isDark: isDark,
                patientName: patientName,
                patientCode: patientCode,
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Fields involved ──
              Text('涉及字段', style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: task.fields
                    .map((f) {
                      final tone = task.isBlocking
                          ? StatusTone.error
                          : isConflict
                          ? StatusTone.conflict
                          : StatusTone.warning;
                      return StatusBadge(label: f, tone: tone);
                    })
                    .toList(growable: false),
              ),

              if (isConflict) ...<Widget>[
                const SizedBox(height: AppSpacing.xl),
                _ConflictResolutionSection(
                  task: task,
                  isDark: isDark,
                  onResolve: (resolvedValue) async {
                    await ref
                        .read(taskRepositoryProvider)
                        .resolveTask(task.id, resolvedValue: resolvedValue);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('已完成冲突核对，采用值：$resolvedValue')),
                      );
                      context.pop();
                    }
                  },
                ),
              ] else ...<Widget>[
                const SizedBox(height: AppSpacing.xxxl),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () =>
                        context.pushReplacement('/screening/${task.caseId}'),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('前往补录'),
                  ),
                ),
              ],
            ],
          );
        },
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: AppErrorState(message: '$error'),
        ),
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.page),
          child: SkeletonBlock(height: 160),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status color bar at top
// ---------------------------------------------------------------------------
class _ColorBar extends StatelessWidget {
  const _ColorBar({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.isBlocking,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final bool isBlocking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
        children: <Widget>[
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isBlocking) ...<Widget>[
            const SizedBox(width: 8),
            StatusBadge(label: '阻断项', tone: StatusTone.error),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Key-value detail section (now includes patient info)
// ---------------------------------------------------------------------------
class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.task,
    required this.isDark,
    required this.patientName,
    required this.patientCode,
  });

  final CompletenessTask task;
  final bool isDark;
  final String patientName;
  final String patientCode;

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
        children: <Widget>[
          _DetailRow(
            icon: Icons.medical_information_outlined,
            label: '所属病例',
            value: '$patientName（$patientCode）',
            theme: theme,
          ),
          const SizedBox(height: AppSpacing.sm),
          _DetailRow(
            icon: Icons.person_outline_rounded,
            label: '责任人',
            value: task.owner,
            theme: theme,
          ),
          const SizedBox(height: AppSpacing.sm),
          _DetailRow(
            icon: Icons.schedule_rounded,
            label: '期望完成',
            value: task.dueLabel,
            theme: theme,
          ),
          const SizedBox(height: AppSpacing.sm),
          _DetailRow(
            icon: Icons.account_tree_outlined,
            label: '任务范围',
            value: task.scope.label,
            theme: theme,
          ),
          if (task.templateId != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            _DetailRow(
              icon: Icons.view_list_outlined,
              label: '模板',
              value: task.templateId!,
              theme: theme,
            ),
          ],
          if (task.fieldPath.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            _DetailRow(
              icon: Icons.route_outlined,
              label: 'CRF路径',
              value: task.fieldPath.join(' / '),
              theme: theme,
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
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
      children: <Widget>[
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
// Conflict resolution section — display + selection + confirm
// ---------------------------------------------------------------------------

enum _ResolutionChoice { sourceA, sourceB, custom }

class _ConflictResolutionSection extends StatefulWidget {
  const _ConflictResolutionSection({
    required this.task,
    required this.isDark,
    required this.onResolve,
  });

  final CompletenessTask task;
  final bool isDark;
  final Future<void> Function(String resolvedValue) onResolve;

  @override
  State<_ConflictResolutionSection> createState() =>
      _ConflictResolutionSectionState();
}

class _ConflictResolutionSectionState
    extends State<_ConflictResolutionSection> {
  _ResolutionChoice? _choice;
  final _customController = TextEditingController();
  bool _isSubmitting = false;

  String? get _resolvedValue {
    if (widget.task.conflicts.isEmpty) return null;
    final conflict = widget.task.conflicts.first;
    switch (_choice) {
      case _ResolutionChoice.sourceA:
        return conflict.valueA;
      case _ResolutionChoice.sourceB:
        return conflict.valueB;
      case _ResolutionChoice.custom:
        final text = _customController.text.trim();
        return text.isEmpty ? null : text;
      case null:
        return null;
    }
  }

  bool get _canSubmit => _resolvedValue != null && !_isSubmitting;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final conflicts = widget.task.conflicts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('冲突详情', style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),

        for (int i = 0; i < conflicts.length; i++) ...<Widget>[
          _buildConflictCard(context, conflicts[i]),
          if (i < conflicts.length - 1) const SizedBox(height: AppSpacing.sm),
        ],

        const SizedBox(height: AppSpacing.xl),
        Text('请选择核对结果', style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),

        if (conflicts.isNotEmpty) ...<Widget>[
          _buildOptionTile(
            context,
            choice: _ResolutionChoice.sourceA,
            label: '采用「${conflicts.first.sourceA}」的值',
            value: conflicts.first.valueA,
            color: AppPalette.error,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildOptionTile(
            context,
            choice: _ResolutionChoice.sourceB,
            label: '采用「${conflicts.first.sourceB}」的值',
            value: conflicts.first.valueB,
            color: AppPalette.success,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildCustomInputTile(context),
        ],

        const SizedBox(height: AppSpacing.xxxl),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _canSubmit
                ? () async {
                    setState(() => _isSubmitting = true);
                    try {
                      await widget.onResolve(_resolvedValue!);
                    } finally {
                      if (mounted) {
                        setState(() => _isSubmitting = false);
                      }
                    }
                  }
                : null,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_rounded, size: 18),
            label: Text(_isSubmitting ? '提交中…' : '确认核对结果'),
          ),
        ),
      ],
    );
  }

  Widget _buildConflictCard(BuildContext context, ConflictEntry conflict) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.cardPadding,
          vertical: 10,
        ),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.swap_horiz_rounded,
              size: 16,
              color: AppPalette.conflict,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(conflict.field, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppPalette.error.withAlpha(
                              widget.isDark ? 12 : 8,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${conflict.sourceA}：${conflict.valueA}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppPalette.error,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppPalette.success.withAlpha(
                              widget.isDark ? 12 : 8,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${conflict.sourceB}：${conflict.valueB}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppPalette.success,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required _ResolutionChoice choice,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isSelected = _choice == choice;

    return GestureDetector(
      onTap: () => setState(() => _choice = choice),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected ? AppPalette.primary : AppPalette.borderLight,
            width: isSelected ? 1.5 : 1,
          ),
          color: isSelected
              ? AppPalette.primary.withAlpha(widget.isDark ? 18 : 10)
              : null,
        ),
        child: Row(
          children: <Widget>[
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 20,
              color: isSelected ? AppPalette.primary : AppPalette.muted,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withAlpha(widget.isDark ? 12 : 8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      value,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomInputTile(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = _choice == _ResolutionChoice.custom;

    return GestureDetector(
      onTap: () => setState(() => _choice = _ResolutionChoice.custom),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected ? AppPalette.primary : AppPalette.borderLight,
            width: isSelected ? 1.5 : 1,
          ),
          color: isSelected
              ? AppPalette.primary.withAlpha(widget.isDark ? 18 : 10)
              : null,
        ),
        child: Row(
          children: <Widget>[
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 20,
              color: isSelected ? AppPalette.primary : AppPalette.muted,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '手动输入',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  if (isSelected) ...<Widget>[
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _customController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: '输入正确的值',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                        ),
                      ),
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
