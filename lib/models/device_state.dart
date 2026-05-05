import 'package:flutter/material.dart';

import '../services/firebase_service.dart';
class DeviceState {
  const DeviceState({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isOn,
    required this.roomId,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isOn;
  final String? roomId;

  factory DeviceState.fromCatalog({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required dynamic raw,
  }) {
    String? roomId;
    if (raw is Map) {
      roomId = raw['roomId']?.toString();
    }
    return DeviceState(
      id: id,
      title: title,
      subtitle: subtitle,
      icon: icon,
      isOn: deviceStatusFromFirebase(raw),
      roomId: roomId,
    );
  }
}

