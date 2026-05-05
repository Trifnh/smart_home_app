import 'package:flutter_riverpod/legacy.dart';

import '../services/mqtt_edge_service.dart';

final mqttEdgeServiceProvider = ChangeNotifierProvider<MqttEdgeService>((ref) {
  return MqttEdgeService.instance;
});

