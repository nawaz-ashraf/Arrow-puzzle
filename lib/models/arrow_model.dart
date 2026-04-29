import 'dart:math';

enum ArrowDirection { up, down, left, right }

extension ArrowDirectionExt on ArrowDirection {
  bool get isHorizontal => this == ArrowDirection.left || this == ArrowDirection.right;
  bool get isVertical   => this == ArrowDirection.up   || this == ArrowDirection.down;

  int get dr {
    switch (this) {
      case ArrowDirection.up:    return -1;
      case ArrowDirection.down:  return  1;
      case ArrowDirection.left:
      case ArrowDirection.right: return  0;
    }
  }

  int get dc {
    switch (this) {
      case ArrowDirection.left:  return -1;
      case ArrowDirection.right: return  1;
      case ArrowDirection.up:
      case ArrowDirection.down:  return  0;
    }
  }

  double get rotationAngle {
    switch (this) {
      case ArrowDirection.up:    return 0;
      case ArrowDirection.right: return pi / 2;
      case ArrowDirection.down:  return pi;
      case ArrowDirection.left:  return -pi / 2;
    }
  }

  String get symbol {
    switch (this) {
      case ArrowDirection.up:    return 'U';
      case ArrowDirection.down:  return 'D';
      case ArrowDirection.left:  return 'L';
      case ArrowDirection.right: return 'R';
    }
  }
}

enum ArrowState { idle, moving, escaped }

/// Arrow piece.
///
/// **Coordinate convention — `row` / `col` is always the TOP-LEFT corner
/// of the arrow's bounding box**, regardless of direction.
///
/// - RIGHT at (r,c) length 2 → occupies (r,c) and (r,c+1). Head = (r,c+1).
/// - LEFT  at (r,c) length 2 → occupies (r,c) and (r,c+1). Head = (r,c).
/// - DOWN  at (r,c) length 2 → occupies (r,c) and (r+1,c). Head = (r+1,c).
/// - UP    at (r,c) length 2 → occupies (r,c) and (r+1,c). Head = (r,c).
class ArrowModel {
  final String id;
  final int row; // top-left row of bounding box
  final int col; // top-left col of bounding box
  final int length;
  final ArrowDirection direction;
  final ArrowState state;
  final bool isBlocker;

  const ArrowModel({
    required this.id,
    required this.row,
    required this.col,
    required this.direction,
    this.length = 1,
    this.state = ArrowState.idle,
    this.isBlocker = false,
  });

  // ── Geometry ──────────────────────────────────────────────────────────────

  /// Every grid cell this arrow occupies.
  List<({int row, int col})> get occupiedCells {
    if (direction.isHorizontal) {
      return List.generate(length, (i) => (row: row, col: col + i));
    } else {
      return List.generate(length, (i) => (row: row + i, col: col));
    }
  }

  /// The leading (head) cell — the end closest to where the arrow moves.
  ({int row, int col}) get head {
    switch (direction) {
      case ArrowDirection.right: return (row: row, col: col + length - 1);
      case ArrowDirection.left:  return (row: row, col: col);          // leftmost
      case ArrowDirection.down:  return (row: row + length - 1, col: col);
      case ArrowDirection.up:    return (row: row, col: col);          // topmost
    }
  }

  /// The cell directly in front of the head — used for collision/escape.
  ({int row, int col}) get frontNext =>
      (row: head.row + direction.dr, col: head.col + direction.dc);

  // ── Rendering helpers (always == row/col with top-left convention) ─────────

  int get visualTopRow  => row;
  int get visualLeftCol => col;
  int get visualRows    => direction.isVertical   ? length : 1;
  int get visualCols    => direction.isHorizontal ? length : 1;

  // ── Movement ──────────────────────────────────────────────────────────────

  /// Returns a copy moved exactly one step in its direction.
  ArrowModel movedOneStep() {
    switch (direction) {
      case ArrowDirection.right: return copyWith(col: col + 1);
      case ArrowDirection.left:  return copyWith(col: col - 1);
      case ArrowDirection.down:  return copyWith(row: row + 1);
      case ArrowDirection.up:    return copyWith(row: row - 1);
    }
  }

  ArrowModel copyWith({
    String? id, int? row, int? col, int? length,
    ArrowDirection? direction, ArrowState? state, bool? isBlocker,
  }) =>
      ArrowModel(
        id: id ?? this.id,
        row: row ?? this.row,
        col: col ?? this.col,
        length: length ?? this.length,
        direction: direction ?? this.direction,
        state: state ?? this.state,
        isBlocker: isBlocker ?? this.isBlocker,
      );

  @override
  String toString() =>
      'Arrow[$id](${direction.symbol}×$length @[$row,$col])';
}
