import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/device_catalog.dart';
import '../models/automation_rule.dart';
import '../providers/firebase_providers.dart';
import '../theme/app_theme.dart';

/// Rule templates for demo + Pi interpreter: IF sensor op threshold THEN device on/off.
class AutomationScreen extends ConsumerStatefulWidget {
  const AutomationScreen({super.key});

  @override
  ConsumerState<AutomationScreen> createState() => _AutomationScreenState();
}

class _AutomationScreenState extends ConsumerState<AutomationScreen> {
  static const _ops = [
    ('gt', '>'),
    ('gte', '≥'),
    ('lt', '<'),
    ('lte', '≤'),
    ('eq', '='),
  ];

  static const _sensorPresets = <({String key, String label, String unit})>[
    (key: 'temperature', label: 'Nhiệt độ', unit: '°C'),
    (key: 'humidity', label: 'Độ ẩm', unit: '%'),
    (key: 'pm25', label: 'PM2.5', unit: 'µg/m³'),
    (key: 'air_quality', label: 'Chất lượng không khí', unit: 'AQI'),
    (key: 'lux', label: 'Ánh sáng', unit: 'lux'),
    (key: 'rain', label: 'Mưa', unit: ''),
    (key: 'presence', label: 'Hiện diện', unit: ''),
    (key: 'door', label: 'Cửa', unit: ''),
    (key: 'gas', label: 'Gas', unit: ''),
    (key: 'smoke', label: 'Khói', unit: ''),
  ];

