import 'dart:developer' as dev;

/// Lightweight analytics tracker.
/// Logs key events to console. Swap implementation for Firebase/Mixpanel later.
class AnalyticsService {
  static void trackEvent(String name, [Map<String, dynamic>? params]) {
    dev.log(
      '[Analytics] $name ${params != null ? params.toString() : ''}',
      name: 'Reset21',
    );
  }

  static void dayLocked({required int day, required double score, required int xp}) {
    trackEvent('day_locked', {'day': day, 'score': score, 'xp': xp});
  }

  static void streakBroken({required int previousStreak, required int missedDays}) {
    trackEvent('streak_broken', {'previous_streak': previousStreak, 'missed_days': missedDays});
  }

  static void rewardSeen({required int day, required double score}) {
    trackEvent('reward_seen', {'day': day, 'score': score});
  }

  static void paywallTriggered({required int day}) {
    trackEvent('paywall_triggered', {'day': day});
  }
}
