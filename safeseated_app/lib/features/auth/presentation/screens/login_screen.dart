import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/validation/form_validators.dart';
import '../../domain/models/user_role.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  UserRole _selectedRole = UserRole.passenger;

  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authStateProvider.notifier)
          .login(
            email: _emailController.text,
            password: _passController.text,
            role: _selectedRole,
          );

      final user = ref.read(authStateProvider).value;

      if (!mounted) return;

      if (user != null) {
        if (user.role == UserRole.passenger) {
          context.go(AppRoutes.passengerHome);
        } else if (user.role == UserRole.driver) {
          context.go(AppRoutes.driverHome);
        } else if (user.role == UserRole.admin) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Admin login succeeded. The Admin dashboard is available in Phase 6.',
                ),
                backgroundColor: AppColors.primary,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.statusDangerText,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 34, 24, 28),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Text(
                          '🛡️',
                          style: TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Welcome back',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Log in to continue',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFFE9E5FF),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Role Selector Segmented Buttons
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0EDFF),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Row(
                          children: [
                            _buildRoleTab('Passenger', UserRole.passenger),
                            _buildRoleTab('Driver', UserRole.driver),
                            _buildRoleTab('Admin', UserRole.admin),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      AppTextField(
                        label: 'Email address',
                        hint: 'name@smiu.edu.pk',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) =>
                            (v == null || !FormValidators.isValidEmail(v))
                            ? 'Enter a valid email'
                            : null,
                      ),
                      AppTextField(
                        label: 'Password',
                        hint: 'Enter your password',
                        isPassword: true,
                        controller: _passController,
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Enter your password'
                            : null,
                      ),

                      const SizedBox(height: 20),
                      AppButton(
                        text: 'Log in',
                        isLoading: _isLoading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 10),
                      AppButton(
                        text: 'Create new account',
                        variant: AppButtonVariant.secondary,
                        onPressed: () => context.push(AppRoutes.roleSelect),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTab(String label, UserRole role) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedRole = role;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    const BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
