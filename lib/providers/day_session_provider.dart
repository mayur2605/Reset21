import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/persistence_service.dart';
import '../services/analytics_service.dart';

/// Immutable state for the day session.
class DaySession {
  final int currentDay;
  final String? lastCompletedDate;
  final bool dayLocked;
  final bool missedDay;
  final bool showPaywall;
  final bool isFirstLaunch;

  const DaySession({
    this.currentDay = 1,
    this.lastCompletedDate,
    this.dayLocked = false,
    this.missedDay = false,
    this.showPaywall = false,
    this.isFirstLaunch = false,
  });

  DaySession copyWith({
    int? currentDay,
    String? lastCompletedDate,
    bool? dayLocked,
    bool? missedDay,
    bool? showPaywall,
    bool? isFirstLaunch,
  }) {
    return DaySession(
      currentDay: currentDay ?? this.currentDay,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      dayLocked: dayLocked ?? this.dayLocked,
      missedDay: missedDay ?? this.missedDay,
      showPaywall: showPaywall ?? this.showPaywall,
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
    );
  }
}

class DaySessionNotifier extends Notifier<DaySession> {
  @override
  DaySession build() {
    try {
      final firstLaunch = PersistenceService.isFirstLaunch();

      if (firstLaunch) {
        // TASK 1: First-time user initialization
        // All Hive defaults are already correct (day=1, xp=0, etc.)
        // Just mark as initialized so we don't re-run
        PersistenceService.markInitialized();

        return const DaySession(
          currentDay: 1,
          lastCompletedDate: null,
          dayLocked: false,
          isFirstLaunch: true,
        );
      }

      // Returning user → rehydrate from Hive
      return DaySession(
        currentDay: PersistenceService.getCurrentDay(),
        lastCompletedDate: PersistenceService.getLastCompletedDate(),
        dayLocked: PersistenceService.getDayLocked(),
      );
    } catch (e) {
      dev.log('[DaySessionNotifier] build failed: $e', name: 'Reset21');
      return const DaySession();
    }
  }

  /// Called once on app start.
  /// Handles day progression, missed-day detection, streak reset, paywall.
  void reconcileOnLaunch(void Function() resetHabits, void Function(int) resetStreak) {
    try {
      final today = _todayIso();
      final lastDate = state.lastCompletedDate;
      bool missed = false;

      if (lastDate != null && lastDate != today) {
        final gap = _daysBetween(lastDate, today);

        if (gap > 1) {
          // TASK 2: Missed one or more days → break streak
          missed = true;
          final previousStreak = PersistenceService.getStreak();
          resetStreak(0);
          AnalyticsService.streakBroken(previousStreak: previousStreak, missedDays: gap - 1);
        }

        // TASK 2: Multi-day skip — advance by gap days, cap at 21
        final newDay = (state.currentDay + gap).clamp(1, 21);
        PersistenceService.setCurrentDay(newDay);
        PersistenceService.setDayLocked(false);
        resetHabits();

        state = state.copyWith(
          currentDay: newDay,
          dayLocked: false,
          missedDay: missed,
          showPaywall: newDay > 3 && !PersistenceService.getPaywallShown(),
        );
      } else if (lastDate == null) {
        // First ever launch – day 1 is already set by default
        state = state.copyWith(dayLocked: false);
      }
      // If lastDate == today, everything stays as-is (session restore).
    } catch (e) {
      dev.log('[DaySessionNotifier] reconcileOnLaunch failed: $e', name: 'Reset21');
    }
  }

  /// Mark today as completed (called from LOCK DAY).
  void lockDay() {
    try {
      final today = _todayIso();
      PersistenceService.setLastCompletedDate(today);
      PersistenceService.setDayLocked(true);

      state = state.copyWith(
        lastCompletedDate: today,
        dayLocked: true,
      );
    } catch (e) {
      dev.log('[DaySessionNotifier] lockDay failed: $e', name: 'Reset21');
    }
  }

  void dismissPaywall() {
    try {
      PersistenceService.setPaywallShown(true);
      state = state.copyWith(showPaywall: false);
    } catch (e) {
      dev.log('[DaySessionNotifier] dismissPaywall failed: $e', name: 'Reset21');
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────
  static String _todayIso() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).toIso8601String().split('T').first;
  }

  static int _daysBetween(String isoA, String isoB) {
    final a = DateTime.parse(isoA);
    final b = DateTime.parse(isoB);
    return b.difference(a).inDays.abs();
  }
}

final daySessionProvider =
    NotifierProvider<DaySessionNotifier, DaySession>(DaySessionNotifier.new);
