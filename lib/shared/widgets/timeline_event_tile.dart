import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/case_detail/domain/case_models.dart';
import 'status_badge.dart';

class TimelineEventTile extends StatelessWidget {
  const TimelineEventTile({
    required this.event,
    required this.selected,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
    this.expandedContent,
    super.key,
  });

  final TimelineEvent event;
  final bool selected;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;
  final Widget? expandedContent;

  static const _railWidth = 20.0;
  static const _lineWidth = 1.5;
  static const _dotTopOffset = 12.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lineColor = isDark ? AppPalette.borderDark : AppPalette.borderLight;
    final dotColor = selected ? AppPalette.primary : AppPalette.muted;
    final dotSize = selected ? 10.0 : 8.0;
    final dotCenterY = _dotTopOffset + dotSize / 2;
    final railCenterX = _railWidth / 2;

    return Stack(
      children: <Widget>[
        if (!isFirst)
          Positioned(
            left: railCenterX - _lineWidth / 2,
            top: 0,
            width: _lineWidth,
            height: dotCenterY,
            child: ColoredBox(color: lineColor),
          ),
        if (!isLast)
          Positioned(
            left: railCenterX - _lineWidth / 2,
            top: dotCenterY,
            bottom: 0,
            width: _lineWidth,
            child: ColoredBox(color: lineColor),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: _railWidth,
              child: Padding(
                padding: const EdgeInsets.only(top: _dotTopOffset),
                child: Center(
                  child: Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      color: selected ? dotColor : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: dotColor,
                        width: selected ? 2.5 : 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  GestureDetector(
                    onTap: onTap,
                    behavior: HitTestBehavior.opaque,
                    child: selected
                        ? _buildExpandedHeader(theme)
                        : _buildCompactHeader(theme),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topCenter,
                    child: selected
                        ? _buildExpandedBody(theme)
                        : const SizedBox.shrink(),
                  ),
                  SizedBox(height: selected ? AppSpacing.lg : AppSpacing.xs),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  TextSpan(
                    text: event.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: '  ${event.dateLabel}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppPalette.muted,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (event.isImportant) ...<Widget>[
            const SizedBox(width: AppSpacing.sm),
            const StatusBadge(label: '关键节点', tone: StatusTone.pending),
          ],
        ],
      ),
    );
  }

  Widget _buildExpandedHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              event.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (event.isImportant)
            const StatusBadge(label: '关键节点', tone: StatusTone.pending),
        ],
      ),
    );
  }

  Widget _buildExpandedBody(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${event.dateLabel} · ${event.subtitle}',
          style: theme.textTheme.bodySmall?.copyWith(color: AppPalette.muted),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(event.description, style: theme.textTheme.bodyMedium),
        if (expandedContent != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          expandedContent!,
        ],
      ],
    );
  }
}
