import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../navigation/shell_navigation_scope.dart';
import '../../providers/firebase_providers.dart';
import '../../providers/room_providers.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/connection_status_bar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _clock;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseService.instance.isUiDemoMode
        ? null
        : FirebaseAuth.instance.currentUser;

    final devices = ref.watch(devicesMapProvider);
    final hub = ref.watch(hubHealthProvider);
    final rooms = ref.watch(roomsProvider);

    final devicesMap = devices.asData?.value ?? const <String, dynamic>{};
    final onCount = devicesMap.values.where((raw) {
      return deviceStatusFromFirebase(raw);
    }).length;

    final w = MediaQuery.sizeOf(context).width;
    final compactHome = w < 430;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const ConnectionStatusBar(),
              const SizedBox(height: 18),
              _Header(
                displayName: user?.email ?? 'Smart Home',
                now: _now,
                city: 'Ho Chi Minh City',
              ),
              const SizedBox(height: 16),
              _WeatherCardCompact(
                now: _now,
                mockTemp: 31,
                mockCondition: 'Clear',
              ),
              const SizedBox(height: 14),
              _SectionTitle(
                title: 'Tổng quan',
                subtitle: 'Realtime từ Raspberry Pi ↔ Firebase',
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, c) {
                  final twoCols = c.maxWidth >= 340;
                  final items = [
                    _MiniStatCard(
                      title: 'Thiết bị bật',
                      value: devices.isLoading ? '--' : '$onCount',
                      icon: Icons.power_rounded,
                      accent: Theme.of(context).colorScheme.primary,
                      footer: 'Tổng: ${devicesMap.length}',
                      compact: compactHome,
                    ),
                    _MiniHubCard(hub: hub, compact: compactHome),
                  ];

                  if (!twoCols) {
                    return Column(
                      children: [
                        for (var i = 0; i < items.length; i++) ...[
                          items[i],
                          if (i < items.length - 1) const SizedBox(height: 10),
                        ],
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: items[0]),
                      const SizedBox(width: 10),
                      Expanded(child: items[1]),
                    ],
                  );
                },
              ),
              if (devices.hasError || hub.hasError) ...[
                const SizedBox(height: 14),
                _InlineError(
                  message: [
                    if (devices.hasError) 'Devices: ${devices.error}',
                    if (hub.hasError) 'Hub: ${hub.error}',
                  ].join('\n'),
                ),
              ],
              const SizedBox(height: 14),
              _SectionTitle(
                title: 'Phòng',
                subtitle: 'Tap để mở room chi tiết',
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: compactHome ? 136 : 146,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final room in rooms) ...[
                      _RoomPreviewCard(roomId: room.id),
                      const SizedBox(width: 12),
                    ],
                  ],
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.displayName,
    required this.now,
    required this.city,
  });

  final String displayName;
  final DateTime now;
  final String city;

  @override
  Widget build(BuildContext context) {
    final greeting = () {
      final h = now.hour;
      if (h < 11) return 'Good morning';
      if (h < 15) return 'Good afternoon';
      if (h < 20) return 'Good evening';
      return 'Good night';
    }();

    final dateLine = '${_two(now.day)}/${_two(now.month)}/${now.year} • ${_two(now.hour)}:${_two(now.minute)}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting,',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.72),
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                displayName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                '$dateLine • $city',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.55),
                    ),
              ),
            ],
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.95),
                AppTheme.accentDim.withValues(alpha: 0.95),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(
                      alpha: 0.18,
                    ),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(Icons.person_rounded, color: Colors.white),
        ),
      ],
    );
  }

  static String _two(int v) => v.toString().padLeft(2, '0');
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.55),
                      ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _WeatherCardCompact extends StatelessWidget {
  const _WeatherCardCompact({
    required this.now,
    required this.mockTemp,
    required this.mockCondition,
  });

  final DateTime now;
  final int mockTemp;
  final String mockCondition;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 430;
    final bg = Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface;
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.r20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.22 : 0.05),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 14,
          vertical: compact ? 10 : 12,
        ),
        child: Row(
          children: [
            Container(
              width: compact ? 44 : 48,
              height: compact ? 44 : 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.cool.withValues(alpha: 0.9),
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
                  ],
                ),
              ),
              child: const Icon(Icons.wb_sunny_rounded, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weather',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.65),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$mockTemp°C • $mockCondition',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ),
            Text(
              '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
    required this.footer,
    required this.compact,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accent;
  final String footer;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface;
    return Container(
      constraints: BoxConstraints(minHeight: compact ? 96 : 108),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.r20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
        ),
      ),
      padding: EdgeInsets.all(compact ? 12 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: compact ? 34 : 36,
                height: compact ? 34 : 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: accent.withValues(alpha: 0.16),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const Spacer(),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.65),
                      fontWeight: FontWeight.w700,
                    ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 10 : 12),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            footer,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55),
                ),
          ),
        ],
      ),
    );
  }
}

