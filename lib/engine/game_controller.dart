import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/arrow_model.dart';
import '../models/grid_model.dart';
import '../models/level_model.dart';
import '../data/level_data.dart';
import '../data/level_generator.dart';
import '../engine/movement_engine.dart';
import '../ui/app_theme.dart';

enum GameStatus { idle, playing, animating, levelComplete }

/// Central state manager. Single source of truth for game state.
class GameController extends ChangeNotifier {
  static const int kTotalLevels = 40;

  final MovementEngine _engine = const MovementEngine();
  final LevelGenerator _generator = LevelGenerator();

  // ── Level pool ────────────────────────────────────────────────────────────
  late final List<LevelModel> _allLevels;

  // ── Progress ──────────────────────────────────────────────────────────────
  int _highestUnlocked = 1;
  final Map<int, int> _bestStars = {};

  // ── Session ───────────────────────────────────────────────────────────────
  late LevelModel _currentLevel;
  late GridModel _grid;
  GameStatus _status = GameStatus.idle;

  final List<GridModel> _undoStack = [];
  String? _hintArrowId;  // ID of the arrow the hint system highlights
  String? _blockedArrowId; // ID of arrow that was just blocked (shake feedback)

  bool _soundEnabled = true;
  int _moveCount = 0;

  // ── Getters ───────────────────────────────────────────────────────────────
  LevelModel get currentLevel  => _currentLevel;
  GridModel  get grid          => _grid;
  GameStatus get status        => _status;
  int        get moveCount     => _moveCount;
  bool       get soundEnabled  => _soundEnabled;
  String?    get hintArrowId   => _hintArrowId;
  String?    get blockedArrowId => _blockedArrowId;
  int        get highestUnlocked => _highestUnlocked;
  bool       get canUndo       => _undoStack.isNotEmpty;
  List<LevelModel> get allLevels => _allLevels;
  int        get targetMoves   => _currentLevel.targetMoves;

  AppColorScheme get colorScheme =>
      AppTheme.forChapter(_currentLevel.chapter);

  int get currentStarRating =>
      _status == GameStatus.levelComplete
          ? _currentLevel.starRating(_moveCount)
          : 0;

  int bestStars(int levelId) => _bestStars[levelId] ?? 0;

  GameController() {
    _allLevels = _buildPool();
    _loadProgress();
    _loadLevel(_allLevels.first);
  }

  // ── Pool ──────────────────────────────────────────────────────────────────

  List<LevelModel> _buildPool() {
    final pool = <LevelModel>[...LevelData.levels];
    for (int id = LevelData.levels.length + 1; id <= kTotalLevels; id++) {
      pool.add(_generator.generate(levelId: id));
    }
    return pool;
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    _highestUnlocked = prefs.getInt('highestUnlocked') ?? 1;
    for (final l in _allLevels) {
      final s = prefs.getInt('stars_${l.id}');
      if (s != null) _bestStars[l.id] = s;
    }
    notifyListeners();
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('highestUnlocked', _highestUnlocked);
    for (final e in _bestStars.entries) {
      await prefs.setInt('stars_${e.key}', e.value);
    }
  }

  Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _highestUnlocked = 1;
    _bestStars.clear();
    _loadLevel(_allLevels.first);
    notifyListeners();
  }

  // ── Level management ──────────────────────────────────────────────────────

  void loadLevel(int levelId) {
    final level = _allLevels.firstWhere(
      (l) => l.id == levelId,
      orElse: () => _allLevels.first,
    );
    _loadLevel(level);
  }

  void _loadLevel(LevelModel level) {
    _currentLevel = level;
    _grid = GridModel.fromArrows(
      rows: level.rows,
      cols: level.cols,
      arrows: level.freshArrows,
    );
    _status = GameStatus.playing;
    _undoStack.clear();
    _hintArrowId = null;
    _moveCount = 0;
    notifyListeners();
  }

  void restartLevel() => _loadLevel(_currentLevel);

  void nextLevel() {
    final idx = _allLevels.indexWhere((l) => l.id == _currentLevel.id);
    if (idx < _allLevels.length - 1) _loadLevel(_allLevels[idx + 1]);
  }

  // ── Gameplay ──────────────────────────────────────────────────────────────

  Future<void> onTap(int row, int col) async {
    if (_status != GameStatus.playing) return;
    final cell = _grid.getArrowAt(row, col);
    if (cell == null || cell.isBlocker) return;

    _hintArrowId = null;
    _undoStack.add(_grid);

    final result = _engine.processTap(_grid, row, col);
    if (!result.valid) {
      _undoStack.removeLast();
      // Show shake feedback for blocked arrow
      _blockedArrowId = cell.id;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 200));
      _blockedArrowId = null;
      notifyListeners();
      return;
    }

    _moveCount++;
    _status = GameStatus.animating;
    notifyListeners();

    for (final step in result.steps) {
      _grid = step;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 110));
    }

    if (result.levelComplete) {
      _status = GameStatus.levelComplete;
      final stars = _currentLevel.starRating(_moveCount);
      final existing = _bestStars[_currentLevel.id] ?? 0;
      if (stars > existing) _bestStars[_currentLevel.id] = stars;
      final nextId = _currentLevel.id + 1;
      if (nextId > _highestUnlocked && nextId <= kTotalLevels) {
        _highestUnlocked = nextId;
      }
      _saveProgress();
    } else {
      _status = GameStatus.playing;
    }
    notifyListeners();
  }

  // ── Undo ──────────────────────────────────────────────────────────────────

  void undo() {
    if (_status != GameStatus.playing || _undoStack.isEmpty) return;
    _grid = _undoStack.removeLast();
    _moveCount = (_moveCount - 1).clamp(0, 9999);
    notifyListeners();
  }

  // ── Hint ──────────────────────────────────────────────────────────────────

  void showHint() {
    if (_status != GameStatus.playing) return;
    _hintArrowId = null;
    for (final arrow in _grid.playableArrows) {
      if (_canEscape(arrow)) {
        _hintArrowId = arrow.id;
        break;
      }
    }
    _hintArrowId ??= _grid.playableArrows.isNotEmpty
        ? _grid.playableArrows.first.id
        : null;
    notifyListeners();
  }

  bool _canEscape(ArrowModel arrow) {
    // Check if arrow can reach the boundary without hitting anything
    var cur = arrow;
    for (int i = 0; i < 20; i++) {
      final fn = cur.frontNext;
      if (!_grid.inBounds(fn.row, fn.col)) return true;
      final occ = _grid.getArrowAt(fn.row, fn.col);
      if (occ != null) return false;
      cur = cur.movedOneStep();
    }
    return false;
  }

  // ── Sound ─────────────────────────────────────────────────────────────────

  void toggleSound() {
    _soundEnabled = !_soundEnabled;
    notifyListeners();
  }
}
