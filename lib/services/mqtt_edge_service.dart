import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Optional LAN path: App → MQTT (Raspberry Pi broker) → ESP32, song song với Firebase.
///
/// Topic convention (đổi `prefix` trong Cài đặt nếu Pi của bạn khác):
/// - Điều khiển: `{prefix}/devices/{deviceId}/set` — payload JSON `{"status": bool, "source": "app"}`
/// - Thoại (offline): `{prefix}/voice/command` — JSON `{"text": "...", "ts": ms}`
class MqttEdgeService extends ChangeNotifier {
  MqttEdgeService._();
  static final MqttEdgeService instance = MqttEdgeService._();

  MqttServerClient? _client;

  bool _enabled = false;
  String _host = '192.168.1.50';
  int _port = 1883;
  String _user = '';
  String _pass = '';
  String _prefix = 'smarthome';

  bool get enabled => _enabled;
  String get host => _host;
  int get port => _port;
  String get user => _user;
  String get pass => _pass;
  String get prefix => _prefix;

  bool get isConnected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  Future<void> loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    _enabled = p.getBool('mqtt_enabled') ?? false;
    _host = p.getString('mqtt_host') ?? _host;
    _port = p.getInt('mqtt_port') ?? 1883;
    _user = p.getString('mqtt_user') ?? '';
    _pass = p.getString('mqtt_pass') ?? '';
    _prefix = p.getString('mqtt_prefix') ?? 'smarthome';
    notifyListeners();
    if (_enabled) {
      scheduleMicrotask(() => unawaited(_tryConnect()));
    }
  }

  Future<void> applySettings({
    required bool enabled,
    required String host,
    required int port,
    required String user,
    required String pass,
    required String prefix,
  }) async {
    _enabled = enabled;
    _host = host.trim();
    _port = port;
    _user = user.trim();
    _pass = pass;
    _prefix = prefix.trim().isEmpty ? 'smarthome' : prefix.trim();

    final p = await SharedPreferences.getInstance();
    await p.setBool('mqtt_enabled', _enabled);
    await p.setString('mqtt_host', _host);
    await p.setInt('mqtt_port', _port);
    await p.setString('mqtt_user', _user);
    await p.setString('mqtt_pass', _pass);
    await p.setString('mqtt_prefix', _prefix);

    notifyListeners();
    await disconnect();
    if (_enabled) {
      await _tryConnect();
    }
  }

  Future<void> disconnect() async {
    try {
      _client?.disconnect();
    } catch (_) {}
    _client = null;
    notifyListeners();
  }

  Future<void> _tryConnect() async {
    if (!_enabled || _host.isEmpty) return;

    await disconnect();

    final clientId = 'flutter_${DateTime.now().millisecondsSinceEpoch}';
    final c = MqttServerClient.withPort(_host, clientId, _port);
    c.logging(on: kDebugMode);
    c.keepAlivePeriod = 30;
    c.connectTimeoutPeriod = 10000;
    c.onDisconnected = () => notifyListeners();
    c.onConnected = () => notifyListeners();
    _client = c;

    try {
      final status = await c.connect(
        _user.isEmpty ? null : _user,
        _pass.isEmpty ? null : _pass,
      );
      if (status?.state != MqttConnectionState.connected) {
        if (kDebugMode) {
          debugPrint('MQTT connect failed: $status');
        }
        _client = null;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('MQTT error: $e');
      _client = null;
    }
    notifyListeners();
  }

  void publishDeviceStateIfReady(String deviceId, bool status) {
    if (!enabled || !isConnected || _client == null) return;
    final topic = '$_prefix/devices/$deviceId/set';
    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode({'status': status, 'source': 'flutter_app'}));
    try {
      _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    } catch (e) {
      if (kDebugMode) debugPrint('MQTT publish device: $e');
    }
  }

  void publishVoiceIfReady(String text) {
    if (!enabled || !isConnected || _client == null) return;
    final topic = '$_prefix/voice/command';
    final builder = MqttClientPayloadBuilder();
    builder.addString(
      jsonEncode({'text': text, 'ts': DateTime.now().millisecondsSinceEpoch}),
    );
    try {
      _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    } catch (e) {
      if (kDebugMode) debugPrint('MQTT publish voice: $e');
    }
  }
}
