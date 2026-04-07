import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/database_service.dart';
import '../design_system.dart';
import 'kinetic_components.dart';

class AccountBottomSheet extends StatefulWidget {
  const AccountBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const AccountBottomSheet(),
    );
  }

  @override
  State<AccountBottomSheet> createState() => _AccountBottomSheetState();
}

class _AccountBottomSheetState extends State<AccountBottomSheet> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await DatabaseService.signInWithGoogle();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('GOOGLE SIGN IN FAILED: $e', style: AppTypography.labelMedium.copyWith(color: Colors.white))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await DatabaseService.signInWithApple();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('APPLE SIGN IN FAILED: $e', style: AppTypography.labelMedium.copyWith(color: Colors.white))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = DatabaseService.currentUserId;
    final isAnonymous = Supabase.instance.client.auth.currentUser?.isAnonymous ?? true;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: AppColors.text, width: 2)),
      ),
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ACCOUNT', style: AppTypography.displayLarge.copyWith(fontSize: 32)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.text),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (isAnonymous) ...[
              Text('UPGRADE TO PERMANENT', style: AppTypography.headlineMedium),
              const SizedBox(height: 8),
              Text('Sync your streaks across devices and never lose progress.', style: AppTypography.labelMedium.copyWith(color: AppColors.outline)),
              const SizedBox(height: 32),
              if (_isLoading)
                const Center(child: CircularProgressIndicator(color: AppColors.primary))
              else ...[
                KineticButton(
                  text: 'CONTINUE WITH GOOGLE',
                  onPressed: _handleGoogleSignIn,
                  isPrimary: false, // For black/white contrast
                  icon: const Icon(Icons.g_mobiledata, color: AppColors.text, size: 32),
                ),
                const SizedBox(height: 16),
                KineticButton(
                  text: 'CONTINUE WITH APPLE',
                  onPressed: _handleAppleSignIn,
                  isPrimary: true, // For neon contrast
                  icon: const Icon(Icons.apple, color: AppColors.background, size: 28),
                ),
              ],
            ] else ...[
              Text('SIGNED IN AS', style: AppTypography.headlineMedium),
              const SizedBox(height: 8),
              Text(Supabase.instance.client.auth.currentUser?.email ?? 'USER: $userId', style: AppTypography.labelMedium),
              const SizedBox(height: 32),
              KineticButton(
                text: 'LOG OUT',
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (mounted) Navigator.pop(context);
                },
                isPrimary: false,
              ),
            ],
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
