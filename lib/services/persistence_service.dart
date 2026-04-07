import 'dart:developer' as dev;
import 'package:hive_flutter/hive_flutter.dart';
import '../models/habit.dart';

/// Centralized Hive persistence layer.
/// Stores ALL app state so full session restore works on restart.
/// All reads/writes are wrapped in try-catch for crash safety.
class PersistenceService {
  static const _settingsBox = 'settings';
  static const _habitsBox = 'habits';
  static const _statsBox = 'stats';
  static const _syncQueueBox = 'sync_queue';

  // ── Bootstrap ────────────────────────────────────────────────────────
  static Future<void> initialize() async {
    try {
      await Hive.initFlutter();
      await Hive.openBox(_settingsBox);
      await Hive.openBox(_habitsBox);
      await Hive.openBox(_statsBox);
      await Hive.openBox(_syncQueueBox);
    } catch (e) {
      dev.log('[PersistenceService] initialize failed: $e', name: 'Reset21');
    }
  }

  // ── First Launch Detection ───────────────────────────────────────────
  static bool isFirstLaunch() {
    try {
      return !Hive.box(_settingsBox).containsKey('initialized');
    } catch (e) {
      dev.log('[PersistenceService] isFirstLaunch failed: $e', name: 'Reset21');
      return true;
    }
  }

  static Future<void> markInitialized() async {
    try {
      await Hive.box(_settingsBox).put('initialized', true);
    } catch (e) {
      dev.log('[PersistenceService] markInitialized failed: $e', name: 'Reset21');
    }
  }

  // ── Day Session ──────────────────────────────────────────────────────
  static int getCurrentDay() {
    try {
      return Hive.box(_settingsBox).get('current_day', defaultValue: 1);
    } catch (e) {
      dev.log('[PersistenceService] getCurrentDay failed: $e', name: 'Reset21');
      return 1;
    }
  }

  static Future<void> setCurrentDay(int day) async {
    try {
      await Hive.box(_settingsBox).put('current_day', day);
    } catch (e) {
      dev.log('[PersistenceService] setCurrentDay failed: $e', name: 'Reset21');
    }
  }

  static String? getLastCompletedDate() {
    try {
      return Hive.box(_settingsBox).get('last_completed_date');
    } catch (e) {
      dev.log('[PersistenceService] getLastCompletedDate failed: $e', name: 'Reset21');
      return null;
    }
  }

  static Future<void> setLastCompletedDate(String isoDate) async {
    try {
      await Hive.box(_settingsBox).put('last_completed_date', isoDate);
    } catch (e) {
      dev.log('[PersistenceService] setLastCompletedDate failed: $e', name: 'Reset21');
    }
  }

  static bool getDayLocked() {
    try {
      return Hive.box(_settingsBox).get('day_locked', defaultValue: false);
    } catch (e) {
      dev.log('[PersistenceService] getDayLocked failed: $e', name: 'Reset21');
      return false;
    }
  }

  static Future<void> setDayLocked(bool locked) async {
    try {
      await Hive.box(_settingsBox).put('day_locked', locked);
    } catch (e) {
      dev.log('[PersistenceService] setDayLocked failed: $e', name: 'Reset21');
    }
  }

  // ── Last Synced Date (duplicate sync guard) ──────────────────────────
  static String? getLastSyncedDate() {
    try {
      return Hive.box(_settingsBox).get('last_synced_date');
    } catch (e) {
      dev.log('[PersistenceService] getLastSyncedDate failed: $e', name: 'Reset21');
      return null;
    }
  }

  static Future<void> setLastSyncedDate(String isoDate) async {
    try {
      await Hive.box(_settingsBox).put('last_synced_date', isoDate);
    } catch (e) {
      dev.log('[PersistenceService] setLastSyncedDate failed: $e', name: 'Reset21');
    }
  }

  // ── Habits ───────────────────────────────────────────────────────────
  static Future<void> saveHabits(List<Habit> habits) async {
    try {
      final box = Hive.box(_habitsBox);
      await box.put('daily_habits', habits.map((h) => h.toJson()).toList());
    } catch (e) {
      dev.log('[PersistenceService] saveHabits failed: $e', name: 'Reset21');
    }
  }

