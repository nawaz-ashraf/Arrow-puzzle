import 'dart:math';
import '../models/arrow_model.dart';
import '../models/level_model.dart';

/// Level configuration that maps a level ID to its generation parameters.
class LevelConfig {
  final int gridSize;
  final int arrowCount;
  final int maxLen;
  final int complexity; // 1-5: controls dependency depth
  final Difficulty difficulty;
  final int targetMoves;

  const LevelConfig({
    required this.gridSize,
    required this.arrowCount,
    required this.maxLen,
    required this.complexity,
    required this.difficulty,
    required this.targetMoves,
  });
}

/// Generates levels using REVERSE construction with 8-stage difficulty curve.
///
/// Solvability guarantee:
/// 1. Start with empty grid (solved state)
/// 2. Add arrows one by one, each MUST have a clear escape path
/// 3. After all arrows placed, run full solvability simulation
/// 4. Full simulation: repeatedly remove any escapable arrow until grid empty
/// 5. If any arrows remain stuck → reject and regenerate
///
/// Difficulty axes:
/// - Grid size:    4×4 → 8×8
/// - Arrow count:  3 → 22
/// - Arrow length: 1 → 3
/// - Complexity:   independent arrows → deep dependency chains
///
/// Deadlock prevention:
/// - No opposite-facing arrows on same row/col adjacent (instant block)
/// - No circular dependency chains
/// - At least one arrow must be initially free
class LevelGenerator {
  LevelGenerator();

  // ── Public API ──────────────────────────────────────────────────────────

  LevelModel generate({required int levelId}) {
    assert(levelId > 13, 'Levels ≤13 are hand-crafted in LevelData');

    final config = getConfig(levelId);
    final name = _nameFor(levelId);

    for (int seed = 0; seed < 80; seed++) {
      final rng = Random(levelId * 31337 + seed);
      final arrows = _buildSolvableLevel(rng: rng, config: config, levelId: levelId);
      if (arrows != null && arrows.length >= (config.arrowCount * 0.7).ceil()) {
        // Final validation: ensure the level is FULLY solvable
        if (_isFullySolvable(arrows, config.gridSize, config.gridSize)) {
          return LevelModel(
            id: levelId, name: name,
            rows: config.gridSize, cols: config.gridSize,
            difficulty: config.difficulty,
            targetMoves: config.targetMoves,
            arrows: arrows,
          );
        }
      }
    }

    return _fallback(levelId: levelId, config: config, name: name);
  }

  // ── 8-Stage Difficulty Curve ────────────────────────────────────────────

