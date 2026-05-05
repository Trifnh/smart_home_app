import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/automation_rule.dart';
import '../services/firebase_service.dart';

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService.instance;
});

/// Raw RTDB maps
final sensorsMapProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final svc = ref.watch(firebaseServiceProvider);
  return svc.listenToSensors();
});

final devicesMapProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final svc = ref.watch(firebaseServiceProvider);
  return svc.listenToDevices();
});

final hubHealthProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final svc = ref.watch(firebaseServiceProvider);
  return svc.listenHubHealth();
});

final firebaseConnectedProvider = StreamProvider<bool>((ref) {
  final svc = ref.watch(firebaseServiceProvider);
  return svc.listenFirebaseConnected();
});

final automationsProvider = StreamProvider<Map<String, AutomationRule>>((ref) {
  final svc = ref.watch(firebaseServiceProvider);
  return svc.listenAutomations();
});

final automationSensorConfigProvider =
    StreamProvider<Map<String, dynamic>>((ref) {
  final svc = ref.watch(firebaseServiceProvider);
  return svc.listenAutomationSensorConfig();
});

final voiceLastResultProvider = StreamProvider<String?>((ref) {
  final svc = ref.watch(firebaseServiceProvider);
  return svc.listenVoiceLastResult();
});

final roomsMapProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final svc = ref.watch(firebaseServiceProvider);
  return svc.listenToRooms();
});

