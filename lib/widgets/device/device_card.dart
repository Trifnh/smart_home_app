import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/firebase_providers.dart';
import '../../theme/app_theme.dart';

class DeviceCard extends ConsumerWidget {
  const DeviceCard({
    super.key,
    required this.deviceId,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isOn,
    this.showSubtitle = true,
    this.dense = false,
  });

  final String deviceId;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isOn;
  final bool showSubtitle;
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardWidth = MediaQuery.sizeOf(context).width;
    final compactMobile = cardWidth <= 430 || dense;
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;
    final bg = Theme.of(context).cardTheme.color ?? scheme.surface;

    final borderColor = isOn
        ? primary.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.42 : 0.30)
        : Theme.of(context).dividerColor.withValues(alpha: 0.75);

    final glow = isOn
        ? [
            BoxShadow(
              color: primary.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.16 : 0.10),
              blurRadius: 24,
              offset: const Offset(0, 16),
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.22 : 0.04),
              blurRadius: 18,
              offset: const Offset(0, 14),
            ),
          ];

    return GestureDetector(
      onTap: () => _toggle(ref, !isOn),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppTheme.r24),
          border: Border.all(color: borderColor),
          boxShadow: glow,
        ),
        padding: EdgeInsets.all(compactMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  width: compactMobile ? 38 : 46,
                  height: compactMobile ? 38 : 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: isOn
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              primary.withValues(alpha: 0.92),
                              AppTheme.accentDim.withValues(alpha: 0.92),
                            ],
                          )
                        : null,
                    color: isOn
                        ? null
                        : Theme.of(context).dividerColor.withValues(alpha: 0.10),
                  ),
                  child: Icon(
                    icon,
                    color: isOn
                        ? Colors.white
                        : scheme.onSurface.withValues(alpha: 0.62),
                  ),
                ),
                const Spacer(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Container(
                    key: ValueKey(isOn),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: (isOn ? primary : scheme.onSurface)
                          .withValues(alpha: isOn ? 0.12 : 0.06),
                      border: Border.all(
                        color: (isOn ? primary : scheme.onSurface)
                            .withValues(alpha: isOn ? 0.22 : 0.12),
                      ),
                    ),
                    child: Text(
                      isOn ? 'ON' : 'OFF',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: isOn
                                ? primary
                                : scheme.onSurface.withValues(alpha: 0.55),
                          ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: compactMobile ? 8 : 12),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
            ),
            if (showSubtitle) ...[
              const SizedBox(height: 6),
              Text(
                subtitle,
                maxLines: compactMobile ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.60),
                      height: 1.25,
                    ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    isOn ? 'Running' : 'Standby',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface.withValues(alpha: 0.72),
                        ),
                  ),
                ),
                Transform.scale(
                  scale: compactMobile ? 0.82 : 0.92,
                  child: Switch.adaptive(
                    value: isOn,
                    activeThumbColor: primary,
                    activeTrackColor: primary.withValues(alpha: 0.35),
                    onChanged: (v) => _toggle(ref, v),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _toggle(WidgetRef ref, bool v) {
    final svc = ref.read(firebaseServiceProvider);
    svc.toggleDevice(deviceId, v);
  }
}

