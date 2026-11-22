import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/pakistan_time.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/app_providers.dart';
import '../../domain/models/ride.dart';
import '../../domain/models/booking.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../core/widgets/karachi_map_canvas.dart';
import 'book_seat_dialog.dart';

class RideDetailsScreen extends ConsumerWidget {
  final Ride ride;

  const RideDetailsScreen({super.key, required this.ride});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final bookingsAsync = ref.watch(
      allPassengerBookingsProvider(user?.email ?? ''),
    );

    Booking? existingBooking;
    bookingsAsync.whenData((bookings) {
      existingBooking = bookings.cast<Booking?>().firstWhere(
        (b) =>
            b?.rideId == ride.id &&
            (b?.status == BookingStatus.pending ||
                b?.status == BookingStatus.accepted ||
                b?.status == BookingStatus.active),
        orElse: () => null,
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Ride details')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Map preview
              KarachiMapCanvas(
                pickup: ride.from,
                destination: ride.to,
                eta: 'Departs ${ride.departureTime}',
              ),
              const SizedBox(height: 16),

              // Ride facts card
              AppCard(
                child: Column(
                  children: [
                    _buildRow('Pickup', ride.from, isBold: true),
                    const Divider(height: 16),
                    _buildRow('Drop-off', ride.to, isBold: true),
                    const Divider(height: 16),
                    _buildRow(
                      'Departure',
                      '${DateFormat('EEE, d MMM yyyy').format(PakistanTime.toPakistan(ride.departureAt))} · ${ride.departureTime}',
                    ),
                    const Divider(height: 16),
                    _buildRow('Seats offered', '${ride.seatsTotal} seats'),
                    const Divider(height: 16),
                    _buildRow('Seats booked', '${ride.seatsBooked} seats'),
                    const Divider(height: 16),
                    _buildRow(
                      'Seats remaining',
                      '${ride.seatsAvailable} seats',
                      highlightColor: ride.seatsAvailable > 0
                          ? AppColors.primary
                          : AppColors.statusDangerText,
                    ),
                    const Divider(height: 16),
                    _buildRow(
                      'Fare per seat',
                      'Rs ${ride.farePerSeat} (cash to driver)',
                      isBold: true,
                      highlightColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Driver & Vehicle Card
              AppCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        AvatarWidget(name: ride.driverName, size: 48),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ride.driverName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 14,
                                    color: AppColors.starGold,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${ride.driverRating} · ${ride.driverReviewCount} reviews',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (ride.isDriverVerified)
                          const StatusPill(
                            text: '✓ Verified',
                            variant: PillVariant.success,
                          ),
                      ],
                    ),
                    const Divider(height: 20),
                    _buildRow('Vehicle', ride.vehicleInfo),
                    const Divider(height: 16),
                    _buildRow('Number plate', ride.vehiclePlate),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Passenger Reviews Section
              const Text(
                'Passenger reviews',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text(
                          '★★★★★',
                          style: TextStyle(
                            color: AppColors.starGold,
                            fontSize: 16,
                          ),
                        ),
                        Spacer(),
                        Text(
                          'Ayesha K. · SMIU',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '“Very safe, clean vehicle and very punctual driving. Highly recommend for university students.”',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const Divider(height: 20),
                    const Row(
                      children: [
                        Text(
                          '★★★★★',
                          style: TextStyle(
                            color: AppColors.starGold,
                            fontSize: 16,
                          ),
                        ),
                        Spacer(),
                        Text(
                          'Mahnoor R. · SMIU',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '“Always on time and respects women commuter safety guidelines. Great carpool companion.”',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action button
              if (existingBooking != null)
                AppButton(
                  text: switch (existingBooking!.status) {
                    BookingStatus.pending =>
                      'Request sent (Pending driver response)',
                    BookingStatus.active =>
                      'Trip in progress · View in Bookings',
                    _ => 'Seat confirmed · View in Bookings',
                  },
                  variant: AppButtonVariant.secondary,
                  onPressed: null,
                )
              else if (ride.isFull)
                const AppButton(
                  text: 'Ride is fully booked',
                  variant: AppButtonVariant.secondary,
                  onPressed: null,
                )
              else
                AppButton(
                  text: 'Request seat (Rs ${ride.farePerSeat})',
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      builder: (ctx) => BookSeatDialog(ride: ride),
                    );
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    bool isBold = false,
    Color? highlightColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: highlightColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
