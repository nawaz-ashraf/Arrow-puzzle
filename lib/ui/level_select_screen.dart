import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../engine/game_controller.dart';
import '../models/level_model.dart';
import '../ui/app_theme.dart';

/// Level selection screen — grouped by chapter with star ratings.
class LevelSelectScreen extends StatelessWidget {
  /// Called with the chosen level ID so HomeShell can navigate to GameScreen.
  final void Function(int levelId) onLevelSelected;

  const LevelSelectScreen({super.key, required this.onLevelSelected});

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
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Select Level',
                          style: TextStyle(
                            color: cs.primary,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          )),
                      const SizedBox(height: 4),
                      Text(
                        'Level ${controller.highestUnlocked} reached',
                        style: TextStyle(
                            color: cs.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildLevelList(context, controller, cs),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLevelList(
      BuildContext context, GameController controller, AppColorScheme cs) {
    final levels = controller.allLevels;
    final groups = <GameChapter, List<LevelModel>>{};
    for (final l in levels) {
      groups.putIfAbsent(l.chapter, () => []).add(l);
    }

    return ListView(
      children: [
        for (final chapter in GameChapter.values)
          if (groups.containsKey(chapter)) ...[
            _ChapterHeader(chapter: chapter),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.88,
              ),
              itemCount: groups[chapter]!.length,
              itemBuilder: (ctx, i) {
                final level = groups[chapter]![i];
                final unlocked = level.id <= controller.highestUnlocked;
                final stars = controller.bestStars(level.id);
                return _LevelCard(
                  level: level,
                  unlocked: unlocked,
                  stars: stars,
                  isCurrent: controller.currentLevel.id == level.id,
                  onTap: unlocked ? () => onLevelSelected(level.id) : null,
                );
              },
            ),
          ],
        const SizedBox(height: 80), // bottom nav clearance
      ],
    );
  }
}

// ── Chapter header ───────────────────────────────────────────────────────────

class _ChapterHeader extends StatelessWidget {
  final GameChapter chapter;
  const _ChapterHeader({required this.chapter});

  (String, IconData, String) get _meta {
    switch (chapter) {
      case GameChapter.softTactile:
        return ('Chapter I · Soft Tactile', Icons.wb_sunny_rounded, '4×4');
      case GameChapter.neonDark:
        return ('Chapter II · Neon Dark', Icons.bolt_rounded, '5×5');
      case GameChapter.goldElite:
        return ('Chapter III · Gold Elite', Icons.auto_awesome_rounded, '6×6');
    }
  }

  AppColorScheme get _cs => AppTheme.forChapter(chapter);

  @override
  Widget build(BuildContext context) {
    final cs = _cs;
    final (label, icon, badge) = _meta;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary.withValues(alpha: 0.18),
            cs.accent.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: cs.accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: TextStyle(
                  color: cs.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                )),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.primary.withValues(alpha: 0.30)),
            ),
            child: Text(badge,
                style: TextStyle(
                    color: cs.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Level card ───────────────────────────────────────────────────────────────

class _LevelCard extends StatelessWidget {
  final LevelModel level;
  final bool unlocked;
  final int stars;
  final bool isCurrent;
  final VoidCallback? onTap;

  const _LevelCard({
    required this.level,
    required this.unlocked,
    required this.stars,
    required this.isCurrent,
    required this.onTap,
  });

  AppColorScheme get _cs => AppTheme.forChapter(level.chapter);

  Color get _diffColor {
    final cs = _cs;
    switch (level.difficulty) {
      case Difficulty.easy:   return cs.successColor;
      case Difficulty.medium: return cs.warningColor;
      case Difficulty.hard:   return cs.errorColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = _cs;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCurrent
                ? cs.accent
                : unlocked
                    ? cs.primary.withValues(alpha: 0.30)
                    : cs.border,
            width: isCurrent ? 2.0 : 1.5,
          ),
          boxShadow: unlocked
              ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.07),
                    blurRadius: 8,
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${level.id}',
                style: TextStyle(
                  color: unlocked ? cs.primary : cs.textSecondary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                )),
            const SizedBox(height: 4),
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: unlocked ? _diffColor : cs.textSecondary,
              ),
            ),
            if (unlocked && stars > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (i) => Icon(
                    i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: i < stars ? cs.accent : cs.textSecondary,
                    size: 9,
                  ),
                ),
              ),
            ],
            if (!unlocked) ...[
              const SizedBox(height: 4),
              Icon(Icons.lock_rounded, color: cs.textSecondary, size: 13),
            ],
          ],
        ),
      ),
    );
  }
}
