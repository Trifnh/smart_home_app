import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/room.dart';
import '../../providers/room_providers.dart';
import '../../theme/app_theme.dart';
import 'room_detail_screen.dart';

class RoomsScreen extends ConsumerStatefulWidget {
  const RoomsScreen({
    super.key,
    this.openRoomId,
    this.openRoomToken = 0,
  });

  final String? openRoomId;
  final int openRoomToken;

  @override
  ConsumerState<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends ConsumerState<RoomsScreen> {
  int _handledOpenToken = -1;
  bool _openScheduled = false;

  @override
  void didUpdateWidget(covariant RoomsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleOpenRoom();
  }

  @override
  void initState() {
    super.initState();
    _scheduleOpenRoom();
  }

  void _scheduleOpenRoom() {
    if (_openScheduled) return;
    _openScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openScheduled = false;
      if (!mounted) return;
      _tryOpenRoom();
    });
  }

  void _tryOpenRoom() {
    final roomId = widget.openRoomId;
    if (roomId == null) return;
    if (_handledOpenToken == widget.openRoomToken) return;
    _handledOpenToken = widget.openRoomToken;
    final rooms = ref.read(roomsProvider);
    Room? room;
    for (final r in rooms) {
      if (r.id == roomId) {
        room = r;
        break;
      }
    }
    final selectedRoom = room;
    if (selectedRoom == null || !mounted) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => RoomDetailScreen(
          roomId: selectedRoom.id,
          roomName: selectedRoom.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final rooms = ref.watch(roomsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      children: [
        Text(
          'Rooms',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Nhóm thiết bị theo phòng để quản lý dễ hơn.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.55),
              ),
        ),
        const SizedBox(height: 16),
        if (rooms.isEmpty)
          _EmptyRooms(
            onSeedHint: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Chưa có rooms trong Firebase. Tạo `rooms/{roomId}` để hiển thị.',
                  ),
                ),
              );
            },
          )
        else
          ...rooms.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RoomCard(room: r),
            ),
          ),
      ],
    );
  }
}

class _RoomCard extends ConsumerWidget {
  const _RoomCard({required this.room});

  final Room room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(roomDevicesProvider(room.id));
    final active = devices.where((d) => d.isOn).length;

    final primary = Theme.of(context).colorScheme.primary;
    final bg = Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface;

    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.r24),
      onTap: () {
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => RoomDetailScreen(roomId: room.id, roomName: room.name),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppTheme.r24),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primary.withValues(alpha: 0.90),
                    AppTheme.accentDim.withValues(alpha: 0.90),
                  ],
                ),
              ),
              child: Icon(room.icon, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$active đang bật • ${devices.length} thiết bị',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final d in devices.take(6))
                        _DevicePill(
                          icon: d.icon,
                          on: d.isOn,
                        ),
                      if (devices.length > 6)
                        _MorePill(count: devices.length - 6),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _DevicePill extends StatelessWidget {
  const _DevicePill({required this.icon, required this.on});

  final IconData icon;
  final bool on;

  @override
  Widget build(BuildContext context) {
    final c = on ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor;
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: c.withValues(alpha: on ? 0.14 : 0.06),
        border: Border.all(color: c.withValues(alpha: on ? 0.35 : 0.35)),
      ),
      child: Icon(icon, size: 18, color: c.withValues(alpha: on ? 0.95 : 0.6)),
    );
  }
}

class _MorePill extends StatelessWidget {
  const _MorePill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).dividerColor.withValues(alpha: 0.06),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.35)),
      ),
      child: Text(
        '+$count',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
      ),
    );
  }
}

class _EmptyRooms extends StatelessWidget {
  const _EmptyRooms({required this.onSeedHint});

  final VoidCallback onSeedHint;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.r24),
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.6)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chưa có phòng',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tạo `rooms/{roomId}` trong Firebase để bật Rooms UI. App vẫn giữ `devices/{id}/status` như cũ.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  height: 1.35,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onSeedHint,
            icon: const Icon(Icons.info_outline_rounded),
            label: const Text('Xem gợi ý schema'),
          ),
        ],
      ),
    );
  }
}

