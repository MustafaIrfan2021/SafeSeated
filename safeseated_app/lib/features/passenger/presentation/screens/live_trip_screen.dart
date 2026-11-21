import 'package:material_ui/material_ui.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/models/booking.dart';
import '../../domain/models/ride.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../core/widgets/karachi_map_canvas.dart';
import 'trip_chat_screen.dart';
import '../../../safety/presentation/screens/sos_dialog.dart';

class LiveTripScreen extends StatelessWidget {
  final Booking booking;
  final Ride ride;

  const LiveTripScreen({super.key, required this.booking, required this.ride});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live trip')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom Animated Karachi Map
              KarachiMapCanvas(
                pickup: ride.from,
                destination: ride.to,
                eta: 'Route preview only',
              ),
              const SizedBox(height: 16),

              // Live Status Card
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
                              Text(
                                '${ride.vehicleInfo} · ${ride.vehiclePlate}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const StatusPill(
                          text: 'Demo trip',
                          variant: PillVariant.info,
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    _buildRow(
                      'Booking status',
                      booking.status.label,
                      highlightColor: AppColors.primary,
                      isBold: true,
                    ),
                    const Divider(height: 16),
                    _buildRow('Pickup area', ride.from),
                    const Divider(height: 16),
                    _buildRow('Destination', ride.to),
                    const Divider(height: 16),
                    _buildRow(
                      'Cash fare to pay',
                      'Rs ${booking.totalFare}',
                      isBold: true,
                    ),
                    const SizedBox(height: 16),

                    // Quick Trip Controls
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(
                              Icons.chat_bubble_outline,
                              size: 16,
                            ),
                            label: const Text(
                              'Chat',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (ctx) => TripChatScreen(
                                    booking: booking,
                                    ride: ride,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.phone_outlined, size: 16),
                            label: const Text(
                              'Call',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Calling is not connected in this demo.',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.share_outlined, size: 16),
                            label: const Text(
                              'Share',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Live trip sharing is not connected in this demo.',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // High-priority SOS in-trip trigger
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          Icons.warning_amber_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: const Text(
                          '🚨 Emergency SOS',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.sosRed,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => const SosDialog(),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              // Safety info card
              AppCard(
                color: AppColors.surfaceSubtle,
                child: const Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This animated map is a visual preview only. Live GPS tracking and trip sharing are not connected.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