  /// Maps any level ID to its precise configuration.
  /// Difficulty ramps smoothly within each stage.
  static LevelConfig getConfig(int level) {
    if (level <= 10) {
      // ── STAGE 1: BEGINNER ──
      // 4×4, 3-5 arrows, length 1, no dependencies
      final arrows = 3 + (level - 1) ~/ 3; // 3,3,3,4,4,4,5,5,5,5
      return LevelConfig(
        gridSize: 4,
        arrowCount: arrows.clamp(3, 5),
        maxLen: 1,
        complexity: 1,
        difficulty: Difficulty.easy,
        targetMoves: arrows + 1,
      );
    }

    if (level <= 25) {
      // ── STAGE 2: EASY ──
      // 5×5, 5-7 arrows, length 1-2, 1-2 dependencies
      final progress = (level - 11) / 14; // 0.0 → 1.0
      final arrows = 5 + (progress * 2).round(); // 5 → 7
      return LevelConfig(
        gridSize: 5,
        arrowCount: arrows,
        maxLen: 2,
        complexity: 2,
        difficulty: Difficulty.easy,
        targetMoves: arrows + 2,
      );
    }

    if (level <= 50) {
      // ── STAGE 3: MEDIUM ──
      // 5×5→6×6, 7-10 arrows, length 1-2, chain deps
      final progress = (level - 26) / 24; // 0.0 → 1.0
      final arrows = 7 + (progress * 3).round(); // 7 → 10
      final grid = level <= 38 ? 5 : 6;
      return LevelConfig(
        gridSize: grid,
        arrowCount: arrows,
        maxLen: 2,
        complexity: 3,
        difficulty: Difficulty.medium,
        targetMoves: arrows + 3,
      );
    }

    if (level <= 100) {
      // ── STAGE 4: HARD ──
      // 6×6, 10-14 arrows, length 1-3, deep chains
      final progress = (level - 51) / 49; // 0.0 → 1.0
      final arrows = 10 + (progress * 4).round(); // 10 → 14
      return LevelConfig(
        gridSize: 6,
        arrowCount: arrows,
        maxLen: 3,
        complexity: 4,
        difficulty: Difficulty.hard,
        targetMoves: arrows + 4,
      );
    }

    if (level <= 150) {
      // ── STAGE 5: EXPERT ──
      // 6×6→7×7, 12-16 arrows, tight spacing
      final progress = ((level - 101) / 49).clamp(0.0, 1.0);
      final arrows = 12 + (progress * 4).round(); // 12 → 16
      final grid = level <= 125 ? 6 : 7;
      return LevelConfig(
        gridSize: grid,
        arrowCount: arrows.clamp(12, 16),
        maxLen: 3,
        complexity: 5,
        difficulty: Difficulty.hard,
        targetMoves: arrows + 5,
      );
    }

    if (level <= 200) {
      // ── STAGE 6: MASTER ──
      // 7×7, 14-18 arrows, deep chains, tight
      final progress = ((level - 151) / 49).clamp(0.0, 1.0);
      final arrows = 14 + (progress * 4).round(); // 14 → 18
      return LevelConfig(
        gridSize: 7,
        arrowCount: arrows.clamp(14, 18),
        maxLen: 3,
        complexity: 5,
        difficulty: Difficulty.hard,
        targetMoves: arrows + 5,
      );
    }

    if (level <= 250) {
      // ── STAGE 7: LEGEND ──
      // 7×7→8×8, 16-20 arrows, extreme chains
      final progress = ((level - 201) / 49).clamp(0.0, 1.0);
      final arrows = 16 + (progress * 4).round(); // 16 → 20
      final grid = level <= 225 ? 7 : 8;
      return LevelConfig(
        gridSize: grid,
        arrowCount: arrows.clamp(16, 20),
        maxLen: 3,
        complexity: 5,
        difficulty: Difficulty.hard,
        targetMoves: arrows + 6,
      );
    }

    // ── STAGE 8: MYTHIC (251-300+) ──
    // 8×8, 18-22 arrows, maximum challenge
    final progress = ((level - 251) / 49).clamp(0.0, 1.0);
    final arrows = 18 + (progress * 4).round(); // 18 → 22
    return LevelConfig(
      gridSize: 8,
      arrowCount: arrows.clamp(18, 22),
      maxLen: 3,
      complexity: 5,
      difficulty: Difficulty.hard,
      targetMoves: arrows + 7,
    );
  }

  // ── Names pool (40+) ───────────────────────────────────────────────────

  String _nameFor(int id) {
    const pool = [
      'Gridlock',    'Tangle',      'Ricochet',    'Junction',    'Cascade',
      'Labyrinth',   'Pulse',       'Circuit',     'Reactor',     'Nexus',
      'Vortex',      'Overdrive',   'Apex',        'Summit',      'Eclipse',
      'Momentum',    'Paradox',     'Helix',       'Fracture',    'Zenith',
      'Catalyst',    'Prism',       'Cipher',      'Phantom',     'Flux',
      'Riptide',     'Tempest',     'Quasar',      'Oblivion',    'Mirage',
      'Singularity', 'Entropy',     'Nebula',      'Horizon',     'Pinnacle',
      'Maelstrom',   'Crucible',    'Inferno',     'Fortress',    'Abyss',
    ];
    return pool[(id - 14) % pool.length];
  }

