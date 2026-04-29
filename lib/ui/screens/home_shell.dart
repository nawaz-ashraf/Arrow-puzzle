import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../engine/game_controller.dart';
import '../app_theme.dart';
import 'main_menu_screen.dart';
import 'settings_screen.dart';
import '../level_select_screen.dart';
import '../game_screen.dart';

/// Root shell with Bottom Navigation Bar.
///
/// Tabs:
///   0 → Home (Main Menu)
///   1 → Levels (Level Select)
///   2 → Settings
///
/// Navigating into a game level pushes [GameScreen] on top of the shell.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tabIndex = 0;

  void _switchTab(int index) {
    setState(() => _tabIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, controller, _) {
        final cs = controller.colorScheme;

        // Status-bar style matches chapter brightness.
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: cs.brightness == Brightness.light
              ? Brightness.dark
              : Brightness.light,
        ));

        return Scaffold(
          backgroundColor: cs.background,
          body: IndexedStack(
            index: _tabIndex,
            children: [
              MainMenuScreen(onSwitchTab: _switchTab),
              LevelSelectScreen(
                onLevelSelected: (levelId) {
                  controller.loadLevel(levelId);
                  Navigator.push(
                    context,
                    _slideRoute(const GameScreen()),
                  );
                },
              ),
              const SettingsScreen(),
            ],
          ),
          bottomNavigationBar: _buildBottomNav(cs),
        );
      },
    );
  }

  Widget _buildBottomNav(AppColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.border, width: 1)),
        boxShadow: cs.brightness == Brightness.dark
            ? [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                )
              ]
            : null,
      ),
      child: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: _switchTab,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: cs.accent,
        unselectedItemColor: cs.textSecondary,
        selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.5),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            activeIcon: Icon(Icons.grid_view_rounded),
            label: 'Levels',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  PageRoute _slideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, a1, a2) => page,
      transitionsBuilder: (context, anim, a2, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
