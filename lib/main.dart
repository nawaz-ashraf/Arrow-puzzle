import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'engine/game_controller.dart';
import 'ui/app_theme.dart';
import 'ui/screens/home_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ArrowPuzzleApp());
}

class ArrowPuzzleApp extends StatelessWidget {
  const ArrowPuzzleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameController(),
      child: Consumer<GameController>(
        builder: (context, controller, _) {
          final cs = controller.colorScheme;
          return MaterialApp(
            title: 'Arrow Escape',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.materialTheme(cs),
            // HomeShell is the root — contains BottomNavigationBar.
            home: const HomeShell(),
          );
        },
      ),
    );
  }
}
