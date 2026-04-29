import 'arrow_model.dart';

/// Chapter a level belongs to (drives the visual theme).
enum GameChapter { softTactile, neonDark, goldElite }

/// Difficulty label for UI display.
enum Difficulty { easy, medium, hard }

/// Immutable model for a single puzzle level.
class LevelModel {
  final int id;
  final String name;
  final int rows;
  final int cols;
  final List<ArrowModel> arrows;
  final Difficulty difficulty;

  /// Par moves for a 3-star rating.
  final int targetMoves;

  const LevelModel({
    required this.id,
    required this.name,
    required this.rows,
    required this.cols,
    required this.arrows,
    required this.difficulty,
    this.targetMoves = 999,
  });

  // ── Chapter ───────────────────────────────────────────────────────────────

  GameChapter get chapter {
    if (id <= 10) return GameChapter.softTactile;
    if (id <= 30) return GameChapter.neonDark;
    return GameChapter.goldElite;
  }

  String get chapterLabel {
    switch (chapter) {
      case GameChapter.softTactile: return 'Chapter I';
      case GameChapter.neonDark:    return 'Chapter II';
      case GameChapter.goldElite:   return 'Chapter III';
    }
  }

  String get difficultyLabel {
    switch (difficulty) {
      case Difficulty.easy:   return 'Easy';
      case Difficulty.medium: return 'Medium';
      case Difficulty.hard:   return 'Hard';
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Playable arrows only (excludes blockers).
  List<ArrowModel> get playableArrows => arrows.where((a) => !a.isBlocker).toList();

  /// Deep-copy arrows for a fresh game session.
  List<ArrowModel> get freshArrows => arrows.map((a) => a.copyWith()).toList();

  /// Star rating based on move count.
  int starRating(int moveCount) {
    if (moveCount <= targetMoves) return 3;
    if (moveCount <= (targetMoves * 1.5).ceil()) return 2;
    return 1;
  }
}
