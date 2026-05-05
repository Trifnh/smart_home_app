import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/device_catalog.dart';
import '../providers/firebase_providers.dart';
import '../services/firebase_service.dart';
import '../widgets/animated_device_tile.dart';

/// Full device list synced from `devices/` in Firebase.
class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  List<DeviceUi> get catalog => DeviceCatalog.defaultTiles();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.watch(firebaseServiceProvider);

    return StreamBuilder<Map<String, dynamic>>(
      stream: svc.listenToDevices(),
      builder: (context, snap) {
        final devices = snap.data ?? {};
        final extraIds = devices.keys
            .where((id) => !catalog.map((d) => d.id).contains(id))
            .toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 108),
          children: [
            Text(
              'Đồng bộ realtime với Raspberry Pi ↔ MQTT ↔ ESP32',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.5),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            ...catalog.map((meta) {
              final raw = devices[meta.id];
              final on = deviceStatusFromFirebase(raw);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AnimatedDeviceTile(
                  meta: meta,
                  isOn: on,
                  onToggle: (v) => svc.toggleDevice(meta.id, v),
                ),
              );
            }),
            if (extraIds.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Thiết bị thêm trong Firebase',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
              ),
              const SizedBox(height: 12),
              ...extraIds.map((id) {
                final raw = devices[id];
                final on = deviceStatusFromFirebase(raw);
                final meta = DeviceUi(
                  id,
                  id,
                  Icons.electrical_services_rounded,
                  'Từ Realtime Database',
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AnimatedDeviceTile(
                    meta: meta,
                    isOn: on,
                    onToggle: (v) => svc.toggleDevice(id, v),
                  ),
                );
              }),
            ],
          ],
        );
      },
    );
  }
}
