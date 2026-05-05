import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../data/device_catalog.dart';
import '../models/device_state.dart';
import '../models/room.dart';
import '../providers/firebase_providers.dart';

final deviceStatesProvider = Provider<List<DeviceState>>((ref) {
  final devices = ref.watch(devicesMapProvider).asData?.value ?? const {};
  final catalog = DeviceCatalog.defaultTiles();

  final ids = <String>{
    ...catalog.map((e) => e.id),
    ...devices.keys.map((e) => e.toString()),
  }.toList()
    ..sort();

  final metaById = {for (final m in catalog) m.id: m};

  return [
    for (final id in ids)
      DeviceState.fromCatalog(
        id: id,
        title: metaById[id]?.title ?? id,
        subtitle: metaById[id]?.subtitle ?? 'Từ Realtime Database',
        icon: metaById[id]?.icon ?? Icons.electrical_services_rounded,
        raw: devices[id],
      ),
  ];
});

final roomsProvider = Provider<List<Room>>((ref) {
  final raw = ref.watch(roomsMapProvider).asData?.value ?? const {};
  final rooms = <Room>[];
  for (final e in raw.entries) {
    rooms.add(Room.fromFirebase(e.key, e.value));
  }
  rooms.sort((a, b) => a.order.compareTo(b.order));
  return rooms;
});

final roomDevicesProvider =
    Provider.family<List<DeviceState>, String>((ref, roomId) {
  final all = ref.watch(deviceStatesProvider);
  final rooms = ref.watch(roomsMapProvider).asData?.value;

  // Prefer explicit rooms index if present.
  final roomRaw = rooms?[roomId];
  Set<String>? indexedIds;
  if (roomRaw is Map && roomRaw['devices'] is Map) {
    indexedIds = <String>{};
    final devs = roomRaw['devices'] as Map;
    for (final e in devs.entries) {
      if (e.value == true || e.value == 1) indexedIds.add(e.key.toString());
    }
  }

  final byIndex =
      indexedIds != null ? all.where((d) => indexedIds!.contains(d.id)) : null;
  if (byIndex != null) return byIndex.toList();

  // Fallback: group by device.roomId.
  return all.where((d) => d.roomId == roomId).toList();
});

