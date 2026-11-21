import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/validation/form_validators.dart';

class PassengerRegistrationScreen extends ConsumerStatefulWidget {
  const PassengerRegistrationScreen({super.key});

  @override
  ConsumerState<PassengerRegistrationScreen> createState() =>
      _PassengerRegistrationScreenState();
}

class _PassengerRegistrationScreenState
    extends ConsumerState<PassengerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _cnicController = TextEditingController();
  final _uniController = TextEditingController(
    text: 'SMIU (Sindh Madressatul Islam University)',
  );
  final _studentIdController = TextEditingController();
  final _programController = TextEditingController();
  final _ecNameController = TextEditingController();
  final _ecPhoneController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _cnicController.dispose();
    _uniController.dispose();
    _studentIdController.dispose();
    _programController.dispose();
    _ecNameController.dispose();
    _ecPhoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authStateProvider.notifier)
          .registerPassenger(
            name: _nameController.text,
            phone: _phoneController.text,
            email: _emailController.text,
            password: _passController.text,
            cnic: _cnicController.text,
            university: _uniController.text,
            studentId: _studentIdController.text,
            programSemester: _programController.text,
            emergencyContactName: _ecNameController.text,
            emergencyContactPhone: _ecPhoneController.text,
            documents: const [],
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Registration successful. Your account is awaiting approval.',
            ),
            backgroundColor: AppColors.statusSuccessText,
          ),
        );
        context.go(AppRoutes.pendingApproval);
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
      appBar: AppBar(title: const Text('Passenger registration')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Personal details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Full name',
                  hint: 'e.g. Mariba Ali',
                  controller: _nameController,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter your full name'
                      : null,
                ),
                AppTextField(
                  label: 'Phone number',
                  hint: '03xx-xxxxxxx',
                  keyboardType: TextInputType.phone,
                  controller: _phoneController,
                  validator: (v) =>
                      (v == null || !FormValidators.isValidPakistanPhone(v))
                      ? 'Enter a valid Pakistan mobile number'
                      : null,
                ),
                AppTextField(
                  label: 'Email address',
                  hint: 'name@smiu.edu.pk or regular email',
                  keyboardType: TextInputType.emailAddress,
                  controller: _emailController,
                  validator: (v) =>
                      (v == null || !FormValidators.isValidEmail(v))
                      ? 'Enter a valid email address'
                      : null,
                ),
                AppTextField(
                  label: 'Password',
                  hint: 'At least 8 characters',
                  isPassword: true,
                  controller: _passController,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty || v.length < 8)
                      ? 'Password must be at least 8 characters'
                      : null,
                ),
                AppTextField(
                  label: 'CNIC number',
                  hint: '42xxx-xxxxxxx-x',
                  keyboardType: TextInputType.number,
                  controller: _cnicController,
                  validator: (v) =>
                      (v == null || !FormValidators.isValidCnic(v))
                      ? 'Enter a 13-digit CNIC number'
                      : null,
                ),

                const SizedBox(height: 12),
                const Text(
                  'University information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'University / Campus',
                  hint: 'e.g. SMIU, NED, KU, IBA, FAST',
                  controller: _uniController,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter university name'
                      : null,
                ),
                AppTextField(
                  label: 'Student ID / Roll number',
                  hint: 'e.g. CSC-22F-042',
                  controller: _studentIdController,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter your student ID'
                      : null,
                ),
                AppTextField(
                  label: 'Degree program & semester',
                  hint: 'e.g. BSCS - 5th Semester',
                  controller: _programController,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter program details'
                      : null,
                ),

                const SizedBox(height: 12),
                const Text(
                  'Emergency contact',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'This contact is saved for future SOS and trip-sharing integration. Notifications are not sent in this demo.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Contact person & relation',
                  hint: 'e.g. Mother / Father / Sister',
                  controller: _ecNameController,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter emergency contact name'
                      : null,
                ),
                AppTextField(
                  label: 'Emergency phone number',
                  hint: '03xx-xxxxxxx',
                  keyboardType: TextInputType.phone,
                  controller: _ecPhoneController,
                  validator: (v) =>
                      (v == null || !FormValidators.isValidPakistanPhone(v))
                      ? 'Enter a valid Pakistan mobile number'
                      : null,
                ),

                const SizedBox(height: 16),
                AppCard(
                  color: AppColors.surfaceSubtle,
                  child: const Text(
                    'After registration, upload CNIC front, CNIC back, and your student card from Verification status.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                AppButton(
                  text: 'Submit for verification',
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
