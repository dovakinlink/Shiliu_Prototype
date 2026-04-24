import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_enums.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/mock/mock_repositories.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/create_case_sheet.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../intake/domain/upload_job.dart';
import '../../screening/domain/screening_models.dart';
import '../domain/inbox_models.dart';

final _inboxFilterProvider =
    NotifierProvider<_InboxFilterNotifier, InboxFilter>(
        _InboxFilterNotifier.new);

class _InboxFilterNotifier extends Notifier<InboxFilter> {
  @override
  InboxFilter build() => InboxFilter.all;

  void set(InboxFilter value) => state = value;
}

class InboxPage extends ConsumerWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(inboxSnapshotProvider);
    final activeFilter = ref.watch(_inboxFilterProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: snapshot.when(
          data: (data) {
            final filteredItems = data.items
                .where((item) => item.matchesFilter(activeFilter))
                .toList(growable: false);

            return CustomScrollView(
              slivers: <Widget>[
                // ── Header ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.page, AppSpacing.xxl,
                      AppSpacing.page, 0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('收件箱',
                                  style: theme.textTheme.headlineMedium),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '${data.totalCount} 项待处理',
                                style: theme.textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                        _CountBadge(
                          count: data.totalCount,
                          color: AppPalette.primary,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Filter tabs ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.page, AppSpacing.xl,
                      AppSpacing.page, AppSpacing.lg,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: InboxFilter.values.map((filter) {
                          final isActive = filter == activeFilter;
                          final count = switch (filter) {
                            InboxFilter.all => data.totalCount,
                            InboxFilter.uploading => data.uploadingCount,
                            InboxFilter.pending => data.pendingCount,
                            InboxFilter.conflict => data.conflictCount,
                          };
                          return Padding(
                            padding: const EdgeInsets.only(
                                right: AppSpacing.sm),
                            child: _FilterTab(
                              label: filter.label,
                              count: count,
                              isActive: isActive,
                              onTap: () => ref
                                  .read(_inboxFilterProvider.notifier)
                                  .set(filter),
                            ),
                          );
                        }).toList(growable: false),
                      ),
                    ),
                  ),
                ),

                // ── Content ──
                if (filteredItems.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.page),
                      child: Center(
                        child: AppEmptyState(
                          icon: Icons.check_circle_outline_rounded,
                          title: '所有任务已处理完毕',
                          description: activeFilter == InboxFilter.all
                              ? '没有待处理的上传或补录任务'
                              : '当前分类下没有待处理项',
                        ),
                      ),
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.page, 0,
                        AppSpacing.page, AppSpacing.xxxxl + 72,
                      ),
                      child: _InboxItemGroup(items: filteredItems, ref: ref),
                    ),
                  ),
              ],
            );
          },
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: AppErrorState(
              message: '$error',
              onRetry: () => ref.invalidate(inboxSnapshotProvider),
            ),
          ),
          loading: () => _buildLoadingSkeleton(),
        ),
      ),
      floatingActionButton: _NewCollectionFab(ref: ref),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.page),
      children: const <Widget>[
        SkeletonBlock(height: 32, width: 120),
        SizedBox(height: AppSpacing.xxl),
        SkeletonBlock(height: 36),
        SizedBox(height: AppSpacing.xl),
        SkeletonBlock(height: 200),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Grouped items — single Card with dividers
// ---------------------------------------------------------------------------
class _InboxItemGroup extends StatelessWidget {
  const _InboxItemGroup({required this.items, required this.ref});

  final List<InboxItem> items;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          for (int i = 0; i < items.length; i++) ...<Widget>[
            switch (items[i].type) {
              InboxItemType.upload =>
                _CompactUploadRow(job: items[i].uploadJob!, ref: ref),
              InboxItemType.completeness =>
                _CompactTaskRow(task: items[i].task!),
            },
            if (i < items.length - 1) const Divider(height: 1, indent: 48),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Compact upload row
// ---------------------------------------------------------------------------
class _CompactUploadRow extends StatelessWidget {
  const _CompactUploadRow({required this.job, required this.ref});

  final UploadJob job;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final (icon, iconColor) = switch (job.source) {
      UploadSource.camera => (Icons.camera_alt_outlined, AppPalette.pending),
      UploadSource.pdf => (Icons.description_outlined, AppPalette.secondary),
      UploadSource.voice => (Icons.mic_none_rounded, AppPalette.conflict),
      UploadSource.gallery => (
          Icons.photo_library_outlined,
          AppPalette.warning,
        ),
    };

    final tone = switch (job.stage) {
      UploadJobStage.queued => StatusTone.neutral,
      UploadJobStage.processing => StatusTone.pending,
      UploadJobStage.extracted => StatusTone.warning,
      UploadJobStage.needsReview => StatusTone.conflict,
    };

    final isReview = job.stage == UploadJobStage.needsReview;

    return InkWell(
      onTap: isReview
          ? () => context.push('/upload-review/${job.id}')
          : () async {
              await ref.read(uploadRepositoryProvider).advanceJob(job.id);
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.cardPadding,
          vertical: 12,
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(isDark ? 25 : 18),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 16, color: iconColor),
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
                          job.documentType,
                          style: theme.textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      StatusBadge(label: job.stage.label, tone: tone),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _buildSubtitle(),
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (isReview)
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: theme.colorScheme.outline,
              )
            else
              Icon(
                Icons.play_circle_outline_rounded,
                size: 20,
                color: AppPalette.primary,
              ),
          ],
        ),
      ),
    );
  }

  String _buildSubtitle() {
    final parts = <String>[job.patientName, job.source.label];
    if (job.pendingReviewFields.isNotEmpty) {
      parts.add('待确认 ${job.pendingReviewFields.length} 项');
    } else {
      parts.add(job.createdAtLabel);
    }
    return parts.join(' · ');
  }
}

