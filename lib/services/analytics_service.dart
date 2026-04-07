import 'dart:developer' as dev;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database_service.dart';

/// Lightweight analytics tracker.
/// Logs key events to console and Supabase.
class AnalyticsService {
  static void trackEvent(String name, [Map<String, dynamic>? params]) {
    dev.log(
      '[Analytics] $name ${params != null ? params.toString() : ''}',
      name: 'Reset21',
    );

    // TASK: Persist to Supabase
    _persistEvent(name, params);
  }

  static Future<void> _persistEvent(String name, Map<String, dynamic>? params) async {
    try {
      if (!DatabaseService.isSupabaseReady) return;
      
      final userId = DatabaseService.currentUserId;
      if (userId == null) return;

      await Supabase.instance.client.from('analytics_events').insert({
        'user_id': userId,
        'event_name': name,
        'payload': params ?? {},
      });
    } catch (e) {
      dev.log('[Analytics] persistence failed: $e', name: 'Reset21');
    }
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
