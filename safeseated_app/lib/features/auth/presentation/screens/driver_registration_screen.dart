import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/validation/form_validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';

class DriverRegistrationScreen extends ConsumerStatefulWidget {
  const DriverRegistrationScreen({super.key});

  @override
  ConsumerState<DriverRegistrationScreen> createState() =>
      _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState
    extends ConsumerState<DriverRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = List.generate(12, (_) => TextEditingController());
  int _seats = 3;
  bool _isLoading = false;
  String? _documentError;

  TextEditingController get _name => _controllers[0];
  TextEditingController get _phone => _controllers[1];
  TextEditingController get _email => _controllers[2];
  TextEditingController get _password => _controllers[3];
  TextEditingController get _cnic => _controllers[4];
  TextEditingController get _city => _controllers[5];
  TextEditingController get _license => _controllers[6];
  TextEditingController get _vehicle => _controllers[7];
  TextEditingController get _plate => _controllers[8];
  TextEditingController get _registration => _controllers[9];
  TextEditingController get _color => _controllers[10];
  TextEditingController get _year => _controllers[11];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value, String label) =>
      value == null || value.trim().isEmpty ? 'Enter $label' : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _documentError = null);
    setState(() => _isLoading = true);
    try {
      await ref
          .read(authStateProvider.notifier)
          .registerDriver(
            name: _name.text,
            phone: _phone.text,
            email: _email.text,
            password: _password.text,
            cnic: _cnic.text,
            city: _city.text,
            licenseNumber: _license.text,
            vehicleMake: _vehicle.text,
            vehicleColor: _color.text,
            vehiclePlate: _plate.text,
            vehicleYear: _year.text,
            seatsTotal: _seats,
            vehicleRegistration: _registration.text,
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
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceAll('Exception: ', '')),
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
      appBar: AppBar(title: const Text('Driver registration')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Driver details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add your contact and identity information to get started.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: 'Full name',
                controller: _name,
                validator: (value) => _required(value, 'your name'),
              ),
              AppTextField(
                label: 'Phone number',
                controller: _phone,
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value == null || !FormValidators.isValidPakistanPhone(value)
                    ? 'Enter a valid Pakistan mobile number'
                    : null,
              ),
              AppTextField(
                label: 'Email address',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value == null || !FormValidators.isValidEmail(value)
                    ? 'Enter a valid email address'
                    : null,
              ),
              AppTextField(
                label: 'Password',
                controller: _password,
                isPassword: true,
                validator: (value) =>
                    value == null || value.trim().isEmpty || value.length < 8
                    ? 'Password must be at least 8 characters'
                    : null,
              ),
              AppTextField(
                label: 'CNIC number',
                controller: _cnic,
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value == null || !FormValidators.isValidCnic(value)
                    ? 'Enter a 13-digit CNIC number'
                    : null,
              ),
              AppTextField(
                label: 'City',
                controller: _city,
                validator: (value) => _required(value, 'your city'),
              ),
              AppTextField(
                label: 'Driving licence number',
                controller: _license,
                validator: (value) => _required(value, 'your licence number'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vehicle details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Make & model',
                controller: _vehicle,
                validator: (value) =>
                    _required(value, 'your vehicle make/model'),
              ),
              AppTextField(
                label: 'Colour',
                controller: _color,
                validator: (value) => _required(value, 'your vehicle colour'),
              ),
              AppTextField(
                label: 'Plate number',
                controller: _plate,
                validator: (value) =>
                    _required(value, 'your vehicle plate number'),
              ),
              AppTextField(
                label: 'Model year',
                controller: _year,
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value == null || !FormValidators.isValidVehicleYear(value)
                    ? 'Enter a valid model year (1990–${DateTime.now().year + 1})'
                    : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _seats,
                decoration: const InputDecoration(
                  labelText: 'Seats for passengers',
                ),
                items: List.generate(
                  4,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text('${index + 1} seats'),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) setState(() => _seats = value);
                },
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Vehicle registration no.',
                controller: _registration,
                validator: (value) =>
                    _required(value, 'your vehicle registration number'),
              ),
              const SizedBox(height: 20),
              const Text(
                'Required documents',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'After registration, upload CNIC front/back, driving licence, vehicle registration, and vehicle photo from Verification status.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              if (_documentError != null) ...[
                const SizedBox(height: 4),
                Text(
                  _documentError!,
                  style: const TextStyle(
                    color: AppColors.statusDangerText,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              AppButton(
                text: 'Submit for verification',
                isLoading: _isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