// ---------------------------------------------------------------------------
// Compact task row — directly navigates to screening for missing field tasks
// ---------------------------------------------------------------------------
class _CompactTaskRow extends StatelessWidget {
  const _CompactTaskRow({required this.task});

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
      onTap: () {
        if (task.type == TaskType.missingField) {
          context.push('/screening/${task.caseId}');
        } else {
          context.push('/task/${task.id}');
        }
      },
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
              size: 20,
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
                    '${task.owner} · 缺：${task.fields.join('、')}',
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
// Supporting widgets (kept from original, unchanged)
// ---------------------------------------------------------------------------

class _NewCollectionFab extends ConsumerWidget {
  const _NewCollectionFab({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        FloatingActionButton.small(
          heroTag: 'fab_create_case',
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (_) => const CreateCaseSheet(),
          ),
          backgroundColor: AppPalette.primary.withAlpha(220),
          foregroundColor: Colors.white,
          child: const Icon(Icons.person_add_alt_1_rounded, size: 18),
        ),
        const SizedBox(height: AppSpacing.md),
        FloatingActionButton.extended(
          heroTag: 'fab_new_upload',
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            builder: (_) => const _SourcePickerSheet(),
          ),
          backgroundColor: AppPalette.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('新增采集'),
        ),
      ],
    );
  }
}

class _SourcePickerSheet extends StatelessWidget {
  const _SourcePickerSheet();

  static const _sourceMeta = <UploadSource, (IconData, Color)>{
    UploadSource.camera: (Icons.camera_alt_outlined, AppPalette.pending),
    UploadSource.pdf: (Icons.description_outlined, AppPalette.secondary),
    UploadSource.voice: (Icons.mic_none_rounded, AppPalette.conflict),
    UploadSource.gallery: (Icons.photo_library_outlined, AppPalette.warning),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.page, AppSpacing.lg, AppSpacing.page, AppSpacing.xl + bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
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
          Text('选择采集方式', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '选择数据来源后填写采集详情',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppPalette.textSecondaryDark
                  : AppPalette.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.65,
            children: UploadSource.values.map((source) {
              final (icon, accent) = _sourceMeta[source]!;
              return _SourceOptionCard(
                icon: icon,
                accent: accent,
                label: source.label,
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/capture/${source.name}');
                },
              );
            }).toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _SourceOptionCard extends StatelessWidget {
  const _SourceOptionCard({
    required this.icon,
    required this.accent,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: theme.cardTheme.color,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: theme.colorScheme.outline,
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withAlpha(isDark ? 25 : 18),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(label, style: theme.textTheme.titleSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isActive
          ? (isDark
              ? AppPalette.primary.withAlpha(30)
              : AppPalette.primarySurface)
          : (isDark
              ? AppPalette.surfaceVariantDark
              : AppPalette.surfaceVariantLight),
      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? AppPalette.primary
                      : (isDark
                          ? AppPalette.textSecondaryDark
                          : AppPalette.textSecondaryLight),
                ),
              ),
              if (count > 0) ...<Widget>[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppPalette.primary.withAlpha(isDark ? 50 : 30)
                        : Colors.transparent,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? AppPalette.primary
                          : (isDark
                              ? AppPalette.textTertiaryDark
                              : AppPalette.textTertiaryLight),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.color});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
