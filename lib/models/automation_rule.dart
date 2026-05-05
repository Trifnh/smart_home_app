class AutomationRule {
  const AutomationRule({
    required this.id,
    required this.name,
    required this.enabled,
    required this.sensorKey,
    required this.operator,
    required this.threshold,
    required this.deviceId,
    required this.targetOn,
  });

  final String id;
  final String name;
  final bool enabled;
  final String sensorKey;
  final String operator;
  final double threshold;
  final String deviceId;
  final bool targetOn;

  factory AutomationRule.fromMap(String id, Map<dynamic, dynamic> raw) {
    bool readBool(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      return false;
    }

    double readDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    return AutomationRule(
      id: id,
      name: raw['name']?.toString() ?? 'Rule',
      enabled: readBool(raw['enabled']),
      sensorKey: raw['sensor']?.toString() ?? 'temperature',
      operator: raw['operator']?.toString() ?? 'gt',
      threshold: readDouble(raw['threshold']),
      deviceId: raw['deviceId']?.toString() ?? 'fan',
      targetOn: readBool(raw['targetOn'] ?? raw['turnOn']),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'enabled': enabled,
    'sensor': sensorKey,
    'operator': operator,
    'threshold': threshold,
    'deviceId': deviceId,
    'targetOn': targetOn,
  };
}
