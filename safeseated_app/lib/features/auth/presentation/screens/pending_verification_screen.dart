import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';

class PendingVerificationScreen extends ConsumerWidget {
  const PendingVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 34, 24, 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7464DF), Color(0xFF40338F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text('⏳', style: TextStyle(fontSize: 30)),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Application submitted',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'We are reviewing ${user?.name ?? 'your details'} and documents.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFE9E5FF),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  AppCard(
                    child: Column(
                      children: [
                        _VerificationStep(
                          title: 'Details & documents submitted',
                          complete: true,
                        ),
                        const Divider(height: 16),
                        _VerificationStep(
                          title: 'Verification by SafeSeated team',
                          complete: false,
                        ),
                        const Divider(height: 16),
                        _VerificationStep(
                          title: 'Approval notification',
                          complete: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    color: AppColors.surfaceSubtle,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Account verification status',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Your account is pending verification. Required document approval is handled through the backend workflow.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Registered email',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                user?.email ?? 'ayesha@smiu.edu.pk',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppButton(
                    text: 'Continue to login',
                    variant: AppButtonVariant.secondary,
                    onPressed: () async {
                      await ref.read(authStateProvider.notifier).logout();
                      if (context.mounted) context.go(AppRoutes.login);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerificationStep extends StatelessWidget {
  final String title;
  final bool complete;

  const _VerificationStep({required this.title, required this.complete});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(
        complete ? Icons.check_circle_rounded : Icons.pending_outlined,
        color: complete
            ? AppColors.statusSuccessText
            : AppColors.statusPendingText,
        size: 20,
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}
