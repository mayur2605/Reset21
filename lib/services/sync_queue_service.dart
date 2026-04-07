import 'dart:developer' as dev;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'persistence_service.dart';

/// Offline-first sync queue.
/// Stores failed Supabase writes in Hive and retries when connectivity returns.
/// All operations wrapped in try-catch for crash safety.
class SyncQueueService {
  static bool _supabaseReady = false;

  static void markSupabaseReady() => _supabaseReady = true;

  /// Attempt to push a daily_log payload to Supabase.
  /// If it fails, queue it locally for retry.
  static Future<void> pushDailyLog(Map<String, dynamic> payload) async {
    if (!_supabaseReady) {
      await PersistenceService.addToSyncQueue(payload);
      return;
    }

    try {
      await Supabase.instance.client.from('daily_logs').insert(payload);
    } catch (e) {
      dev.log('[SyncQueue] push failed, queuing: $e', name: 'Reset21');
      await PersistenceService.addToSyncQueue(payload);
    }
  }

  /// Drain the queue: attempt to push every saved payload.
  /// Called on app start and when network becomes available.
  static Future<void> drainQueue() async {
    if (!_supabaseReady) return;

    try {
      final queue = PersistenceService.getSyncQueue();
      if (queue.isEmpty) return;

      final failed = <Map<String, dynamic>>[];

      for (final payload in queue) {
        try {
          await Supabase.instance.client.from('daily_logs').insert(payload);
        } catch (e) {
          dev.log('[SyncQueue] drain item failed: $e', name: 'Reset21');
          failed.add(payload);
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
