import 'arrow_model.dart';

/// Manages the 2-D grid state.
///
/// Arrows are tracked in two structures:
/// 1. `arrows` — canonical list of all pieces.
/// 2. `_occupancy` — fast O(1) lookup: "which arrow occupies cell (r,c)?".
///
/// Multi-cell arrows register an entry for **every** cell they occupy.
class GridModel {
  final int rows;
  final int cols;

  /// All pieces (playable arrows + blockers).
  final List<ArrowModel> arrows;

  /// Cell-key → arrow that occupies it.
  final Map<String, ArrowModel> _occupancy;

  GridModel._({
    required this.rows,
    required this.cols,
    required this.arrows,
  }) : _occupancy = _buildOccupancy(arrows);

  factory GridModel.fromArrows({
    required int rows,
    required int cols,
    required List<ArrowModel> arrows,
  }) =>
      GridModel._(rows: rows, cols: cols, arrows: arrows);

  // ── Occupancy map ─────────────────────────────────────────────────────────

  static Map<String, ArrowModel> _buildOccupancy(List<ArrowModel> arrows) {
    final map = <String, ArrowModel>{};
    for (final a in arrows) {
      for (final cell in a.occupiedCells) {
        map['${cell.row},${cell.col}'] = a;
      }
    }
    return map;
  }

  static String _key(int r, int c) => '$r,$c';

  // ── Queries ───────────────────────────────────────────────────────────────

  bool inBounds(int r, int c) =>
      r >= 0 && r < rows && c >= 0 && c < cols;

  /// Returns the arrow (or blocker) that occupies cell (r,c), or null.
  ArrowModel? getArrowAt(int r, int c) => _occupancy[_key(r, c)];

  bool isCellOccupied(int r, int c) => _occupancy.containsKey(_key(r, c));

  List<ArrowModel> get playableArrows =>
      arrows.where((a) => !a.isBlocker).toList();

  List<ArrowModel> get blockers =>
      arrows.where((a) => a.isBlocker).toList();

  /// Level is won when **all playable arrows** have escaped.
  bool get isEmpty => playableArrows.isEmpty;

  // ── Mutations (return new GridModel — immutable pattern) ──────────────────

  /// Replace [old] with [updated] (same id).
  GridModel replaceArrow(ArrowModel old, ArrowModel updated) {
    final newArrows = [
      for (final a in arrows)
        if (a.id == old.id) updated else a,
    ];
    return GridModel._(rows: rows, cols: cols, arrows: newArrows);
  }

  /// Remove an arrow entirely (it escaped).
  GridModel removeArrow(ArrowModel arrow) {
    final newArrows = arrows.where((a) => a.id != arrow.id).toList();
    return GridModel._(rows: rows, cols: cols, arrows: newArrows);
  }

  // ── Legacy compat (used by hint system) ──────────────────────────────────
  bool hasArrow(int r, int c) => isCellOccupied(r, c);
  List<ArrowModel> get allArrows => arrows;
}
