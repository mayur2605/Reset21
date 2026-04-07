import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/stats_provider.dart';
import '../design_system.dart';
import '../widgets/kinetic_components.dart';
import '../widgets/account_bottom_sheet.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('DASHBOARD', style: AppTypography.displayLarge),
                  IconButton(
                    onPressed: () => AccountBottomSheet.show(context),
                    icon: const Icon(Icons.account_circle_outlined, color: AppColors.text, size: 32),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              KineticCard(
                backgroundColor: AppColors.primary,
                child: Column(
                  children: [
                    _buildStatBlock('TOTAL XP', stats.totalXp.toString()),
                    const Divider(color: AppColors.text, thickness: 2),
                    _buildStatBlock('CURRENT STREAK', '${stats.currentStreak} DAYS'),
                    const Divider(color: AppColors.text, thickness: 2),
                    _buildStatBlock('RANK', stats.level.toUpperCase()),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('MY PLAN', style: AppTypography.headlineMedium),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _buildPlanCard('21 DAY RESET', 'IN PROGRESS', true),
                    const SizedBox(height: 16),
                    _buildPlanCard('EARLY BIRD', 'NOT STARTED', false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBlock(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.labelMedium),
          Text(value, style: AppTypography.dataLarge),
        ],
      ),
    );
  }

  Widget _buildPlanCard(String title, String status, bool isActive) {
    return KineticCard(
      backgroundColor: isActive ? Colors.white : AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTypography.headlineMedium.copyWith(fontSize: 16)),
          Text(status, style: AppTypography.labelMedium.copyWith(color: isActive ? AppColors.secondary : AppColors.outline)),
        ],
      ),
    );
  }
}
