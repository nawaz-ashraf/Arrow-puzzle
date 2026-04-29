import 'package:flutter/material.dart';
import '../../models/arrow_model.dart';
import '../app_theme.dart';

/// Visual tile for a single arrow piece.
///
/// Length-1 → centred rotating Icon.
/// Length 2+ → CustomPainter with shaft + filled triangular arrowhead.
///
/// The arrowhead is always drawn at the HEAD end:
///   RIGHT → right side of container
///   LEFT  → left side of container
///   DOWN  → bottom of container
///   UP    → top of container
class ArrowWidget extends StatefulWidget {
  final ArrowModel arrow;
  final bool isHint;
  final AppColorScheme colorScheme;

  const ArrowWidget({
    super.key,
    required this.arrow,
    required this.isHint,
    required this.colorScheme,
  });

  @override
  State<ArrowWidget> createState() => _ArrowWidgetState();
}

class _ArrowWidgetState extends State<ArrowWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulse;
  late AnimationController _tap;
  late Animation<double> _pulseAnim;
  late Animation<double> _tapAnim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.90, end: 1.0)
        .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));

    _tap = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 80),
        lowerBound: 0.0,
        upperBound: 0.1);
    _tapAnim = Tween<double>(begin: 1.0, end: 0.90).animate(_tap);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _tap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.arrow.isBlocker) return _buildBlocker();

    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _tap]),
      builder: (_, child) {
        final scale =
            (widget.isHint ? _pulseAnim.value : 1.0) * _tapAnim.value;
        return Transform.scale(scale: scale, child: child);
      },
      child: _buildArrow(),
    );
  }

  // ── Blocker tile ──────────────────────────────────────────────────────────

  Widget _buildBlocker() {
    final cs = widget.colorScheme;
    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: cs.blockerColor.withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(8),
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

  // ── Playable arrow ────────────────────────────────────────────────────────

  Widget _buildArrow() {
    final cs      = widget.colorScheme;
    final isHint  = widget.isHint;
    final color   = isHint ? cs.accent : cs.primary;
    final bgColor = isHint
        ? cs.accent.withValues(alpha: 0.14)
        : cs.primary.withValues(alpha: 0.12);
    final borderC = isHint
        ? cs.accent.withValues(alpha: 0.75)
        : cs.primary.withValues(alpha: 0.40);

    return GestureDetector(
      onTapDown: (_) => _tap.forward(),
      onTapUp:   (_) => _tap.reverse(),
      onTapCancel: ()  => _tap.reverse(),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderC, width: isHint ? 2.0 : 1.5),
          boxShadow: [
            BoxShadow(
              color: (isHint ? cs.accent : cs.primary).withValues(alpha: 0.18),
              blurRadius: isHint ? 12 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: widget.arrow.length == 1
            ? _iconArrow(color)
            : _paintedArrow(color),
      ),
    );
  }

  // ── Length-1: rotated icon ────────────────────────────────────────────────

  Widget _iconArrow(Color color) {
    return Center(
      child: Transform.rotate(
        angle: widget.arrow.direction.rotationAngle,
        child: Icon(Icons.arrow_upward_rounded, color: color, size: 28),
      ),
    );
  }

  // ── Length 2+: custom painter ─────────────────────────────────────────────

  Widget _paintedArrow(Color color) {
    return CustomPaint(
      painter: _ArrowBarPainter(direction: widget.arrow.direction, color: color),
    );
  }
}

// ── Arrow bar painter ─────────────────────────────────────────────────────────
//
// Draws a rounded shaft + filled triangular arrowhead.
//
// With the top-left convention:
//   RIGHT → head at RIGHT end of container  (headX = size.width)
//   LEFT  → head at LEFT  end of container  (headX = 0)
//   DOWN  → head at BOTTOM of container     (headY = size.height)
//   UP    → head at TOP    of container     (headY = 0)

class _ArrowBarPainter extends CustomPainter {
  final ArrowDirection direction;
  final Color color;
  const _ArrowBarPainter({required this.direction, required this.color});

  static const double _margin  = 10.0; // space from edge to shaft ends
  static const double _headLen = 13.0; // triangle base offset
  static const double _headW   = 9.0;  // half-width of triangle base

  @override
  void paint(Canvas canvas, Size size) {
    final shaft = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..strokeWidth = direction.isHorizontal
          ? size.height * 0.22
          : size.width  * 0.22
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final cx = size.width  / 2;
    final cy = size.height / 2;

    Offset shaftStart, shaftEnd, headTip;
    Path head;

    switch (direction) {
      case ArrowDirection.right:
        shaftStart = Offset(_margin, cy);
        shaftEnd   = Offset(size.width - _margin - _headLen, cy);
        headTip    = Offset(size.width - _margin, cy);
        head = Path()
          ..moveTo(headTip.dx, headTip.dy)
          ..lineTo(headTip.dx - _headLen, headTip.dy - _headW)
          ..lineTo(headTip.dx - _headLen, headTip.dy + _headW)
          ..close();
        break;

      case ArrowDirection.left:
        shaftStart = Offset(size.width - _margin, cy);
        shaftEnd   = Offset(_margin + _headLen, cy);
        headTip    = Offset(_margin, cy);
        head = Path()
          ..moveTo(headTip.dx, headTip.dy)
          ..lineTo(headTip.dx + _headLen, headTip.dy - _headW)
          ..lineTo(headTip.dx + _headLen, headTip.dy + _headW)
          ..close();
        break;

      case ArrowDirection.down:
        shaftStart = Offset(cx, _margin);
        shaftEnd   = Offset(cx, size.height - _margin - _headLen);
        headTip    = Offset(cx, size.height - _margin);
        head = Path()
          ..moveTo(headTip.dx, headTip.dy)
          ..lineTo(headTip.dx - _headW, headTip.dy - _headLen)
          ..lineTo(headTip.dx + _headW, headTip.dy - _headLen)
          ..close();
        break;

      case ArrowDirection.up:
        shaftStart = Offset(cx, size.height - _margin);
        shaftEnd   = Offset(cx, _margin + _headLen);
        headTip    = Offset(cx, _margin);
        head = Path()
          ..moveTo(headTip.dx, headTip.dy)
          ..lineTo(headTip.dx - _headW, headTip.dy + _headLen)
          ..lineTo(headTip.dx + _headW, headTip.dy + _headLen)
          ..close();
        break;
    }

    canvas.drawLine(shaftStart, shaftEnd, shaft);
    canvas.drawPath(head, fill);
  }

  @override
  bool shouldRepaint(covariant _ArrowBarPainter old) =>
      old.direction != direction || old.color != color;
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
