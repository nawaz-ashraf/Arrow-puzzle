import 'package:flutter/material.dart';
import '../app_theme.dart';

/// Callback to switch the HomeShell tab.
typedef TabSwitcher = void Function(int index);

/// Premium main menu screen.
///
/// Design: Stitch Core Palette — Soft White background, Deep Teal typography,
/// Energetic Orange primary action button, decorative geometric arrows.
class MainMenuScreen extends StatefulWidget {
  final TabSwitcher onSwitchTab;
  const MainMenuScreen({super.key, required this.onSwitchTab});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ac;
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _btnScale;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _titleFade = CurvedAnimation(parent: _ac, curve: const Interval(0, 0.6, curve: Curves.easeOut));
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ac, curve: const Interval(0, 0.6, curve: Curves.easeOut)));
    _btnScale = CurvedAnimation(parent: _ac, curve: const Interval(0.5, 1.0, curve: Curves.elasticOut));
    _ac.forward();
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const cs = AppTheme.softTactile;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [cs.background, cs.backgroundAlt],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // ── Decorative background arrows ─────────────────────────────
            ..._buildDecoArrows(cs),

            // ── Content ──────────────────────────────────────────────────
            Column(
              children: [
                const Spacer(flex: 2),

                // Title block
                SlideTransition(
                  position: _titleSlide,
                  child: FadeTransition(
                    opacity: _titleFade,
                    child: _buildTitleBlock(cs),
                  ),
                ),

                const Spacer(flex: 2),

                // Buttons
                ScaleTransition(
                  scale: _btnScale,
                  child: _buildButtons(context, cs),
                ),

                const Spacer(flex: 1),

                // Version
                FadeTransition(
                  opacity: _titleFade,
                  child: Text(
                    'v1.0 · Arrow Escape',
                    style: TextStyle(color: cs.textSecondary, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Title block ───────────────────────────────────────────────────────────

  Widget _buildTitleBlock(AppColorScheme cs) {
    return Column(
      children: [
        // Icon badge
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.30),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.arrow_upward_rounded,
              color: Colors.white, size: 48),
        ),
        const SizedBox(height: 24),

        // Game title
        Text(
          'ARROW',
          style: TextStyle(
            color: cs.primary,
            fontSize: 42,
            fontWeight: FontWeight.w900,
            letterSpacing: 6,
            height: 1.0,
          ),
        ),
        Text(
          'ESCAPE',
          style: TextStyle(
            color: cs.accent,
            fontSize: 42,
            fontWeight: FontWeight.w900,
            letterSpacing: 6,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Slide · Escape · Master',
          style: TextStyle(
            color: cs.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  // ── Buttons ───────────────────────────────────────────────────────────────

  Widget _buildButtons(BuildContext context, AppColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          // Primary: Play
          _MenuButton(
            label: 'PLAY',
            icon: Icons.play_arrow_rounded,
            isPrimary: true,
            cs: cs,
            onTap: () => widget.onSwitchTab(1), // go to Levels tab
          ),
          const SizedBox(height: 14),

          // Secondary row
          Row(
            children: [
              Expanded(
                child: _MenuButton(
                  label: 'LEVELS',
                  icon: Icons.grid_view_rounded,
                  isPrimary: false,
                  cs: cs,
                  onTap: () => widget.onSwitchTab(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MenuButton(
                  label: 'SETTINGS',
                  icon: Icons.settings_rounded,
                  isPrimary: false,
                  cs: cs,
                  onTap: () => widget.onSwitchTab(2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Decorative arrows ────────────────────────────────────────────────────

  List<Widget> _buildDecoArrows(AppColorScheme cs) {
    // (top, left, size, angle)
    const cfg = [
      [60.0,  20.0, 28.0,  1.57],
      [120.0, 30.0, 20.0,  0.0],
      [200.0, 40.0, 16.0,  3.14],
      [300.0, 50.0, 24.0, -1.57],
      [500.0, 30.0, 18.0,  0.0],
      [580.0, 20.0, 22.0,  1.57],
    ];
    return cfg.map((c) => Positioned(
      top: c[0],
      left: c[1],
      child: Transform.rotate(
        angle: c[3],
        child: Icon(
          Icons.arrow_upward_rounded,
          size: c[2],
          color: cs.primary.withValues(alpha: 0.08),
        ),
      ),
    )).toList();
  }
}

// ── Reusable menu button ─────────────────────────────────────────────────────

class _MenuButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final AppColorScheme cs;
  final VoidCallback onTap;

  const _MenuButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.cs,
    required this.onTap,
  });

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 80),
        lowerBound: 0.0, upperBound: 0.04);
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    final bg = widget.isPrimary ? cs.accent : cs.surface;
    final fg = widget.isPrimary ? Colors.white : cs.primary;
    final border = widget.isPrimary ? cs.accent : cs.border;

    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) {
        _press.reverse();
        widget.onTap();
      },
      onTapCancel: () => _press.reverse(),
      child: AnimatedBuilder(
        animation: _press,
        builder: (_, child) => Transform.scale(
          scale: 1.0 - _press.value,
          child: child,
        ),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
              vertical: widget.isPrimary ? 18 : 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 1.5),
            boxShadow: widget.isPrimary
                ? [
                    BoxShadow(
                      color: cs.accent.withValues(alpha: 0.30),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                    // Tactile 4px lip (design system spec)
                    BoxShadow(
                      color: const Color(0xFFCC6800),
                      blurRadius: 0,
                      offset: const Offset(0, 4),
                      spreadRadius: -2,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: fg, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: fg,
                  fontSize: widget.isPrimary ? 17 : 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