class _MiniHubCard extends StatelessWidget {
  const _MiniHubCard({required this.hub, required this.compact});

  final AsyncValue<Map<String, dynamic>> hub;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final data = hub.asData?.value ?? const <String, dynamic>{};
    final onlineRaw = data['online'];
    final online = onlineRaw == true ||
        onlineRaw == 1 ||
        (onlineRaw is String &&
            (onlineRaw.toLowerCase() == 'true' || onlineRaw == '1'));

    final lastSeen = data['lastSeen'];
    DateTime? last;
    if (lastSeen is int) last = DateTime.fromMillisecondsSinceEpoch(lastSeen);
    if (lastSeen is num) last = DateTime.fromMillisecondsSinceEpoch(lastSeen.toInt());
    final Duration? ago = last == null ? null : DateTime.now().difference(last);
    final lastText = ago == null
        ? 'Last updated: --'
        : (ago.inSeconds < 60
            ? 'Last updated: ${ago.inSeconds}s ago'
            : 'Last updated: ${ago.inMinutes}m ago');

    final accent = online ? AppTheme.accent : AppTheme.danger;
    return _MiniStatCard(
      title: 'Hub',
      value: hub.isLoading ? '--' : (online ? 'ONLINE' : 'OFFLINE'),
      icon: Icons.hub_rounded,
      accent: accent,
      footer: lastText,
      compact: compact,
    );
  }
}

class _RoomPreviewCard extends ConsumerWidget {
  const _RoomPreviewCard({required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(roomsProvider).firstWhere((r) => r.id == roomId);
    final devices = ref.watch(roomDevicesProvider(roomId));
    final activeCount = devices.where((d) => d.isOn).length;
    double? temp;
    double? hum;
    final roomsRaw = ref.watch(roomsMapProvider).asData?.value;
    final raw = roomsRaw?[roomId];
    var showTemp = true;
    var showHum = true;
    if (raw is Map) {
      showTemp = _sensorKeyVisibleForPreview(raw, 'temperature');
      showHum = _sensorKeyVisibleForPreview(raw, 'humidity');
      final sensorsRaw = raw['sensors'];
      if (sensorsRaw is Map) {
        if (showTemp) {
          final t = sensorsRaw['temperature'];
          if (t is num) temp = t.toDouble();
        }
        if (showHum) {
          final h = sensorsRaw['humidity'];
          if (h is num) hum = h.toDouble();
        }
      }
    }

    final bg = Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface;
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.r24),
      onTap: () {
        final nav = ShellNavigationScope.maybeOf(context);
        nav?.goToRoom(roomId);
      },
      child: Container(
      width: 220,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.r24),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primary.withValues(alpha: 0.85),
                      AppTheme.accentDim.withValues(alpha: 0.85),
                    ],
                  ),
                ),
                child: Icon(room.icon, color: Colors.white),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: primary.withValues(alpha: 0.10),
                ),
                child: Text(
                  '$activeCount on',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            room.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            () {
              final parts = <String>[];
              if (showTemp) {
                parts.add('Temp: ${temp?.toStringAsFixed(1) ?? '--'}°C');
              }
              if (showHum) {
                parts.add('Hum: ${hum?.toStringAsFixed(0) ?? '--'}%');
              }
              if (parts.isEmpty) return 'Tap to open';
              return parts.join('  ');
            }(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55),
                ),
          ),
        ],
      ),
    ));
  }
}

/// Khớp logic phòng chi tiết: có `sensor_config` không rỗng thì chỉ hiện key được bật.
bool _sensorKeyVisibleForPreview(dynamic roomRaw, String sensorKey) {
  if (roomRaw is! Map) return false;
  final cfgRaw = roomRaw['sensor_config'];
  if (cfgRaw is! Map || cfgRaw.isEmpty) return true;
  final want = sensorKey.toLowerCase();
  dynamic entry;
  for (final e in cfgRaw.entries) {
    if (e.key.toString().toLowerCase() == want) {
      entry = e.value;
      break;
    }
  }
  if (entry == null) return false;
  return _previewConfigEntryEnabled(entry);
}

bool _previewConfigEntryEnabled(dynamic v) {
  if (v == true) return true;
  if (v is Map) {
    final e = v['enabled'];
    return e == true ||
        e == 1 ||
        (e is String && (e.toLowerCase() == 'true' || e == '1'));
  }
  return false;
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.r20),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.35)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: AppTheme.danger.withValues(alpha: 0.9)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.35,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.85),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

