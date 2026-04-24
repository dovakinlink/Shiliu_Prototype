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
import '../../case_detail/domain/case_models.dart';
import '../domain/screening_models.dart';

final screeningSnapshotProvider =
    FutureProvider.family<ScreeningSnapshot?, String>((ref, caseId) async {
      ref.watch(mockAppStoreProvider);
      return ref.read(screeningRepositoryProvider).getSnapshot(caseId);
    });

final screeningCaseSummaryProvider = FutureProvider.family<CaseDetail?, String>(
  (ref, caseId) async {
    ref.watch(mockAppStoreProvider);
    return ref.read(caseRepositoryProvider).getCaseDetail(caseId);
  },
);

class ScreeningPage extends ConsumerStatefulWidget {
  const ScreeningPage({required this.caseId, super.key});

  final String caseId;

  @override
  ConsumerState<ScreeningPage> createState() => _ScreeningPageState();
}

class _ScreeningPageState extends ConsumerState<ScreeningPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers =
      <String, TextEditingController>{};

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshotAsync = ref.watch(screeningSnapshotProvider(widget.caseId));
    final detailAsync = ref.watch(screeningCaseSummaryProvider(widget.caseId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('筛查快照')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.sm,
          AppSpacing.page,
          AppSpacing.xxxxl,
        ),
        children: <Widget>[
          detailAsync.when(
            data: (detail) => detail == null
                ? const SizedBox.shrink()
                : _PatientHeader(detail: detail),
            error: (error, _) => AppErrorState(message: '$error'),
            loading: () => const SkeletonBlock(height: 44),
          ),
          const SizedBox(height: AppSpacing.lg),
          snapshotAsync.when(
            data: (snapshot) {
              if (snapshot == null) {
                return const AppEmptyState(
                  icon: Icons.assignment_outlined,
                  title: '快照不存在',
                  description: '当前病例没有筛查快照数据',
                );
              }
              final missingFields = snapshot.missingFields;
              for (final field in missingFields) {
                _controllers.putIfAbsent(field, TextEditingController.new);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _SnapshotHeader(snapshot: snapshot),
                  const SizedBox(height: AppSpacing.lg),
                  _CompletenessOverview(snapshot: snapshot),
                  const SizedBox(height: AppSpacing.lg),
                  _StatusBars(snapshot: snapshot),
                  if (snapshot.tasks.isNotEmpty) ...<Widget>[
                    const SizedBox(height: AppSpacing.xl),
                    _TasksSection(tasks: snapshot.tasks),
                  ],
                  if (missingFields.isNotEmpty) ...<Widget>[
                    const SizedBox(height: AppSpacing.xl),
                    Text('缺字段补录', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.md),
                    _SupplementForm(
                      formKey: _formKey,
                      missingFields: missingFields,
                      controllers: _controllers,
                      onSubmit: () async {
                        if (!_formKey.currentState!.validate()) return;
                        final messenger = ScaffoldMessenger.of(context);
                        final values = <String, String>{
                          for (final field in missingFields)
                            field: _controllers[field]!.text.trim(),
                        };
                        await ref
                            .read(screeningRepositoryProvider)
                            .supplementFields(widget.caseId, values);
                        if (!mounted) return;
                        messenger.showSnackBar(
                          const SnackBar(content: Text('已回写字段并刷新筛查状态')),
                        );
                      },
                    ),
                  ],
                  if (missingFields.isEmpty && snapshot.tasks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xl),
                      child: const AppEmptyState(
                        icon: Icons.verified_outlined,
                        title: '数据完整',
                        description: '所有字段已齐全，可直接用于队列筛选',
                      ),
                    ),
                ],
              );
            },
            error: (error, _) => AppErrorState(message: '$error'),
            loading: () => const SkeletonBlock(height: 180),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Patient header — compact Row, no Card wrapper
// ---------------------------------------------------------------------------
class _PatientHeader extends StatelessWidget {
  const _PatientHeader({required this.detail});

  final CaseDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: <Widget>[
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppPalette.primarySurface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          alignment: Alignment.center,
          child: Text(
            detail.summary.patientName.isNotEmpty
                ? detail.summary.patientName[0]
                : '?',
            style: const TextStyle(
              fontSize: 15,
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
              Text(
                detail.summary.patientName,
                style: theme.textTheme.titleMedium,
              ),
              Text(
                '${detail.summary.patientCode} · ${detail.summary.tumorType}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Snapshot header — inline title + status badge + key fact chips
// ---------------------------------------------------------------------------
class _SnapshotHeader extends StatelessWidget {
  const _SnapshotHeader({required this.snapshot});

  final ScreeningSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                snapshot.projectTitle,
                style: theme.textTheme.titleMedium,
              ),
            ),
            StatusBadge(
              label: snapshot.status.label,
              tone: switch (snapshot.status) {
                ScreeningStatus.ready => StatusTone.success,
                ScreeningStatus.partial => StatusTone.warning,
                ScreeningStatus.notReady => StatusTone.error,
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: snapshot.keyFacts
              .map((fact) => StatusBadge(label: fact))
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _CompletenessOverview extends StatelessWidget {
  const _CompletenessOverview({required this.snapshot});

  final ScreeningSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _CompletionTile(
            label: '通用核心',
            value: snapshot.coreCompletionRate,
            icon: Icons.schema_outlined,
            color: AppPalette.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _CompletionTile(
            label: snapshot.crfTemplateLabel ?? '专病 CRF',
            value: snapshot.crfCompletionRate,
            icon: Icons.account_tree_outlined,
            color: AppPalette.pending,
          ),
        ),
      ],
    );
  }
}

class _CompletionTile extends StatelessWidget {
  const _CompletionTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final double value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? AppPalette.surfaceVariantDark
            : AppPalette.surfaceVariantLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 16, color: color),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${(value * 100).round()}%',
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: LinearProgressIndicator(
              value: value.clamp(0, 1).toDouble(),
              minHeight: 4,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              backgroundColor: isDark
                  ? AppPalette.borderDark
                  : AppPalette.borderLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Blocking / reminder — compact color-bar indicators
// ---------------------------------------------------------------------------
class _StatusBars extends StatelessWidget {
  const _StatusBars({required this.snapshot});

  final ScreeningSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasBlocking = snapshot.blockingFields.isNotEmpty;
    final hasReminder = snapshot.reminderFields.isNotEmpty;

    if (!hasBlocking && !hasReminder) {
      return _ColorBar(
        icon: Icons.check_circle_outline_rounded,
        label: '数据完整',
        fields: const <String>[],
        color: AppPalette.success,
        tone: StatusTone.success,
        isDark: isDark,
      );
    }

    return Column(
      children: <Widget>[
        if (hasBlocking)
          _ColorBar(
            icon: Icons.block_rounded,
            label: '阻断',
            fields: snapshot.blockingFields,
            color: AppPalette.error,
            tone: StatusTone.error,
            isDark: isDark,
          ),
        if (hasBlocking && hasReminder) const SizedBox(height: AppSpacing.sm),
        if (hasReminder)
          _ColorBar(
            icon: Icons.notifications_none_rounded,
            label: '提醒',
            fields: snapshot.reminderFields,
            color: AppPalette.warning,
            tone: StatusTone.warning,
            isDark: isDark,
          ),
      ],
    );
  }
}

class _ColorBar extends StatelessWidget {
  const _ColorBar({
    required this.icon,
    required this.label,
    required this.fields,
    required this.color,
    required this.tone,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final List<String> fields;
  final Color color;
  final StatusTone tone;
  final bool isDark;

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
          if (fields.isNotEmpty) ...<Widget>[
            const SizedBox(width: 10),
            Expanded(
              child: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: fields
                    .map((f) => StatusBadge(label: f, tone: tone))
                    .toList(growable: false),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tasks — all tasks grouped in a single Card with dividers
// ---------------------------------------------------------------------------
class _TasksSection extends StatelessWidget {
  const _TasksSection({required this.tasks});

  final List<CompletenessTask> tasks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('待处理任务', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: <Widget>[
              for (int i = 0; i < tasks.length; i++) ...<Widget>[
                _CompactTaskTile(task: tasks[i]),
                if (i < tasks.length - 1) const Divider(height: 1, indent: 44),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CompactTaskTile extends StatelessWidget {
  const _CompactTaskTile({required this.task});

  final CompletenessTask task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isConflict = task.type == TaskType.conflictReview;
    final accentColor = task.isBlocking
        ? AppPalette.error
        : isConflict
        ? AppPalette.conflict
        : AppPalette.warning;

    return InkWell(
      onTap: () => context.push('/task/${task.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.cardPadding,
          vertical: 12,
        ),
        child: Row(
          children: <Widget>[
            Icon(
              isConflict
                  ? Icons.compare_arrows_rounded
                  : Icons.edit_note_rounded,
              size: 18,
              color: accentColor,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(task.title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    '${task.type.label}：${task.fields.join('、')}',
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: theme.colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Supplement form — kept in Card but more compact
// ---------------------------------------------------------------------------
class _SupplementForm extends StatelessWidget {
  const _SupplementForm({
    required this.formKey,
    required this.missingFields,
    required this.controllers,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final List<String> missingFields;
  final Map<String, TextEditingController> controllers;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ...missingFields.map(
                (field) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: TextFormField(
                    controller: controllers[field],
                    keyboardType: field == 'ECOG评分'
                        ? TextInputType.number
                        : TextInputType.text,
                    decoration: InputDecoration(
                      labelText: field,
                      hintText: _hintOf(field),
                      isDense: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请补录$field';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onSubmit,
                  child: const Text('提交补录'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _hintOf(String field) {
  return switch (field) {
    'ECOG评分' => '输入 0-4 的整数',
    '当前方案' => '例如：PD-1 单药维持',
    '关键分子标志物' => '例如：PD-L1 TPS 70%',
    '转移部位' => '例如：肝、腹膜',
    '病理类型' => '例如：肺腺癌',
    '尿路梗阻程度' => '例如：无、轻度、中度、重度',
    'pT' => '例如：pT2',
    'pN' => '例如：pN0',
    'pM' => '例如：pM0',
    'PD-L1' => '例如：高表达',
    'CPS得分' => '例如：18',
    _ => '请输入$field',
  };
}
