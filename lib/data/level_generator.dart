import 'dart:math';
import '../models/arrow_model.dart';
import '../models/level_model.dart';

/// Level configuration that maps a level ID to its generation parameters.
class LevelConfig {
  final int gridSize;
  final int arrowCount;
  final int maxLen;
  final int complexity;
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

/// Generates levels using REVERSE construction with solvability guarantee.
///
/// Deadlock prevention:
/// - No opposite-facing arrows on same row/col that mutually block
/// - No circular dependency chains (graph-based cycle detection)
/// - At least one arrow must be initially free
/// - Every generated level is validated before returning
class LevelGenerator {
  LevelGenerator();

  // ── Public API ──────────────────────────────────────────────────────────

  LevelModel generate({required int levelId}) {
    assert(levelId > 13, 'Levels ≤13 are hand-crafted in LevelData');
    final config = getConfig(levelId);
    final name = _nameFor(levelId);
    final maxSeeds = config.complexity >= 4 ? 200 : 150;

    for (int seed = 0; seed < maxSeeds; seed++) {
      final rng = Random(levelId * 31337 + seed);
      final arrows = _buildSolvableLevel(rng: rng, config: config, levelId: levelId);
      if (arrows != null && arrows.length >= (config.arrowCount * 0.7).ceil()) {
        if (_isFullySolvable(arrows, config.gridSize, config.gridSize)) {
          if (!_hasAnyOppositeDeadlock(arrows) &&
              !_hasCircularDependency(arrows, config.gridSize, config.gridSize)) {
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
    }
    return _fallback(levelId: levelId, config: config, name: name);
  }

  // ── Public solvability validator ────────────────────────────────────────

  /// Validates that a [LevelModel] is fully solvable.
  static bool isLevelSolvable(LevelModel level) {
    final arrows = level.arrows.where((a) => !a.isBlocker).toList();
    if (arrows.isEmpty) return true;
    if (_hasAnyOppositeDeadlock(arrows)) return false;
    if (_hasCircularDependency(arrows, level.rows, level.cols)) return false;
    return _isFullySolvable(arrows, level.rows, level.cols);
  }

  // ── 8-Stage Difficulty Curve ────────────────────────────────────────────

  static LevelConfig getConfig(int level) {
    if (level <= 10) {
      final arrows = 3 + (level - 1) ~/ 3;
      return LevelConfig(gridSize: 4, arrowCount: arrows.clamp(3, 5),
        maxLen: 1, complexity: 1, difficulty: Difficulty.easy, targetMoves: arrows + 1);
    }
    if (level <= 25) {
      final progress = (level - 11) / 14;
      final arrows = 5 + (progress * 2).round();
      return LevelConfig(gridSize: 5, arrowCount: arrows,
        maxLen: 2, complexity: 2, difficulty: Difficulty.easy, targetMoves: arrows + 2);
    }
    if (level <= 50) {
      final progress = (level - 26) / 24;
      final arrows = 7 + (progress * 3).round();
      final grid = level <= 38 ? 5 : 6;
      return LevelConfig(gridSize: grid, arrowCount: arrows,
        maxLen: 2, complexity: 3, difficulty: Difficulty.medium, targetMoves: arrows + 3);
    }
    if (level <= 100) {
      final progress = (level - 51) / 49;
      final arrows = 10 + (progress * 4).round();
      return LevelConfig(gridSize: 6, arrowCount: arrows,
        maxLen: 3, complexity: 4, difficulty: Difficulty.hard, targetMoves: arrows + 4);
    }
    if (level <= 150) {
      final progress = ((level - 101) / 49).clamp(0.0, 1.0);
      final arrows = 12 + (progress * 4).round();
      final grid = level <= 125 ? 6 : 7;
      return LevelConfig(gridSize: grid, arrowCount: arrows.clamp(12, 16),
        maxLen: 3, complexity: 5, difficulty: Difficulty.hard, targetMoves: arrows + 5);
    }
    if (level <= 200) {
      final progress = ((level - 151) / 49).clamp(0.0, 1.0);
      final arrows = 14 + (progress * 4).round();
      return LevelConfig(gridSize: 7, arrowCount: arrows.clamp(14, 18),
        maxLen: 3, complexity: 5, difficulty: Difficulty.hard, targetMoves: arrows + 5);
    }
    if (level <= 250) {
      final progress = ((level - 201) / 49).clamp(0.0, 1.0);
      final arrows = 16 + (progress * 4).round();
      final grid = level <= 225 ? 7 : 8;
      return LevelConfig(gridSize: grid, arrowCount: arrows.clamp(16, 20),
        maxLen: 3, complexity: 5, difficulty: Difficulty.hard, targetMoves: arrows + 6);
    }
    // STAGE 8: MYTHIC (251-300+)
    final progress = ((level - 251) / 49).clamp(0.0, 1.0);
    final arrows = 18 + (progress * 4).round();
    return LevelConfig(gridSize: 8, arrowCount: arrows.clamp(18, 22),
      maxLen: 3, complexity: 5, difficulty: Difficulty.hard, targetMoves: arrows + 7);
  }

  // ── Names pool ─────────────────────────────────────────────────────────

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
    required Random rng, required LevelConfig config, required int levelId,
  }) {
    final rows = config.gridSize;
    final cols = config.gridSize;
    final arrows = <ArrowModel>[];
    final occupied = <String>{};
    int placed = 0;

    // Phase 1: Place "free" arrows (clear escape path)
    final freeCount = _freeArrowCount(config);
    for (int attempt = 0; attempt < freeCount * 50 && placed < freeCount; attempt++) {
      final candidate = _randomArrow(rng, rows, cols, config.maxLen, levelId, placed);
      if (candidate == null) continue;
      final keys = candidate.occupiedCells.map((c) => '${c.row},${c.col}').toList();
      if (keys.any(occupied.contains)) continue;
      if (!_canEscape(candidate, arrows, rows, cols)) continue;
      if (_createsOppositeBlock(candidate, arrows)) continue;
      occupied.addAll(keys);
      arrows.add(candidate);
      placed++;
    }

    if (placed == 0) return null;

    // Phase 2: Place "dependent" arrows
    final totalTarget = config.arrowCount;
    for (int attempt = 0; attempt < totalTarget * 100 && placed < totalTarget; attempt++) {
      final candidate = _randomArrow(rng, rows, cols, config.maxLen, levelId, placed);
      if (candidate == null) continue;
      final keys = candidate.occupiedCells.map((c) => '${c.row},${c.col}').toList();
      if (keys.any(occupied.contains)) continue;
      if (_createsOppositeBlock(candidate, arrows)) continue;

      // Check for circular dependencies before adding
      final tentative = [...arrows, candidate];
      if (_hasCircularDependency(tentative, rows, cols)) continue;

      occupied.addAll(keys);
      arrows.add(candidate);
      placed++;
    }

    if (placed < (totalTarget * 0.7).ceil()) return null;

    // Ensure at least one arrow is initially free
    final hasFree = arrows.any((a) =>
        _canEscape(a, arrows.where((o) => o.id != a.id).toList(), rows, cols));
    if (!hasFree) return null;

    return arrows;
  }

  int _freeArrowCount(LevelConfig config) {
    switch (config.complexity) {
      case 1: return config.arrowCount;
      case 2: return config.arrowCount - 1;
      case 3: return (config.arrowCount * 0.5).ceil();
      case 4: return (config.arrowCount * 0.3).ceil();
      default: return (config.arrowCount * 0.2).ceil();
    }
  }

  ArrowModel? _randomArrow(Random rng, int rows, int cols, int maxLen, int levelId, int index) {
    final dir = ArrowDirection.values[rng.nextInt(4)];
    final len = 1 + rng.nextInt(maxLen);
    final maxR = dir.isVertical ? rows - len : rows - 1;
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
    if (cells.any((cell) => cell.row < 0 || cell.row >= rows || cell.col < 0 || cell.col >= cols)) {
      return null;
    }
    return ArrowModel(id: '${levelId}_A$index', row: r, col: c, direction: dir, length: len);
  }

  static bool _canEscape(ArrowModel arrow, List<ArrowModel> existingArrows, int rows, int cols) {
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

  static bool _isFullySolvable(List<ArrowModel> arrows, int rows, int cols) {
    if (arrows.isEmpty) return true;
    var remaining = List<ArrowModel>.from(arrows);
    bool progress = true;
    while (remaining.isNotEmpty && progress) {
      progress = false;
      for (int i = 0; i < remaining.length; i++) {
        final arrow = remaining[i];
        final others = <ArrowModel>[...remaining.sublist(0, i), ...remaining.sublist(i + 1)];
        if (_canEscape(arrow, others, rows, cols)) {
          remaining = others;
          progress = true;
          break;
        }
      }
    }
    return remaining.isEmpty;
  }

  // ── Deadlock prevention: opposite-facing check ─────────────────────────

  bool _createsOppositeBlock(ArrowModel candidate, List<ArrowModel> existing) {
    for (final a in existing) {
      if (candidate.direction == ArrowDirection.right && a.direction == ArrowDirection.left &&
          candidate.row == a.row && candidate.col < a.col) {
        final gap = a.col - (candidate.col + candidate.length - 1) - 1;
        if (gap <= 1) return true;
      }
      if (candidate.direction == ArrowDirection.left && a.direction == ArrowDirection.right &&
          candidate.row == a.row && candidate.col > a.col) {
        final gap = candidate.col - (a.col + a.length - 1) - 1;
        if (gap <= 1) return true;
      }
      if (candidate.direction == ArrowDirection.down && a.direction == ArrowDirection.up &&
          candidate.col == a.col && candidate.row < a.row) {
        final gap = a.row - (candidate.row + candidate.length - 1) - 1;
        if (gap <= 1) return true;
      }
      if (candidate.direction == ArrowDirection.up && a.direction == ArrowDirection.down &&
          candidate.col == a.col && candidate.row > a.row) {
        final gap = candidate.row - (a.row + a.length - 1) - 1;
        if (gap <= 1) return true;
      }
    }
    return false;
  }

  /// Checks all pairs for any opposite-facing deadlock.
  static bool _hasAnyOppositeDeadlock(List<ArrowModel> arrows) {
    for (int i = 0; i < arrows.length; i++) {
      for (int j = i + 1; j < arrows.length; j++) {
        if (_arePairDeadlocked(arrows[i], arrows[j])) return true;
      }
    }
    return false;
  }

  static bool _arePairDeadlocked(ArrowModel a, ArrowModel b) {
    // → ← on same row
    if (a.direction == ArrowDirection.right && b.direction == ArrowDirection.left &&
        a.row == b.row && a.col < b.col) {
      if (b.col - (a.col + a.length - 1) - 1 <= 0) return true;
    }
    if (b.direction == ArrowDirection.right && a.direction == ArrowDirection.left &&
        b.row == a.row && b.col < a.col) {
      if (a.col - (b.col + b.length - 1) - 1 <= 0) return true;
    }
    // ↓ ↑ on same col
    if (a.direction == ArrowDirection.down && b.direction == ArrowDirection.up &&
        a.col == b.col && a.row < b.row) {
      if (b.row - (a.row + a.length - 1) - 1 <= 0) return true;
    }
    if (b.direction == ArrowDirection.down && a.direction == ArrowDirection.up &&
        b.col == a.col && b.row < a.row) {
      if (a.row - (b.row + b.length - 1) - 1 <= 0) return true;
    }
    return false;
  }

  // ── Circular dependency detection ──────────────────────────────────────

  static bool _hasCircularDependency(List<ArrowModel> arrows, int rows, int cols) {
    final adj = <String, Set<String>>{};
    for (final arrow in arrows) {
      adj[arrow.id] = <String>{};
    }
    for (final arrow in arrows) {
      final others = arrows.where((a) => a.id != arrow.id).toList();
      final blocker = _findBlocker(arrow, others, rows, cols);
      if (blocker != null) adj[arrow.id]!.add(blocker);
    }
    final visited = <String>{};
    final inStack = <String>{};
    bool hasCycle(String node) {
      if (inStack.contains(node)) return true;
      if (visited.contains(node)) return false;
      visited.add(node);
      inStack.add(node);
      for (final neighbor in adj[node] ?? <String>{}) {
        if (hasCycle(neighbor)) return true;
      }
      inStack.remove(node);
      return false;
    }
    for (final arrow in arrows) {
      if (hasCycle(arrow.id)) return true;
    }
    return false;
  }

  static String? _findBlocker(ArrowModel arrow, List<ArrowModel> others, int rows, int cols) {
    final occupancy = <String, String>{};
    for (final a in others) {
      for (final cell in a.occupiedCells) {
        occupancy['${cell.row},${cell.col}'] = a.id;
      }
    }
    var hr = arrow.head.row;
    var hc = arrow.head.col;
    final dr = arrow.direction.dr;
    final dc = arrow.direction.dc;
    for (int step = 0; step < rows + cols; step++) {
      hr += dr;
      hc += dc;
      if (hr < 0 || hr >= rows || hc < 0 || hc >= cols) return null;
      final blockerId = occupancy['$hr,$hc'];
      if (blockerId != null) return blockerId;
    }
    return null;
  }

  // ── Fallback ────────────────────────────────────────────────────────────

  LevelModel _fallback({required int levelId, required LevelConfig config, required String name}) {
    final arrows = <ArrowModel>[];
    int i = 0;
    for (int r = 0; r < config.gridSize && i < 6; r += 2) {
      arrows.add(ArrowModel(id: '${levelId}_F$i', row: r, col: 0, direction: ArrowDirection.right));
      i++;
    }
    return LevelModel(id: levelId, name: name, rows: config.gridSize, cols: config.gridSize,
      difficulty: config.difficulty, targetMoves: config.targetMoves, arrows: arrows);
  }
}
