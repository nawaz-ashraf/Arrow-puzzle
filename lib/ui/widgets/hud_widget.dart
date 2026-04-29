import 'package:flutter/material.dart';
import '../../engine/game_controller.dart';
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
          _ActionBtn(
              icon: Icons.lightbulb_outline_rounded, label: 'Hint',
              enabled: controller.status == GameStatus.playing,
              onTap: controller.showHint, cs: cs),
          _Div(cs: cs),
          _ActionBtn(
              icon: Icons.replay_rounded, label: 'Restart',
              enabled: true, onTap: controller.restartLevel, cs: cs),
        ],
      ),
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
