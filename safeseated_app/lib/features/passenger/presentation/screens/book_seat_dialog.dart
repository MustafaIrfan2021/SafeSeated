import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/app_providers.dart';
import '../../domain/models/ride.dart';
import '../../../../core/widgets/app_button.dart';

class BookSeatDialog extends ConsumerStatefulWidget {
  final Ride ride;

  const BookSeatDialog({super.key, required this.ride});

  @override
  ConsumerState<BookSeatDialog> createState() => _BookSeatDialogState();
}

class _BookSeatDialogState extends ConsumerState<BookSeatDialog> {
  int _seats = 1;
  late TextEditingController _pickupTimeController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _pickupTimeController = TextEditingController(
      text: widget.ride.departureAt.toUtc().toIso8601String(),
    );
  }

  @override
  void dispose() {
    _pickupTimeController.dispose();
    super.dispose();
  }

  int get _maxAvailable => widget.ride.seatsAvailable;
  int get _totalFare => widget.ride.farePerSeat * _seats;

  Future<void> _submitBooking() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    if (_seats > _maxAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only $_maxAvailable seats left on this ride.'),
          backgroundColor: AppColors.statusDangerText,
        ),
      );
      return;
    }

    final pickup = _pickupTimeController.text.trim();
    if (pickup.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please specify your preferred pickup time.'),
          backgroundColor: AppColors.statusDangerText,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(bookingRepositoryProvider);
      await repo.createBooking(
        rideId: widget.ride.id,
        passengerEmail: user.email,
        passengerName: user.name,
        seats: _seats,
        pickupTime: pickup,
        totalFare: _totalFare,
      );

      // Refresh bookings
      ref.invalidate(passengerBookingsProvider);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Booking request submitted to ${widget.ride.driverName}.',
            ),
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
        setState(() => _isSubmitting = false);
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
                'Request seats',
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
          Text(
            '${widget.ride.from} ➔ ${widget.ride.to}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Seats availability bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Seat availability',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '$_maxAvailable of ${widget.ride.seatsTotal} seats remaining',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stepper for number of seats
          Row(
            children: [
              const Text(
                'Number of seats',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(10),
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 16),
                      onPressed: _seats < _maxAvailable
                          ? () => setState(() => _seats++)
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Pickup time input
          const Text(
            'Preferred pickup time',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _pickupTimeController,
            decoration: const InputDecoration(
              hintText: 'e.g. 8:15 AM',
              prefixIcon: Icon(
                Icons.access_time,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Total calculation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total fare (cash to driver)',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              Text(
                'Rs $_totalFare',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          AppButton(
            text: 'Send request to driver',
            isLoading: _isSubmitting,
            onPressed: _submitBooking,
          ),
        ],
      ),
    );
  }
}
