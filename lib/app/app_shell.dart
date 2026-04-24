import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  static const _items = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.inbox_outlined),
      selectedIcon: Icon(Icons.inbox_rounded),
      label: '收件箱',
    ),
    NavigationDestination(
      icon: Icon(Icons.folder_shared_outlined),
      selectedIcon: Icon(Icons.folder_shared_rounded),
      label: '病例库',
    ),
    NavigationDestination(
      icon: Icon(Icons.playlist_add_check_outlined),
      selectedIcon: Icon(Icons.playlist_add_check_rounded),
      label: '筛查中心',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: '我的',
    ),
  ];

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final border = isDark
        ? Border(top: BorderSide(color: theme.colorScheme.outline, width: 0.5))
        : Border(top: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5));

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(border: border),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _onTap,
          destinations: _items,
        ),
      ),
    );
  }
}
