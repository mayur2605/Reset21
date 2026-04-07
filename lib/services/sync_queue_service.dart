import 'dart:developer' as dev;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'database_service.dart';
import 'persistence_service.dart';

/// Offline-first sync queue.
/// Stores failed Supabase writes in Hive and retries when connectivity returns.
/// All operations wrapped in try-catch for crash safety.
class SyncQueueService {
  static bool _supabaseReady = false;

  static void markSupabaseReady() => _supabaseReady = true;

  /// Attempt to push a profile update to Supabase.
  static Future<void> pushProfileUpdate(Map<String, dynamic> data) async {
    final payload = {
      'type': 'profile_update',
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (!_supabaseReady) {
      await PersistenceService.addToSyncQueue(payload);
      return;
    }

    try {
      await DatabaseService.syncProfile(
        currentDay: data['current_day'],
        streak: data['current_streak'],
        xp: data['total_xp'],
        level: data['level'],
        dayLocked: data['day_locked'],
        lastCompletedDate: data['last_completed_date'],
      );
    } catch (e) {
      dev.log('[SyncQueue] profile push failed, queuing: $e', name: 'Reset21');
      await PersistenceService.addToSyncQueue(payload);
    }
  }

  /// Attempt to push a daily_log payload to Supabase.
  static Future<void> pushDailyLog(Map<String, dynamic> data) async {
    final payload = {
      'type': 'daily_log',
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (!_supabaseReady) {
      await PersistenceService.addToSyncQueue(payload);
      return;
    }

    try {
      // Re-trigger the normalized sync logic in DatabaseService
      await DatabaseService.syncDailyLog(
        date: data['date'],
        habits: data['habits'],
        score: data['score'],
        xp: data['xp'],
        streak: data['streak'],
      );
    } catch (e) {
      dev.log('[SyncQueue] daily_log push failed, queuing: $e', name: 'Reset21');
      await PersistenceService.addToSyncQueue(payload);
    }
  }

  /// Drain the queue: attempt to push every saved payload.
  static Future<void> drainQueue() async {
    if (!_supabaseReady) return;

    try {
      final queue = PersistenceService.getSyncQueue();
      if (queue.isEmpty) return;

      dev.log('[SyncQueue] Draining ${queue.length} items', name: 'Reset21');
      final failed = <Map<String, dynamic>>[];

      for (final item in queue) {
        try {
          final type = item['type'];
          final data = item['data'];

          if (type == 'daily_log') {
            await DatabaseService.syncDailyLog(
              date: data['date'],
              habits: data['habits'],
              score: data['score'],
              xp: data['xp'],
              streak: data['streak'],
            );
          } else if (type == 'profile_update') {
            await DatabaseService.syncProfile(
              currentDay: data['current_day'],
              streak: data['current_streak'],
              xp: data['total_xp'],
              level: data['level'],
              dayLocked: data['day_locked'],
              lastCompletedDate: data['last_completed_date'],
            );
          }
        } catch (e) {
          dev.log('[SyncQueue] drain item failed: $e', name: 'Reset21');
          failed.add(item);
        }
      }

      await PersistenceService.setSyncQueue(failed);
    } catch (e) {
      dev.log('[SyncQueue] drainQueue failed: $e', name: 'Reset21');
    }
  }

  /// Listen to connectivity changes and drain queue when online.
  static void listenForConnectivity() {
    try {
      Connectivity().onConnectivityChanged.listen((results) {
        try {
          final hasConnection = results.any((r) => r != ConnectivityResult.none);
          if (hasConnection) {
            drainQueue();
          }
        } catch (e) {
          dev.log('[SyncQueue] connectivity callback failed: $e', name: 'Reset21');
        }
      });
    } catch (e) {
      dev.log('[SyncQueue] listenForConnectivity failed: $e', name: 'Reset21');
    }
  }
}
