import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/validation/form_validators.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _cnicController;
  late final TextEditingController _universityController;
  late final TextEditingController _studentIdController;
  late final TextEditingController _programController;
  late final TextEditingController _contactNameController;
  late final TextEditingController _contactPhoneController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).value;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _cnicController = TextEditingController(text: user?.cnic ?? '');
    _universityController = TextEditingController(text: user?.university ?? '');
    _studentIdController = TextEditingController(text: user?.studentId ?? '');
    _programController = TextEditingController(
      text: user?.programSemester ?? '',
    );
    _contactNameController = TextEditingController(
      text: user?.emergencyContactName ?? '',
    );
    _contactPhoneController = TextEditingController(
      text: user?.emergencyContactPhone ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cnicController.dispose();
    _universityController.dispose();
    _studentIdController.dispose();
    _programController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await ref
          .read(authStateProvider.notifier)
          .updatePassengerProfile(
            name: _nameController.text,
            phone: _phoneController.text,
            university: _universityController.text,
            studentId: _studentIdController.text,
            programSemester: _programController.text,
            emergencyContactName: _contactNameController.text,
            emergencyContactPhone: _contactPhoneController.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile details saved.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save profile: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personal information')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Personal details',
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
                    AppTextField(
                      label: 'Full name',
                      controller: _nameController,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter your full name'
                          : null,
                    ),
                    AppTextField(
                      label: 'Phone number',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (value) =>
                          value == null ||
                              !FormValidators.isValidPakistanPhone(value)
                          ? 'Enter a valid Pakistan mobile number'
                          : null,
                    ),
                    AppTextField(
                      label: 'Email address',
                      controller: _emailController,
                      readOnly: true,
                    ),
                    AppTextField(
                      label: 'CNIC number',
                      controller: _cnicController,
                      readOnly: true,
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Changes to university, student, CNIC, or driver verification details return the account to pending verification.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'University information',
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
                    AppTextField(
                      label: 'University',
                      controller: _universityController,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter your university'
                          : null,
                    ),
                    AppTextField(
                      label: 'Student ID / Roll number',
                      controller: _studentIdController,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter your student ID'
                          : null,
                    ),
                    AppTextField(
                      label: 'Degree program & semester',
                      controller: _programController,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter your program details'
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Emergency contact',
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
                    AppTextField(
                      label: 'Contact person',
                      controller: _contactNameController,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter an emergency contact name'
                          : null,
                    ),
                    AppTextField(
                      label: 'Contact phone',
                      controller: _contactPhoneController,
                      keyboardType: TextInputType.phone,
                      validator: (value) =>
                          value == null ||
                              !FormValidators.isValidPakistanPhone(value)
                          ? 'Enter a valid Pakistan mobile number'
                          : null,
                    ),
                    const Text(
                      'These details are stored by the backend profile service.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