  // ── Core: reverse-construction algorithm ────────────────────────────────

  List<ArrowModel>? _buildSolvableLevel({
    required Random rng,
    required LevelConfig config,
    required int levelId,
  }) {
    final rows = config.gridSize;
    final cols = config.gridSize;
    final arrows = <ArrowModel>[];
    final occupied = <String>{};
    int placed = 0;

    // Phase 1: Place "free" arrows (independent, clear escape)
    final freeCount = _freeArrowCount(config);
    for (int attempt = 0; attempt < freeCount * 40 && placed < freeCount; attempt++) {
      final candidate = _randomArrow(rng, rows, cols, config.maxLen, levelId, placed);
      if (candidate == null) continue;

      final keys = candidate.occupiedCells.map((c) => '${c.row},${c.col}').toList();
      if (keys.any(occupied.contains)) continue;
      if (!_canEscape(candidate, arrows, rows, cols)) continue;

      // Deadlock check: no opposite-facing arrows blocking each other
      if (_createsOppositeBlock(candidate, arrows)) continue;

      occupied.addAll(keys);
      arrows.add(candidate);
      placed++;
    }

    // Phase 2: Place "dependent" arrows (blocked by existing, creates sequencing)
    final totalTarget = config.arrowCount;
    for (int attempt = 0; attempt < totalTarget * 80 && placed < totalTarget; attempt++) {
      final candidate = _randomArrow(rng, rows, cols, config.maxLen, levelId, placed);
      if (candidate == null) continue;

      final keys = candidate.occupiedCells.map((c) => '${c.row},${c.col}').toList();
      if (keys.any(occupied.contains)) continue;

      // For dependent arrows, we allow blocked ones but MUST verify
      // they can eventually escape once other arrows are removed.
      // This is checked by _isFullySolvable after all arrows are placed.

      // Still reject if it creates an obvious deadlock
      if (_createsOppositeBlock(candidate, arrows)) continue;

      occupied.addAll(keys);
      arrows.add(candidate);
      placed++;
    }

    if (placed < (totalTarget * 0.7).ceil()) return null;
    return arrows;
  }

  /// How many arrows should be "free" (independent) vs dependent.
  int _freeArrowCount(LevelConfig config) {
    switch (config.complexity) {
      case 1: return config.arrowCount;     // all independent
      case 2: return config.arrowCount - 1; // 1 dependent
      case 3: return (config.arrowCount * 0.5).ceil(); // half dependent
      case 4: return (config.arrowCount * 0.3).ceil(); // mostly chains
      default: return (config.arrowCount * 0.2).ceil(); // expert: tight
    }
  }

  /// Creates a random arrow candidate (or null if bounds fail).
  ArrowModel? _randomArrow(Random rng, int rows, int cols, int maxLen, int levelId, int index) {
    final dir = ArrowDirection.values[rng.nextInt(4)];
    final len = 1 + rng.nextInt(maxLen);

    final maxR = dir.isVertical   ? rows - len : rows - 1;
    final maxC = dir.isHorizontal ? cols - len : cols - 1;
    if (maxR < 0 || maxC < 0) return null;

    final r = rng.nextInt(maxR + 1);
    final c = rng.nextInt(maxC + 1);

    final List<({int row, int col})> cells;
    if (dir.isHorizontal) {
      cells = List.generate(len, (i) => (row: r, col: c + i));
    } else {
      cells = List.generate(len, (i) => (row: r + i, col: c));
    }

    if (cells.any((cell) =>
        cell.row < 0 || cell.row >= rows ||
        cell.col < 0 || cell.col >= cols)) {
      return null;
    }

    return ArrowModel(
      id: '${levelId}_A$index', row: r, col: c,
      direction: dir, length: len,
    );
  }

