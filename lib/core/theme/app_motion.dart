import 'package:flutter/material.dart';

class AppMotion {
  static const fast = Duration(milliseconds: 120);
  static const medium = Duration(milliseconds: 180);
  static const slow = Duration(milliseconds: 220);

  static Duration resolve(BuildContext context, Duration fallback) {
    final mediaQuery = MediaQuery.maybeOf(context);
    if (mediaQuery?.disableAnimations ?? false) {
      return Duration.zero;
    }
    return fallback;
  }
}
