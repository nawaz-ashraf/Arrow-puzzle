import 'arrow_model.dart';

/// Chapter a level belongs to (drives the visual theme).
enum GameChapter { beginner, easy, medium, hard, expert }

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

  // ── Chapter (5-stage progression) ─────────────────────────────────────────

  GameChapter get chapter {
    if (id <= 10) return GameChapter.beginner;
    if (id <= 25) return GameChapter.easy;
    if (id <= 50) return GameChapter.medium;
    if (id <= 100) return GameChapter.hard;
    return GameChapter.expert;
  }

  String get chapterLabel {
    switch (chapter) {
      case GameChapter.beginner: return 'Chapter I';
      case GameChapter.easy:     return 'Chapter II';
      case GameChapter.medium:   return 'Chapter III';
      case GameChapter.hard:     return 'Chapter IV';
      case GameChapter.expert:   return 'Chapter V';
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
