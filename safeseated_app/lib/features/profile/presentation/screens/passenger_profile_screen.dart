import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../auth/domain/models/verification_status.dart';
import 'personal_info_screen.dart';
import 'verification_status_screen.dart';
import 'password_security_screen.dart';
import 'notifications_screen.dart';

class PassengerProfileScreen extends ConsumerWidget {
  const PassengerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final verificationStatus = user?.status ?? VerificationStatus.pending;
    final verificationStatusVariant = switch (verificationStatus) {
      VerificationStatus.pending => PillVariant.pending,
      VerificationStatus.approved => PillVariant.success,
      VerificationStatus.rejected ||
      VerificationStatus.suspended => PillVariant.danger,
    };

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7464DF), Color(0xFF40338F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    AvatarWidget(
                      name: user?.name ?? 'Passenger',
                      size: 72,
                      backgroundColor: Colors.white,
                      textColor: AppColors.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.name ?? 'Ayesha Khan',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Passenger · SafeSeated member',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFE9E5FF),
                      ),
                    ),
                    const SizedBox(height: 10),
                    StatusPill(
                      text: verificationStatus.label,
                      variant: verificationStatusVariant,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _buildMenuItem(
                context,
                icon: Icons.person_outline,
                title: 'Personal information',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => const PersonalInfoScreen(),
                    ),
                  );
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.verified_user_outlined,
                title: 'Verification status',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => const VerificationStatusScreen(),
                    ),
                  );
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.lock_outline,
                title: 'Password & security',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => const PasswordSecurityScreen(),
                    ),
                  );
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.logout,
                iconColor: AppColors.statusDangerText,
                textColor: AppColors.statusDangerText,
                title: 'Log out',
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Log out of SafeSeated?'),
                      content: const Text(
                        'Are you sure you want to end your current session?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            'Log out',
                            style: TextStyle(color: AppColors.statusDangerText),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await ref.read(authStateProvider.notifier).logout();
                    if (context.mounted) {
                      context.go(AppRoutes.welcome);
                    }
                  }
                },
              ),
              const SizedBox(height: 20),

              // Demo helper reset button
              AppButton(
                text: 'Reset Demo Data to Initial State',
                variant: AppButtonVariant.outline,
                onPressed: () async {
                  await ref.read(authStateProvider.notifier).resetDemoData();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Demo data has been reset.'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                    context.go(AppRoutes.welcome);
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    Color? iconColor,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: (iconColor ?? AppColors.primary).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor ?? AppColors.primary, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textColor ?? AppColors.textPrimary,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
