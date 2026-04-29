import '../models/grid_model.dart';

/// Result of a single tap/move operation.
class MoveResult {
  /// Ordered grid snapshots to drive step-by-step animation.
  final List<GridModel> steps;
  final bool levelComplete;
  final bool valid;

  const MoveResult({
    required this.steps,
    required this.levelComplete,
    required this.valid,
  });

  static const invalid = MoveResult(steps: [], levelComplete: false, valid: false);
}

/// Core movement engine — clean, predictable, step-by-step.
///
/// **Rules:**
/// 1. Tapped cell → find the arrow occupying it.
/// 2. Arrow moves one cell at a time in its direction.
/// 3. If the cell in front of its **head** is occupied by a DIFFERENT piece → **STOP**.
///    No chain reactions.
/// 4. If the cell in front of the head is outside the grid → **escape** (remove).
/// 5. Tap counts as a move only if the arrow actually moved (steps > 0).
/// 6. Level complete when every playable arrow has escaped.
class MovementEngine {
  const MovementEngine();

  MoveResult processTap(GridModel grid, int row, int col) {
    final arrow = grid.getArrowAt(row, col);
    if (arrow == null || arrow.isBlocker) return MoveResult.invalid;

    final steps = <GridModel>[];
    var current = grid;
    var cur = arrow;

    for (int safety = 0; safety < 100; safety++) {
      final next = cur.frontNext;

      // ── Out of bounds: arrow escapes ───────────────────────────────────
      if (!current.inBounds(next.row, next.col)) {
        current = current.removeArrow(cur);
        steps.add(current);
        break;
      }

      // ── Check for obstacle (another arrow or blocker) ──────────────────
      final occupant = current.getArrowAt(next.row, next.col);
      // CRITICAL FIX: ignore self! A multi-cell arrow's frontNext might
      // overlap with its own body during occupancy lookup. Only block on
      // a DIFFERENT piece.
      if (occupant != null && occupant.id != cur.id) {
        break;
      }

      // ── Empty cell: advance one step ───────────────────────────────────
      final moved = cur.movedOneStep();
      current = current.replaceArrow(cur, moved);
      cur = moved;
      steps.add(current);
    }

    // If nothing moved (immediately blocked), treat as invalid tap.
    if (steps.isEmpty) return MoveResult.invalid;

    return MoveResult(
      steps: steps,
      levelComplete: current.isEmpty,
      valid: true,
    );
  }
}