  Future<void> _openEditor([AutomationRule? existing]) async {
    final svc = ref.read(firebaseServiceProvider);
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final thCtrl = TextEditingController(
      text: existing != null ? '${existing.threshold}' : '30',
    );
    var sensor = existing?.sensorKey ?? 'temperature';
    var op = existing?.operator ?? 'gt';
    var deviceId = existing?.deviceId ?? 'fan';
    var targetOn = existing?.targetOn ?? true;
    var enabled = existing?.enabled ?? true;
    final sensorChoices = _automationSensorChoices(
      ref.read(automationSensorConfigProvider).asData?.value,
      ref.read(sensorsMapProvider).asData?.value,
    );
    if (sensorChoices.isNotEmpty && !sensorChoices.contains(sensor)) {
      sensor = sensorChoices.first;
    }
    final devicesRaw = ref.read(devicesMapProvider).asData?.value ?? const <String, dynamic>{};
    final deviceChoices = <String>{
      ...DeviceCatalog.ids,
      ...devicesRaw.keys.map((k) => k.toString()),
    }.toList()
      ..sort();
    if (existing != null && !deviceChoices.contains(existing.deviceId)) {
      deviceChoices.add(existing.deviceId);
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 22,
            right: 22,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setSheet) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Điều kiện tự động',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Switch.adaptive(
                          value: enabled,
                          onChanged: (v) => setSheet(() => enabled = v),
                        ),
                      ],
                    ),
                    Text(
                      'Firebase: automations/{{id}}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tên rule (demo)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sensor',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownMenu<String>(
                      key: ValueKey('sensor-$sensor'),
                      initialSelection: sensor,
                      width: MediaQuery.sizeOf(context).width - 44,
                      dropdownMenuEntries: [
                        for (final k in sensorChoices)
                          DropdownMenuEntry(
                            value: k,
                            label: _sensorLabelFromConfigOrPreset(
                              k,
                              ref.read(automationSensorConfigProvider).asData?.value,
                            ),
                          ),
                      ],
                      onSelected: (v) =>
                          setSheet(() => sensor = v ?? 'temperature'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Điều kiện',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.65),
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownMenu<String>(
                                key: ValueKey('op-$op'),
                                initialSelection: op,
                                width: double.infinity,
                                dropdownMenuEntries: [
                                  for (final o in _ops)
                                    DropdownMenuEntry(value: o.$1, label: o.$2),
                                ],
                                onSelected: (v) =>
                                    setSheet(() => op = v ?? 'gt'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: thCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]'),
                              ),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Ngưỡng',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Thiết bị đích',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownMenu<String>(
                      key: ValueKey('dev-$deviceId'),
                      initialSelection: deviceId,
                      width: MediaQuery.sizeOf(context).width - 44,
                      dropdownMenuEntries: [
                        for (final id in deviceChoices)
                          DropdownMenuEntry(
                            value: id,
                            label: _deviceLabel(id, devicesRaw),
                          ),
                      ],
                      onSelected: (v) => setSheet(() => deviceId = v ?? 'fan'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Hành động',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: true, label: Text('Bật thiết bị')),
                        ButtonSegment(
                          value: false,
                          label: Text('Tắt thiết bị'),
                        ),
                      ],
                      emptySelectionAllowed: false,
                      selected: {targetOn},
                      onSelectionChanged: (s) {
                        final v = s.isEmpty ? true : s.first;
                        setSheet(() => targetOn = v);
                      },
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          final tid = existing?.id ?? svc.newAutomationPushId();
                          final th = double.tryParse(thCtrl.text.trim()) ?? 0;
                          final rule = AutomationRule(
                            id: tid,
                            name: nameCtrl.text.trim().isEmpty
                                ? 'Untitled rule'
                                : nameCtrl.text.trim(),
                            enabled: enabled,
                            sensorKey: sensor,
                            operator: op,
                            threshold: th,
                            deviceId: deviceId,
                            targetOn: targetOn,
                          );
                          Navigator.pop(context);
                          await svc.saveAutomationRule(rule);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã lưu rule lên Firebase'),
                            ),
                          );
                        },
                        child: Text(
                          existing == null ? 'Thêm rule' : 'Cập nhật',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    nameCtrl.dispose();
    thCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final svc = ref.watch(firebaseServiceProvider);
    final autoCfg =
        ref.watch(automationSensorConfigProvider).asData?.value ?? const <String, dynamic>{};
    final enabledSensors = _automationEnabledSensors(autoCfg);

    return Stack(
      children: [
        StreamBuilder<Map<String, AutomationRule>>(
          stream: svc.listenAutomations(),
          builder: (context, snap) {
            final rules = snap.data?.entries.toList() ?? [];
            rules.sort((a, b) => a.key.compareTo(b.key));

            if (rules.isEmpty) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 108),
                children: [
                  _AutoSensorHeader(
                    enabledSensors: enabledSensors,
                    onManage: () => _openAutomationSensorManager(autoCfg),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_fix_high_rounded,
                            size: 56,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.25),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Chưa có rule',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'VD: IF nhiệt độ > 30°C THEN bật quạt',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 108),
              itemCount: rules.length + 1,
              separatorBuilder: (_, unused) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                if (i == 0) {
                  return _AutoSensorHeader(
                    enabledSensors: enabledSensors,
                    onManage: () => _openAutomationSensorManager(autoCfg),
                  );
                }
                final r = rules[i - 1].value;
                final opLabel = _ops
                    .firstWhere(
                      (o) => o.$1 == r.operator,
                      orElse: () => (r.operator, r.operator),
                    )
                    .$2;
                return Dismissible(
                  key: Key(r.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.red.withValues(alpha: 0.3),
                    child: const Icon(Icons.delete_outline),
                  ),
                  confirmDismiss: (_) async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Xoá rule?'),
                        content: Text('${r.name} (${r.id})'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Huỷ'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Xoá'),
                          ),
                        ],
                      ),
                    );
                    return ok == true;
                  },
                  onDismissed: (_) => svc.deleteAutomationRule(r.id),
                  child: Material(
                    color: Theme.of(context).cardTheme.color ??
                        Theme.of(context).colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: Theme.of(context).dividerColor.withValues(alpha: 0.8),
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () async => _openEditor(r),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  r.enabled
                                      ? Icons.play_circle_outline
                                      : Icons.pause_circle_outline,
                                  color: r.enabled
                                      ? AppTheme.accent
                                      : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    r.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Text(
                                  r.enabled ? 'Bật' : 'Tắt',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: r.enabled
                                        ? AppTheme.accent
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'NẾU ${r.sensorKey} $opLabel ${r.threshold} '
                              'THÌ ${r.targetOn ? 'BẬT' : 'TẮT'} ${r.deviceId}',
                              style: TextStyle(
                                height: 1.35,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
        Positioned(
          bottom: 88,
          right: 20,
          child: FloatingActionButton.extended(
            onPressed: () => _openEditor(),
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('+ Rule'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  List<String> _automationEnabledSensors(Map<String, dynamic> cfg) {
    if (cfg.isEmpty) return const ['temperature', 'humidity'];
    final out = <String>[];
    for (final e in cfg.entries) {
      final k = e.key.toString().toLowerCase();
      if (_configEntryEnabled(e.value)) out.add(k);
    }
    out.sort();
    return out;
  }

  List<String> _automationSensorChoices(
    Map<String, dynamic>? cfg,
    Map<String, dynamic>? globalSensors,
  ) {
    final c = cfg ?? const <String, dynamic>{};
    if (c.isNotEmpty) {
      final enabled = _automationEnabledSensors(c);
      return enabled;
    }
    final s = <String>{
      for (final p in _sensorPresets) p.key.toLowerCase(),
      ...?globalSensors?.keys.map((k) => k.toString().toLowerCase()),
      'temperature',
      'humidity',
    };
    final out = s.toList()..sort();
    return out;
  }

  bool _configEntryEnabled(dynamic v) {
    if (v == true) return true;
    if (v is Map) {
      final e = v['enabled'];
      return e == true ||
          e == 1 ||
          (e is String && (e.toLowerCase() == 'true' || e == '1'));
    }
    return false;
  }

  String _sensorLabelFromConfigOrPreset(String key, Map<String, dynamic>? cfg) {
    final k = key.toLowerCase();
    final fromCfg = cfg?[k];
    if (fromCfg is Map) {
      final label = fromCfg['label'];
      if (label is String && label.trim().isNotEmpty) return '${label.trim()} ($k)';
    }
    for (final p in _sensorPresets) {
      if (p.key == k) return '${p.label} ($k)';
    }
    return k;
  }

  String _deviceLabel(String deviceId, Map<String, dynamic> devicesRaw) {
    final id = deviceId.trim();
    final byCatalog = {
      for (final d in DeviceCatalog.defaultTiles()) d.id: d.title,
    }[id];
    if (byCatalog != null) return byCatalog;

    final raw = devicesRaw[id];
    if (raw is Map) {
      final name = raw['name'] ?? raw['title'] ?? raw['label'];
      if (name is String && name.trim().isNotEmpty) return name.trim();
    }
    return id;
  }

  Future<void> _openAutomationSensorManager(Map<String, dynamic> cfg) async {
    final svc = ref.read(firebaseServiceProvider);
    final keyCtrl = TextEditingController();
    final labelCtrl = TextEditingController();
    final unitCtrl = TextEditingController();

    final globalSensors = ref.read(sensorsMapProvider).asData?.value ?? const <String, dynamic>{};
    final known = <String>{
      ...cfg.keys.map((k) => k.toString().toLowerCase()),
      ...globalSensors.keys.map((k) => k.toString().toLowerCase()),
      for (final p in _sensorPresets) p.key.toLowerCase(),
    }.toList()
      ..sort();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 22,
            right: 22,
            top: 18,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setSheet) {
              final liveCfg = ref.read(automationSensorConfigProvider).asData?.value ??
                  Map<String, dynamic>.from(cfg);
              final enabled = _automationEnabledSensors(liveCfg);
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Sensor cho Automation',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const Spacer(),
                        Text(
                          '${enabled.length} bật',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.55),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Bật/tắt key sensor để dropdown “Sensor” trong rule chỉ hiện key được bật.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 14),
                    for (final k in known) ...[
                      _AutoSensorRow(
                        sensorKey: k,
                        label: _sensorLabelFromConfigOrPreset(k, liveCfg),
                        enabled: enabled.contains(k),
                        onToggle: (v) async {
                          await svc.upsertAutomationSensorConfig(
                            sensorKey: k,
                            enabled: v,
                          );
                          setSheet(() {});
                        },
                        onRemove: liveCfg.containsKey(k)
                            ? () async {
                                await svc.removeAutomationSensorConfig(sensorKey: k);
                                setSheet(() {});
                              }
                            : null,
                      ),
                      const SizedBox(height: 8),
                    ],
                    const Divider(height: 28),
                    const Text(
                      'Thêm sensor key mới',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: keyCtrl,
                      decoration: const InputDecoration(
                        labelText: 'sensorKey (vd: co2, soil_moisture)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: labelCtrl,
                            decoration: const InputDecoration(labelText: 'Label (tuỳ chọn)'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 120,
                          child: TextField(
                            controller: unitCtrl,
                            decoration: const InputDecoration(labelText: 'Unit'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () async {
                        final key = keyCtrl.text.trim().toLowerCase();
                        if (key.isEmpty) return;
                        await svc.upsertAutomationSensorConfig(
                          sensorKey: key,
                          enabled: true,
                          label: labelCtrl.text,
                          unit: unitCtrl.text,
                        );
                        keyCtrl.clear();
                        labelCtrl.clear();
                        unitCtrl.clear();
                        setSheet(() {});
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add sensor'),
                      style: FilledButton.styleFrom(backgroundColor: AppTheme.accentDim),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    keyCtrl.dispose();
    labelCtrl.dispose();
    unitCtrl.dispose();
  }
}

class _AutoSensorHeader extends StatelessWidget {
  const _AutoSensorHeader({
    required this.enabledSensors,
    required this.onManage,
  });

  final List<String> enabledSensors;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.8)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sensors_rounded, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Sensor dùng cho rule',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: onManage,
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text('Chỉnh'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final k in enabledSensors)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    k,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              if (enabledSensors.isEmpty)
                Text(
                  'Chưa bật sensor nào',
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.55),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AutoSensorRow extends StatelessWidget {
  const _AutoSensorRow({
    required this.sensorKey,
    required this.label,
    required this.enabled,
    required this.onToggle,
    required this.onRemove,
  });

  final String sensorKey;
  final String label;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                sensorKey,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
        if (onRemove != null)
          IconButton(
            tooltip: 'Remove from config',
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        Switch.adaptive(value: enabled, onChanged: onToggle),
      ],
    );
  }
}
