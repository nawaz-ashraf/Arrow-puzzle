import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../engine/game_controller.dart';
import '../app_theme.dart';

/// Settings screen with sound toggle and progress reset.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, controller, _) {
        final cs = controller.colorScheme;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [cs.background, cs.backgroundAlt],
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Settings',
                          style: TextStyle(
                            color: cs.primary,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          )),
                      const SizedBox(height: 4),
                      Text('Customise your experience',
                          style: TextStyle(
                              color: cs.textSecondary, fontSize: 14)),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── Settings cards ────────────────────────────────────────
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      // Sound section
                      _SectionHeader(title: 'Audio', cs: cs),
                      _SettingTile(
                        icon: controller.soundEnabled
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        title: 'Sound Effects',
                        subtitle: controller.soundEnabled ? 'On' : 'Off',
                        cs: cs,
                        trailing: Switch(
                          value: controller.soundEnabled,
                          onChanged: (_) => controller.toggleSound(),
                          activeThumbColor: cs.accent,
                          inactiveThumbColor: cs.textSecondary,
                          inactiveTrackColor: cs.border,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Progress section
                      _SectionHeader(title: 'Progress', cs: cs),
                      _SettingTile(
                        icon: Icons.emoji_events_rounded,
                        title: 'Highest Level',
                        subtitle: 'Level ${controller.highestUnlocked}',
                        cs: cs,
                      ),
                      const SizedBox(height: 8),
                      _SettingTile(
                        icon: Icons.delete_outline_rounded,
                        title: 'Reset Progress',
                        subtitle: 'Clear all stars and level progress',
                        cs: cs,
                        iconColor: cs.errorColor,
                        titleColor: cs.errorColor,
                        onTap: () => _confirmReset(context, controller, cs),
                      ),

                      const SizedBox(height: 24),

                      // About section
                      _SectionHeader(title: 'About', cs: cs),
                      _SettingTile(
                        icon: Icons.info_outline_rounded,
                        title: 'Arrow Escape',
                        subtitle: 'Version 1.0 · Grid Puzzle Game',
                        cs: cs,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmReset(
      BuildContext context, GameController controller, AppColorScheme cs) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Reset Progress?',
            style: TextStyle(
                color: cs.textPrimary, fontWeight: FontWeight.w700)),
        content: Text(
          'This will clear all your stars and unlock states. This cannot be undone.',
          style: TextStyle(color: cs.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: cs.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.resetProgress();
            },
            child: Text('Reset',
                style: TextStyle(
                    color: cs.errorColor, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final AppColorScheme cs;
  const _SectionHeader({required this.title, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: cs.primary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final AppColorScheme cs;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.cs,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (iconColor ?? cs.primary).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor ?? cs.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        color: titleColor ?? cs.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      )),
                  Text(subtitle,
                      style: TextStyle(
                          color: cs.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (onTap != null && trailing == null)
              Icon(Icons.chevron_right_rounded,
                  color: cs.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
