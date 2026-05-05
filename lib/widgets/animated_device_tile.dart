import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class DeviceUi {
  const DeviceUi(this.id, this.title, this.icon, this.subtitle);

  final String id;
  final String title;
  final IconData icon;
  final String subtitle;
}

class AnimatedDeviceTile extends StatelessWidget {
  const AnimatedDeviceTile({
    super.key,
    required this.meta,
    required this.isOn,
    required this.onToggle,
    this.dense = false,
  });

  final DeviceUi meta;
  final bool isOn;
  final ValueChanged<bool> onToggle;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onToggle(!isOn),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.all(dense ? 14 : 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isOn
                ? [AppTheme.accent.withValues(alpha: 0.18), AppTheme.bgCard]
                : [AppTheme.bgCard, AppTheme.bgCard],
          ),
          border: Border.all(
            color: isOn
                ? AppTheme.accent.withValues(alpha: 0.42)
                : AppTheme.outline,
            width: 1,
          ),
          boxShadow: isOn
              ? [
                  BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              padding: EdgeInsets.all(dense ? 10 : 14),
              decoration: BoxDecoration(
                color: isOn
                    ? AppTheme.accent.withValues(alpha: 0.2)
                    : AppTheme.bgElevated,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                meta.icon,
                color: isOn ? AppTheme.accent : const Color(0xFF64748B),
                size: dense ? 26 : 30,
              ),
            ),
            SizedBox(width: dense ? 12 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meta.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meta.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isOn ? 'BẬT' : 'TẮT',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1,
                    color: isOn ? AppTheme.accent : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  child: Switch.adaptive(
                    value: isOn,
                    activeThumbColor: AppTheme.accent,
                    activeTrackColor: AppTheme.accent.withValues(alpha: 0.35),
                    onChanged: onToggle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
