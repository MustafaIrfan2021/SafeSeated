import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/app_providers.dart';
import '../../domain/models/booking.dart';
import '../../domain/models/ride.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../../core/widgets/status_pill.dart';
import 'live_trip_screen.dart';
import 'rate_driver_dialog.dart';

class PassengerBookingsScreen extends ConsumerWidget {
  const PassengerBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final selectedTab = ref.watch(bookingTabProvider);
    final bookingsAsync = ref.watch(
      passengerBookingsProvider(user?.email ?? ''),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('My bookings'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Segmented Tab Filter Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.background,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EDFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTab(
                        ref,
                        'Pending',
                        BookingStatus.pending,
                        selectedTab,
                      ),
                      _buildTab(
                        ref,
                        'Accepted',
                        BookingStatus.accepted,
                        selectedTab,
                      ),
                      _buildTab(
                        ref,
                        'In progress',
                        BookingStatus.active,
                        selectedTab,
                      ),
                      _buildTab(
                        ref,
                        'Rejected',
                        BookingStatus.rejected,
                        selectedTab,
                      ),
                      _buildTab(
                        ref,
                        'Cancelled',
                        BookingStatus.cancelled,
                        selectedTab,
                      ),
                      _buildTab(
                        ref,
                        'Completed',
                        BookingStatus.completed,
                        selectedTab,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bookings List
            Expanded(
              child: bookingsAsync.when(
                data: (bookings) {
                  if (bookings.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 44,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No ${selectedTab.label.toLowerCase()} bookings.',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Search available rides or request a custom route.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final booking = bookings[index];
                      final ride = ref.watch(rideByIdProvider(booking.rideId));
                      return ride.when(
                        data: (ride) =>
                            _buildBookingCard(context, ref, booking, ride),
                        loading: () => const Card(
                          child: ListTile(
                            title: Text('Loading trip details…'),
                            leading: CircularProgressIndicator(),
                          ),
                        ),
                        error: (error, stack) =>
                            Text('Could not load trip details: $error'),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Could not load bookings: $error'),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => ref.invalidate(
                          passengerBookingsProvider(user?.email ?? ''),
                        ),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(
    WidgetRef ref,
    String label,
    BookingStatus status,
    BookingStatus current,
  ) {
    final isSelected = current == status;
    return SizedBox(
      width: 88,
      child: GestureDetector(
        onTap: () {
          ref.read(bookingTabProvider.notifier).state = status;
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
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
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(
    BuildContext context,
    WidgetRef ref,
    Booking booking,
    Ride? ride,
  ) {
    final driverName = ride?.driverName ?? 'Driver';
    final vehicle = ride?.vehicleInfo ?? 'Verified Vehicle';
    final plate = ride?.vehiclePlate ?? 'Plate';
    final routeText = '${ride?.from ?? "Pickup"} ➔ ${ride?.to ?? "SMIU"}';

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarWidget(name: driverName, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routeText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '$driverName · $vehicle ($plate)',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill.fromStatus(booking.status.label),
            ],
          ),
          const Divider(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${booking.date} · pickup ${booking.pickupTime}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${booking.seats} seat(s) · Rs ${booking.totalFare}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: Text('Booking #${booking.id}'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _detailRow('Route', routeText),
                      _detailRow('Driver', driverName),
                      _detailRow('Vehicle', '$vehicle · $plate'),
                      _detailRow('Status', booking.status.label),
                      _detailRow('Travel date', booking.date),
                      _detailRow('Pickup time', booking.pickupTime),
                      _detailRow('Seats', '${booking.seats}'),
                      _detailRow('Total fare', 'Rs ${booking.totalFare}'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
              icon: const Icon(Icons.receipt_long_outlined, size: 16),
              label: const Text('Booking details'),
            ),
          ),

          // Action Buttons depending on status
          if (booking.status == BookingStatus.pending) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.statusDangerText,
                  side: const BorderSide(color: AppColors.statusDangerBorder),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Cancel booking request?'),
                      content: const Text(
                        'This will cancel your pending booking request.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('No, keep'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            'Yes, cancel',
                            style: TextStyle(color: AppColors.statusDangerText),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await ref
                        .read(bookingRepositoryProvider)
                        .cancelBooking(booking.id);
                    final user = ref.read(authStateProvider).value;
                    if (user != null) {
                      ref.invalidate(passengerBookingsProvider(user.email));
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Booking request cancelled.'),
                          backgroundColor: AppColors.textSecondary,
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  'Cancel request',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ] else if ((booking.status == BookingStatus.accepted ||
                  booking.status == BookingStatus.active) &&
              ride != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.location_on, size: 16),
                label: const Text(
                  'View trip status',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) =>
                          LiveTripScreen(booking: booking, ride: ride),
                    ),
                  );
                },
              ),
            ),
          ] else if (booking.status == BookingStatus.completed) ...[
            const SizedBox(height: 10),
            if (booking.rating != null) ...[
              Row(
                children: [
                  Text(
                    '★' * (booking.rating ?? 5),
                    style: const TextStyle(
                      color: AppColors.starGold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '“${booking.reviewText ?? "Safe ride"}”',
                      style: const TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(
                    Icons.star,
                    size: 16,
                    color: AppColors.starGold,
                  ),
                  label: const Text(
                    '★ Rate this driver',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentLavender,
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      builder: (ctx) => RateDriverDialog(booking: booking),
                    );
                  },
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
