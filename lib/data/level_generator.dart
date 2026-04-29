import 'dart:math';
import '../models/arrow_model.dart';
import '../models/level_model.dart';

/// Generates levels using REVERSE construction:
///
/// 1. Start with empty grid (solved state)
/// 2. Add arrows one by one, each MUST have a clear escape path
///    considering only previously placed arrows
/// 3. Player solves in reverse order → GUARANTEED solvable
///
/// Why this works:
/// - Arrow N can escape (clear path when placed with arrows 1..N-1)
/// - After N escapes, arrow N-1 can escape (path was clear with 1..N-2)
/// - ... all the way down to arrow 1 (placed on empty grid)
class LevelGenerator {
  LevelGenerator();

  LevelModel generate({required int levelId}) {
    assert(levelId > 13, 'Levels ≤13 are hand-crafted in LevelData');

    final (gridSize, maxLen, diff) = _tierFor(levelId);
    final arrowCount = min(3 + levelId ~/ 2, gridSize * 2);
    final targetMoves = arrowCount + (levelId ~/ 5);
    final name = _nameFor(levelId);

    for (int seed = 0; seed < 50; seed++) {
      final rng = Random(levelId * 31337 + seed);
      final arrows = _buildSolvableLevel(
        rng: rng, rows: gridSize, cols: gridSize,
        arrowCount: arrowCount, maxLen: maxLen, levelId: levelId,
      );
      if (arrows != null && arrows.length >= (arrowCount * 0.7).ceil()) {
        return LevelModel(
          id: levelId, name: name, rows: gridSize, cols: gridSize,
          difficulty: diff, targetMoves: targetMoves, arrows: arrows,
        );
      }
    }

    return _fallback(
      levelId: levelId, rows: gridSize, cols: gridSize,
      name: name, targetMoves: targetMoves, diff: diff,
    );
  }

  // ── Tier configuration ──────────────────────────────────────────────────

  (int, int, Difficulty) _tierFor(int id) {
    if (id <= 10) return (4, 1, Difficulty.easy);
    if (id <= 30) return (5, 2, id <= 20 ? Difficulty.medium : Difficulty.hard);
    return (6, 3, Difficulty.hard);
  }

  String _nameFor(int id) {
    const pool = [
      'Gridlock', 'Tangle', 'Ricochet', 'Junction', 'Cascade',
      'Labyrinth', 'Pulse', 'Circuit', 'Reactor', 'Nexus',
      'Vortex', 'Overdrive', 'Apex', 'Summit', 'Eclipse',
    ];
    return pool[(id - 14) % pool.length];
  }

  // ── Core: reverse-construction algorithm ────────────────────────────────

  List<ArrowModel>? _buildSolvableLevel({
    required Random rng,
    required int rows, required int cols,
    required int arrowCount, required int maxLen,
    required int levelId,
  }) {
    final arrows = <ArrowModel>[];
    final occupied = <String>{};
    int placed = 0;

    for (int attempt = 0; attempt < arrowCount * 50 && placed < arrowCount; attempt++) {
      final dir = ArrowDirection.values[rng.nextInt(4)];
      final len = 1 + rng.nextInt(maxLen);

      final maxR = dir.isVertical   ? rows - len : rows - 1;
      final maxC = dir.isHorizontal ? cols - len : cols - 1;
      if (maxR < 0 || maxC < 0) continue;

      final r = rng.nextInt(maxR + 1);
      final c = rng.nextInt(maxC + 1);

      // All cells this arrow occupies
      final List<({int row, int col})> cells;
      if (dir.isHorizontal) {
        cells = List.generate(len, (i) => (row: r, col: c + i));
      } else {
        cells = List.generate(len, (i) => (row: r + i, col: c));
      }

      // Bounds check
      if (cells.any((cell) =>
          cell.row < 0 || cell.row >= rows ||
          cell.col < 0 || cell.col >= cols)) continue;

      // No overlaps with existing arrows
      final keys = cells.map((cell) => '${cell.row},${cell.col}').toList();
      if (keys.any(occupied.contains)) continue;

      // ★ THE KEY CHECK: can this arrow escape to the edge?
      final candidate = ArrowModel(
        id: '${levelId}_A$placed', row: r, col: c,
        direction: dir, length: len,
      );

      if (!_canEscape(candidate, arrows, rows, cols)) continue;

      occupied.addAll(keys);
      arrows.add(candidate);
      placed++;
    }

    if (placed < (arrowCount * 0.7).ceil()) return null;
    return arrows;
  }

  /// Simulates the arrow moving step-by-step in its direction.
  /// Returns true ONLY if the arrow reaches the grid boundary
  /// without hitting any existing arrow.
  bool _canEscape(
    ArrowModel arrow, List<ArrowModel> existingArrows,
    int rows, int cols,
  ) {
    // Build occupancy from existing arrows only
    final occupied = <String>{};
    for (final a in existingArrows) {
      for (final cell in a.occupiedCells) {
        occupied.add('${cell.row},${cell.col}');
      }
    }

    // Trace from the head outward, one step at a time
    var hr = arrow.head.row;
    var hc = arrow.head.col;
    final dr = arrow.direction.dr;
    final dc = arrow.direction.dc;

    for (int step = 0; step < rows + cols; step++) {
      hr += dr;
      hc += dc;

      // Reached edge → escaped!
      if (hr < 0 || hr >= rows || hc < 0 || hc >= cols) return true;

      // Hit another arrow → blocked
      if (occupied.contains('$hr,$hc')) return false;
    }

    return false; // safety fallback
  }

  // ── Fallback (simple guaranteed-solvable layout) ────────────────────────

  LevelModel _fallback({
    required int levelId, required int rows, required int cols,
    required String name, required int targetMoves, required Difficulty diff,
  }) {
    final arrows = <ArrowModel>[];
    int i = 0;
    for (int r = 0; r < rows && i < 8; r += 2) {
      arrows.add(ArrowModel(
        id: '${levelId}_F$i', row: r, col: 0,
        direction: ArrowDirection.right,
      ));
      i++;
    }
    return LevelModel(
      id: levelId, name: name, rows: rows, cols: cols,
      difficulty: diff, targetMoves: targetMoves, arrows: arrows,
    );
  }
}
