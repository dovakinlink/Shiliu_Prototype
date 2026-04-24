import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_enums.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/mock/mock_repositories.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/info_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../domain/screening_hub_models.dart';

class ScreeningHubPage extends ConsumerWidget {
  const ScreeningHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(screeningHubSnapshotProvider);
    final theme = Theme.of(context);

    return SafeArea(
      child: snapshot.when(
        data: (data) => RefreshIndicator(
          color: AppPalette.primary,
          onRefresh: () async =>
              ref.invalidate(screeningHubSnapshotProvider),
          child: CustomScrollView(
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page, AppSpacing.xxl,
                    AppSpacing.page, 0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('筛查中心',
                          style: theme.textTheme.headlineMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '管理所有病例的筛查状态与补录进度',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page, AppSpacing.xl,
                    AppSpacing.page, 0,
                  ),
                  child: _ProgressOverview(data: data),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page, AppSpacing.xl,
                    AppSpacing.page, 0,
                  ),
                  child: _StatusDistribution(data: data),
                ),
              ),

              if (data.topBlockingFields.isNotEmpty) ...<Widget>[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.page, AppSpacing.sectionGap,
                      AppSpacing.page, AppSpacing.md,
                    ),
                    child: Text('阻断项汇总',
                        style: theme.textTheme.titleLarge),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.page),
                  sliver: SliverList.separated(
                    itemCount: data.topBlockingFields.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) =>
                        _BlockingFieldCard(
                            item: data.topBlockingFields[index]),
                  ),
                ),
              ],

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page, AppSpacing.sectionGap,
                    AppSpacing.page, AppSpacing.md,
                  ),
                  child: Row(
                    children: <Widget>[
                      Text('病例筛查列表',
                          style: theme.textTheme.titleLarge),
                      const Spacer(),
                      Text(
                        '${data.projects.length} 例',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppPalette.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page, 0,
                  AppSpacing.page, AppSpacing.xxxxl,
                ),
                sliver: SliverList.separated(
                  itemCount: data.projects.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) =>
                      _ProjectCard(project: data.projects[index]),
                ),
              ),
            ],
          ),
        ),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: AppErrorState(
            message: '$error',
            onRetry: () => ref.invalidate(screeningHubSnapshotProvider),
          ),
        ),
        loading: () => ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: const <Widget>[
            SkeletonBlock(height: 32, width: 140),
            SizedBox(height: AppSpacing.xl),
            SkeletonBlock(height: 160),
            SizedBox(height: AppSpacing.lg),
            SkeletonBlock(height: 100),
          ],
        ),
      ),
    );
  }
}

class _ProgressOverview extends StatelessWidget {
  const _ProgressOverview({required this.data});

  final ScreeningHubSnapshot data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InfoCard(
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 80,
            height: 80,
            child: CustomPaint(
              painter: _ProgressRingPainter(
                progress: data.overallProgress,
                trackColor: isDark
                    ? AppPalette.borderDark
                    : AppPalette.borderLight,
                progressColor: AppPalette.primary,
              ),
              child: Center(
                child: Text(
                  '${(data.overallProgress * 100).round()}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppPalette.primary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('整体筛查进度',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${data.totalCases} 例病例中 ${data.readyCount} 例已达可初筛状态',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${data.partialCount} 例部分可筛 · ${data.notReadyCount} 例不可筛',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  _ProgressRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;
    const strokeWidth = 6.0;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      trackColor != oldDelegate.trackColor;
}

class _StatusDistribution extends StatelessWidget {
  const _StatusDistribution({required this.data});

  final ScreeningHubSnapshot data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final total = data.totalCases;

    return Row(
      children: <Widget>[
        Expanded(
          child: _StatusTile(
            label: '可初筛',
            count: data.readyCount,
            total: total,
            color: AppPalette.success,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatusTile(
            label: '部分可筛',
            count: data.partialCount,
            total: total,
            color: AppPalette.warning,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatusTile(
            label: '不可筛',
            count: data.notReadyCount,
            total: total,
            color: AppPalette.error,
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
    required this.isDark,
  });

  final String label;
  final int count;
  final int total;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: theme.colorScheme.outline,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(label, style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$count',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          if (total > 0)
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(AppSpacing.radiusFull),
              child: LinearProgressIndicator(
                value: count / total,
                minHeight: 3,
                backgroundColor: isDark
                    ? AppPalette.borderDark
                    : AppPalette.borderLight,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
        ],
      ),
    );
  }
}

class _BlockingFieldCard extends StatelessWidget {
  const _BlockingFieldCard({required this.item});

  final BlockingFieldSummary item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InfoCard(
      child: Row(
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppPalette.error.withAlpha(isDark ? 25 : 18),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.block_rounded,
                size: 18, color: AppPalette.error),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(item.fieldName,
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  '影响 ${item.caseCount} 例病例',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          StatusBadge(
            label: '${item.caseCount} 例',
            tone: StatusTone.error,
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project});

  final ScreeningProject project;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusTone = switch (project.status) {
      ScreeningStatus.ready => StatusTone.success,
      ScreeningStatus.partial => StatusTone.warning,
      ScreeningStatus.notReady => StatusTone.error,
    };

    return Material(
      color: theme.cardTheme.color,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/screening/${project.caseId}'),
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
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppPalette.primarySurface,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      project.patientName.isNotEmpty
                          ? project.patientName[0]
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
                        Text(project.patientName,
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          project.patientCode,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(
                    label: project.status.label,
                    tone: statusTone,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: project.keyFacts
                    .map((fact) => StatusBadge(label: fact))
                    .toList(growable: false),
              ),
              if (project.blockingCount > 0 ||
                  project.reminderCount > 0) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: <Widget>[
                    if (project.blockingCount > 0)
                      StatusBadge(
                        label: '${project.blockingCount} 个阻断项',
                        tone: StatusTone.error,
                      ),
                    if (project.blockingCount > 0 &&
                        project.reminderCount > 0)
                      const SizedBox(width: AppSpacing.xs),
                    if (project.reminderCount > 0)
                      StatusBadge(
                        label: '${project.reminderCount} 个提醒项',
                        tone: StatusTone.warning,
                      ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: theme.colorScheme.outline,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
