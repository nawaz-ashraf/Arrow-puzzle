import 'package:flutter/material.dart';
import '../../engine/game_controller.dart';
import '../../services/ad_service.dart';
import '../app_theme.dart';

/// HUD — Moves counter, Target counter, Undo/Hint/Restart buttons.
class HudWidget extends StatelessWidget {
  final GameController controller;
  const HudWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = controller.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatTile(
            icon: Icons.touch_app_rounded,
            value: '${controller.moveCount}',
            label: 'Moves',
            valueColor: cs.textPrimary,
            cs: cs,
          ),
          _Div(cs: cs),
          _TargetTile(controller: controller, cs: cs),
          _Div(cs: cs),
          _ActionBtn(
              icon: Icons.undo_rounded, label: 'Undo',
              enabled: controller.canUndo, onTap: controller.undo, cs: cs),
          _Div(cs: cs),
          _HintBtn(controller: controller, cs: cs),
          _Div(cs: cs),
          _ActionBtn(
              icon: Icons.replay_rounded, label: 'Restart',
              enabled: true, onTap: controller.restartLevel, cs: cs),
        ],
      ),
    );
  }
}

// ── Hint button with free-hint count badge ──────────────────────────────────

class _HintBtn extends StatelessWidget {
  final GameController controller;
  final AppColorScheme cs;
  const _HintBtn({required this.controller, required this.cs});

  void _onTap(BuildContext context) {
    final success = controller.showHint();
    if (!success) {
      // No free hints → offer rewarded ad
      _showRewardedAdDialog(context);
    }
  }

  void _showRewardedAdDialog(BuildContext context) {
    final cs = controller.colorScheme;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Need a Hint?',
            style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800)),
        content: Text(
          'Watch a short video to earn a free hint!',
          style: TextStyle(color: cs.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: cs.textSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              AdService.instance.showRewardedAd(
                onReward: () => controller.grantHintFromAd(),
                onAdNotReady: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Ad not ready yet. Try again shortly.'),
                      backgroundColor: cs.errorColor,
                    ),
                  );
                },
              );
            },
            icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
            label: const Text('Watch Ad'),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabled = controller.status == GameStatus.playing;
    final c = enabled ? cs.textPrimary : cs.textSecondary;
    final hints = controller.freeHints;

    return GestureDetector(
      onTap: enabled ? () => _onTap(context) : null,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.lightbulb_outline_rounded, color: c, size: 22),
            if (hints > 0)
              Positioned(
                right: -8,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: cs.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Text('$hints',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        Text('Hint', style: TextStyle(color: c, fontSize: 10)),
      ]),
    );
  }
}

class _TargetTile extends StatelessWidget {
  final GameController controller;
  final AppColorScheme cs;
  const _TargetTile({required this.controller, required this.cs});

  Color _color() {
    final m = controller.moveCount, t = controller.targetMoves;
    if (m == 0) return cs.textSecondary;
    if (m <= t) return cs.successColor;
    if (m <= (t * 1.5).ceil()) return cs.warningColor;
    return cs.errorColor;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        Icon(Icons.star_rounded, color: color, size: 14),
        const SizedBox(width: 3),
        Text('${controller.moveCount}/${controller.targetMoves}',
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800)),
      ]),
      Text('Target', style: TextStyle(color: cs.textSecondary, fontSize: 10)),
    ]);
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color valueColor;
  final AppColorScheme cs;
  const _StatTile({required this.icon, required this.value, required this.label,
      required this.valueColor, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        Icon(icon, color: cs.primary, size: 14),
        const SizedBox(width: 3),
        Text(value,
            style: TextStyle(color: valueColor, fontSize: 14, fontWeight: FontWeight.w800)),
      ]),
      Text(label, style: TextStyle(color: cs.textSecondary, fontSize: 10)),
    ]);
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final AppColorScheme cs;
  const _ActionBtn({required this.icon, required this.label, required this.enabled,
      required this.onTap, required this.cs});

  @override
  Widget build(BuildContext context) {
    final c = enabled ? cs.textPrimary : cs.textSecondary;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: c, size: 22),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: c, fontSize: 10)),
      ]),
    );
  }
}

class _Div extends StatelessWidget {
  final AppColorScheme cs;
  const _Div({required this.cs});
  @override
  Widget build(BuildContext context) =>
      Container(height: 28, width: 1, color: cs.border);
}
