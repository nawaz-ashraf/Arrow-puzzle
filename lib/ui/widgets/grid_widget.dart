import 'package:flutter/material.dart';
import '../../engine/game_controller.dart';
import '../../models/arrow_model.dart';
import '../app_theme.dart';

/// Renders the puzzle grid using GridView.builder with smooth animations.
class GridWidget extends StatelessWidget {
  final GameController controller;
  const GridWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final grid = controller.grid;
    final cs   = controller.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 4),
            child: _GridBadge(rows: grid.rows, cols: grid.cols, cs: cs),
          ),
        ),
        AspectRatio(
          aspectRatio: grid.cols / grid.rows,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: cs.primary.withValues(alpha: 0.30),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: grid.rows * grid.cols,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: grid.cols,
                ),
                itemBuilder: (context, index) {
                  final row = index ~/ grid.cols;
                  final col = index % grid.cols;
                  final arrow = grid.getArrowAt(row, col);

                  return _GridCell(
                    key: ValueKey('cell_${row}_$col'),
                    row: row,
                    col: col,
                    arrow: arrow,
                    controller: controller,
                    cs: cs,
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Animated grid cell ────────────────────────────────────────────────────────

class _GridCell extends StatefulWidget {
  final int row, col;
  final ArrowModel? arrow;
  final GameController controller;
  final AppColorScheme cs;

  const _GridCell({
    super.key,
    required this.row,
    required this.col,
    required this.arrow,
    required this.controller,
    required this.cs,
  });

  @override
  State<_GridCell> createState() => _GridCellState();
}

class _GridCellState extends State<_GridCell> {
  bool _isTapped = false;

  @override
  void didUpdateWidget(covariant _GridCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.arrow?.id != oldWidget.arrow?.id) _isTapped = false;
  }

  @override
  Widget build(BuildContext context) {
    final arrow = widget.arrow;
    final cs = widget.cs;
    final isHint = arrow != null && widget.controller.hintArrowId == arrow.id;
    final isBlocked = arrow != null && widget.controller.blockedArrowId == arrow.id;
    final hasPlayableArrow = arrow != null && !arrow.isBlocker;

    return GestureDetector(
      onTapDown: hasPlayableArrow
          ? (_) => setState(() => _isTapped = true) : null,
      onTapUp: hasPlayableArrow
          ? (_) => setState(() => _isTapped = false) : null,
      onTapCancel: hasPlayableArrow
          ? () => setState(() => _isTapped = false) : null,
      onTap: hasPlayableArrow
          ? () => widget.controller.onTap(widget.row, widget.col)
          : null,
      child: AnimatedScale(
        scale: _isTapped ? 0.85 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.all(3),
          transform: isBlocked
              ? Matrix4.translationValues(4, 0, 0)
              : Matrix4.identity(),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: isBlocked
                ? cs.errorColor.withValues(alpha: 0.18)
                : arrow == null
                    ? cs.surface.withValues(alpha: 0.5)
                    : isHint
                        ? cs.accent.withValues(alpha: 0.14)
                        : cs.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isBlocked
                  ? cs.errorColor.withValues(alpha: 0.70)
                  : arrow == null
                      ? cs.border.withValues(alpha: 0.40)
                      : isHint
                          ? cs.accent.withValues(alpha: 0.75)
                          : cs.primary.withValues(alpha: 0.40),
              width: isBlocked ? 2.0 : isHint ? 2.0 : 1.2,
            ),
            boxShadow: isBlocked
                ? [
                    BoxShadow(
                      color: cs.errorColor.withValues(alpha: 0.30),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : hasPlayableArrow
                    ? [
                        BoxShadow(
                          color: (isHint ? cs.accent : cs.primary)
                              .withValues(alpha: 0.18),
                          blurRadius: isHint ? 10 : 5,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: _buildContent(arrow, isHint, cs),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ArrowModel? arrow, bool isHint, AppColorScheme cs) {
    if (arrow == null) {
      return SizedBox.expand(key: const ValueKey('empty'));
    }

    // For multi-cell arrows, only show icon on anchor cell
    if (widget.row != arrow.row || widget.col != arrow.col) {
      return SizedBox.expand(key: ValueKey('body_${arrow.id}'));
    }

    final color = isHint ? cs.accent : cs.primary;
    return Center(
      key: ValueKey('arrow_${arrow.id}'),
      child: Transform.rotate(
        angle: arrow.direction.rotationAngle,
        child: Icon(Icons.arrow_upward_rounded, color: color, size: 26),
      ),
    );
  }
}

// ── Grid size badge ───────────────────────────────────────────────────────────

class _GridBadge extends StatelessWidget {
  final int rows, cols;
  final AppColorScheme cs;
  const _GridBadge({required this.rows, required this.cols, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
      ),
      child: Text('$rows×$cols',
          style: TextStyle(
              color: cs.primary, fontSize: 11,
              fontWeight: FontWeight.w700, letterSpacing: 1.0)),
    );
  }
}
