import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arrow_puzzle/services/daily_reward_service.dart';

void main() {
  group('DailyRewardService', () {
    setUp(() {
      // Reset SharedPreferences for each test
      SharedPreferences.setMockInitialValues({});
    });

    test('Daily reward can be claimed once per day', () async {
      final service = DailyRewardService();
      await service.load();

      // First claim should succeed
      final result1 = await service.claimDailyReward();
      expect(result1, isNotNull, reason: 'First claim should succeed');
      expect(result1!.$1, greaterThanOrEqualTo(1)); // At least 1 hint

      // Second claim same day should fail
      final result2 = await service.claimDailyReward();
      expect(result2, isNull, reason: 'Second claim same day should return null');
    });

    test('canClaimDailyReward returns false after claim', () async {
      final service = DailyRewardService();
      await service.load();

      // Before claiming
      final canClaimBefore = await service.canClaimDailyReward();
      expect(canClaimBefore, isTrue);

      // Claim
      await service.claimDailyReward();

      // After claiming
      final canClaimAfter = await service.canClaimDailyReward();
      expect(canClaimAfter, isFalse);
    });

    test('App restart does not reset reward (persisted via SharedPreferences)', () async {
      final service1 = DailyRewardService();
      await service1.load();

      // Claim reward
      final result = await service1.claimDailyReward();
      expect(result, isNotNull);

      // Simulate app restart: create new service instance, reload from prefs
      final service2 = DailyRewardService();
      await service2.load();

      // Should already be claimed
      expect(service2.claimedToday, isTrue);
      final result2 = await service2.claimDailyReward();
      expect(result2, isNull, reason: 'Restart should not allow re-claim');
    });

    test('Date format is zero-padded yyyy-MM-dd', () async {
      final service = DailyRewardService();
      await service.load();

      // Claim to store date
      await service.claimDailyReward();

      // Read back the stored date
      final prefs = await SharedPreferences.getInstance();
      final storedDate = prefs.getString('daily_reward_last_claim');

      expect(storedDate, isNotNull);
      // Verify format: yyyy-MM-dd with zero padding
      final parts = storedDate!.split('-');
      expect(parts.length, 3);
      expect(parts[0].length, 4, reason: 'Year should be 4 digits');
      expect(parts[1].length, 2, reason: 'Month should be zero-padded to 2 digits');
      expect(parts[2].length, 2, reason: 'Day should be zero-padded to 2 digits');
    });

    test('Streak increments on consecutive days', () async {
      // Day 1
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final yesterdayKey =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      // Pre-set yesterday's claim
      SharedPreferences.setMockInitialValues({
        'daily_reward_last_claim': yesterdayKey,
        'daily_reward_streak': 2,
        'free_hints': 5,
      });

      final service = DailyRewardService();
      await service.load();

      // Should be able to claim today
      expect(service.claimedToday, isFalse);
      final result = await service.claimDailyReward();
      expect(result, isNotNull);

      // Streak should have incremented from 2 to 3
      expect(service.streak, 3);
    });

    test('Streak resets after gap day', () async {
      // Set last claim to 2 days ago (gap)
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      final twoDaysAgoKey =
          '${twoDaysAgo.year}-${twoDaysAgo.month.toString().padLeft(2, '0')}-${twoDaysAgo.day.toString().padLeft(2, '0')}';

      SharedPreferences.setMockInitialValues({
        'daily_reward_last_claim': twoDaysAgoKey,
        'daily_reward_streak': 5,
        'free_hints': 5,
      });

      final service = DailyRewardService();
      await service.load();
      await service.claimDailyReward();

      // Streak should reset to 1
      expect(service.streak, 1);
    });

    test('Hints accumulate correctly', () async {
      SharedPreferences.setMockInitialValues({
        'free_hints': 2,
      });

      final service = DailyRewardService();
      await service.load();

      expect(service.freeHints, 2);

      // Claim daily reward (+1 hint)
      await service.claimDailyReward();
      expect(service.freeHints, 3);

      // Use a hint
      final used = await service.useHint();
      expect(used, isTrue);
      expect(service.freeHints, 2);
    });

    test('Load guard prevents claim before load', () async {
      final service = DailyRewardService();
      // Don't call load() first — claimDailyReward should auto-load

      final result = await service.claimDailyReward();
      expect(result, isNotNull, reason: 'Should auto-load and then claim');
      expect(service.loaded, isTrue);
    });
  });
}
