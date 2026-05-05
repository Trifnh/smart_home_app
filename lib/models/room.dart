import 'package:flutter/material.dart';

class Room {
  const Room({
    required this.id,
    required this.name,
    required this.icon,
    required this.order,
    required this.deviceIds,
  });

  final String id;
  final String name;
  final IconData icon;
  final int order;
  final Set<String> deviceIds;

  static IconData iconFromString(String? s) {
    switch ((s ?? '').toLowerCase().trim()) {
      case 'sofa':
      case 'weekend':
      case 'living':
        return Icons.weekend_rounded;
      case 'bed':
      case 'bedroom':
        return Icons.bed_rounded;
      case 'kitchen':
        return Icons.kitchen_rounded;
      case 'bath':
      case 'bathroom':
        return Icons.bathtub_rounded;
      default:
        return Icons.meeting_room_rounded;
    }
  }

  factory Room.fromFirebase(String id, dynamic raw) {
    if (raw is Map) {
      final name = raw['name']?.toString() ?? id;
      final icon = iconFromString(raw['icon']?.toString());
      final order = (raw['order'] is num) ? (raw['order'] as num).toInt() : 999;
      final devices = <String>{};
      final rawDevices = raw['devices'];
      if (rawDevices is Map) {
        for (final e in rawDevices.entries) {
          if (e.value == true || e.value == 1) devices.add(e.key.toString());
        }
      }
      return Room(
        id: id,
        name: name,
        icon: icon,
        order: order,
        deviceIds: devices,
      );
    }
    return Room(
      id: id,
      name: id,
      icon: Icons.meeting_room_rounded,
      order: 999,
      deviceIds: const {},
    );
  }
}

