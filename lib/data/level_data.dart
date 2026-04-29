import '../models/arrow_model.dart';
import '../models/level_model.dart';

/// Hand-crafted levels — no blockers, arrows only.
///
/// **Coordinate convention (top-left corner):**
/// `row, col` = top-left of the arrow's bounding box.
class LevelData {
  LevelData._();

  static final List<LevelModel> levels = [

    // ── CHAPTER I — Soft Tactile (4×4, length=1) ────────────────────────

    LevelModel(
      id: 1, name: 'Warm Up', rows: 4, cols: 4,
      difficulty: Difficulty.easy, targetMoves: 4,
      arrows: [
        _a('1a', 2, 0, ArrowDirection.up),
        _a('1b', 1, 2, ArrowDirection.right),
        _a('1c', 2, 3, ArrowDirection.down),
        _a('1d', 3, 1, ArrowDirection.left),
      ],
    ),

    LevelModel(
      id: 2, name: 'Four Corners', rows: 4, cols: 4,
      difficulty: Difficulty.easy, targetMoves: 4,
      arrows: [
        _a('2a', 1, 0, ArrowDirection.up),
        _a('2b', 0, 2, ArrowDirection.right),
        _a('2c', 2, 3, ArrowDirection.down),
        _a('2d', 3, 1, ArrowDirection.left),
      ],
    ),

    LevelModel(
      id: 3, name: 'Clear the Path', rows: 4, cols: 4,
      difficulty: Difficulty.easy, targetMoves: 3,
      arrows: [
        _a('3a', 1, 1, ArrowDirection.right),
        _a('3b', 1, 2, ArrowDirection.up),
        _a('3c', 2, 1, ArrowDirection.down),
      ],
    ),

    LevelModel(
      id: 4, name: 'Crossroads', rows: 4, cols: 4,
      difficulty: Difficulty.easy, targetMoves: 4,
      arrows: [
        _a('4a', 2, 1, ArrowDirection.up),
        _a('4b', 1, 2, ArrowDirection.right),
        _a('4c', 2, 2, ArrowDirection.down),
        _a('4d', 1, 1, ArrowDirection.left),
      ],
    ),

    LevelModel(
      id: 5, name: 'Long Slide', rows: 4, cols: 4,
      difficulty: Difficulty.medium, targetMoves: 4,
      arrows: [
        _a('5a', 2, 2, ArrowDirection.up),
        _a('5b', 1, 1, ArrowDirection.left),
        _a('5c', 2, 1, ArrowDirection.down),
        _a('5d', 1, 2, ArrowDirection.right),
      ],
    ),

    LevelModel(
      id: 6, name: 'Locked Box', rows: 4, cols: 4,
      difficulty: Difficulty.medium, targetMoves: 4,
      arrows: [
        _a('6a', 0, 1, ArrowDirection.right),
        _a('6b', 1, 2, ArrowDirection.down),
        _a('6c', 2, 2, ArrowDirection.left),
        _a('6d', 2, 1, ArrowDirection.up),
      ],
    ),

    LevelModel(
      id: 7, name: 'Traffic Jam', rows: 4, cols: 4,
      difficulty: Difficulty.medium, targetMoves: 5,
      arrows: [
        _a('7a', 0, 1, ArrowDirection.down),
        _a('7b', 1, 1, ArrowDirection.right),
        _a('7c', 1, 2, ArrowDirection.up),
        _a('7d', 2, 2, ArrowDirection.left),
        _a('7e', 2, 1, ArrowDirection.down),
      ],
    ),

    LevelModel(
      id: 8, name: 'Surround', rows: 4, cols: 4,
      difficulty: Difficulty.hard, targetMoves: 6,
      arrows: [
        _a('8a', 1, 1, ArrowDirection.up),
        _a('8b', 1, 2, ArrowDirection.right),
        _a('8c', 2, 2, ArrowDirection.down),
        _a('8d', 2, 1, ArrowDirection.left),
        _a('8e', 0, 0, ArrowDirection.right),
        _a('8f', 3, 3, ArrowDirection.left),
      ],
    ),

    LevelModel(
      id: 9, name: 'The Maze', rows: 4, cols: 4,
      difficulty: Difficulty.hard, targetMoves: 6,
      arrows: [
        _a('9a', 1, 0, ArrowDirection.down),
        _a('9b', 2, 1, ArrowDirection.right),
        _a('9c', 2, 2, ArrowDirection.up),
        _a('9d', 1, 2, ArrowDirection.left),
        _a('9e', 0, 2, ArrowDirection.up),
        _a('9f', 3, 1, ArrowDirection.down),
      ],
    ),

    LevelModel(
      id: 10, name: 'Final Chapter', rows: 4, cols: 4,
      difficulty: Difficulty.hard, targetMoves: 6,
      arrows: [
        _a('10a', 0, 1, ArrowDirection.right),
        _a('10b', 1, 2, ArrowDirection.right),
        _a('10c', 1, 3, ArrowDirection.down),
        _a('10d', 2, 3, ArrowDirection.left),
        _a('10e', 2, 2, ArrowDirection.left),
        _a('10f', 2, 1, ArrowDirection.up),
      ],
    ),

    // ── CHAPTER II — Neon Dark (5×5, length 1-2, no blockers) ────────────

    LevelModel(
      id: 11, name: 'Blockade', rows: 5, cols: 5,
      difficulty: Difficulty.medium, targetMoves: 8,
      arrows: [
        _a('11a', 0, 0, ArrowDirection.right, length: 2),
        _a('11b', 0, 3, ArrowDirection.down),
        _a('11c', 2, 3, ArrowDirection.right),
        _a('11d', 2, 4, ArrowDirection.down),
        _a('11e', 4, 2, ArrowDirection.left, length: 2),
        _a('11f', 2, 1, ArrowDirection.up),
        _a('11g', 3, 2, ArrowDirection.up),
        _a('11h', 4, 0, ArrowDirection.right),
      ],
    ),

    LevelModel(
      id: 12, name: 'The Wall', rows: 5, cols: 5,
      difficulty: Difficulty.medium, targetMoves: 9,
      arrows: [
        _a('12a', 1, 1, ArrowDirection.up, length: 2),
        _a('12b', 0, 3, ArrowDirection.right),
        _a('12c', 2, 2, ArrowDirection.right, length: 2),
        _a('12d', 3, 4, ArrowDirection.down),
        _a('12e', 3, 2, ArrowDirection.left),
        _a('12f', 4, 1, ArrowDirection.left),
        _a('12g', 2, 0, ArrowDirection.up),
        _a('12h', 2, 4, ArrowDirection.down),
      ],
    ),

    LevelModel(
      id: 13, name: 'Pressure', rows: 5, cols: 5,
      difficulty: Difficulty.hard, targetMoves: 10,
      arrows: [
        _a('13a', 0, 0, ArrowDirection.right, length: 2),
        _a('13b', 1, 3, ArrowDirection.up),
        _a('13c', 4, 1, ArrowDirection.right, length: 2),
        _a('13d', 3, 0, ArrowDirection.down),
        _a('13e', 2, 3, ArrowDirection.right),
        _a('13f', 2, 1, ArrowDirection.left),
        _a('13g', 0, 2, ArrowDirection.down, length: 2),
        _a('13h', 3, 4, ArrowDirection.up),
      ],
    ),
  ];

  static ArrowModel _a(String id, int row, int col, ArrowDirection dir,
      {int length = 1}) =>
      ArrowModel(id: id, row: row, col: col, direction: dir, length: length);
}
