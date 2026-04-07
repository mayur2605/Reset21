import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/persistence_service.dart';
import 'habit_provider.dart';

class Stats {
  final int totalXp;
  final int currentStreak;
  final String level;

  const Stats({
    this.totalXp = 0,
    this.currentStreak = 0,
    this.level = 'Beginner',
  });

  Stats copyWith({
    int? totalXp,
    int? currentStreak,
    String? level,
  }) {
    return Stats(
      totalXp: totalXp ?? this.totalXp,
      currentStreak: currentStreak ?? this.currentStreak,
      level: level ?? this.level,
    );
  }
}

class StatsNotifier extends Notifier<Stats> {
  @override
  Stats build() {
    try {
      return Stats(
        totalXp: PersistenceService.getTotalXp(),
        currentStreak: PersistenceService.getStreak(),
        level: PersistenceService.getLevel(),
      );
    } catch (e) {
      dev.log('[StatsNotifier] build failed: $e', name: 'Reset21');
      return const Stats();
    }
  }

  void updateStats(double dailyScore, int completedHabits, int completedBonus, bool isPerfectDay) {
    try {
      int xpGained = (completedHabits * 10) + (completedBonus * 20);
      if (isPerfectDay) xpGained += 50;

      int newTotalXp = state.totalXp + xpGained;
      int newStreak = dailyScore >= 0.7 ? state.currentStreak + 1 : 0;
      
      String newLevel = _calculateLevel(newTotalXp);

      state = state.copyWith(
        totalXp: newTotalXp,
        currentStreak: newStreak,
        level: newLevel,
      );

      // Persist
      PersistenceService.setTotalXp(newTotalXp);
      PersistenceService.setStreak(newStreak);
      PersistenceService.setLevel(newLevel);
    } catch (e) {
      dev.log('[StatsNotifier] updateStats failed: $e', name: 'Reset21');
    }
  }

  /// Force-set streak (used by day session on missed-day detection).
  void resetStreak(int value) {
    try {
      state = state.copyWith(currentStreak: value);
      PersistenceService.setStreak(value);
    } catch (e) {
      dev.log('[StatsNotifier] resetStreak failed: $e', name: 'Reset21');
    }
  }

  static String _calculateLevel(int xp) {
    if (xp < 100) return 'Beginner';
    if (xp < 300) return 'Starter';
    if (xp < 700) return 'Warrior';
    return 'Elite';
  }

  void setStats(Stats stats) {
    state = stats;
  }
}

final statsProvider = NotifierProvider<StatsNotifier, Stats>(StatsNotifier.new);

final xpGainedProvider = Provider<int>((ref) {
  final habits = ref.watch(habitProvider);
  final completedNormal = habits.where((h) => h.isCompleted && !h.isBonus).length;
  final completedBonus = habits.where((h) => h.isCompleted && h.isBonus).length;
  final isPerfect = habits.every((h) => h.isCompleted);
  
  return (completedNormal * 10) + (completedBonus * 20) + (isPerfect ? 50 : 0);
});
