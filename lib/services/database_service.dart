import 'dart:developer' as dev;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
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
      final url = dotenv.env['SUPABASE_URL'] ?? '';
      final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

      if (url.isEmpty || anonKey.isEmpty) {
        throw Exception('Supabase URL or Anon Key is missing in .env');
      }

      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
      );
      
      _initialized = true;

      // TASK: Anonymous sign-in for RLS
      await _ensureAuthenticated();

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

  static Future<void> _ensureAuthenticated() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        dev.log('[DatabaseService] No session, signing in anonymously...', name: 'Reset21');
        await Supabase.instance.client.auth.signInAnonymously();
      }
    } catch (e) {
      dev.log('[DatabaseService] Anonymous sign-in failed: $e', name: 'Reset21');
    }
  }

  static bool get isSupabaseReady => _initialized && Supabase.instance.client.auth.currentSession != null;

  static String? get currentUserId => Supabase.instance.client.auth.currentUser?.id;

  // ── OAuth Sign-In Methods ───────────────────────────────────────────

  /// Native Google Sign-In (Upgrades Anonymous account automatically)
  static Future<AuthResponse?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: dotenv.env['GOOGLE_IOS_CLIENT_ID'], // Required for iOS
        serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'], // Required for Android to get ID token
      );
      
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) throw 'No ID Token found.';
      if (accessToken == null) throw 'No Access Token found.';

      final response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      dev.log('[DatabaseService] Google sign-in successful: ${response.user?.id}', name: 'Reset21');
      return response;
    } catch (e) {
      dev.log('[DatabaseService] Google sign-in failed: $e', name: 'Reset21');
      rethrow;
    }
  }

  /// Native Apple Sign-In (Upgrades Anonymous account automatically)
  static Future<AuthResponse?> signInWithApple() async {
    try {
      final rawNonce = _generateRawNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) throw 'No ID Token found.';

      final response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      dev.log('[DatabaseService] Apple sign-in successful: ${response.user?.id}', name: 'Reset21');
      return response;
    } catch (e) {
      dev.log('[DatabaseService] Apple sign-in failed: $e', name: 'Reset21');
      rethrow;
    }
  }

  static String _generateRawNonce() {
    final random = Random.secure();
    return base64Url.encode(List<int>.generate(16, (_) => random.nextInt(256)));
  }

  // ── Legacy convenience methods (kept for backward compat) ────────────
  static Future<void> saveHabitsOffline(List<Habit> habits) async {
    await PersistenceService.saveHabits(habits);
  }

  static Future<List<Habit>> getHabitsOffline() async {
    return PersistenceService.getHabits();
  }

  // ── Supabase write sync with normalized 5-table schema ──────────────────

  /// Sync a profile update (XP, streak, etc.).
  static Future<void> syncProfile({
    required int currentDay,
    required int streak,
    required int xp,
    required String level,
    required bool dayLocked,
    String? lastCompletedDate,
  }) async {
    if (!isSupabaseReady) {
      await SyncQueueService.pushProfileUpdate({
        'current_day': currentDay,
        'current_streak': streak,
        'total_xp': xp,
        'level': level,
        'day_locked': dayLocked,
        'last_completed_date': lastCompletedDate,
      });
      return;
    }

    try {
      final userId = currentUserId;
      if (userId == null) return;

      await Supabase.instance.client.from('profiles').upsert({
        'id': userId,
        'current_day': currentDay,
        'current_streak': streak,
        'total_xp': xp,
        'level': level,
        'day_locked': dayLocked,
        'last_completed_date': lastCompletedDate,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      dev.log('[DatabaseService] syncProfile failed: $e', name: 'Reset21');
      await SyncQueueService.pushProfileUpdate({
        'current_day': currentDay,
        'current_streak': streak,
        'total_xp': xp,
        'level': level,
        'day_locked': dayLocked,
        'last_completed_date': lastCompletedDate,
      });
    }
  }

  /// Sync a daily log + habit entries.
  static Future<void> syncDailyLog({
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
        'date': date,
        'habits': habits,
        'score': score,
        'xp': xp,
        'streak': streak,
      };

      if (!isSupabaseReady) {
        await SyncQueueService.pushDailyLog(payload);
        return;
      }

      await _executeDailyLogSync(payload);
      
      // Mark today as synced
      await PersistenceService.setLastSyncedDate(date);
    } catch (e) {
      dev.log('[DatabaseService] syncDailyLog failed: $e', name: 'Reset21');
    }
  }

  /// Internal: handles the insertion into multiple tables.
  static Future<void> _executeDailyLogSync(Map<String, dynamic> data) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('No authenticated user');

    final date = data['date'];
    final List<Habit> habits = data['habits'];

    // 1. Insert into daily_logs
    final logResponse = await Supabase.instance.client.from('daily_logs').upsert({
      'user_id': userId,
      'date': date,
      'score': data['score'],
      'xp_earned': data['xp'],
      'streak_at_lock': data['streak'],
      'is_perfect': habits.every((h) => h.isCompleted),
      'synced_at': DateTime.now().toIso8601String(),
    }).select('id').single();

    final logId = logResponse['id'];

    // 2. Prepare habit entries
    // We need the habit IDs from the 'habits' table. 
    // For simplicity in this session, we assume the seeding trigger handled it.
    // We fetch current habit IDs for this user to map titles to IDs.
    final habitMapResponse = await Supabase.instance.client
        .from('habits')
        .select('id, title')
        .eq('user_id', userId);
    
    final Map<String, String> titleToId = {
      for (var row in (habitMapResponse as List)) row['title']: row['id']
    };

    final entryPayloads = habits.map((h) => {
      'daily_log_id': logId,
      'habit_id': titleToId[h.title] ?? h.id, // Fallback to local ID if title not found
      'user_id': userId,
      'date': date,
      'is_completed': h.isCompleted,
    }).toList();

    // 3. Insert habit entries
    await Supabase.instance.client.from('habit_entries').upsert(entryPayloads);
  }

  /// Called on fresh launch to try and restore profile data.
  static Future<Map<String, dynamic>?> fetchProfile() async {
    if (!isSupabaseReady) return null;
    try {
      final userId = currentUserId;
      if (userId == null) return null;

      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      return response;
    } catch (e) {
      dev.log('[DatabaseService] fetchProfile failed: $e', name: 'Reset21');
      return null;
    }
  }
}
