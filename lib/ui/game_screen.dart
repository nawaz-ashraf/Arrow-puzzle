import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../engine/game_controller.dart';
import '../models/level_model.dart';
import '../ui/app_theme.dart';
import 'widgets/grid_widget.dart';
import 'widgets/hud_widget.dart';

/// Main gameplay screen — pushed on top of [HomeShell].
class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, controller, _) {
        final cs = controller.colorScheme;

        return Scaffold(
          backgroundColor: cs.background,
          body: SafeArea(
            child: Stack(
              children: [
                // Background gradient
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [cs.background, cs.backgroundAlt],
                      ),
                    ),
                  ),
                ),

                // Main content
                Column(
                  children: [
                    _TopBar(controller: controller, cs: cs),
                    const SizedBox(height: 4),
                    _LevelBanner(controller: controller, cs: cs),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: GridWidget(controller: controller),
                        ),
                      ),
                    ),
                    HudWidget(controller: controller),
                    const SizedBox(height: 8),
                  ],
                ),

                // Level complete overlay
                if (controller.status == GameStatus.levelComplete)
                  _LevelCompleteOverlay(controller: controller, cs: cs),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Top bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final GameController controller;
  final AppColorScheme cs;
  const _TopBar({required this.controller, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _IconBtn(
            icon: Icons.arrow_back_ios_rounded,
            cs: cs,
            onTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: Center(
              child: Text(
                'ARROW ESCAPE',
                style: TextStyle(
                  color: cs.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                ),
              ),
            ),
          ),
          _IconBtn(
            icon: controller.soundEnabled
                ? Icons.volume_up_rounded
                : Icons.volume_off_rounded,
            cs: cs,
            onTap: controller.toggleSound,
          ),
        ],
      ),
    );
  }
}

// ── Level banner ──────────────────────────────────────────────────────────────

class _LevelBanner extends StatelessWidget {
  final GameController controller;
  final AppColorScheme cs;
  const _LevelBanner({required this.controller, required this.cs});

  Color _diffColor(Difficulty d) {
    switch (d) {
      case Difficulty.easy:
        return cs.successColor;
      case Difficulty.medium:
        return cs.warningColor;
      case Difficulty.hard:
        return cs.errorColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = controller.currentLevel;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Badge('LVL ${level.id}', cs.primary, cs),
        const SizedBox(width: 8),
        _Badge(level.name, cs.textSecondary, cs),
        const SizedBox(width: 8),
        _Badge(
          level.difficultyLabel.toUpperCase(),
          _diffColor(level.difficulty),
          cs,
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final AppColorScheme cs;
  const _Badge(this.label, this.color, this.cs);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final AppColorScheme cs;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.cs, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.border),
        ),
        child: Icon(icon, color: cs.textPrimary, size: 20),
      ),
    );
  }
}

// ── Level Complete overlay ────────────────────────────────────────────────────

class _LevelCompleteOverlay extends StatefulWidget {
  final GameController controller;
  final AppColorScheme cs;
  const _LevelCompleteOverlay({required this.controller, required this.cs});

  @override
  State<_LevelCompleteOverlay> createState() => _LevelCompleteOverlayState();
}

class _LevelCompleteOverlayState extends State<_LevelCompleteOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ac;
  late Animation<double> _scale, _fade;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scale = CurvedAnimation(parent: _ac, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ac, curve: Curves.easeIn);
    _ac.forward();
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    final stars = widget.controller.currentStarRating;
    final moves = widget.controller.moveCount;
    final target = widget.controller.targetMoves;

    return FadeTransition(
      opacity: _fade,
      child: Container(
        color: Colors.black.withValues(alpha: 0.65),
        child: Center(
          child: ScaleTransition(
            scale: _scale,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 28),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: cs.accent.withValues(alpha: 0.50),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: cs.accent.withValues(alpha: 0.22),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    stars == 3 ? '🏆' : (stars == 2 ? '🎉' : '✅'),
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'LEVEL CLEARED!',
                    style: TextStyle(
                      color: cs.accent,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          i < stars
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: i < stars ? cs.accent : cs.textSecondary,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$moves moves · target $target',
                    style: TextStyle(color: cs.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _OvBtn(
                        'Retry',
                        Icons.replay_rounded,
                        cs.textSecondary,
                        cs,
                        widget.controller.restartLevel,
                      ),
                      const SizedBox(width: 12),
                      _OvBtn(
                        'Next',
                        Icons.arrow_forward_rounded,
                        cs.accent,
                        cs,
                        () {
                          widget.controller.nextLevel();
                          // Stay on GameScreen — level reloads in place.
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OvBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final AppColorScheme cs;
  final VoidCallback onTap;
  const _OvBtn(this.label, this.icon, this.color, this.cs, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.40)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 17),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
