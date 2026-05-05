import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/automation_rule.dart';
import 'mqtt_edge_service.dart';

class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  bool _initialized = false;
  bool _uiDemo = false;

  // Firebase RTDB plugin streams can be single-subscription on some platforms.
  // The app listens to the same paths from multiple tabs (Home + Devices),
  // so we cache broadcast streams here to avoid "Stream has already been listened to".
  Stream<Map<String, dynamic>>? _sensors$;
  Stream<Map<String, dynamic>>? _devices$;
  Stream<bool>? _firebaseConnected$;
  Stream<Map<String, dynamic>>? _hubHealth$;
  Stream<Map<String, AutomationRule>>? _automations$;
  Stream<Map<String, dynamic>>? _automationSensorConfig$;
  Stream<String?>? _voiceLastResult$;
  Stream<Map<String, dynamic>>? _rooms$;

  /// `true` khi đã gọi [activateUiDemo] (vd. `--dart-define=MOCK_UI=true`).
  bool get isUiDemoMode => _uiDemo;

  FirebaseAuth get _auth {
    _ensureInitialized();
    return FirebaseAuth.instance;
  }

  FirebaseDatabase get _database {
    _ensureInitialized();
    return FirebaseDatabase.instance;
  }

  /// Dữ liệu giả: sensor dao động, thiết bị, hub online, automation mẫu, voice placeholder.
  static void activateUiDemo() {
    final s = instance;
    s._uiDemo = true;
    s._initialized = false;
    s._ensureDemoControllers();
    s._seedUiDemo();

    s._demoHubTimer?.cancel();
    s._demoHubTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      s._emitDemoHubPulse();
    });
  }

  Map<String, dynamic> _sensorMap = {};
  final Map<String, dynamic> _devicesMap = {};

  StreamController<Map<String, dynamic>>? _demoSensorsCtrl;
  StreamController<Map<String, dynamic>>? _demoDevicesCtrl;
  StreamController<Map<String, AutomationRule>>? _demoRulesCtrl;
  StreamController<Map<String, dynamic>>? _demoAutoSensorCfgCtrl;
  StreamController<bool>? _demoFbCtrl;
  StreamController<Map<String, dynamic>>? _demoHubCtrl;
  StreamController<String?>? _demoVoiceCtrl;
  Timer? _demoSensorTimer;
  Timer? _demoHubTimer;
  Map<String, AutomationRule> _rulesMap = {};
  final Map<String, dynamic> _autoSensorCfg = {
    'temperature': {'enabled': true, 'label': 'Nhiệt độ', 'unit': '°C'},
    'humidity': {'enabled': true, 'label': 'Độ ẩm', 'unit': '%'},
  };

  void _ensureDemoControllers() {
    _demoSensorsCtrl ??= StreamController<Map<String, dynamic>>.broadcast(
      onListen: () {
        scheduleMicrotask(() {
          if (!_uiDemo || _demoSensorsCtrl!.isClosed) return;
          _demoSensorsCtrl!.add(Map<String, dynamic>.from(_sensorMap));
        });
      },
    );
    _demoDevicesCtrl ??= StreamController<Map<String, dynamic>>.broadcast(
      onListen: () {
        scheduleMicrotask(() {
          if (!_uiDemo || _demoDevicesCtrl!.isClosed) return;
          _demoDevicesCtrl!.add(_cloneDevicesMap());
        });
      },
    );
    _demoRulesCtrl ??= StreamController<Map<String, AutomationRule>>.broadcast(
      onListen: () {
        scheduleMicrotask(() {
          if (!_uiDemo || _demoRulesCtrl!.isClosed) return;
          _demoRulesCtrl!.add(Map<String, AutomationRule>.from(_rulesMap));
        });
      },
    );
    _demoAutoSensorCfgCtrl ??=
        StreamController<Map<String, dynamic>>.broadcast(onListen: () {
      scheduleMicrotask(() {
        if (!_uiDemo || _demoAutoSensorCfgCtrl!.isClosed) return;
        _demoAutoSensorCfgCtrl!.add(Map<String, dynamic>.from(_autoSensorCfg));
      });
    });
    _demoFbCtrl ??= StreamController<bool>.broadcast(
      onListen: () {
        scheduleMicrotask(() {
          if (!_uiDemo || _demoFbCtrl!.isClosed) return;
          _demoFbCtrl!.add(true);
        });
      },
    );
    _demoHubCtrl ??= StreamController<Map<String, dynamic>>.broadcast(
      onListen: () {
        scheduleMicrotask(() {
          if (!_uiDemo || _demoHubCtrl!.isClosed) return;
          _emitDemoHubPulse();
        });
      },
    );
    _demoVoiceCtrl ??= StreamController<String?>.broadcast(
      onListen: () {
        scheduleMicrotask(() {
          if (!_uiDemo || _demoVoiceCtrl!.isClosed) return;
          _demoVoiceCtrl!.add(
            'Pi (giả lập): "Bật đèn phòng khách" — đã thực hiện.',
          );
        });
      },
    );
  }

  void _seedUiDemo() {
    _sensorMap = {'temperature': 28.2, 'humidity': 65.0};
    _devicesMap.clear();
    _devicesMap.addAll({
      'light1': {'status': true},
      'light2': {'status': false},
      'fan': {'status': true},
      'ac': {'status': false},
    });

    _rulesMap = {
      'demo_rule_hot': AutomationRule(
        id: 'demo_rule_hot',
        name: 'Nóng thì bật quạt',
        enabled: true,
        sensorKey: 'temperature',
        operator: 'gt',
        // Nhiệt độ mock khởi tạo ~28°C; ngưỡng 27 để rule bật quạt ngay khi mở demo.
        threshold: 27,
        deviceId: 'fan',
        targetOn: true,
      ),
      'demo_rule_dry': AutomationRule(
        id: 'demo_rule_dry',
        name: 'Khô thì relay (demo)',
        enabled: false,
        sensorKey: 'humidity',
        operator: 'lt',
        threshold: 35,
        deviceId: 'relay',
        targetOn: true,
      ),
    };

    _demoSensorTimer?.cancel();
    _demoSensorTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_uiDemo) return;
      var t = (_sensorMap['temperature'] as num?)?.toDouble() ?? 28;
      var h = (_sensorMap['humidity'] as num?)?.toDouble() ?? 65;
      t = (t + (t < 31 ? 0.2 : -0.25)).clamp(25.0, 32.5);
      h = (h + (h < 72 ? 0.9 : -0.7)).clamp(42.0, 88.0);
      _sensorMap['temperature'] = t;
      _sensorMap['humidity'] = h;
      if (!_demoSensorsCtrl!.isClosed) {
        _demoSensorsCtrl!.add(Map<String, dynamic>.from(_sensorMap));
      }
      _applyDemoAutomations();
    });

    scheduleMicrotask(() {
      if (!_uiDemo) return;
      _demoSensorsCtrl?.add(Map<String, dynamic>.from(_sensorMap));
      _applyDemoAutomations();
      _demoRulesCtrl?.add(Map<String, AutomationRule>.from(_rulesMap));
      _demoFbCtrl?.add(true);
      _emitDemoHubPulse();
    });
  }

  void _emitDemoHubPulse() {
    if (!_uiDemo || _demoHubCtrl == null || _demoHubCtrl!.isClosed) return;
    _demoHubCtrl!.add({
      'online': true,
      'lastSeen': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Map<String, dynamic> _cloneDevicesMap() {
    return Map<String, dynamic>.from(
      _devicesMap.map((k, v) {
        if (v is Map) {
          return MapEntry(
            k,
            Map<String, dynamic>.from(v.map((ik, iv) => MapEntry('$ik', iv))),
          );
        }
        return MapEntry(k, v);
      }),
    );
  }

  static bool _operatorMatches(String op, double value, double th) {
    switch (op) {
      case 'gt':
        return value > th;
      case 'gte':
        return value >= th;
      case 'lt':
        return value < th;
      case 'lte':
        return value <= th;
      case 'eq':
        return (value - th).abs() < 1e-6;
      default:
        return false;
    }
  }

  double? _demoSensorNum(String key) {
    final raw = _sensorMap[key];
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw);
    return null;
  }

  void _setDemoDeviceStatus(String deviceId, bool on) {
    final prev = _devicesMap[deviceId];
    if (prev is Map) {
      _devicesMap[deviceId] = Map<String, dynamic>.from(
        prev.map((k, v) => MapEntry(k.toString(), v)),
      )..['status'] = on;
    } else {
      _devicesMap[deviceId] = {'status': on};
    }
  }

  /// UI mock: không có Pi — đánh giá rule trong app và cập nhật `devices/`.
  ///
  /// Điều kiện đúng → [AutomationRule.targetOn]; sai → ngược lại (vd. nhiệt độ
  /// không còn > 20 thì tắt quạt nếu rule là “bật khi > 20”).
  void _applyDemoAutomations() {
    if (!_uiDemo) return;
    final entries = _rulesMap.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final e in entries) {
      final rule = e.value;
      if (!rule.enabled) continue;
      final v = _demoSensorNum(rule.sensorKey);
      if (v == null) continue;
      final met = _operatorMatches(rule.operator, v, rule.threshold);
      final on = met ? rule.targetOn : !rule.targetOn;
      _setDemoDeviceStatus(rule.deviceId, on);
    }
    if (_demoDevicesCtrl != null && !_demoDevicesCtrl!.isClosed) {
      _demoDevicesCtrl!.add(_cloneDevicesMap());
    }
  }

  Future<void> initFirebase({FirebaseOptions? options}) async {
    if (_uiDemo) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: options);
      }
      _initialized = true;
    } on FirebaseException catch (e) {
      _initialized = false;
      throw Exception(
        'Firebase initialization failed: ${e.message ?? e.code}. '
        'If running on Web, configure Firebase web app (flutterfire configure).',
      );
    } catch (e) {
      _initialized = false;
      throw Exception('Firebase initialization failed: $e');
    }
  }

  void _ensureInitialized() {
    if (_uiDemo) {
      throw StateError('Firebase not used in UI demo mode');
    }
    if (!_initialized || Firebase.apps.isEmpty) {
      throw Exception(
        'Firebase is not initialized. Call initFirebase() first and ensure web options are configured.',
      );
    }
  }

  Future<User?> signUpWithEmail(String email, String password) async {
    if (_uiDemo) return null;
    final result = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return result.user;
  }

  Future<User?> signInWithEmail(String email, String password) async {
    if (_uiDemo) return null;
    final result = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return result.user;
  }

  Future<void> signOut() async {
    if (_uiDemo) return;
    await _auth.signOut();
  }

  Stream<Map<String, dynamic>> listenToSensors() {
    if (_uiDemo) return _demoSensorsCtrl!.stream;
    return _sensors$ ??= _database
        .ref('sensors')
        .onValue
        .map((event) {
          final value = event.snapshot.value;
          if (value is Map) {
            return Map<String, dynamic>.from(
              value.map((k, v) => MapEntry(k.toString(), v)),
            );
          }
          return <String, dynamic>{};
        })
        .asBroadcastStream();
  }

  Future<void> toggleDevice(String deviceId, bool status) async {
    if (_uiDemo) {
      _devicesMap[deviceId] = {'status': status};
      _demoDevicesCtrl?.add(_cloneDevicesMap());
      return;
    }
    await _database.ref('devices/$deviceId').update({'status': status});
    MqttEdgeService.instance.publishDeviceStateIfReady(deviceId, status);
  }

  Stream<Map<String, dynamic>> listenToDevices() {
    if (_uiDemo) return _demoDevicesCtrl!.stream;
    return _devices$ ??= _database
        .ref('devices')
        .onValue
        .map((event) {
          final value = event.snapshot.value;
          if (value is Map) {
            return Map<String, dynamic>.from(
              value.map((k, v) => MapEntry(k.toString(), v)),
            );
          }
          return <String, dynamic>{};
        })
        .asBroadcastStream();
  }

  Future<void> sendVoiceCommand(String command) async {
    if (_uiDemo) {
      final t = command.trim();
      _demoVoiceCtrl?.add('Pi (giả lập): đã nhận "$t" — chờ NLP trên Pi thực.');
      return;
    }
    await _database.ref().update({
      'voice_command': command.trim(),
      'voice_commands/pending': command.trim(),
      'voice_commands/ts': ServerValue.timestamp,
    });
    MqttEdgeService.instance.publishVoiceIfReady(command.trim());
  }

  Stream<String?> listenVoiceLastResult() {
    if (_uiDemo) return _demoVoiceCtrl!.stream;
    return _voiceLastResult$ ??= _database
        .ref('voice_result')
        .onValue
        .map((e) => e.snapshot.value?.toString())
        .asBroadcastStream();
  }

  Stream<bool> listenFirebaseConnected() {
    if (_uiDemo) return _demoFbCtrl!.stream;
    return _firebaseConnected$ ??= _database
        .ref('.info/connected')
        .onValue
        .map((e) => e.snapshot.value == true)
        .asBroadcastStream();
  }

  Stream<Map<String, dynamic>> listenHubHealth() {
    if (_uiDemo) return _demoHubCtrl!.stream;
    return _hubHealth$ ??= _database
        .ref('system/hub')
        .onValue
        .map((event) {
          final value = event.snapshot.value;
          if (value is Map) {
            return Map<String, dynamic>.from(
              value.map((k, v) => MapEntry(k.toString(), v)),
            );
          }
          return <String, dynamic>{};
        })
        .asBroadcastStream();
  }

  Stream<Map<String, AutomationRule>> listenAutomations() {
    if (_uiDemo) return _demoRulesCtrl!.stream;
    return _automations$ ??= _database
        .ref('automations')
        .onValue
        .map((event) {
          final value = event.snapshot.value;
          final out = <String, AutomationRule>{};
          if (value is Map) {
            for (final entry in value.entries) {
              final key = entry.key.toString();
              final raw = entry.value;
              if (raw is Map) {
                out[key] = AutomationRule.fromMap(key, raw);
              }
            }
          }
          return out;
        })
        .asBroadcastStream();
  }

  /// `automation_config/sensor_config/{sensorKey}` = { enabled, label, unit, updatedAt }
  Stream<Map<String, dynamic>> listenAutomationSensorConfig() {
    if (_uiDemo) return _demoAutoSensorCfgCtrl!.stream;
    return _automationSensorConfig$ ??= _database
        .ref('automation_config/sensor_config')
        .onValue
        .map((event) {
          final value = event.snapshot.value;
          if (value is Map) {
            return Map<String, dynamic>.from(
              value.map((k, v) => MapEntry(k.toString().toLowerCase(), v)),
            );
          }
          return <String, dynamic>{};
        })
        .asBroadcastStream();
  }

  /// Room metadata/index for scalable UI:
  /// - `rooms/{roomId}`: { name, icon, order, ... }
  /// - `rooms/{roomId}/devices/{deviceId}`: true
  ///
  /// Additive only; does not replace `devices/{deviceId}` state.
  Stream<Map<String, dynamic>> listenToRooms() {
    if (_uiDemo) {
      return Stream<Map<String, dynamic>>.value({
        'living': {
          'name': 'Living Room',
          'icon': 'weekend',
          'order': 1,
          'devices': {'light1': true, 'fan': true},
        },
        'bedroom': {
          'name': 'Bedroom',
          'icon': 'bed',
          'order': 2,
          'devices': {'light2': true},
        },
        'kitchen': {
          'name': 'Kitchen',
          'icon': 'kitchen',
          'order': 3,
          'devices': {'ac': true},
        },
      });
    }
    return _rooms$ ??= _database
        .ref('rooms')
        .onValue
        .map((event) {
          final value = event.snapshot.value;
          if (value is Map) {
            return Map<String, dynamic>.from(
              value.map((k, v) => MapEntry(k.toString(), v)),
            );
          }
          return <String, dynamic>{};
        })
        .asBroadcastStream();
  }

  Future<void> saveAutomationRule(AutomationRule rule) async {
    if (_uiDemo) {
      _rulesMap[rule.id] = rule;
      _demoRulesCtrl?.add(Map<String, AutomationRule>.from(_rulesMap));
      _applyDemoAutomations();
      return;
    }
    await _database.ref('automations/${rule.id}').set(rule.toMap());
  }

  Future<void> deleteAutomationRule(String id) async {
    if (_uiDemo) {
      _rulesMap.remove(id);
      _demoRulesCtrl?.add(Map<String, AutomationRule>.from(_rulesMap));
      _applyDemoAutomations();
      return;
    }
    await _database.ref('automations/$id').remove();
  }

  Future<void> upsertAutomationSensorConfig({
    required String sensorKey,
    required bool enabled,
    String? label,
    String? unit,
  }) async {
    final key = sensorKey.trim().toLowerCase();
    if (key.isEmpty) return;
    if (_uiDemo) {
      _autoSensorCfg[key] = {
        'enabled': enabled,
        if (label != null && label.trim().isNotEmpty) 'label': label.trim(),
        if (unit != null && unit.trim().isNotEmpty) 'unit': unit.trim(),
      };
      _demoAutoSensorCfgCtrl?.add(Map<String, dynamic>.from(_autoSensorCfg));
      return;
    }
    final data = <String, dynamic>{
      'enabled': enabled,
      'updatedAt': ServerValue.timestamp,
    };
    if (label != null && label.trim().isNotEmpty) data['label'] = label.trim();
    if (unit != null && unit.trim().isNotEmpty) data['unit'] = unit.trim();
    await _database.ref('automation_config/sensor_config/$key').update(data);
  }

  Future<void> removeAutomationSensorConfig({required String sensorKey}) async {
    final key = sensorKey.trim().toLowerCase();
    if (key.isEmpty) return;
    if (_uiDemo) {
      _autoSensorCfg.remove(key);
      _demoAutoSensorCfgCtrl?.add(Map<String, dynamic>.from(_autoSensorCfg));
      return;
    }
    await _database.ref('automation_config/sensor_config/$key').remove();
  }

  /// Sensor config contract for Pi readers:
  /// `rooms/{roomId}/sensor_config/{sensorKey}` = { enabled: true, label, unit, updatedAt }
  Future<void> upsertRoomSensorConfig({
    required String roomId,
    required String sensorKey,
    required bool enabled,
    String? label,
    String? unit,
  }) async {
    final key = sensorKey.trim().toLowerCase();
    if (key.isEmpty) return;
    if (_uiDemo) return;
    final data = <String, dynamic>{
      'enabled': enabled,
      'updatedAt': ServerValue.timestamp,
    };
    if (label != null && label.trim().isNotEmpty) data['label'] = label.trim();
    if (unit != null && unit.trim().isNotEmpty) data['unit'] = unit.trim();
    await _database.ref('rooms/$roomId/sensor_config/$key').update(data);
  }

  Future<void> removeRoomSensorConfig({
    required String roomId,
    required String sensorKey,
  }) async {
    final key = sensorKey.trim().toLowerCase();
    if (key.isEmpty) return;
    if (_uiDemo) return;
    await _database.ref('rooms/$roomId/sensor_config/$key').remove();
  }

  String newAutomationPushId() {
    if (_uiDemo) {
      return 'demo_${DateTime.now().millisecondsSinceEpoch}';
    }
    return _database.ref('automations').push().key ??
        'rule_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<bool> checkConnection() async {
    if (_uiDemo) return true;
    final ref = _database.ref('.info/connected');
    final evt = await ref.onValue.first.timeout(const Duration(seconds: 5));
    return evt.snapshot.value == true;
  }
}

bool deviceStatusFromFirebase(dynamic raw) {
  if (raw == true) return true;
  if (raw == false) return false;
  if (raw is num) return raw != 0;
  if (raw is String) {
    final l = raw.toLowerCase().trim();
    return l == 'true' || l == '1' || l == 'on';
  }
  if (raw is Map) {
    final s = raw['status'] ?? raw['on'] ?? raw['power'] ?? raw['state'];
    if (s is bool) return s;
    if (s is num) return s != 0;
    if (s is String) {
      final l = s.toLowerCase().trim();
      return l == 'true' || l == '1' || l == 'on';
    }
  }
  return false;
}
