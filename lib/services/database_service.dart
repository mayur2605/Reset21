import 'dart:developer' as dev;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/habit.dart';
import 'persistence_service.dart';
import 'sync_queue_service.dart';

class DatabaseService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    // Initialize Hive persistence first
    await PersistenceService.initialize();

    // Initialize Supabase
    try {
      await Supabase.initialize(
        url: 'YOUR_SUPABASE_URL',
        anonKey: 'YOUR_SUPABASE_ANON_KEY',
      );
      _initialized = true;
      SyncQueueService.markSupabaseReady();

      // Drain any queued payloads from previous sessions
      await SyncQueueService.drainQueue();
    } catch (e) {
      // Supabase not configured – app works fully offline
      dev.log('[DatabaseService] Supabase init failed (offline mode): $e', name: 'Reset21');
      _initialized = false;
    }

    // Start listening for connectivity changes
    try {
      SyncQueueService.listenForConnectivity();
    } catch (e) {
      dev.log('[DatabaseService] connectivity listener failed: $e', name: 'Reset21');
    }
  }

  static bool get isSupabaseReady => _initialized;

  // ── Legacy convenience methods (kept for backward compat) ────────────
  static Future<void> saveHabitsOffline(List<Habit> habits) async {
    await PersistenceService.saveHabits(habits);
  }

  static Future<List<Habit>> getHabitsOffline() async {
    return PersistenceService.getHabits();
  }

  // ── Supabase write sync with duplicate protection ────────────────────
  /// Push a daily log to Supabase. Non-blocking; queues on failure.
  /// TASK 3: Skips if already synced for today.
  static Future<void> syncDailyLog({
    required String userId,
    required String date,
    required List<Habit> habits,
    required double score,
    required int xp,
    required int streak,
  }) async {
    try {
      // Duplicate sync guard
      final lastSynced = PersistenceService.getLastSyncedDate();
      if (lastSynced == date) {
        dev.log('[DatabaseService] Sync skipped: already synced for $date', name: 'Reset21');
        return;
      }

      final payload = {
        'user_id': userId,
        'date': date,
        'habits': habits.map((h) => h.toJson()).toList(),
        'score': score,
        'xp': xp,
        'streak': streak,
        'synced_at': DateTime.now().toIso8601String(),
      };

      await SyncQueueService.pushDailyLog(payload);

      // Mark today as synced
      await PersistenceService.setLastSyncedDate(date);
    } catch (e) {
      dev.log('[DatabaseService] syncDailyLog failed: $e', name: 'Reset21');
    }
  }
}
