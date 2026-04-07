import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../services/persistence_service.dart';

class HabitNotifier extends Notifier<List<Habit>> {
  static final _defaultHabits = [
    Habit(id: '1', title: 'Wake up @ 6am', subtitle: '7:00 AM', date: DateTime.now()),
    Habit(id: '2', title: 'Meditation', date: DateTime.now()),
    Habit(id: '3', title: 'Exercise', date: DateTime.now()),
    Habit(id: '4', title: 'Skin Care Routine', date: DateTime.now()),
    Habit(id: '5', title: 'Complete 10K steps', subtitle: '5,635 steps', date: DateTime.now()),
    Habit(id: '6', title: '3L Water', subtitle: '1.5L', date: DateTime.now()),
    Habit(id: '7', title: 'No Junk & Sugar', isBonus: true, date: DateTime.now()),
    Habit(id: '8', title: '1 hr Study', date: DateTime.now()),
    Habit(id: '9', title: 'Read book', date: DateTime.now()),
    Habit(id: '10', title: 'Plan next day', date: DateTime.now()),
  ];

  @override
  List<Habit> build() {
    try {
      // Rehydrate from Hive; fall back to defaults on first launch
      final saved = PersistenceService.getHabits();
      return saved.isNotEmpty ? saved : List.from(_defaultHabits);
    } catch (e) {
      dev.log('[HabitNotifier] build failed: $e', name: 'Reset21');
      return List.from(_defaultHabits);
    }
  }

  void toggleHabit(String id) {
    try {
      state = [
        for (final habit in state)
          if (habit.id == id)
            habit.copyWith(isCompleted: !habit.isCompleted)
          else
            habit,
      ];
      PersistenceService.saveHabits(state);
    } catch (e) {
      dev.log('[HabitNotifier] toggleHabit failed: $e', name: 'Reset21');
    }
  }

  /// Reset all habits to NOT_STARTED for a new day.
  void resetAllHabits() {
    try {
      state = [
        for (final habit in state)
          habit.copyWith(isCompleted: false, date: DateTime.now()),
      ];
      PersistenceService.saveHabits(state);
    } catch (e) {
      dev.log('[HabitNotifier] resetAllHabits failed: $e', name: 'Reset21');
    }
  }

  void setHabits(List<Habit> habits) {
    state = habits;
    PersistenceService.saveHabits(state);
  }
}

final habitProvider = NotifierProvider<HabitNotifier, List<Habit>>(HabitNotifier.new);

final scoreProvider = Provider<double>((ref) {
  final habits = ref.watch(habitProvider);
  if (habits.isEmpty) return 0.0;
  final completed = habits.where((h) => h.isCompleted).length;
  return completed / habits.length;
});
