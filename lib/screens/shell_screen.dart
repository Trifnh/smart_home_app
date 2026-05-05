import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../navigation/shell_navigation_scope.dart';
import '../providers/theme_providers.dart';
import '../services/firebase_service.dart';
import 'automation_screen.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'room/rooms_screen.dart';
import 'settings_screen.dart';

/// Bottom navigation shell — Home, Rooms, Automations, Profile.
class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  int _index = 0;
  String? _pendingRoomId;
  int _roomJumpToken = 0;

  static const _titles = ['Home', 'Rooms', 'Automations', 'Profile'];

  void _goRoomsTab() => setState(() => _index = 1);
  void _goToSpecificRoom(String roomId) {
    setState(() {
      _index = 1;
      _pendingRoomId = roomId;
      _roomJumpToken++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final email = FirebaseService.instance.isUiDemoMode
        ? 'demo@ui-preview.local (dữ liệu giả)'
        : (FirebaseAuth.instance.currentUser?.email ?? '');

    return ShellNavigationScope(
      goToRoomsTab: _goRoomsTab,
      goToRoom: _goToSpecificRoom,
      child: Scaffold(
        extendBodyBehindAppBar: false,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _titles[_index],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (_index == 0 && email.isNotEmpty)
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.55),
                    fontWeight: FontWeight.normal,
                  ),
                ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Light / Dark',
              icon: Icon(
                switch (themeMode) {
                  ThemeMode.dark => Icons.dark_mode_rounded,
                  ThemeMode.light => Icons.light_mode_rounded,
                  _ => Icons.brightness_6_rounded,
                },
              ),
              onPressed: () {
                ref.read(themeModeProvider.notifier).cycle();
              },
            ),
            IconButton(
              tooltip: 'MQTT / Cài đặt',
              icon: const Icon(Icons.settings_rounded),
              onPressed: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        // IndexedStack keeps all tabs mounted so device/sensor streams stay
        // subscribed — realtime stays consistent across tabs.
        body: IndexedStack(
          index: _index,
          children: [
            const HomeScreen(),
            RoomsScreen(
              openRoomId: _pendingRoomId,
              openRoomToken: _roomJumpToken,
            ),
            const AutomationScreen(),
            const ProfileScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(
                Icons.dashboard_rounded,
              ),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.meeting_room_outlined),
              selectedIcon: Icon(
                Icons.meeting_room_rounded,
              ),
              label: 'Rooms',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_mode_outlined),
              selectedIcon: Icon(
                Icons.auto_mode_rounded,
              ),
              label: 'Auto',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(
                Icons.person_rounded,
              ),
              label: 'Me',
            ),
          ],
        ),
      ),
    );
  }
}
