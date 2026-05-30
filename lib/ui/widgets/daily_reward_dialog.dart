import 'package:flutter/material.dart';
import '../../engine/game_controller.dart';
import '../app_theme.dart';

/// Shows daily reward popup when user hasn't claimed today's reward.
class DailyRewardDialog {
  DailyRewardDialog._();

  /// Call this from any screen on init to auto-show if unclaimed.
  /// Properly awaits service readiness before checking.
  static Future<void> checkAndShow(BuildContext context, GameController controller) async {
    // Wait for services to be fully loaded before checking
    if (!controller.dailyRewards.loaded) {
      // Services not ready yet — wait a bit and retry once
      await Future.delayed(const Duration(milliseconds: 500));
      if (!context.mounted) return;
      if (!controller.dailyRewards.loaded) return; // Still not loaded, bail
    }

    // Use the proper canClaimDailyReward() which double-checks persisted date
    final canClaim = await controller.dailyRewards.canClaimDailyReward();
    if (!canClaim) return;

    final result = await controller.dailyRewards.claimDailyReward();
    if (result == null) return;

    controller.refreshUI(); // Update hint count in UI

    if (!context.mounted) return;

    final (hintsAwarded, isStreakBonus) = result;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DailyRewardContent(
        hintsAwarded: hintsAwarded,
        isStreakBonus: isStreakBonus,
        streak: controller.streak,
        cs: controller.colorScheme,
      ),
    );
  }
}

class _DailyRewardContent extends StatelessWidget {
  final int hintsAwarded;
  final bool isStreakBonus;
  final int streak;
  final AppColorScheme cs;

  const _DailyRewardContent({
    required this.hintsAwarded,
    required this.isStreakBonus,
    required this.streak,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎁', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'Daily Reward!',
            style: TextStyle(
              color: cs.accent,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '+$hintsAwarded Free Hint${hintsAwarded > 1 ? 's' : ''}',
            style: TextStyle(
              color: cs.primary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (isStreakBonus)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: cs.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cs.accent.withValues(alpha: 0.30)),
              ),
              child: Text(
                '🔥 $streak-day streak bonus!',
                style: TextStyle(
                  color: cs.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const SizedBox(height: 6),
          Text(
            'Come back tomorrow for more!',
            style: TextStyle(color: cs.textSecondary, fontSize: 12),
          ),
        ],
      ),
      actions: [
        Center(
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Collect', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }
}
