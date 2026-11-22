import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../passenger/domain/models/booking.dart';

class DriverTripsScreen extends ConsumerStatefulWidget {
  const DriverTripsScreen({super.key, this.isActive = true});

  final bool isActive;

  @override
  ConsumerState<DriverTripsScreen> createState() => _DriverTripsScreenState();
}

class _DriverTripsScreenState extends ConsumerState<DriverTripsScreen> {
  static const _statuses = [
    BookingStatus.pending,
    BookingStatus.accepted,
    BookingStatus.rejected,
    BookingStatus.completed,
  ];

  BookingStatus _selectedStatus = BookingStatus.pending;

  @override
  void didUpdateWidget(covariant DriverTripsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        ref.invalidate(driverBookingsProvider(user.email));
      }
    }
  }

  Future<void> _changeStatus(
    BuildContext context,
    String email,
    Booking booking,
    BookingStatus status,
  ) async {
    try {
      await ref
          .read(bookingRepositoryProvider)
          .updateDriverBookingStatus(
            bookingId: booking.id,
            driverEmail: email,
            status: status,
          );
      ref.invalidate(driverBookingsProvider(email));
      ref.invalidate(driverRidesProvider(email));
      ref.invalidate(passengerBookingsProvider(booking.passengerEmail));
      ref.invalidate(allPassengerBookingsProvider(booking.passengerEmail));
      ref.invalidate(availableRidesProvider);
      ref.invalidate(allAvailableRidesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking marked ${status.label.toLowerCase()}.'),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceAll('Bad state: ', '')),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const SizedBox.shrink();
    final bookings = ref.watch(driverBookingsProvider(user.email));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride requests'),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(driverBookingsProvider(user.email));
          await ref.read(driverBookingsProvider(user.email).future);
        },
        child: bookings.when(
          data: (items) {
            final filtered = items.where((booking) {
              return booking.status == _selectedStatus ||
                  (_selectedStatus == BookingStatus.accepted &&
                      booking.status == BookingStatus.active);
            }).toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statuses.map((status) {
                      final count = items.where((booking) {
                        return booking.status == status ||
                            (status == BookingStatus.accepted &&
                                booking.status == BookingStatus.active);
                      }).length;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('${status.label} ($count)'),
                          selected: _selectedStatus == status,
                          onSelected: (_) =>
                              setState(() => _selectedStatus = status),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                if (filtered.isEmpty)
                  _EmptyMessage(
                    'No ${_selectedStatus.label.toLowerCase()} requests.',
                  )
                else
                  ...filtered.map(
                    (booking) => _TripBookingCard(
                      booking: booking,
                      onAction: (status) =>
                          _changeStatus(context, user.email, booking, status),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) =>
              Center(child: Text('Could not load bookings: $error')),
        ),
      ),
    );
  }
}

class _TripBookingCard extends ConsumerWidget {
  final Booking booking;
  final ValueChanged<BookingStatus> onAction;

  const _TripBookingCard({required this.booking, required this.onAction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ride = ref.watch(rideByIdProvider(booking.rideId));
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(
                    booking.passengerName.isEmpty
                        ? '?'
                        : booking.passengerName[0].toUpperCase(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.passengerName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${booking.date} · ${booking.pickupTime}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(booking.status.label),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 10),
            ride.when(
              data: (item) => Text(
                item == null
                    ? 'Ride details unavailable'
                    : '${item.from} → ${item.to}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (error, stack) => const Text('Ride details unavailable'),
            ),
            const SizedBox(height: 6),
            _InfoRow(label: 'Fare', value: 'PKR ${booking.totalFare}'),
            _InfoRow(label: 'Seats requested', value: '${booking.seats}'),
            if (booking.status == BookingStatus.completed) ...[
              const SizedBox(height: 4),
              _InfoRow(
                label: 'Passenger rating',
                value: booking.rating == null
                    ? 'Not rated yet'
                    : '${booking.rating} / 5',
              ),
              if (booking.reviewText?.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '“${booking.reviewText}”',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: _actions()),
          ],
        ),
      ),
    );
  }

  List<Widget> _actions() {
    switch (booking.status) {
      case BookingStatus.pending:
        return [
          OutlinedButton(
            onPressed: () => onAction(BookingStatus.rejected),
            child: const Text('Reject'),
          ),
          FilledButton(
            onPressed: () => onAction(BookingStatus.accepted),
            child: const Text('Approve'),
          ),
        ];
      case BookingStatus.accepted:
        return [
          FilledButton(
            onPressed: () => onAction(BookingStatus.active),
            child: const Text('Start trip'),
          ),
        ];
      case BookingStatus.active:
        return [
          FilledButton(
            onPressed: () => onAction(BookingStatus.completed),
            child: const Text('Mark trip completed'),
          ),
        ];
      case BookingStatus.rejected:
      case BookingStatus.cancelled:
      case BookingStatus.completed:
        return const [];
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _EmptyMessage extends StatelessWidget {
  final String text;
  const _EmptyMessage(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Center(
      child: Text(text, style: const TextStyle(color: AppColors.textSecondary)),
    ),
  );
}
