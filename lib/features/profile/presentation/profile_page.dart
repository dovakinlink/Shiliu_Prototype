import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/mock/mock_app_store.dart';
import '../../../data/mock/mock_repositories.dart';
import '../../../shared/widgets/info_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../dashboard/domain/dashboard_metric.dart';

final _profileMetricsProvider =
    FutureProvider<DashboardSnapshot>((ref) async {
  ref.watch(mockAppStoreProvider);
  return ref.read(dashboardRepositoryProvider).getSnapshot();
});

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(_profileMetricsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.xxl,
          AppSpacing.page,
          AppSpacing.xxxxl,
        ),
        children: <Widget>[
          _UserInfoHeader(isDark: isDark),

          const SizedBox(height: AppSpacing.sectionGap),
          Text('数据概览', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          metricsAsync.when(
            data: (data) => _MetricGrid(metrics: data.metrics),
            error: (_, __) => const SizedBox.shrink(),
            loading: () => const SizedBox(height: 120),
          ),

          const SizedBox(height: AppSpacing.sectionGap),
          Text('快捷入口', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          _QuickEntryList(isDark: isDark),

          const SizedBox(height: AppSpacing.sectionGap),
          Text('外观设置', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          _AppearanceCard(isDark: isDark),

          const SizedBox(height: AppSpacing.sectionGap),
          Text('系统信息', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          _SystemInfoCard(isDark: isDark),
        ],
      ),
    );
  }
}

class _UserInfoHeader extends StatelessWidget {
  const _UserInfoHeader({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InfoCard(
      child: Row(
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  AppPalette.primary,
                  AppPalette.primaryLight,
                ],
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            alignment: Alignment.center,
            child: const Text(
              '张',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('张医生', style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '肿瘤内科 · 主治医师',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: <Widget>[
                    StatusBadge(
                      label: '项目秘书',
                      tone: StatusTone.pending,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    StatusBadge(
                      label: '数据录入',
                      tone: StatusTone.success,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.settings_outlined,
              color: isDark
                  ? AppPalette.textTertiaryDark
                  : AppPalette.textTertiaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<DashboardMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: metrics
              .map((metric) => SizedBox(
                    width: cardWidth,
                    child: _MetricTile(metric: metric),
                  ))
              .toList(growable: false),
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});

  final DashboardMetric metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(metric.label, style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            metric.value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(metric.helper, style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          StatusBadge(
            label: metric.deltaLabel,
            tone:
                metric.isPositive ? StatusTone.success : StatusTone.warning,
          ),
        ],
      ),
    );
  }
}

class _QuickEntryList extends StatelessWidget {
  const _QuickEntryList({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          _QuickEntryTile(
            icon: Icons.inbox_rounded,
            label: '收件箱',
            subtitle: '查看待处理任务',
            onTap: () => context.go('/inbox'),
            isDark: isDark,
            showDivider: true,
          ),
          _QuickEntryTile(
            icon: Icons.folder_shared_rounded,
            label: '全部病例',
            subtitle: '浏览与检索病例库',
            onTap: () => context.go('/cases'),
            isDark: isDark,
            showDivider: true,
          ),
          _QuickEntryTile(
            icon: Icons.playlist_add_check_rounded,
            label: '筛查概览',
            subtitle: '查看筛查进度与阻断项',
            onTap: () => context.go('/screening-hub'),
            isDark: isDark,
            showDivider: true,
          ),
          _QuickEntryTile(
            icon: Icons.help_outline_rounded,
            label: '使用帮助',
            subtitle: '了解石榴的功能',
            onTap: () {},
            isDark: isDark,
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _QuickEntryTile extends StatelessWidget {
  const _QuickEntryTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.isDark,
    required this.showDivider,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDark;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: <Widget>[
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.cardPadding,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppPalette.primary.withAlpha(25)
                        : AppPalette.primarySurface,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 18, color: AppPalette.primary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(label, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 1),
                      Text(subtitle, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: isDark
                      ? AppPalette.textTertiaryDark
                      : AppPalette.textTertiaryLight,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 0.5,
            indent: AppSpacing.cardPadding + 36 + AppSpacing.md,
          ),
      ],
    );
  }
}

class _AppearanceCard extends ConsumerWidget {
  const _AppearanceCard({required this.isDark});

  final bool isDark;

  static const _modes = <(ThemeMode, String, IconData)>[
    (ThemeMode.light, '浅色', Icons.light_mode_rounded),
    (ThemeMode.dark, '深色', Icons.dark_mode_rounded),
    (ThemeMode.system, '跟随系统', Icons.brightness_auto_rounded),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentMode = ref.watch(themeModeProvider);

    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                size: 18,
                color: AppPalette.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('显示模式', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: _modes.map((entry) {
              final (mode, label, icon) = entry;
              final selected = currentMode == mode;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: mode == ThemeMode.system ? 0 : AppSpacing.sm,
                  ),
                  child: _ThemeModeChip(
                    icon: icon,
                    label: label,
                    selected: selected,
                    isDark: isDark,
                    onTap: () {
                      ref.read(themeModeProvider.notifier).setThemeMode(mode);
                    },
                  ),
                ),
              );
            }).toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _ThemeModeChip extends StatelessWidget {
  const _ThemeModeChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bgColor = selected
        ? (isDark
            ? AppPalette.primary.withAlpha(30)
            : AppPalette.primarySurface)
        : (isDark ? AppPalette.surfaceVariantDark : AppPalette.surfaceVariantLight);

    final fgColor = selected
        ? AppPalette.primary
        : (isDark ? AppPalette.textSecondaryDark : AppPalette.textSecondaryLight);

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: selected
                ? Border.all(color: AppPalette.primary.withAlpha(80), width: 1.5)
                : null,
          ),
          child: Column(
            children: <Widget>[
              Icon(icon, size: 22, color: fgColor),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: fgColor,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SystemInfoCard extends StatelessWidget {
  const _SystemInfoCard({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {

    return InfoCard(
      child: Column(
        children: <Widget>[
          _InfoRow(label: '应用版本', value: 'v1.0.0 (Prototype)'),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(label: '数据字典版本', value: 'v2026-04-14'),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(label: '病例总数', value: '24 例'),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(label: '环境', value: 'Mock 数据 · 开发模式'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(label, style: theme.textTheme.bodyMedium),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
