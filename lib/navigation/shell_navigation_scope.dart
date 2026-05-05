import 'package:flutter/material.dart';

/// Lets the Home dashboard jump to another bottom-nav tab without a global router.
class ShellNavigationScope extends InheritedWidget {
  const ShellNavigationScope({
    required this.goToRoomsTab,
    required this.goToRoom,
    required super.child,
    super.key,
  });

  final VoidCallback goToRoomsTab;
  final ValueChanged<String> goToRoom;

  static ShellNavigationScope? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ShellNavigationScope>();

  @override
  bool updateShouldNotify(ShellNavigationScope oldWidget) =>
      goToRoomsTab != oldWidget.goToRoomsTab || goToRoom != oldWidget.goToRoom;
}
