import 'package:flutter/material.dart';

import '../../core/constants/app_enums.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/case_detail/domain/case_models.dart';
import 'status_badge.dart';

/// Full-screen-style searchable BottomSheet for selecting a patient case.
///
/// Returns the selected [CaseSummary] via `Navigator.pop`.
class CasePickerSheet extends StatefulWidget {
  const CasePickerSheet({
    required this.cases,
    this.selectedId,
    this.onCreateCase,
    super.key,
  });

  final List<CaseSummary> cases;
  final String? selectedId;
  final VoidCallback? onCreateCase;

  @override
  State<CasePickerSheet> createState() => _CasePickerSheetState();
}

class _CasePickerSheetState extends State<CasePickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  List<CaseSummary> get _filteredCases {
    if (_query.isEmpty) return widget.cases;
    final q = _query.toLowerCase();
    return widget.cases.where((c) {
      return c.patientName.toLowerCase().contains(q) ||
          c.patientCode.toLowerCase().contains(q) ||
          c.tumorType.toLowerCase().contains(q) ||
          c.primarySite.toLowerCase().contains(q);
    }).toList(growable: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) => Column(
        children: <Widget>[
          _buildHeader(theme, isDark),
          _buildSearchBar(theme, isDark),
          Expanded(child: _buildList(theme, isDark, scrollController)),
          _buildFooter(theme, isDark, bottom),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page, AppSpacing.md, AppSpacing.sm, 0,
      ),
      child: Column(
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
          Row(
            children: <Widget>[
              Expanded(
                child: Text('选择病例', style: theme.textTheme.titleLarge),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, size: 22),
                style: IconButton.styleFrom(
                  foregroundColor: isDark
                      ? AppPalette.textSecondaryDark
                      : AppPalette.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page, AppSpacing.sm, AppSpacing.page, AppSpacing.sm,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _query = value.trim()),
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: '搜索姓名、编号或肿瘤类型…',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                  icon: const Icon(Icons.clear_rounded, size: 18),
                )
              : null,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
      ),
    );
  }

  Widget _buildList(
    ThemeData theme,
    bool isDark,
    ScrollController scrollController,
  ) {
    final cases = _filteredCases;

    if (cases.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.search_off_rounded,
                size: 48,
                color: isDark
                    ? AppPalette.textTertiaryDark
                    : AppPalette.textTertiaryLight,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '未找到匹配的病例',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: isDark
                      ? AppPalette.textSecondaryDark
                      : AppPalette.textSecondaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '尝试其他关键词，或新建病例',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppPalette.textTertiaryDark
                      : AppPalette.textTertiaryLight,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      itemCount: cases.length,
      itemBuilder: (context, index) {
        final item = cases[index];
        final isSelected = item.id == widget.selectedId;
        return _CaseOptionTile(
          key: ValueKey(item.id),
          summary: item,
          isSelected: isSelected,
          isDark: isDark,
          onTap: () => Navigator.pop(context, item),
        );
      },
    );
  }

  Widget _buildFooter(ThemeData theme, bool isDark, double bottomPadding) {
    if (widget.onCreateCase == null) return SizedBox(height: bottomPadding);

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.page, AppSpacing.sm,
        AppSpacing.page, AppSpacing.lg + bottomPadding,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppPalette.borderDark : AppPalette.borderLight,
            width: 0.5,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: widget.onCreateCase,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('新建病例'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppPalette.primary,
            side: const BorderSide(color: AppPalette.primary, width: 1),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
        ),
      ),
    );
  }
}

class _CaseOptionTile extends StatelessWidget {
  const _CaseOptionTile({
    required this.summary,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
    super.key,
  });

  final CaseSummary summary;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final selectedBg = isDark
        ? AppPalette.primary.withAlpha(18)
        : AppPalette.primarySurface.withAlpha(180);
    final defaultBg = isDark ? AppPalette.surfaceDark : Colors.transparent;

    final screeningTone = switch (summary.screeningStatus) {
      ScreeningStatus.ready => StatusTone.success,
      ScreeningStatus.partial => StatusTone.warning,
      ScreeningStatus.notReady => StatusTone.error,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: isSelected ? selectedBg : defaultBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: isSelected
                    ? AppPalette.primary.withAlpha(isDark ? 80 : 120)
                    : (isDark ? AppPalette.borderDark : AppPalette.borderLight),
                width: isSelected ? 1.5 : 0.5,
              ),
            ),
            child: Row(
              children: <Widget>[
                _buildAvatar(),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _buildInfo(theme)),
                const SizedBox(width: AppSpacing.sm),
                _buildTrailing(theme, screeningTone),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final letter =
        summary.patientName.isNotEmpty ? summary.patientName[0] : '?';

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isSelected
            ? AppPalette.primary.withAlpha(isDark ? 40 : 30)
            : (isDark
                ? AppPalette.primary.withAlpha(18)
                : AppPalette.primarySurface),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: isSelected ? AppPalette.primary : AppPalette.primaryDark,
        ),
      ),
    );
  }

  Widget _buildInfo(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Flexible(
              child: Text(
                summary.patientName,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              summary.patientCode,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppPalette.textTertiaryDark
                    : AppPalette.textTertiaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          '${summary.tumorType} · ${summary.stage} · ${summary.lineOfTherapy}线治疗',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark
                ? AppPalette.textSecondaryDark
                : AppPalette.textSecondaryLight,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          summary.lastUpdatedLabel,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: isDark
                ? AppPalette.textTertiaryDark
                : AppPalette.textTertiaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildTrailing(ThemeData theme, StatusTone screeningTone) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        StatusBadge(
          label: ScreeningStatusX(summary.screeningStatus).label,
          tone: screeningTone,
        ),
        if (isSelected) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Icon(Icons.check_circle_rounded, size: 18, color: AppPalette.primary),
        ],
      ],
    );
  }
}
