import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../auth/domain/models/user.dart';
import '../../../passenger/domain/models/ride_request.dart';

Future<bool> showDriverRequestOfferDialog({
  required BuildContext context,
  required User user,
  required PassengerRideRequest request,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (_) => _DriverRequestOfferDialog(user: user, request: request),
      ) ??
      false;
}

class _DriverRequestOfferDialog extends ConsumerStatefulWidget {
  final User user;
  final PassengerRideRequest request;

  const _DriverRequestOfferDialog({required this.user, required this.request});

  @override
  ConsumerState<_DriverRequestOfferDialog> createState() =>
      _DriverRequestOfferDialogState();
}

class _DriverRequestOfferDialogState
    extends ConsumerState<_DriverRequestOfferDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _fare = TextEditingController(text: '350');
  late final _seats = TextEditingController(
    text: widget.user.seatsTotal.toString(),
  );
  bool _saving = false;

  @override
  void dispose() {
    _fare.dispose();
    _seats.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(bookingRepositoryProvider)
          .offerRideForPassengerRequest(
            requestId: widget.request.id,
            driverEmail: widget.user.email,
            driverName: widget.user.name,
            farePerSeat: int.parse(_fare.text),
            seatsOffered: int.parse(_seats.text),
            vehicleSeatCapacity: widget.user.seatsTotal,
            vehicleInfo:
                '${widget.user.vehicleMake ?? 'Vehicle'} · ${widget.user.vehicleColor ?? ''}',
            vehiclePlate:
                widget.user.vehiclePlate ??
                widget.user.vehicleRegistration ??
                '',
          );
      ref.invalidate(openPassengerRideRequestsProvider);
      ref.invalidate(driverBookingsProvider(widget.user.email));
      ref.invalidate(driverRidesProvider(widget.user.email));
      ref.invalidate(passengerBookingsProvider(widget.request.passengerEmail));
      ref.invalidate(
        allPassengerBookingsProvider(widget.request.passengerEmail),
      );
      ref.invalidate(
        passengerRideRequestsProvider(widget.request.passengerEmail),
      );
      ref.invalidate(availableRidesProvider);
      ref.invalidate(allAvailableRidesProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceAll('Bad state: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add ride for this request'),
    content: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.request.pickup} → ${widget.request.destination}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.request.time} · ${widget.request.seats} seat(s) requested',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fare,
                decoration: const InputDecoration(
                  labelText: 'Fare per seat (PKR)',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final amount = int.tryParse(value ?? '');
                  return amount == null || amount < 1
                      ? 'Enter a fare greater than zero'
                      : null;
                },
              ),
              TextFormField(
                controller: _seats,
                decoration: InputDecoration(
                  labelText: 'Seats you offer (max ${widget.user.seatsTotal})',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final count = int.tryParse(value ?? '');
                  if (count == null || count < widget.request.seats) {
                    return 'Offer at least ${widget.request.seats} seat(s)';
                  }
                  if (count > widget.user.seatsTotal) {
                    return 'Your vehicle has ${widget.user.seatsTotal} seats';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context, false),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _saving ? null : _submit,
        child: Text(_saving ? 'Adding ride…' : 'Confirm & add ride'),
      ),
    ],
  );
}
