import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/mqtt_providers.dart';
import '../theme/app_theme.dart';

/// Cấu hình MQTT tới broker trên Raspberry Pi (LAN) — hybrid với Firebase.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _host = TextEditingController();
  final _port = TextEditingController();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  final _prefix = TextEditingController();
  bool _enabled = false;
  var _seeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    _seeded = true;
    final m = ref.read(mqttEdgeServiceProvider);
    _host.text = m.host;
    _port.text = '${m.port}';
    _user.text = m.user;
    _pass.text = m.pass;
    _prefix.text = m.prefix;
    _enabled = m.enabled;
  }

  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    _user.dispose();
    _pass.dispose();
    _prefix.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final port = int.tryParse(_port.text.trim()) ?? 1883;
    final mqtt = ref.read(mqttEdgeServiceProvider);
    final messenger = ScaffoldMessenger.of(context);
    await mqtt.applySettings(
      enabled: _enabled,
      host: _host.text,
      port: port,
      user: _user.text,
      pass: _pass.text,
      prefix: _prefix.text,
    );
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          mqtt.isConnected
              ? 'Đã kết nối MQTT ${mqtt.host}:${mqtt.port}'
              : (mqtt.enabled
                    ? 'Đã lưu — MQTT chưa kết nối (kiểm tra IP/broker)'
                    : 'Đã tắt MQTT'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = ref.watch(mqttEdgeServiceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt MQTT (LAN)')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Bật khi demo offline: điện thoại cùng Wi-Fi với Pi, broker Mosquitto '
            'thường chạy cổng 1883. App vẫn ghi Firebase khi có mạng; MQTT gửi song song.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 20),
          SwitchListTile.adaptive(
            value: _enabled,
            title: const Text('Bật MQTT hybrid'),
            subtitle: Text(
              'Topics: {prefix}/devices/{{id}}/set và {prefix}/voice/command',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ),
            onChanged: (v) => setState(() => _enabled = v),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _host,
            decoration: const InputDecoration(
              labelText: 'Broker (IP hoặc hostname Pi)',
              hintText: '192.168.1.50',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _port,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Cổng'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _prefix,
            decoration: const InputDecoration(
              labelText: 'Topic prefix',
              hintText: 'smarthome',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _user,
            decoration: const InputDecoration(labelText: 'User (tuỳ chọn)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pass,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password (tuỳ chọn)'),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(
                Icons.circle,
                size: 12,
                color: m.isConnected ? AppTheme.accent : const Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  m.isConnected
                      ? 'MQTT: đã kết nối'
                      : (m.enabled ? 'MQTT: chưa kết nối' : 'MQTT: đang tắt'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: AppTheme.accentDim,
            ),
            child: const Text('Lưu và kết nối'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await ref.read(mqttEdgeServiceProvider).disconnect();
              if (!mounted) return;
              messenger.showSnackBar(
                const SnackBar(content: Text('Đã ngắt MQTT')),
              );
            },
            child: const Text('Ngắt MQTT'),
          ),
        ],
      ),
    );
  }
}
