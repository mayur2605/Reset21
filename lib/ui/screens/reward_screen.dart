import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../../providers/habit_provider.dart';
import '../../providers/stats_provider.dart';
import '../../providers/day_session_provider.dart';
import '../../services/analytics_service.dart';
import '../design_system.dart';
import '../widgets/kinetic_components.dart';

class RewardScreen extends ConsumerStatefulWidget {
  const RewardScreen({super.key});

  @override
  ConsumerState<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends ConsumerState<RewardScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
    _confettiController.play();

    // Fire analytics after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final day = ref.read(daySessionProvider).currentDay;
      final score = ref.read(scoreProvider);
      AnalyticsService.rewardSeen(day: day, score: score);
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(statsProvider);
    final score = ref.watch(scoreProvider);
    final xpGained = ref.watch(xpGainedProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: KineticCard(
                backgroundColor: Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'DAY COMPLETE',
                      style: AppTypography.headlineLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildStatRow('DAILY SCORE', '${(score * 100).toInt()}%'),
                    _buildStatRow('XP EARNED', '+$xpGained'),
                    _buildStatRow('NEW STREAK', '${stats.currentStreak} DAYS'),
                    _buildStatRow('LEVEL', stats.level.toUpperCase()),
                    const SizedBox(height: 32),
                    Text(
                      _getMessage(score),
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 32),
                    KineticButton(
                      text: 'CONTINUE',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [AppColors.secondary, AppColors.text, AppColors.success],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.labelMedium),
          Text(value, style: AppTypography.dataMedium),
        ],
      ),
    );
  }

  String _getMessage(double score) {
    if (score == 1.0) return 'PERFECT DAY! YOU ARE UNSTOPPABLE. 🔥';
    if (score >= 0.7) return 'STRONG PERFORMANCE. KEEP THE STREAK ALIVE! 💪';
    return 'NOT YOUR BEST DAY, BUT YOU DIDN\'T QUIT. TRY AGAIN TOMORROW! 🛡️';
  }
}
