import 'package:flutter/material.dart';
import '../../engine/game_controller.dart';
import '../../models/arrow_model.dart';
import '../app_theme.dart';

/// Renders the puzzle grid using a Stack-based layout.
///
/// Empty cells are drawn via a GridView background layer.
/// Arrows are positioned as unified widgets in a Stack overlay,
/// so multi-cell arrows render as a single connected piece.
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cellW = constraints.maxWidth / grid.cols;
                  final cellH = constraints.maxHeight / grid.rows;

                  return Stack(
                    children: [
                      // Background: empty cell grid
                      _buildCellBackground(grid.rows, grid.cols, cellW, cellH, cs),

                      // Foreground: arrows as unified positioned widgets
                      ...grid.arrows.map((arrow) => _PositionedArrow(
                        key: ValueKey('arrow_${arrow.id}'),
                        arrow: arrow,
                        cellW: cellW,
                        cellH: cellH,
                        controller: controller,
                        cs: cs,
                      )),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Draws the background grid cells (empty tiles).
  Widget _buildCellBackground(int rows, int cols, double cellW, double cellH, AppColorScheme cs) {
    return Stack(
      children: [
        for (int r = 0; r < rows; r++)
          for (int c = 0; c < cols; c++)
            Positioned(
              left: c * cellW,
              top: r * cellH,
              width: cellW,
              height: cellH,
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: cs.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: cs.border.withValues(alpha: 0.40),
                    width: 1.2,
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

// ── Positioned arrow: single connected piece ──────────────────────────────────

class _PositionedArrow extends StatefulWidget {
  final ArrowModel arrow;
  final double cellW, cellH;
  final GameController controller;
  final AppColorScheme cs;

  const _PositionedArrow({
    super.key,
    required this.arrow,
    required this.cellW,
    required this.cellH,
    required this.controller,
    required this.cs,
  });

  @override
  State<_PositionedArrow> createState() => _PositionedArrowState();
}

class _PositionedArrowState extends State<_PositionedArrow>
    with TickerProviderStateMixin {
  bool _isTapped = false;
  late AnimationController _pulse;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.0)
        .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final arrow = widget.arrow;
    final cs = widget.cs;
    final cellW = widget.cellW;
    final cellH = widget.cellH;

    // Calculate positioned rect
    final left = arrow.col * cellW;
    final top = arrow.row * cellH;
    final width = arrow.direction.isHorizontal ? cellW * arrow.length : cellW;
    final height = arrow.direction.isVertical ? cellH * arrow.length : cellH;

    final isHint = widget.controller.hintArrowId == arrow.id;
    final isBlocked = widget.controller.blockedArrowId == arrow.id;
    final isPlayable = !arrow.isBlocker;

    return AnimatedPositioned(
      key: ValueKey('pos_${arrow.id}'),
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        onTapDown: isPlayable
            ? (_) => setState(() => _isTapped = true) : null,
        onTapUp: isPlayable
            ? (_) => setState(() => _isTapped = false) : null,
        onTapCancel: isPlayable
            ? () => setState(() => _isTapped = false) : null,
        onTap: isPlayable
            ? () => widget.controller.onTap(arrow.row, arrow.col)
            : null,
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (_, child) {
            final scale = _isTapped
                ? 0.90
                : isHint
                    ? _pulseAnim.value
                    : 1.0;
            return Transform.scale(scale: scale, child: child);
          },
          child: arrow.isBlocker
              ? _BlockerPiece(arrow: arrow, cs: cs)
              : _ArrowPiece(
                  arrow: arrow,
                  isHint: isHint,
                  isBlocked: isBlocked,
                  cs: cs,
                ),
        ),
      ),
    );
  }
}

// ── Unified arrow piece (single or multi-cell) ───────────────────────────────

class _ArrowPiece extends StatelessWidget {
  final ArrowModel arrow;
  final bool isHint;
  final bool isBlocked;
  final AppColorScheme cs;

  const _ArrowPiece({
    required this.arrow,
    required this.isHint,
    required this.isBlocked,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final color   = isHint ? cs.accent : cs.primary;
    final bgColor = isBlocked
        ? cs.errorColor.withValues(alpha: 0.18)
        : isHint
            ? cs.accent.withValues(alpha: 0.14)
            : cs.primary.withValues(alpha: 0.12);
    final borderC = isBlocked
        ? cs.errorColor.withValues(alpha: 0.70)
        : isHint
            ? cs.accent.withValues(alpha: 0.75)
            : cs.primary.withValues(alpha: 0.40);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.all(3),
      transform: isBlocked
          ? Matrix4.translationValues(4, 0, 0)
          : Matrix4.identity(),
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderC,
          width: isBlocked ? 2.0 : isHint ? 2.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isBlocked ? cs.errorColor : color).withValues(alpha: 0.22),
            blurRadius: isHint ? 14 : isBlocked ? 10 : 6,
            spreadRadius: isHint ? 2 : 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _UnifiedArrowPainter(
          direction: arrow.direction,
          length: arrow.length,
          color: color,
          glowColor: color.withValues(alpha: 0.30),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

// ── Blocker piece ─────────────────────────────────────────────────────────────

class _BlockerPiece extends StatelessWidget {
  final ArrowModel arrow;
  final AppColorScheme cs;
  const _BlockerPiece({required this.arrow, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: cs.blockerColor.withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.blockerColor, width: 1.5),
      ),
      child: Center(
        child: CustomPaint(
          size: const Size(18, 18),
          painter: _XPainter(color: cs.textSecondary),
        ),
      ),
    );
  }
}

// ── Unified arrow painter ─────────────────────────────────────────────────────
//
// Draws a single connected arrow piece that spans the full widget:
// - Rounded neon-glowing body (capsule shape)
// - Shaft line from tail to near the head
// - Filled triangular arrowhead at the head end
// - Neon glow effect via shadow layer
//
// Works for both length-1 and length-2+ arrows.

class _UnifiedArrowPainter extends CustomPainter {
  final ArrowDirection direction;
  final int length;
  final Color color;
  final Color glowColor;

  const _UnifiedArrowPainter({
    required this.direction,
    required this.length,
    required this.color,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (length == 1) {
      _paintSingleCell(canvas, size);
    } else {
      _paintMultiCell(canvas, size);
    }
  }

  // ── Single-cell arrow: centered icon-style arrow ──────────────────────────

  void _paintSingleCell(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.shortestSide * 0.30;

    // Neon glow circle
    final glowPaint = Paint()
      ..color = glowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(cx, cy), radius * 0.6, glowPaint);

    // Arrow triangle
    final headSize = radius * 0.85;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    switch (direction) {
      case ArrowDirection.up:
        path.moveTo(cx, cy - headSize);
        path.lineTo(cx - headSize * 0.7, cy + headSize * 0.4);
        path.lineTo(cx + headSize * 0.7, cy + headSize * 0.4);
        break;
      case ArrowDirection.down:
        path.moveTo(cx, cy + headSize);
        path.lineTo(cx - headSize * 0.7, cy - headSize * 0.4);
        path.lineTo(cx + headSize * 0.7, cy - headSize * 0.4);
        break;
      case ArrowDirection.left:
        path.moveTo(cx - headSize, cy);
        path.lineTo(cx + headSize * 0.4, cy - headSize * 0.7);
        path.lineTo(cx + headSize * 0.4, cy + headSize * 0.7);
        break;
      case ArrowDirection.right:
        path.moveTo(cx + headSize, cy);
        path.lineTo(cx - headSize * 0.4, cy - headSize * 0.7);
        path.lineTo(cx - headSize * 0.4, cy + headSize * 0.7);
        break;
    }
    path.close();
    canvas.drawPath(path, fill);
  }

  // ── Multi-cell arrow: connected shaft + arrowhead ─────────────────────────

  void _paintMultiCell(Canvas canvas, Size size) {
    final isH = direction.isHorizontal;
    final margin = 6.0;
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Shaft dimensions
    final shaftThickness = isH ? size.height * 0.28 : size.width * 0.28;
    final headLen = isH ? size.width * 0.08 : size.height * 0.08;
    final headW = shaftThickness * 1.3;

    // Neon glow under the shaft
    final glowPaint = Paint()
      ..color = glowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Shaft paint
    final shaftPaint = Paint()
      ..color = color.withValues(alpha: 0.65)
      ..strokeWidth = shaftThickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Head paint
    final headPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    Offset shaftStart, shaftEnd, headTip;
    Path head;

    switch (direction) {
      case ArrowDirection.right:
        shaftStart = Offset(margin + shaftThickness / 2, cy);
        shaftEnd   = Offset(size.width - margin - headLen - 2, cy);
        headTip    = Offset(size.width - margin, cy);
        head = Path()
          ..moveTo(headTip.dx, headTip.dy)
          ..lineTo(headTip.dx - headLen * 1.5, headTip.dy - headW / 2)
          ..lineTo(headTip.dx - headLen * 1.5, headTip.dy + headW / 2)
          ..close();
        // Glow line
        canvas.drawLine(shaftStart, shaftEnd, glowPaint..strokeWidth = shaftThickness + 4);
        break;

      case ArrowDirection.left:
        shaftStart = Offset(size.width - margin - shaftThickness / 2, cy);
        shaftEnd   = Offset(margin + headLen + 2, cy);
        headTip    = Offset(margin, cy);
        head = Path()
          ..moveTo(headTip.dx, headTip.dy)
          ..lineTo(headTip.dx + headLen * 1.5, headTip.dy - headW / 2)
          ..lineTo(headTip.dx + headLen * 1.5, headTip.dy + headW / 2)
          ..close();
        canvas.drawLine(shaftStart, shaftEnd, glowPaint..strokeWidth = shaftThickness + 4);
        break;

      case ArrowDirection.down:
        shaftStart = Offset(cx, margin + shaftThickness / 2);
        shaftEnd   = Offset(cx, size.height - margin - headLen - 2);
        headTip    = Offset(cx, size.height - margin);
        head = Path()
          ..moveTo(headTip.dx, headTip.dy)
          ..lineTo(headTip.dx - headW / 2, headTip.dy - headLen * 1.5)
          ..lineTo(headTip.dx + headW / 2, headTip.dy - headLen * 1.5)
          ..close();
        canvas.drawLine(shaftStart, shaftEnd, glowPaint..strokeWidth = shaftThickness + 4);
        break;

      case ArrowDirection.up:
        shaftStart = Offset(cx, size.height - margin - shaftThickness / 2);
        shaftEnd   = Offset(cx, margin + headLen + 2);
        headTip    = Offset(cx, margin);
        head = Path()
          ..moveTo(headTip.dx, headTip.dy)
          ..lineTo(headTip.dx - headW / 2, headTip.dy + headLen * 1.5)
          ..lineTo(headTip.dx + headW / 2, headTip.dy + headLen * 1.5)
          ..close();
        canvas.drawLine(shaftStart, shaftEnd, glowPaint..strokeWidth = shaftThickness + 4);
        break;
    }

    // Draw shaft
    canvas.drawLine(shaftStart, shaftEnd, shaftPaint);

    // Draw arrowhead glow
    canvas.drawPath(head, Paint()
      ..color = glowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));

    // Draw arrowhead
    canvas.drawPath(head, headPaint);

    // Draw decorative dots along the shaft (visual flair)
    _drawShaftDots(canvas, shaftStart, shaftEnd, shaftThickness);
  }

  /// Draws subtle dot accents along the shaft for visual richness.
  void _drawShaftDots(Canvas canvas, Offset start, Offset end, double thickness) {
    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.30)
      ..style = PaintingStyle.fill;
    final dotRadius = thickness * 0.12;

    // Place 2 dots along the shaft
    for (int i = 1; i <= 2; i++) {
      final t = i / 3;
      final dot = Offset(
        start.dx + (end.dx - start.dx) * t,
        start.dy + (end.dy - start.dy) * t,
      );
      canvas.drawCircle(dot, dotRadius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _UnifiedArrowPainter old) =>
      old.direction != direction || old.color != color ||
      old.length != length || old.glowColor != glowColor;
}

// ── Blocker X painter ─────────────────────────────────────────────────────────

class _XPainter extends CustomPainter {
  final Color color;
  const _XPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset.zero, Offset(size.width, size.height), p);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), p);
  }

  @override
  bool shouldRepaint(covariant _XPainter old) => old.color != color;
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
