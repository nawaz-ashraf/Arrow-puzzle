import 'dart:math';
import '../models/arrow_model.dart';
import '../models/level_model.dart';

/// Procedurally generates levels for IDs beyond hand-crafted ones.
///
/// Difficulty scaling (no blockers — arrows block each other):
/// - Level 1–10  → 4×4, 3–5 arrows, length 1
/// - Level 11–30 → 5×5, 6–8 arrows, length 1–2
/// - Level 31+   → 6×6, 8–12 arrows, length 1–3
class LevelGenerator {
  LevelGenerator();

  LevelModel generate({required int levelId}) {
    assert(levelId > 13, 'Levels ≤13 are hand-crafted in LevelData');
    final rng = Random(levelId * 31337);

    final (gridSize, maxLen, diff) = _tierFor(levelId);
    final arrowCount = min(3 + levelId ~/ 2, gridSize * 2);
    final targetMoves = arrowCount + (levelId ~/ 5);
    final name = _nameFor(levelId);

    for (int attempt = 0; attempt < 25; attempt++) {
      final r = Random(levelId * 31337 + attempt);
      final result = _tryBuild(
        rng: r, levelId: levelId, rows: gridSize, cols: gridSize,
        arrowCount: arrowCount, maxLen: maxLen,
        name: name, targetMoves: targetMoves, diff: diff,
      );
      if (result != null) return result;
    }

    return _fallback(levelId: levelId, rows: gridSize, cols: gridSize,
        name: name, targetMoves: targetMoves, diff: diff);
  }

  // ── Tier configuration ────────────────────────────────────────────────────

  (int, int, Difficulty) _tierFor(int id) {
    if (id <= 10) {
      return (4, 1, Difficulty.easy);
    } else if (id <= 30) {
      return (5, 2, id <= 20 ? Difficulty.medium : Difficulty.hard);
    } else {
      return (6, 3, Difficulty.hard);
    }
  }

  // ── Names pool ────────────────────────────────────────────────────────────

  String _nameFor(int id) {
    const pool = [
      'Gridlock', 'Tangle', 'Ricochet', 'Junction', 'Cascade',
      'Labyrinth', 'Pulse', 'Circuit', 'Reactor', 'Nexus',
      'Vortex', 'Overdrive', 'Apex', 'Summit', 'Eclipse',
    ];
    return pool[(id - 14) % pool.length];
  }

  // ── Builder ───────────────────────────────────────────────────────────────

  LevelModel? _tryBuild({
    required Random rng,
    required int levelId, required int rows, required int cols,
    required int arrowCount, required int maxLen,
    required String name, required int targetMoves, required Difficulty diff,
  }) {
    final occupied = <String>{};
    final allPieces = <ArrowModel>[];

    // Place playable arrows (no blockers)
    int placed = 0;
    for (int attempts = 0; attempts < arrowCount * 30 && placed < arrowCount; attempts++) {
      final dir = ArrowDirection.values[rng.nextInt(4)];
      final len = 1 + rng.nextInt(maxLen);

      final maxR = dir.isVertical   ? rows - len : rows - 1;
      final maxC = dir.isHorizontal ? cols - len : cols - 1;
      if (maxR < 0 || maxC < 0) continue;

      final r = rng.nextInt(maxR + 1);
      final c = rng.nextInt(maxC + 1);

      // All cells of this arrow
      final List<({int row, int col})> cells;
      if (dir.isHorizontal) {
        cells = List.generate(len, (i) => (row: r, col: c + i));
      } else {
        cells = List.generate(len, (i) => (row: r + i, col: c));
      }

      // Bounds check
      if (cells.any((cell) => cell.row < 0 || cell.row >= rows ||
          cell.col < 0 || cell.col >= cols)) continue;

      // No overlaps
      final keys = cells.map((cell) => '${cell.row},${cell.col}').toList();
      if (keys.any(occupied.contains)) continue;

      // Check frontNext is not blocked (but allow out-of-bounds = escape)
      final ({int row, int col}) headCell;
      switch (dir) {
        case ArrowDirection.right: headCell = (row: r, col: c + len - 1); break;
        case ArrowDirection.left:  headCell = (row: r, col: c);           break;
        case ArrowDirection.down:  headCell = (row: r + len - 1, col: c); break;
        case ArrowDirection.up:    headCell = (row: r, col: c);           break;
      }
      final fnr = headCell.row + dir.dr, fnc = headCell.col + dir.dc;
      if (fnr >= 0 && fnr < rows && fnc >= 0 && fnc < cols &&
          occupied.contains('$fnr,$fnc')) continue;

      // Prevent unsolvable opposite locks (neighbor conflict)
      if (!_isValidPlacement(r, c, dir, allPieces)) continue;

      occupied.addAll(keys);
      allPieces.add(ArrowModel(
        id: '${levelId}_A$placed', row: r, col: c,
        direction: dir, length: len,
      ));
      placed++;
    }

    if (placed < (arrowCount * 0.7).ceil()) return null;

    // Must have at least one immediately escapable arrow
    if (!_hasEscape(rows, cols, allPieces)) return null;

    return LevelModel(
      id: levelId, name: name, rows: rows, cols: cols,
      difficulty: diff, targetMoves: targetMoves, arrows: allPieces,
    );
  }

  bool _hasEscape(int rows, int cols, List<ArrowModel> pieces) {
    final occ = <String>{};
    for (final p in pieces) {
      for (final cell in p.occupiedCells) { occ.add('${cell.row},${cell.col}'); }
    }
    for (final p in pieces) {
      final fn = p.frontNext;
      if (fn.row < 0 || fn.row >= rows || fn.col < 0 || fn.col >= cols) return true;
      if (!occ.contains('${fn.row},${fn.col}')) return true;
    }
    return false;
  }

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

  // ── Opposite-lock prevention ──────────────────────────────────────────────

  static bool _isOpposite(ArrowDirection a, ArrowDirection b) {
    return (a == ArrowDirection.up && b == ArrowDirection.down) ||
           (a == ArrowDirection.down && b == ArrowDirection.up) ||
           (a == ArrowDirection.left && b == ArrowDirection.right) ||
           (a == ArrowDirection.right && b == ArrowDirection.left);
  }

  bool _isValidPlacement(int r, int c, ArrowDirection dir, List<ArrowModel> arrows) {
    for (final a in arrows) {
      // Check neighbor conflict
      if (a.col == c && a.row == r + 1 && _isOpposite(dir, a.direction)) return false;
      if (a.col == c && a.row == r - 1 && _isOpposite(dir, a.direction)) return false;
      if (a.col == c + 1 && a.row == r && _isOpposite(dir, a.direction)) return false;
      if (a.col == c - 1 && a.row == r && _isOpposite(dir, a.direction)) return false;
    }
    return true;
  }
}
