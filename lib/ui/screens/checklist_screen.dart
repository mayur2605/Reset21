import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/habit_provider.dart';
import '../../providers/stats_provider.dart';
import '../../providers/day_session_provider.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../services/analytics_service.dart';
import 'reward_screen.dart';
import '../design_system.dart';
import '../widgets/kinetic_components.dart';

class ChecklistScreen extends ConsumerStatefulWidget {
  const ChecklistScreen({super.key});

  @override
  ConsumerState<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends ConsumerState<ChecklistScreen> {
  bool _reconciled = false;
  bool _isProcessing = false; // TASK 5: double-click prevention

  @override
  void initState() {
    super.initState();
    // Run reconciliation once after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reconcileSession();
    });
  }

  void _reconcileSession() {
    if (_reconciled) return;
    _reconciled = true;

    try {
      final dayNotifier = ref.read(daySessionProvider.notifier);
      dayNotifier.reconcileOnLaunch(
        () => ref.read(habitProvider.notifier).resetAllHabits(),
        (v) => ref.read(statsProvider.notifier).resetStreak(v),
      );

      // Sync reconciled profile to Supabase
      final updatedStats = ref.read(statsProvider);
      final updatedSession = ref.read(daySessionProvider);
      DatabaseService.syncProfile(
        currentDay: updatedSession.currentDay,
        streak: updatedStats.currentStreak,
        xp: updatedStats.totalXp,
        level: updatedStats.level,
        dayLocked: updatedSession.dayLocked,
        lastCompletedDate: updatedSession.lastCompletedDate,
      );

      // Schedule notifications with the current day
      final day = ref.read(daySessionProvider).currentDay;
      NotificationService.scheduleDailyReminders(currentDay: day);
    } catch (e) {
      dev.log('[ChecklistScreen] reconcileSession failed: $e', name: 'Reset21');
    }
  }

  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(habitProvider);
    final score = ref.watch(scoreProvider);
    final stats = ref.watch(statsProvider);
    final daySession = ref.watch(daySessionProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'DAY ${daySession.currentDay.toString().padLeft(2, '0')}',
                          style: AppTypography.displayLarge,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('LEVEL: ${stats.level.toUpperCase()}', style: AppTypography.labelMedium),
                            Text('STREAK: ${stats.currentStreak}', style: AppTypography.dataMedium),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildProgressBar(score),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(score * 100).toInt()}% COMPLETE',
                          style: AppTypography.labelMedium,
                        ),
                        Text(
                          _getMotivationText(score, habits.length),
                          style: AppTypography.labelMedium.copyWith(color: AppColors.secondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Habits List
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final habit = habits[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _HabitCard(habit: habit),
                    );
                  },
                  childCount: habits.length,
                ),
              ),
            ),

            // CTA Button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: daySession.dayLocked
                    ? Center(
                        child: Text(
                          'DAY LOCKED ✅',
                          style: AppTypography.headlineMedium.copyWith(color: AppColors.success),
                        ),
                      )
                    : _isProcessing
                        ? const Center(
                            child: SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: AppColors.text,
                              ),
                            ),
                          )
                        : KineticButton(
                            text: 'LOCK DAY & EARN XP',
                            onPressed: () => _handleLockDay(context, ref),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(double progress) {
    return Container(
      height: 24,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.text, width: 4),
      ),
      child: Stack(
        children: [
          FractionallySizedBox(
            widthFactor: progress,
            child: Container(
              color: progress >= 1.0 ? AppColors.success : AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  String _getMotivationText(double score, int total) {
    if (score == 0) return 'START YOUR DAY 🚀';
    if (score < 0.7) return 'KEEP GOING. STREAK AT 70%';
    if (score < 1.0) {
      final remaining = total - (score * total).toInt();
      return '$remaining TASK${remaining > 1 ? 'S' : ''} TO 100%';
    }
    return 'PERFECT DAY REACHED! ✨';
  }

  Future<void> _handleLockDay(BuildContext context, WidgetRef ref) async {
    // TASK 5: Double-click prevention
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final score = ref.read(scoreProvider);
      final habits = ref.read(habitProvider);
      final daySession = ref.read(daySessionProvider);
      final completedNormal = habits.where((h) => h.isCompleted && !h.isBonus).length;
      final completedBonus = habits.where((h) => h.isCompleted && h.isBonus).length;
      final isPerfect = habits.every((h) => h.isCompleted);
      final xpGained = ref.read(xpGainedProvider);

      // 1. Update stats (XP, streak, level)
      ref.read(statsProvider.notifier).updateStats(
        score, 
        completedNormal, 
        completedBonus, 
        isPerfect,
      );

      // 2. Mark day as locked
      ref.read(daySessionProvider.notifier).lockDay();

      // 3. Persist habits
      await DatabaseService.saveHabitsOffline(habits);

      // 4. Supabase write sync (normalized tables)
      final updatedStats = ref.read(statsProvider);
      
      // Update Daily logs (normalized)
      await DatabaseService.syncDailyLog(
        date: DateTime.now().toIso8601String().split('T').first,
        habits: habits,
        score: score,
        xp: xpGained,
        streak: updatedStats.currentStreak,
      );

      // Update Profile (Stats)
      await DatabaseService.syncProfile(
        currentDay: daySession.currentDay,
        streak: updatedStats.currentStreak,
        xp: updatedStats.totalXp,
        level: updatedStats.level,
        dayLocked: true,
        lastCompletedDate: DateTime.now().toIso8601String().split('T').first,
      );

      // 5. Analytics
      AnalyticsService.dayLocked(
        day: daySession.currentDay,
        score: score,
        xp: xpGained,
      );

      // 6. Navigate to reward
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const RewardScreen()),
      );
    } catch (e) {
      dev.log('[ChecklistScreen] _handleLockDay failed: $e', name: 'Reset21');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}

class _HabitCard extends ConsumerWidget {
  final dynamic habit;

  const _HabitCard({required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        try {
          // Don't allow toggling if day is locked
          final dayLocked = ref.read(daySessionProvider).dayLocked;
          if (dayLocked) return;

          ref.read(habitProvider.notifier).toggleHabit(habit.id);

          if (!habit.isCompleted) {
            _showFeedback(context, "Strong move 💪");
          }
        } catch (e) {
          dev.log('[_HabitCard] onTap failed: $e', name: 'Reset21');
        }
      },
      child: KineticCard(
        backgroundColor: habit.isCompleted ? AppColors.primary.withAlpha(25) : Colors.white,
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.text, width: 3),
                color: habit.isCompleted ? AppColors.primary : Colors.transparent,
              ),
              child: habit.isCompleted 
                ? const Icon(Icons.close, size: 24, color: AppColors.text)
                : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.title,
                    style: AppTypography.headlineMedium.copyWith(
                      fontSize: 18,
                      decoration: habit.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (habit.subtitle != null)
                    Text(
                      habit.subtitle!,
                      style: AppTypography.dataMedium.copyWith(fontSize: 14),
                    ),
                ],
              ),
            ),
            if (habit.isBonus)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  border: Border.all(color: AppColors.text, width: 2),
                ),
                child: Text(
                  'BONUS',
                  style: AppTypography.labelMedium.copyWith(color: Colors.white, fontSize: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showFeedback(BuildContext context, String message) {
     if (!context.mounted) return;
     ScaffoldMessenger.of(context).clearSnackBars();
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(
         duration: const Duration(seconds: 1),
         backgroundColor: AppColors.text,
         content: Text(message, style: const TextStyle(color: Colors.white)),
       ),
     );
  }
}
