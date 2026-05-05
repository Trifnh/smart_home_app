import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/firebase_providers.dart';
import '../../theme/app_theme.dart';

class SensorConfigScreen extends ConsumerStatefulWidget {
  const SensorConfigScreen({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  final String roomId;
  final String roomName;

  @override
  ConsumerState<SensorConfigScreen> createState() => _SensorConfigScreenState();
}

class _SensorConfigScreenState extends ConsumerState<SensorConfigScreen> {
  static const _presets = <_SensorPreset>[
    _SensorPreset('temperature', 'Temperature', '°C'),
    _SensorPreset('humidity', 'Humidity', '%'),
    _SensorPreset('air_quality', 'Air quality', ''),
    _SensorPreset('presence', 'Presence', ''),
    _SensorPreset('door', 'Door', ''),
    _SensorPreset('lux', 'Light intensity', 'lux'),
    _SensorPreset('rain', 'Rain', ''),
    _SensorPreset('pm25', 'PM2.5', ''),
  ];

  Future<void> _addCustom() async {
    final keyCtrl = TextEditingController();
    final labelCtrl = TextEditingController();
    final unitCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add custom sensor key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyCtrl,
              decoration: const InputDecoration(labelText: 'sensor_key'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: labelCtrl,
              decoration: const InputDecoration(labelText: 'Label (optional)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: unitCtrl,
              decoration: const InputDecoration(labelText: 'Unit (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;
    final key = keyCtrl.text.trim().toLowerCase();
    if (key.isEmpty) return;
    await ref.read(firebaseServiceProvider).upsertRoomSensorConfig(
          roomId: widget.roomId,
          sensorKey: key,
          enabled: true,
          label: labelCtrl.text.trim(),
          unit: unitCtrl.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final roomsRaw = ref.watch(roomsMapProvider).asData?.value ?? const <String, dynamic>{};
    final room = roomsRaw[widget.roomId];
    final cfg = _readConfig(room);
    final cfgKeys = cfg.keys.toSet();

    return Scaffold(
      appBar: AppBar(
        title: Text('Sensor config • ${widget.roomName}'),
        actions: [
          IconButton(
            tooltip: 'Add custom key',
            onPressed: _addCustom,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          Text(
            'Pi should read `rooms/${widget.roomId}/sensor_config/*` and publish values to `rooms/${widget.roomId}/sensors/*`.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
          const SizedBox(height: 14),
          ..._presets.map((p) {
            final active = cfgKeys.contains(p.key) && _isEnabled(cfg[p.key]);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ConfigTile(
                title: p.label,
                subtitle: '${p.key}${p.unit.isEmpty ? '' : ' • ${p.unit}'}',
                active: active,
                onChanged: (v) async {
                  if (v) {
                    await ref.read(firebaseServiceProvider).upsertRoomSensorConfig(
                          roomId: widget.roomId,
                          sensorKey: p.key,
                          enabled: true,
                          label: p.label,
                          unit: p.unit,
                        );
                  } else {
                    await ref.read(firebaseServiceProvider).removeRoomSensorConfig(
                          roomId: widget.roomId,
                          sensorKey: p.key,
                        );
                  }
                },
              ),
            );
          }),
          if (cfg.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Configured keys',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            ...cfg.entries.map((e) {
              final key = e.key;
              final value = e.value;
              final preset = _presets.where((p) => p.key == key).firstOrNull;
              if (preset != null) return const SizedBox.shrink();
              final enabled = _isEnabled(value);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ConfigTile(
                  title: (value is Map && value['label'] != null)
                      ? '${value['label']}'
                      : key,
                  subtitle: key,
                  active: enabled,
                  trailingDelete: true,
                  onDelete: () async {
                    await ref.read(firebaseServiceProvider).removeRoomSensorConfig(
                          roomId: widget.roomId,
                          sensorKey: key,
                        );
                  },
                  onChanged: (v) async {
                    if (v) {
                      await ref.read(firebaseServiceProvider).upsertRoomSensorConfig(
                            roomId: widget.roomId,
                            sensorKey: key,
                            enabled: true,
                          );
                    } else {
                      await ref.read(firebaseServiceProvider).removeRoomSensorConfig(
                            roomId: widget.roomId,
                            sensorKey: key,
                          );
                    }
                  },
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  static Map<String, dynamic> _readConfig(dynamic roomRaw) {
    if (roomRaw is! Map) return {};
    final raw = roomRaw['sensor_config'];
    if (raw is! Map) return {};
    return Map<String, dynamic>.from(raw.map((k, v) => MapEntry('$k', v)));
  }

  static bool _isEnabled(dynamic v) {
    if (v is bool) return v;
    if (v is Map) {
      final e = v['enabled'];
      return e == true || e == 1 || e == 'true';
    }
    return false;
  }
}

class _ConfigTile extends StatelessWidget {
  const _ConfigTile({
    required this.title,
    required this.subtitle,
    required this.active,
    required this.onChanged,
    this.trailingDelete = false,
    this.onDelete,
  });

  final String title;
  final String subtitle;
  final bool active;
  final ValueChanged<bool> onChanged;
  final bool trailingDelete;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.r20),
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.6)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
          ),
          if (trailingDelete)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          Switch.adaptive(
            value: active,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SensorPreset {
  const _SensorPreset(this.key, this.label, this.unit);
  final String key;
  final String label;
  final String unit;
}

extension _FirstWhereOrNullExt<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