  static List<Habit> getHabits() {
    try {
      final box = Hive.box(_habitsBox);
      final data = box.get('daily_habits') as List<dynamic>?;
      if (data == null) return [];
      return data
          .map((json) => Habit.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      dev.log('[PersistenceService] getHabits failed: $e', name: 'Reset21');
      return [];
    }
  }

  // ── Stats (XP, Streak, Level) ────────────────────────────────────────
  static int getTotalXp() {
    try {
      return Hive.box(_statsBox).get('total_xp', defaultValue: 0);
    } catch (e) {
      dev.log('[PersistenceService] getTotalXp failed: $e', name: 'Reset21');
      return 0;
    }
  }

  static Future<void> setTotalXp(int xp) async {
    try {
      await Hive.box(_statsBox).put('total_xp', xp);
    } catch (e) {
      dev.log('[PersistenceService] setTotalXp failed: $e', name: 'Reset21');
    }
  }

  static int getStreak() {
    try {
      return Hive.box(_statsBox).get('streak', defaultValue: 0);
    } catch (e) {
      dev.log('[PersistenceService] getStreak failed: $e', name: 'Reset21');
      return 0;
    }
  }

  static Future<void> setStreak(int streak) async {
    try {
      await Hive.box(_statsBox).put('streak', streak);
    } catch (e) {
      dev.log('[PersistenceService] setStreak failed: $e', name: 'Reset21');
    }
  }

  static String getLevel() {
    try {
      return Hive.box(_statsBox).get('level', defaultValue: 'Beginner');
    } catch (e) {
      dev.log('[PersistenceService] getLevel failed: $e', name: 'Reset21');
      return 'Beginner';
    }
  }

  static Future<void> setLevel(String level) async {
    try {
      await Hive.box(_statsBox).put('level', level);
    } catch (e) {
      dev.log('[PersistenceService] setLevel failed: $e', name: 'Reset21');
    }
  }

  // ── Sync Queue ───────────────────────────────────────────────────────
  static Future<void> addToSyncQueue(Map<String, dynamic> payload) async {
    try {
      final box = Hive.box(_syncQueueBox);
      final queue = getSyncQueue();
      queue.add(payload);
      await box.put('queue', queue);
    } catch (e) {
      dev.log('[PersistenceService] addToSyncQueue failed: $e', name: 'Reset21');
    }
  }

  static List<Map<String, dynamic>> getSyncQueue() {
    try {
      final box = Hive.box(_syncQueueBox);
      final raw = box.get('queue') as List<dynamic>?;
      if (raw == null) return [];
      return raw.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      dev.log('[PersistenceService] getSyncQueue failed: $e', name: 'Reset21');
      return [];
    }
  }

  static Future<void> clearSyncQueue() async {
    try {
      await Hive.box(_syncQueueBox).put('queue', []);
    } catch (e) {
      dev.log('[PersistenceService] clearSyncQueue failed: $e', name: 'Reset21');
    }
  }

  static Future<void> setSyncQueue(List<Map<String, dynamic>> queue) async {
    try {
      await Hive.box(_syncQueueBox).put('queue', queue);
    } catch (e) {
      dev.log('[PersistenceService] setSyncQueue failed: $e', name: 'Reset21');
    }
  }

  // ── Paywall ──────────────────────────────────────────────────────────
  static bool getPaywallShown() {
    try {
      return Hive.box(_settingsBox).get('paywall_shown', defaultValue: false);
    } catch (e) {
      dev.log('[PersistenceService] getPaywallShown failed: $e', name: 'Reset21');
      return false;
    }
  }

  static Future<void> setPaywallShown(bool shown) async {
    try {
      await Hive.box(_settingsBox).put('paywall_shown', shown);
    } catch (e) {
      dev.log('[PersistenceService] setPaywallShown failed: $e', name: 'Reset21');
    }
  }
}
