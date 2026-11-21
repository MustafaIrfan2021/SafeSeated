import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';

class CreateRideRequestDialog extends ConsumerStatefulWidget {
  final String initialPickup;

  const CreateRideRequestDialog({super.key, this.initialPickup = ''});

  @override
  ConsumerState<CreateRideRequestDialog> createState() =>
      _CreateRideRequestDialogState();
}

class _CreateRideRequestDialogState
    extends ConsumerState<CreateRideRequestDialog> {
  late TextEditingController _pickupController;
  final _destinationController = TextEditingController(
    text: 'SMIU, Shahrah-e-Faisal',
  );
  final _timeController = TextEditingController();
  int _seats = 1;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pickupController = TextEditingController(
      text: widget.initialPickup.isNotEmpty
          ? widget.initialPickup
          : 'Gulistan-e-Jauhar',
    );
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final p = _pickupController.text.trim();
    final d = _destinationController.text.trim();
    final t = _timeController.text.trim();

    if (p.isEmpty || d.isEmpty || t.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all request fields.'),
          backgroundColor: AppColors.statusDangerText,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(rideRepositoryProvider);
      await repo.createPassengerRideRequest(
        passengerEmail: user.email,
        passengerName: user.name,
        pickup: p,
        destination: d,
        time: t,
        seats: _seats,
      );

      // Invalidate requests provider
      ref.invalidate(passengerRideRequestsProvider);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride request submitted to available drivers.'),
            backgroundColor: AppColors.statusSuccessText,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
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
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Request a custom ride',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close,
                  size: 20,
                  color: AppColors.textMuted,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Text(
            'Verified drivers matching your route will see your request and offer seats.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Pickup area',
            hint: 'e.g. Gulshan-e-Iqbal Block 5',
            controller: _pickupController,
          ),
          AppTextField(
            label: 'Destination',
            hint: 'e.g. SMIU, Shahrah-e-Faisal',
            controller: _destinationController,
          ),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Pickup time',
                  hint: 'e.g. 2026-11-20 08:15',
                  controller: _timeController,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seats',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 16),
                          onPressed: _seats > 1
                              ? () => setState(() => _seats--)
                              : null,
                        ),
                        Text(
                          '$_seats',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 16),
                          onPressed: _seats < 4
                              ? () => setState(() => _seats++)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppButton(
            text: 'Send request to drivers',
            isLoading: _isLoading,
            onPressed: _submitRequest,
          ),
        ],
      ),
    );
  }
}