  /// Simulates the arrow moving step-by-step in its direction.
  /// Returns true ONLY if the arrow reaches the grid boundary
  /// without hitting any existing arrow.
  bool _canEscape(
    ArrowModel arrow, List<ArrowModel> existingArrows,
    int rows, int cols,
  ) {
    final occupied = <String>{};
    for (final a in existingArrows) {
      for (final cell in a.occupiedCells) {
        occupied.add('${cell.row},${cell.col}');
      }
    }

    var hr = arrow.head.row;
    var hc = arrow.head.col;
    final dr = arrow.direction.dr;
    final dc = arrow.direction.dc;

    for (int step = 0; step < rows + cols; step++) {
      hr += dr;
      hc += dc;
      if (hr < 0 || hr >= rows || hc < 0 || hc >= cols) return true;
      if (occupied.contains('$hr,$hc')) return false;
    }

    return false;
  }

  // ── Full solvability check ─────────────────────────────────────────────

  /// Simulates solving the entire level by repeatedly removing any arrow
  /// that can escape. If ALL arrows can eventually be removed, the level
  /// is fully solvable. This catches dependency chains and deadlocks.
  bool _isFullySolvable(List<ArrowModel> arrows, int rows, int cols) {
    if (arrows.isEmpty) return true;

    var remaining = List<ArrowModel>.from(arrows);
    bool progress = true;

    while (remaining.isNotEmpty && progress) {
      progress = false;
      for (int i = 0; i < remaining.length; i++) {
        final arrow = remaining[i];
        final others = <ArrowModel>[
          ...remaining.sublist(0, i),
          ...remaining.sublist(i + 1),
        ];
        if (_canEscape(arrow, others, rows, cols)) {
          remaining = others;
          progress = true;
          break; // restart loop with updated list
        }
      }
    }

    return remaining.isEmpty;
  }

  // ── Deadlock prevention: opposite-facing check ─────────────────────────

  /// Checks if placing [candidate] creates an obvious deadlock where
  /// two arrows face each other on the same row/col and block each other.
  bool _createsOppositeBlock(ArrowModel candidate, List<ArrowModel> existing) {
    for (final a in existing) {
      // Same row, facing each other horizontally
      if (candidate.direction == ArrowDirection.right &&
          a.direction == ArrowDirection.left &&
          candidate.row == a.row &&
          candidate.col < a.col) {
        // candidate → ... ← a — potential mutual block
        final gap = a.col - (candidate.col + candidate.length - 1) - 1;
        if (gap <= 0) return true;
      }
      if (candidate.direction == ArrowDirection.left &&
          a.direction == ArrowDirection.right &&
          candidate.row == a.row &&
          candidate.col > a.col) {
        final gap = candidate.col - (a.col + a.length - 1) - 1;
        if (gap <= 0) return true;
      }

      // Same col, facing each other vertically
      if (candidate.direction == ArrowDirection.down &&
          a.direction == ArrowDirection.up &&
          candidate.col == a.col &&
          candidate.row < a.row) {
        final gap = a.row - (candidate.row + candidate.length - 1) - 1;
        if (gap <= 0) return true;
      }
      if (candidate.direction == ArrowDirection.up &&
          a.direction == ArrowDirection.down &&
          candidate.col == a.col &&
          candidate.row > a.row) {
        final gap = candidate.row - (a.row + a.length - 1) - 1;
        if (gap <= 0) return true;
      }
    }
    return false;
  }

  // ── Fallback ────────────────────────────────────────────────────────────

  LevelModel _fallback({
    required int levelId, required LevelConfig config, required String name,
  }) {
    final arrows = <ArrowModel>[];
    int i = 0;
    for (int r = 0; r < config.gridSize && i < 6; r += 2) {
      arrows.add(ArrowModel(
        id: '${levelId}_F$i', row: r, col: 0,
        direction: ArrowDirection.right,
      ));
      i++;
    }
    return LevelModel(
      id: levelId, name: name,
      rows: config.gridSize, cols: config.gridSize,
      difficulty: config.difficulty,
      targetMoves: config.targetMoves,
      arrows: arrows,
    );
  }
}
