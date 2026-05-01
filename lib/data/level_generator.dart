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

/// Generates levels using REVERSE construction with 5-stage difficulty curve.
///
/// Solvability guarantee:
/// 1. Start with empty grid (solved state)
/// 2. Add arrows one by one, each MUST have a clear escape path
/// 3. Player solves in reverse placement order → always solvable
///
/// Difficulty axes:
/// - Grid size:   4×4 → 5×5 → 6×6 → 7×7
/// - Arrow count: 3 → 16
/// - Complexity:  independent arrows → deep dependency chains
class LevelGenerator {
  LevelGenerator();

  // ── Public API ──────────────────────────────────────────────────────────

  LevelModel generate({required int levelId}) {
    assert(levelId > 13, 'Levels ≤13 are hand-crafted in LevelData');

    final config = getConfig(levelId);
    final name = _nameFor(levelId);

    for (int seed = 0; seed < 50; seed++) {
      final rng = Random(levelId * 31337 + seed);
      final arrows = _buildSolvableLevel(rng: rng, config: config, levelId: levelId);
      if (arrows != null && arrows.length >= (config.arrowCount * 0.7).ceil()) {
        return LevelModel(
          id: levelId, name: name,
          rows: config.gridSize, cols: config.gridSize,
          difficulty: config.difficulty,
          targetMoves: config.targetMoves,
          arrows: arrows,
        );
      }
    }

    return _fallback(levelId: levelId, config: config, name: name);
  }

  // ── 5-Stage Difficulty Curve ────────────────────────────────────────────

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

    // ── STAGE 5: EXPERT (100+) ──
    // 6×6→7×7, 12-16 arrows, tight spacing
    final progress = ((level - 101) / 50).clamp(0.0, 1.0);
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

  // ── Names pool ──────────────────────────────────────────────────────────

  String _nameFor(int id) {
    const pool = [
      'Gridlock',   'Tangle',    'Ricochet',  'Junction',  'Cascade',
      'Labyrinth',  'Pulse',     'Circuit',   'Reactor',   'Nexus',
      'Vortex',     'Overdrive', 'Apex',      'Summit',    'Eclipse',
      'Momentum',   'Paradox',   'Helix',     'Fracture',  'Zenith',
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

      occupied.addAll(keys);
      arrows.add(candidate);
      placed++;
    }

    // Phase 2: Place "dependent" arrows (blocked by existing, creates sequencing)
    final totalTarget = config.arrowCount;
    for (int attempt = 0; attempt < totalTarget * 60 && placed < totalTarget; attempt++) {
      final candidate = _randomArrow(rng, rows, cols, config.maxLen, levelId, placed);
      if (candidate == null) continue;

      final keys = candidate.occupiedCells.map((c) => '${c.row},${c.col}').toList();
      if (keys.any(occupied.contains)) continue;
      if (!_canEscape(candidate, arrows, rows, cols)) continue;

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
        cell.col < 0 || cell.col >= cols)) return null;

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
