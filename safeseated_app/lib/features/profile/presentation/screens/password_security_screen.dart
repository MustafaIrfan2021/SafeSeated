import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';

class PasswordSecurityScreen extends ConsumerStatefulWidget {
  const PasswordSecurityScreen({super.key});

  @override
  ConsumerState<PasswordSecurityScreen> createState() =>
      _PasswordSecurityScreenState();
}

class _PasswordSecurityScreenState
    extends ConsumerState<PasswordSecurityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPassController.text != _confirmPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New passwords do not match.'),
          backgroundColor: AppColors.statusDangerText,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authStateProvider.notifier)
          .updatePassword(_currentPassController.text, _newPassController.text);

      _currentPassController.clear();
      _newPassController.clear();
      _confirmPassController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated successfully ✓'),
            backgroundColor: AppColors.statusSuccessText,
          ),
        );
        Navigator.pop(context);
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Password & security')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Change password',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              AppCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AppTextField(
                        label: 'Current password',
                        isPassword: true,
                        controller: _currentPassController,
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Enter current password'
                            : null,
                      ),
                      AppTextField(
                        label: 'New password (min 8 chars)',
                        isPassword: true,
                        controller: _newPassController,
                        validator: (v) => (v == null || v.length < 8)
                            ? 'At least 8 characters required'
                            : null,
                      ),
                      AppTextField(
                        label: 'Confirm new password',
                        isPassword: true,
                        controller: _confirmPassController,
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Confirm your new password'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      AppButton(
                        text: 'Update password',
                        isLoading: _isLoading,
                        onPressed: _updatePassword,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Security & sessions',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              AppCard(
                child: Column(
                  children: [
                    _buildRow('Login method', 'Email & password'),
                    const Divider(height: 16),
                    _buildRow('Last login session', 'Today, 9:41 AM (Karachi)'),
                    const Divider(height: 16),
                    _buildRow('Active device', 'This mobile phone'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
