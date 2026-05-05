import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/firebase_providers.dart';
import '../../providers/room_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/device/device_card.dart';
import 'sensor_config_screen.dart';

class RoomDetailScreen extends ConsumerWidget {
  const RoomDetailScreen({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  final String roomId;
  final String roomName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(roomDevicesProvider(roomId));
    final roomsRaw = ref.watch(roomsMapProvider).asData?.value ?? const <String, dynamic>{};
    final roomRaw = roomsRaw[roomId];
    final sensors = _extractVisibleSensors(roomRaw);
    final hasSensorConfig = _hasNonEmptySensorConfig(roomRaw);
    final w = MediaQuery.sizeOf(context).width;
    final cross = w >= 1024 ? 3 : 2;
    final ratio = w >= 1024
        ? 1.45
        : w >= 900
            ? 1.30
            : w <= 420
                ? 0.92
                : 1.05;

    return Scaffold(
      appBar: AppBar(
        title: Text(roomName),
        actions: [
          IconButton(
            tooltip: 'Sensor config',
            icon: const Icon(Icons.add_chart_rounded),
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => SensorConfigScreen(
                    roomId: roomId,
                    roomName: roomName,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        child: ListView(
          children: [
            _SectionTitle(
              title: 'Môi trường phòng',
              subtitle: sensors.isEmpty
                  ? (hasSensorConfig
                      ? 'Bật sensor trong Sensor config (nút +)'
                      : 'Chưa có sensor cho phòng này')
                  : '${sensors.length} sensor hiển thị',
            ),
            const SizedBox(height: 10),
            if (sensors.isEmpty)
              _NoSensorCard(roomId: roomId, configOnlyMode: hasSensorConfig)
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sensors.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: w <= 420 ? 1 : 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: w <= 420 ? 2.8 : 1.9,
                ),
                itemBuilder: (_, i) {
                  final e = sensors.entries.elementAt(i);
                  final spec = _sensorSpec(e.key);
                  return _SensorTile(
                    label: spec.label,
                    value: _formatValue(e.value, unit: spec.unit),
                    icon: spec.icon,
                    accent: spec.accent,
                  );
                },
              ),
            const SizedBox(height: 16),
            _SectionTitle(
              title: 'Thiết bị',
              subtitle: devices.isEmpty
                  ? 'Chưa có thiết bị trong phòng'
                  : '${devices.length} thiết bị điều khiển',
            ),
            const SizedBox(height: 10),
            if (devices.isEmpty)
              _EmptyRoom(roomId: roomId)
            else
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: cross,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: ratio,
                children: [
                  for (final d in devices)
                    DeviceCard(
                      deviceId: d.id,
                      title: d.title,
                      subtitle: d.subtitle,
                      icon: d.icon,
                      isOn: d.isOn,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// Khi có `sensor_config` không rỗng: chỉ hiện ô sensor cho key có `enabled: true`.
  /// Khi chưa có config (Pi cũ): hiện toàn bộ map `sensors`.
  static Map<String, dynamic> _extractVisibleSensors(dynamic roomRaw) {
    if (roomRaw is! Map) return const {};
    final sensorsRaw = roomRaw['sensors'];
    final all = sensorsRaw is Map
        ? Map<String, dynamic>.from(
            sensorsRaw.map((k, v) => MapEntry(k.toString().toLowerCase(), v)),
          )
        : <String, dynamic>{};

    final cfgRaw = roomRaw['sensor_config'];
    if (cfgRaw is! Map || cfgRaw.isEmpty) {
      return Map<String, dynamic>.from(all);
    }

    final enabledKeys = <String>{};
    for (final e in cfgRaw.entries) {
      final k = e.key.toString().toLowerCase();
      if (_configEntryEnabled(e.value)) enabledKeys.add(k);
    }
    if (enabledKeys.isEmpty) return const {};

    final out = <String, dynamic>{};
    for (final k in enabledKeys) {
      out[k] = all[k];
    }
    final sorted = Map.fromEntries(
      out.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    return sorted;
  }

  static bool _hasNonEmptySensorConfig(dynamic roomRaw) {
    if (roomRaw is! Map) return false;
    final cfgRaw = roomRaw['sensor_config'];
    return cfgRaw is Map && cfgRaw.isNotEmpty;
  }

  static bool _configEntryEnabled(dynamic v) {
    if (v == true) return true;
    if (v is Map) {
      final e = v['enabled'];
      return e == true ||
          e == 1 ||
          (e is String && (e.toLowerCase() == 'true' || e == '1'));
    }
    return false;
  }

  static String _formatValue(dynamic v, {String unit = ''}) {
    if (v == null) return '--';
    if (v is bool) return v ? 'Detected' : 'None';
    if (v is num) {
      final base = v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
      return unit.isEmpty ? base : '$base$unit';
    }
    final s = '$v';
    return unit.isEmpty ? s : '$s$unit';
  }

  static ({String label, String unit, IconData icon, Color accent}) _sensorSpec(
    String key,
  ) {
    switch (key.toLowerCase()) {
      case 'temperature':
        return (
          label: 'Temperature',
          unit: '°C',
          icon: Icons.thermostat_rounded,
          accent: AppTheme.warm,
        );
      case 'humidity':
        return (
          label: 'Humidity',
          unit: '%',
          icon: Icons.water_drop_rounded,
          accent: AppTheme.cool,
        );
      case 'air_quality':
      case 'airquality':
        return (
          label: 'Air Quality',
          unit: '',
          icon: Icons.air_rounded,
          accent: const Color(0xFF60A5FA),
        );
      case 'presence':
      case 'motion':
        return (
          label: 'Presence',
          unit: '',
          icon: Icons.person_pin_circle_rounded,
          accent: const Color(0xFF10B981),
        );
      case 'door':
      case 'door_open':
        return (
          label: 'Door',
          unit: '',
          icon: Icons.door_front_door_rounded,
          accent: const Color(0xFFF59E0B),
        );
      case 'light':
      case 'lux':
        return (
          label: 'Light',
          unit: ' lux',
          icon: Icons.wb_sunny_rounded,
          accent: const Color(0xFFFACC15),
        );
      case 'rain':
        return (
          label: 'Rain',
          unit: '',
          icon: Icons.grain_rounded,
          accent: const Color(0xFF38BDF8),
        );
      case 'pm25':
        return (
          label: 'PM2.5',
          unit: '',
          icon: Icons.blur_on_rounded,
          accent: const Color(0xFFA78BFA),
        );
      default:
        return (
          label: key,
          unit: '',
          icon: Icons.sensors_rounded,
          accent: const Color(0xFF94A3B8),
        );
    }
  }

}

class _EmptyRoom extends StatelessWidget {
  const _EmptyRoom({required this.roomId});

  final String roomId;

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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chưa có thiết bị trong phòng',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kiểm tra `rooms/$roomId/devices/{deviceId}=true` hoặc thêm `roomId` vào `devices/{deviceId}`.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  height: 1.35,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
        ],
      ),
    );
  }
}

class _NoSensorCard extends StatelessWidget {
  const _NoSensorCard({required this.roomId, required this.configOnlyMode});

  final String roomId;
  final bool configOnlyMode;

  @override
  Widget build(BuildContext context) {
    final msg = configOnlyMode
        ? 'Không có sensor nào được bật. Mở nút + → Sensor config để bật key cần hiển thị. Khi tắt key, ô tương ứng biến mất.'
        : 'Gửi dữ liệu vào `rooms/$roomId/sensors/*` hoặc dùng Sensor config để chọn key hiển thị (Pi publish theo key đã bật).';
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.r20),
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.6)),
      ),
      padding: const EdgeInsets.all(14),
      child: Text(
        msg,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              height: 1.35,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
            ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
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
    );
  }
}

class _SensorTile extends StatelessWidget {
  const _SensorTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

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
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: accent.withValues(alpha: 0.15),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

