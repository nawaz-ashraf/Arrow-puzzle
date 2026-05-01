import 'package:shared_preferences/shared_preferences.dart';

/// Manages daily rewards and streak bonuses.
///
/// - 1 free hint given daily on first app open
/// - Streak bonus: extra hint after 3 consecutive days
class DailyRewardService {
  static const _keyLastClaimDate = 'daily_reward_last_claim';
  static const _keyStreak = 'daily_reward_streak';
  static const _keyFreeHints = 'free_hints';
  static const int kInitialFreeHints = 3;

  int _freeHints = kInitialFreeHints;
  int _streak = 0;
  bool _claimedToday = false;

  int get freeHints => _freeHints;
  int get streak => _streak;
  bool get claimedToday => _claimedToday;

  // ── Load / Save ─────────────────────────────────────────────────────────

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _freeHints = prefs.getInt(_keyFreeHints) ?? kInitialFreeHints;
    _streak = prefs.getInt(_keyStreak) ?? 0;

    final lastClaim = prefs.getString(_keyLastClaimDate);
    final today = _todayKey();

    if (lastClaim == today) {
      _claimedToday = true;
    } else {
      _claimedToday = false;
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyFreeHints, _freeHints);
    await prefs.setInt(_keyStreak, _streak);
  }

  // ── Daily Claim ─────────────────────────────────────────────────────────

  /// Returns (hintsAwarded, isStreakBonus) or null if already claimed.
  Future<(int, bool)?> claimDailyReward() async {
    if (_claimedToday) return null;

    final prefs = await SharedPreferences.getInstance();
    final lastClaim = prefs.getString(_keyLastClaimDate);
    final today = _todayKey();
    final yesterday = _dateKey(DateTime.now().subtract(const Duration(days: 1)));

    // Update streak
    if (lastClaim == yesterday) {
      _streak++;
    } else {
      _streak = 1;
    }

    // Base reward: 1 hint
    int reward = 1;
    bool isStreakBonus = false;

    // Streak bonus: every 3 consecutive days → extra hint
    if (_streak > 0 && _streak % 3 == 0) {
      reward += 1;
      isStreakBonus = true;
    }

    _freeHints += reward;
    _claimedToday = true;

    await prefs.setString(_keyLastClaimDate, today);
    await _save();

    return (reward, isStreakBonus);
  }

  // ── Hint Usage ──────────────────────────────────────────────────────────

  bool get hasHints => _freeHints > 0;

  /// Uses one free hint. Returns true if successful.
  Future<bool> useHint() async {
    if (_freeHints <= 0) return false;
    _freeHints--;
    await _save();
    return true;
  }

  /// Grants hints (e.g. from rewarded ad).
  Future<void> addHints(int count) async {
    _freeHints += count;
    await _save();
  }

  // ── Date helpers ────────────────────────────────────────────────────────

  String _todayKey() => _dateKey(DateTime.now());
  String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
}
