import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/firebase_providers.dart';
import '../providers/mqtt_providers.dart';

class ConnectionStatusBar extends ConsumerStatefulWidget {
  const ConnectionStatusBar({super.key, this.compact = false});

  final bool compact;

  @override
  ConsumerState<ConnectionStatusBar> createState() => _ConnectionStatusBarState();
}

class _ConnectionStatusBarState extends ConsumerState<ConnectionStatusBar> {
  late final StreamSubscription<List<ConnectivityResult>> _netSub;
  List<ConnectivityResult> _connectivity = [ConnectivityResult.none];

  @override
  void initState() {
    super.initState();
    Connectivity().checkConnectivity().then((r) {
      if (mounted) setState(() => _connectivity = r);
    });
    _netSub = Connectivity().onConnectivityChanged.listen((r) {
      if (mounted) setState(() => _connectivity = r);
    });
  }

  @override
  void dispose() {
    _netSub.cancel();
    super.dispose();
  }

  bool get _hasInternet =>
      _connectivity.isNotEmpty &&
      _connectivity.any((r) => r != ConnectivityResult.none);

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(firebaseServiceProvider);
    final mqtt = ref.watch(mqttEdgeServiceProvider);

    return StreamBuilder<bool>(
      stream: service.listenFirebaseConnected(),
      initialData: false,
      builder: (context, fbSnap) {
        final firebaseOn = fbSnap.data == true;

        return StreamBuilder<Map<String, dynamic>>(
          stream: service.listenHubHealth(),
          builder: (context, hubSnap) {
            final hub = hubSnap.data ?? {};
            final hubOnline = hub['online'];
            bool hubAlive =
                hubOnline == true || hubOnline == 1 || hubOnline == 'true';
            if (!hubAlive && hub['lastSeen'] != null) {
              final ls = hub['lastSeen'];
              final ms = ls is num ? ls.toInt() : int.tryParse('$ls') ?? 0;
              if (ms > 0) {
                hubAlive = DateTime.now().millisecondsSinceEpoch - ms < 90000;
              }
            }

            if (widget.compact) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dot(_hasInternet, 'Mạng'),
                  const SizedBox(width: 8),
                  _dot(firebaseOn, 'Cloud'),
                  const SizedBox(width: 8),
                  _dot(hubOnline != null ? hubAlive : firebaseOn, 'Hub'),
                  const SizedBox(width: 8),
                  _dot(mqtt.isConnected, 'MQTT'),
                ],
              );
            }

            return Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _chip(
                  icon: Icons.wifi_rounded,
                  label: _hasInternet ? 'Mạng' : 'Mạng offline',
                  active: _hasInternet,
                  sub: !_hasInternet ? 'Chế độ local/demo hạn chế' : null,
                ),
                _chip(
                  icon: Icons.cloud_done_rounded,
                  label: firebaseOn ? 'Firebase realtime' : 'Cloud ngắt',
                  active: firebaseOn,
                ),
                _chip(
                  icon: Icons.hub_rounded,
                  label: hub['online'] != null
                      ? (hubAlive ? 'Edge hub online' : 'Edge hub offline')
                      : 'Hub (Pi) chưa gửi trạng thái',
                  active: hub['online'] != null ? hubAlive : firebaseOn,
                  sub: hub['online'] == null ? 'Cấu hình Pi ghi system/hub' : null,
                ),
                _chip(
                  icon: Icons.cable_rounded,
                  label: mqtt.enabled
                      ? (mqtt.isConnected ? 'MQTT LAN' : 'MQTT chờ broker')
                      : 'MQTT tắt',
                  active: mqtt.isConnected,
                  sub: mqtt.enabled ? '${mqtt.host}:${mqtt.port}' : 'Cài đặt → bật hybrid',
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _dot(bool on, String tip) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: '$tip: ${on ? "OK" : "off"}',
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: on ? scheme.primary : scheme.outline.withValues(alpha: 0.8),
          boxShadow: on
              ? [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.45),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
      ),
    );
  }

  Widget _chip({
    required IconData icon,
    required String label,
    required bool active,
    String? sub,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final bg = Theme.of(context).cardTheme.color ?? scheme.surface;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: bg,
        border: Border.all(
          color: active
              ? scheme.primary.withValues(alpha: 0.45)
              : scheme.outline.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: active
                ? scheme.primary
                : scheme.onSurface.withValues(alpha: 0.45),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (sub != null)
                  Text(
                    sub,
                    style: TextStyle(
                      fontSize: 10,
                      color: scheme.onSurface.withValues(alpha: 0.55),
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
