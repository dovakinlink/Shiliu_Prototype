import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

class InfoCard extends StatelessWidget {
  const InfoCard({
    required this.child,
    this.padding,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding ??
            const EdgeInsets.all(AppSpacing.cardPadding),
        child: child,
      ),
    );
  }
}
