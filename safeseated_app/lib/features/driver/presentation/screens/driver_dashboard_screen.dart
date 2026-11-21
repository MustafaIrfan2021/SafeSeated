import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../passenger/domain/models/booking.dart';
import 'driver_request_offer_dialog.dart';

class DriverDashboardScreen extends ConsumerWidget {
  const DriverDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const SizedBox.shrink();
    final online = ref.watch(driverOnlineProvider(user.email));
    ref.watch(driverRidesProvider(user.email));
    final bookings = ref.watch(driverBookingsProvider(user.email));
    final notifications = ref.watch(notificationsProvider(user.email));
    final requests = ref.watch(openPassengerRideRequestsProvider);
    final unreadCount =
        notifications.valueOrNull?.where((item) => !item.isRead).length ?? 0;
    final bookingItems = bookings.valueOrNull ?? const <Booking>[];
    final completed = bookingItems
        .where((booking) => booking.status == BookingStatus.completed)
        .toList();
    final ratingItems = completed
        .where((booking) => booking.rating != null)
        .toList();
    final averageRating = ratingItems.isEmpty
        ? '—'
        : (ratingItems.fold<int>(
                    0,
                    (total, booking) => total + booking.rating!,
                  ) /
                  ratingItems.length)
              .toStringAsFixed(1);
    final earnings = completed.fold<int>(
      0,
      (total, booking) => total + booking.totalFare,
    );
    final pending = bookingItems
        .where((booking) => booking.status == BookingStatus.pending)
        .toList();
    final accepted = bookingItems
        .where(
          (booking) =>
              booking.status == BookingStatus.accepted ||
              booking.status == BookingStatus.active,
        )
        .toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 26),
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
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Driver dashboard',
                          style: TextStyle(
                            color: Color(0xFFE9E5FF),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.name.split(' ').first,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        onPressed: () => context.push(AppRoutes.notifications),
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: Colors.white,
                        ),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          top: 5,
                          right: 7,
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF5D73),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(driverOnlineProvider(user.email));
                  ref.invalidate(driverRidesProvider(user.email));
                  ref.invalidate(driverBookingsProvider(user.email));
                  ref.invalidate(openPassengerRideRequestsProvider);
                  await ref.read(driverRidesProvider(user.email).future);
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    online.valueOrNull == false
                                        ? 'You are offline'
                                        : 'You are online',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    online.valueOrNull == false
                                        ? 'Passengers cannot see your rides'
                                        : 'Passengers can see and request your rides',
                                  ),
                                ],
                              ),
                            ),
                            online.when(
                              data: (isOnline) => FilledButton.tonal(
                                onPressed: () async {
                                  await ref
                                      .read(rideRepositoryProvider)
                                      .setDriverOnline(user.email, !isOnline);
                                  ref.invalidate(
                                    driverOnlineProvider(user.email),
                                  );
                                  ref.invalidate(availableRidesProvider);
                                  ref.invalidate(allAvailableRidesProvider);
                                },
                                child: Text(
                                  isOnline ? 'Go offline' : 'Go online',
                                ),
                              ),
                              loading: () => const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              error: (error, stack) => const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            label: 'Rating',
                            value: averageRating,
                            icon: Icons.star_outline,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MetricCard(
                            label: 'Earnings',
                            value: 'PKR $earnings',
                            icon: Icons.account_balance_wallet_outlined,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MetricCard(
                            label: 'New requests',
                            value: '${pending.length}',
                            icon: Icons.mark_email_unread_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Passenger ride requests',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        requests.when(
                          data: (items) => _CountBadge(count: items.length),
                          loading: () => const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          error: (error, stack) =>
                              const Icon(Icons.error_outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    requests.when(
                      data: (items) {
                        if (items.isEmpty) {
                          return const _EmptyCard(
                            'No open passenger requests.',
                          );
                        }
                        return Column(
                          children: items
                              .map(
                                (request) => Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const CircleAvatar(
                                              child: Icon(Icons.person_outline),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                request.passengerName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            const _StatusBadge(label: 'Open'),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          '${request.pickup} → ${request.destination}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        _DetailRow(
                                          label: 'Pickup time',
                                          value: request.time,
                                        ),
                                        _DetailRow(
                                          label: 'Seats needed',
                                          value: '${request.seats}',
                                        ),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          width: double.infinity,
                                          child: FilledButton(
                                            onPressed: () async {
                                              final added =
                                                  await showDriverRequestOfferDialog(
                                                    context: context,
                                                    user: user,
                                                    request: request,
                                                  );
                                              if (added && context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Ride added and passenger booking accepted.',
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                            child: const Text(
                                              'Add ride for this request',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => _EmptyCard(
                        'Could not load passenger requests: $error',
                      ),
                    ),
                    const SizedBox(height: 10),
                    _SectionHeader(
                      title: 'Ride requests',
                      action: 'View all',
                      onPressed: () => context.go(AppRoutes.driverTrips),
                    ),
                    const SizedBox(height: 8),
                    if (pending.isEmpty)
                      const _EmptyCard('No pending booking requests.')
                    else
                      ...pending.map(
                        (booking) => _DashboardBookingCard(
                          booking: booking,
                          onAction: (status) => _changeBookingStatus(
                            context,
                            ref,
                            user.email,
                            booking,
                            status,
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    _SectionHeader(
                      title: 'Accepted trips',
                      action: 'View all',
                      onPressed: () => context.go(AppRoutes.driverTrips),
                    ),
                    const SizedBox(height: 8),
                    if (accepted.isEmpty)
                      const _EmptyCard('No accepted trips.')
                    else
                      ...accepted.map(
                        (booking) => _DashboardBookingCard(
                          booking: booking,
                          onAction: (status) => _changeBookingStatus(
                            context,
                            ref,
                            user.email,
                            booking,
                            status,
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () => context.go(AppRoutes.driverRides),
                      icon: const Icon(Icons.directions_car_outlined),
                      label: const Text('Manage my rides'),
                    ),
                    const SizedBox(height: 8),
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(14),
                        child: Text(
                          'Demo only: payments, notifications and live trip tracking are not connected.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _changeBookingStatus(
  BuildContext context,
  WidgetRef ref,
  String driverEmail,
  Booking booking,
  BookingStatus status,
) async {
  try {
    await ref
        .read(bookingRepositoryProvider)
        .updateDriverBookingStatus(
          bookingId: booking.id,
          driverEmail: driverEmail,
          status: status,
        );
    ref.invalidate(driverBookingsProvider(driverEmail));
    ref.invalidate(driverRidesProvider(driverEmail));
    ref.invalidate(passengerBookingsProvider(booking.passengerEmail));
    ref.invalidate(allPassengerBookingsProvider(booking.passengerEmail));
    ref.invalidate(availableRidesProvider);
    ref.invalidate(allAvailableRidesProvider);
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceAll('Bad state: ', ''))),
      );
    }
  }
}

class _DashboardBookingCard extends ConsumerWidget {
  final Booking booking;
  final ValueChanged<BookingStatus> onAction;

  const _DashboardBookingCard({required this.booking, required this.onAction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ride = ref.watch(rideByIdProvider(booking.rideId));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              booking.passengerName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            ride.when(
              data: (item) => Text(
                item == null
                    ? 'Ride details unavailable'
                    : '${item.from} → ${item.to}',
              ),
              loading: () => const LinearProgressIndicator(),
              error: (error, stack) => const Text('Ride details unavailable'),
            ),
            const SizedBox(height: 4),
            Text(
              '${booking.pickupTime} · ${booking.seats} seat(s) · PKR ${booking.totalFare}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: switch (booking.status) {
                BookingStatus.pending => [
                  OutlinedButton(
                    onPressed: () => onAction(BookingStatus.rejected),
                    child: const Text('Reject'),
                  ),
                  FilledButton(
                    onPressed: () => onAction(BookingStatus.accepted),
                    child: const Text('Accept'),
                  ),
                ],
                BookingStatus.accepted => [
                  FilledButton(
                    onPressed: () => onAction(BookingStatus.active),
                    child: const Text('Start trip'),
                  ),
                ],
                BookingStatus.active => [
                  FilledButton(
                    onPressed: () => onAction(BookingStatus.completed),
                    child: const Text('Mark completed'),
                  ),
                ],
                _ => const <Widget>[],
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: Theme.of(context).textTheme.titleLarge),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback onPressed;

  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      TextButton(onPressed: onPressed, child: Text(action)),
    ],
  );
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) =>
      Chip(label: Text('$count'), visualDensity: VisualDensity.compact);
}

class _StatusBadge extends StatelessWidget {
  final String label;
  const _StatusBadge({required this.label});

  @override
  Widget build(BuildContext context) =>
      Chip(label: Text(label), visualDensity: VisualDensity.compact);
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

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

class _EmptyCard extends StatelessWidget {
  final String text;
  const _EmptyCard(this.text);

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Text(text, style: const TextStyle(color: AppColors.textSecondary)),
    ),
  );
}
