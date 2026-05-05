import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/device_catalog.dart';
import '../providers/firebase_providers.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_device_tile.dart';
import '../widgets/connection_status_bar.dart';
import '../navigation/shell_navigation_scope.dart';
import '../widgets/voice_dialog.dart';

/// Home tab: sensors, hub status, shortcuts (đèn/quạt), microphone command.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({
    super.key,

    /// When false (inside [ShellScreen]), skips nested scaffold/chrome.
    this.showAppChrome = true,
  });

  final bool showAppChrome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.watch(firebaseServiceProvider);
    final user = svc.isUiDemoMode
        ? null
        : FirebaseAuth.instance.currentUser;
    final quickDevices = DeviceCatalog.defaultTiles()
        .where((d) => d.id == 'light1' || d.id == 'fan')
        .toList();

    final body = CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const ConnectionStatusBar(),
              const SizedBox(height: 20),
              StreamBuilder<Map<String, dynamic>>(
                stream: svc.listenToSensors(),
                builder: (_, snap) {
                  final data = snap.data ?? {};
                  final tmp = data['temperature'];
                  final hum = data['humidity'];
                  final tStr = tmp == null ? '--' : formatSensorNum(tmp);
                  final hStr = hum == null ? '--' : formatSensorNum(hum);
                  return Row(
                    children: [
                      Expanded(
                        child: _SensorGlowCard(
                          label: 'Nhiệt độ',
                          unit: '°C',
                          valueText: tStr,
                          accent: AppTheme.warm,
                          icon: Icons.thermostat_rounded,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _SensorGlowCard(
                          label: 'Độ ẩm',
                          unit: '%',
                          valueText: hStr,
                          accent: AppTheme.cool,
                          icon: Icons.water_drop_rounded,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Điều khiển nhanh',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      ShellNavigationScope.maybeOf(context)?.goToRoomsTab();
                    },
                    icon: const Icon(Icons.tune_rounded, size: 18),
                    label: const Text('Tất cả'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              StreamBuilder<Map<String, dynamic>>(
                stream: svc.listenToDevices(),
                builder: (_, snap) {
                  final devices = snap.data ?? {};
                  return Column(
                    children: [
                      for (final meta in quickDevices)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AnimatedDeviceTile(
                            dense: true,
                            meta: meta,
                            isOn: deviceStatusFromFirebase(devices[meta.id]),
                            onToggle: (v) => svc.toggleDevice(meta.id, v),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              const Text(
                'Voice command → Firebase',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Ghi vào voice_command (+ voice_commands/pending); Pi NLP xử lý.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: VoiceCommandPanel(
                  onOpenDialog: () => VoiceDialog.show(context),
                ),
              ),
              StreamBuilder<String?>(
                stream: svc.listenVoiceLastResult(),
                builder: (_, rs) {
                  final t = rs.data;
                  if (t == null || t.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.outline),
                          color: AppTheme.bgCard,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.subtitles_rounded,
                                color: AppTheme.accent,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Kết quả từ Hub (voice_result)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                    ),
                                    Text(t),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ]),
          ),
        ),
      ],
    );

    if (showAppChrome) {
      return Scaffold(
        appBar: AppBar(
          title: Text(user?.email ?? 'Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: () async {
                await svc.signOut();
              },
            ),
          ],
        ),
        body: body,
      );
    }

    return body;
  }

  static String formatSensorNum(dynamic v) {
    if (v is num) return v.toStringAsFixed(v % 1 == 0 ? 0 : 1);
    return v.toString();
  }
}

class _SensorGlowCard extends StatelessWidget {
  const _SensorGlowCard({
    required this.label,
    required this.unit,
    required this.valueText,
    required this.accent,
    required this.icon,
  });

  final String label;
  final String unit;
  final String valueText;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        // Wide rows (laptop/web) used to force huge height via AspectRatio; cap
        // height so cards stay compact and aligned.
        final h = (c.maxWidth / 1.42).clamp(108.0, 142.0);
        return SizedBox(
          height: h,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppTheme.outline),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.bgCard,
                  AppTheme.bgCard.withBlue(40).withGreen(52),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: accent.withValues(alpha: 0.15),
                        ),
                        child: Icon(icon, color: accent, size: 22),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: accent.withValues(alpha: 0.12),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          unit,
                          style: TextStyle(
                            fontSize: 11,
                            color: accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          valueText == '--' ? '--' : '$valueText$unit',
                          style: TextStyle(
                            fontSize: h >= 130 ? 28 : 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class VoiceCommandPanel extends StatelessWidget {
  const VoiceCommandPanel({super.key, required this.onOpenDialog});

  final VoidCallback onOpenDialog;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpenDialog,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: MediaQuery.of(context).size.width * 0.42,
        height: MediaQuery.of(context).size.width * 0.42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF2DD4BF), Color(0xFF0891B2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withValues(alpha: 0.38),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic_rounded, size: 48, color: Colors.white),
            SizedBox(height: 8),
            Text(
              'Chạm để ra lệnh',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}